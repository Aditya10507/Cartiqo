@echo off
REM SwiftCart Custom OTP - Quick Deployment Script (Windows)
REM This script automates the Cloud Functions setup and deployment

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  SwiftCart Custom OTP - Cloud Functions Deployment
echo ============================================================
echo.

REM Check prerequisites
echo [1/5] Checking prerequisites...
echo.

REM Check Node.js
node --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not found. Please install Node.js 18+
    echo Download from: https://nodejs.org/
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do echo [OK] Node.js %%i

REM Check npm
npm --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm not found. Please install npm
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do echo [OK] npm %%i

REM Check Firebase CLI
firebase --version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Firebase CLI not found. Installing...
    call npm install -g firebase-tools
)
echo [OK] Firebase CLI installed

REM Navigate to functions folder
echo.
echo [2/5] Installing dependencies...
echo.
cd functions
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    exit /b 1
)
echo [OK] Dependencies installed

REM Build TypeScript
echo.
echo [3/5] Building TypeScript...
echo.
call npm run build
if errorlevel 1 (
    echo ERROR: Failed to build TypeScript
    exit /b 1
)
echo [OK] TypeScript compiled

REM Prompt for Twilio credentials
echo.
echo [4/5] Writing functions\.env with OTP credentials...
echo.
echo Please enter your Twilio credentials from: https://www.twilio.com/console
echo Press Enter to skip the optional email OTP settings.
echo.

set /p TWILIO_ACCOUNT_SID="Enter Twilio Account SID: "
set /p TWILIO_AUTH_TOKEN="Enter Twilio Auth Token: "
set /p TWILIO_PHONE_NUMBER="Enter Twilio Phone Number (e.g., +1234567890): "
set /p RESEND_API_KEY="Enter Resend API Key (optional): "
set /p FROM_EMAIL="Enter From Email (optional, default otp@swiftcart.com): "

> .env (
    echo TWILIO_ACCOUNT_SID=%TWILIO_ACCOUNT_SID%
    echo TWILIO_AUTH_TOKEN=%TWILIO_AUTH_TOKEN%
    echo TWILIO_PHONE_NUMBER=%TWILIO_PHONE_NUMBER%
    if not "%RESEND_API_KEY%"=="" echo RESEND_API_KEY=%RESEND_API_KEY%
    if not "%FROM_EMAIL%"=="" echo FROM_EMAIL=%FROM_EMAIL%
)

echo [OK] functions\.env written

REM Deploy
echo.
echo [5/5] Deploying Cloud Functions...
echo.
call firebase deploy --only functions

if errorlevel 1 (
    echo ERROR: Deployment failed. Check the output above.
    exit /b 1
)

echo.
echo ============================================================
echo  DEPLOYMENT COMPLETE!
echo ============================================================
echo.
echo Next steps:
echo   1. Test SMS sending by opening your Flutter app
echo   2. Open the custom Phone OTP screen
echo   3. Enter a phone number and click 'Send OTP'
echo   4. Check your phone for the SMS
echo   5. View logs: firebase functions:log
echo.
echo Don't forget to update Firestore Rules!
echo See FUNCTIONS_DEPLOYMENT_GUIDE.md for security rules
echo.

endlocal
