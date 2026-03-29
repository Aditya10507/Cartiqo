import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import twilio from 'twilio';
import { existsSync, readFileSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Initialize Firebase Admin
admin.initializeApp();

function loadLocalEnv(): void {
  const currentDir = path.dirname(fileURLToPath(import.meta.url));
  const envPath = path.join(currentDir, '..', '.env');

  if (!existsSync(envPath)) {
    return;
  }

  const envFile = readFileSync(envPath, 'utf8');
  for (const rawLine of envFile.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) {
      continue;
    }

    const separatorIndex = line.indexOf('=');
    if (separatorIndex <= 0) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (!process.env[key]) {
      process.env[key] = value;
    }
  }
}

loadLocalEnv();

function getRequiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(
      `Missing ${name}. Set it in functions/.env for local deploys or use Firebase Functions secrets for production.`
    );
  }
  return value;
}

function getTwilioClient() {
  const accountSid = getRequiredEnv('TWILIO_ACCOUNT_SID');
  const authToken = getRequiredEnv('TWILIO_AUTH_TOKEN');
  return twilio(accountSid, authToken);
}

/**
 * Cloud Function: Send SMS OTP
 * Triggers when a new phone_otp document is created
 * Sends SMS via Twilio to the phone number with the OTP code
 */
export const sendPhoneOtp = functions
  .region('us-central1')
  .firestore.document('phone_otp/{phoneNumber}')
  .onCreate(async (snap: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    try {
      const phoneNumber = context.params.phoneNumber as string;
      const otpData = snap.data();
      if (!otpData) {
        throw new Error('OTP document has no data');
      }
      const otp = otpData.otp as string;
      const createdAt = otpData.createdAt as admin.firestore.Timestamp;

      functions.logger.info(
        `Sending OTP to ${phoneNumber}`,
        { otp, createdAt }
      );

      // Validate phone number format
      if (!phoneNumber.startsWith('+')) {
        throw new Error('Phone number must include country code (e.g., +1234567890)');
      }

      // Send SMS via Twilio
      const twilioClient = getTwilioClient();
      const message = await twilioClient.messages.create({
        body: `Your SwiftCart OTP is: ${otp}\n\nValid for 5 minutes. Do not share with anyone.`,
        from: getRequiredEnv('TWILIO_PHONE_NUMBER'),
        to: phoneNumber,
      });

      functions.logger.info(
        `SMS sent successfully to ${phoneNumber}`,
        { messageId: message.sid }
      );

      // Update Firestore document to mark SMS as sent
      await snap.ref.update({
        smsSent: true,
        smsSentAt: admin.firestore.FieldValue.serverTimestamp(),
        twilioMessageSid: message.sid,
      });

      return { success: true, messageId: message.sid };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      functions.logger.error(`Failed to send OTP SMS: ${errorMessage}`, { error });

      // Update document to record failure
      try {
        await snap.ref.update({
          smsSent: false,
          smsError: errorMessage,
          smsErrorAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        functions.logger.error('Failed to update OTP document with error', { updateError });
      }

      throw new functions.https.HttpsError(
        'internal',
        `Failed to send SMS: ${errorMessage}`
      );
    }
  });

/**
 * Cloud Function: Cleanup Expired OTPs
 * Runs every 10 minutes via Cloud Scheduler
 * Deletes OTP documents that have expired (expiresAt < now)
 */
export const cleanupExpiredOtps = functions
  .region('us-central1')
  .pubsub.schedule('every 10 minutes')
  .onRun(async (context: any) => {
    try {
      const now = admin.firestore.Timestamp.now();
      const db = admin.firestore();
      const batch = db.batch();

      // Query all expired OTPs
      const snapshot = await db
        .collection('phone_otp')
        .where('expiresAt', '<', now)
        .get();

      functions.logger.info(`Found ${snapshot.size} expired OTP documents to delete`);

      // Delete in batches (Firestore batch operation limit is 500)
      snapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
        batch.delete(doc.ref);
      });

      if (snapshot.size > 0) {
        await batch.commit();
        functions.logger.info(`Successfully deleted ${snapshot.size} expired OTP documents`);
      }

      return { deletedCount: snapshot.size };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      functions.logger.error(`Cleanup job failed: ${errorMessage}`, { error });
      throw error;
    }
  });

/**
 * Optional HTTP Endpoint: Manual OTP verification (if client-side verification fails)
 * POST /verifyOtp with { phoneNumber, otp }
 */
export const verifyOtpManual = functions
  .region('us-central1')
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    try {
      const { phoneNumber, otp } = data;

      // Validate input
      if (!phoneNumber || !otp) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing phoneNumber or otp'
        );
      }

      // Get OTP document
      const db = admin.firestore();
      const otpDoc = await db.collection('phone_otp').doc(phoneNumber).get();

      if (!otpDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'No OTP found for this phone number'
        );
      }

      const otpData = otpDoc.data();

      // Check expiry
      const now = admin.firestore.Timestamp.now();
      if (otpData?.expiresAt < now) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'OTP has expired'
        );
      }

      // Check attempts
      if ((otpData?.attempts || 0) >= (otpData?.maxAttempts || 5)) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Maximum verification attempts exceeded'
        );
      }

      // Verify OTP
      if (otpData?.otp !== otp) {
        // Increment attempts
        await otpDoc.ref.update({
          attempts: (otpData?.attempts || 0) + 1,
        });

        throw new functions.https.HttpsError(
          'unauthenticated',
          'Invalid OTP'
        );
      }

      // Verification successful
      functions.logger.info(`OTP verified successfully for ${phoneNumber}`);

      return { success: true, message: 'OTP verified successfully' };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      functions.logger.error(`Manual OTP verification failed: ${errorMessage}`, { error });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError('internal', `Verification failed: ${errorMessage}`);
    }
  });

/**
 * Cloud Function: Log OTP SMS Events
 * Optional: Track OTP events for analytics
 */
export const logOtpEvent = functions
  .region('us-central1')
  .firestore.document('phone_otp/{phoneNumber}')
  .onUpdate(async (change: functions.Change<admin.firestore.DocumentSnapshot>, context: functions.EventContext) => {
    try {
      const before = change.before.data();
      const after = change.after.data();

      // Log when SMS is sent
      if (before && after && !before.smsSent && after.smsSent) {
        functions.logger.info(`OTP SMS sent event logged for ${context.params.phoneNumber}`);
      }

      // Log when OTP is verified
      if (before && after && before.status === 'pending' && after.status === 'verified') {
        functions.logger.info(`OTP verified event logged for ${context.params.phoneNumber}`);
      }

      return null;
    } catch (error) {
      functions.logger.error('Failed to log OTP event', { error });
      return null; // Don't throw in audit logs
    }
  });

// ============================================================================
// EMAIL OTP FUNCTIONS (Using Resend or SendGrid)
// ============================================================================

// Email configuration (from environment variables)
function getResendApiKey() {
  return getRequiredEnv('RESEND_API_KEY');
}

function getFromEmail() {
  return process.env.FROM_EMAIL?.trim() || 'otp@swiftcart.com';
}

/**
 * Helper function to send email via Resend API
 * Install: npm install resend
 */
async function sendEmailViaResend(
  to: string,
  subject: string,
  html: string
): Promise<string> {
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${getResendApiKey()}`,
    },
    body: JSON.stringify({
      from: getFromEmail(),
      to,
      subject,
      html,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Resend API error: ${error}`);
  }

  const data = (await response.json()) as { id: string };
  return data.id;
}

/**
 * Cloud Function: Send Email OTP for Signup
 * Triggers when a new email_otp_signup document is created
 */
export const sendEmailOtpSignup = functions
  .region('us-central1')
  .firestore.document('email_otp_signup/{email}')
  .onCreate(async (snap: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    try {
      const email = context.params.email as string;
      const otpData = snap.data();
      if (!otpData) {
        throw new Error('Email OTP document has no data');
      }
      const otp = otpData.otp as string;

      functions.logger.info(`Sending signup OTP to ${email}`, { otp });

      // Validate email format
      if (!email.includes('@')) {
        throw new Error('Invalid email format');
      }

      // Create HTML email template
      const htmlContent = `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 40px; border-radius: 8px; }
              .header { text-align: center; margin-bottom: 30px; }
              .otp-box { background-color: #0B5ED7; color: white; padding: 30px; text-align: center; border-radius: 8px; margin: 30px 0; }
              .otp-code { font-size: 48px; font-weight: bold; letter-spacing: 8px; }
              .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Welcome to SwiftCart!</h1>
                <p>Complete your sign-up process</p>
              </div>
              <p>Hi there,</p>
              <p>Use the code below to verify your email address and complete your account setup.</p>
              <div class="otp-box">
                <div class="otp-code">${otp}</div>
                <p style="margin-top: 10px; font-size: 14px;">This code expires in 10 minutes</p>
              </div>
              <p><strong>Important:</strong> Never share this code with anyone. SwiftCart staff will never ask for this code.</p>
              <p>If you didn't request this, you can safely ignore this email.</p>
              <div class="footer">
                <p>&copy; 2026 SwiftCart. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `;

      // Send email via Resend
      const emailId = await sendEmailViaResend(
        email,
        'SwiftCart - Verify Your Email',
        htmlContent
      );

      functions.logger.info(`Email sent successfully to ${email}`, { emailId });

      // Update document to mark email as sent
      await snap.ref.update({
        emailSent: true,
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        emailId,
      });

      return { success: true, emailId };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      functions.logger.error(`Failed to send signup email: ${errorMessage}`, { error });

      // Update document to record failure
      try {
        await snap.ref.update({
          emailSent: false,
          emailError: errorMessage,
          emailErrorAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        functions.logger.error('Failed to update email_otp_signup document', { updateError });
      }

      throw new functions.https.HttpsError('internal', `Failed to send email: ${errorMessage}`);
    }
  });

/**
 * Cloud Function: Send Email OTP for Password Reset (Forgot Password)
 * Triggers when a new password_reset_otp document is created
 */
export const sendPasswordResetOtp = functions
  .region('us-central1')
  .firestore.document('password_reset_otp/{email}')
  .onCreate(async (snap: admin.firestore.DocumentSnapshot, context: functions.EventContext) => {
    try {
      const email = context.params.email as string;
      const otpData = snap.data();
      if (!otpData) {
        throw new Error('Password reset OTP document has no data');
      }
      const otp = otpData.otp as string;

      functions.logger.info(`Sending password reset OTP to ${email}`, { otp });

      // Validate email format
      if (!email.includes('@')) {
        throw new Error('Invalid email format');
      }

      // Create HTML email template
      const htmlContent = `
        <!DOCTYPE html>
        <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; background-color: #f5f5f5; }
              .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 40px; border-radius: 8px; }
              .header { text-align: center; margin-bottom: 30px; }
              .warning { background-color: #fff3cd; padding: 15px; border-radius: 4px; margin: 20px 0; border-left: 4px solid #ff9800; }
              .otp-box { background-color: #0F9B8E; color: white; padding: 30px; text-align: center; border-radius: 8px; margin: 30px 0; }
              .otp-code { font-size: 48px; font-weight: bold; letter-spacing: 8px; }
              .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Password Reset Request</h1>
              </div>
              <p>Hi,</p>
              <p>You requested to reset your SwiftCart password. Use the code below to complete the process.</p>
              <div class="otp-box">
                <div class="otp-code">${otp}</div>
                <p style="margin-top: 10px; font-size: 14px;">This code expires in 10 minutes</p>
              </div>
              <div class="warning">
                <strong>Security Notice:</strong> If you didn't request a password reset, please ignore this email or contact support immediately.
              </div>
              <p><strong>Never share this code.</strong> SwiftCart staff will never ask for this code.</p>
              <p>Steps to reset your password:</p>
              <ol>
                <li>Enter your email on the forgot password page</li>
                <li>Enter the code above when prompted</li>
                <li>Set your new password</li>
              </ol>
              <div class="footer">
                <p>&copy; 2026 SwiftCart. All rights reserved.</p>
              </div>
            </div>
          </body>
        </html>
      `;

      // Send email via Resend
      const emailId = await sendEmailViaResend(
        email,
        'SwiftCart - Reset Your Password',
        htmlContent
      );

      functions.logger.info(`Password reset email sent successfully to ${email}`, { emailId });

      // Update document to mark email as sent
      await snap.ref.update({
        emailSent: true,
        emailSentAt: admin.firestore.FieldValue.serverTimestamp(),
        emailId,
      });

      return { success: true, emailId };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      functions.logger.error(`Failed to send password reset email: ${errorMessage}`, { error });

      // Update document to record failure
      try {
        await snap.ref.update({
          emailSent: false,
          emailError: errorMessage,
          emailErrorAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        functions.logger.error('Failed to update password_reset_otp document', { updateError });
      }

      throw new functions.https.HttpsError('internal', `Failed to send email: ${errorMessage}`);
    }
  });

/**
 * Cloud Function: Cleanup Expired Email OTPs
 * Runs every 10 minutes via Cloud Scheduler
 * Deletes OTP documents that have expired
 */
export const cleanupExpiredEmailOtps = functions
  .region('us-central1')
  .pubsub.schedule('every 10 minutes')
  .onRun(async () => {
    try {
      const now = admin.firestore.Timestamp.now();
      const db = admin.firestore();

      // Clean up signup OTPs
      const signupSnapshot = await db
        .collection('email_otp_signup')
        .where('expiresAt', '<', now)
        .get();

      functions.logger.info(`Found ${signupSnapshot.size} expired signup OTP documents`);

      const signupBatch = db.batch();
      signupSnapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
        signupBatch.delete(doc.ref);
      });

      if (signupSnapshot.size > 0) {
        await signupBatch.commit();
        functions.logger.info(`Deleted ${signupSnapshot.size} expired signup OTP documents`);
      }

      // Clean up password reset OTPs
      const resetSnapshot = await db
        .collection('password_reset_otp')
        .where('expiresAt', '<', now)
        .get();

      functions.logger.info(`Found ${resetSnapshot.size} expired password reset OTP documents`);

      const resetBatch = db.batch();
      resetSnapshot.docs.forEach((doc: admin.firestore.QueryDocumentSnapshot) => {
        resetBatch.delete(doc.ref);
      });

      if (resetSnapshot.size > 0) {
        await resetBatch.commit();
        functions.logger.info(`Deleted ${resetSnapshot.size} expired password reset OTP documents`);
      }

      return {
        successfulCleanup: true,
        signupOtpsDeleted: signupSnapshot.size,
        resetOtpsDeleted: resetSnapshot.size,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      functions.logger.error(`Email OTP cleanup job failed: ${errorMessage}`, { error });
      throw error;
    }
  });

