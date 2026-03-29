#!/bin/bash
# SwiftCart Custom OTP - Quick Deployment Script
# This script automates the Cloud Functions setup and deployment

set -e # Exit on error

echo "📱 SwiftCart Custom OTP - Cloud Functions Deployment"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${BLUE}1. Checking prerequisites...${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js $(node --version)${NC}"

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found. Please install npm${NC}"
    exit 1
fi
echo -e "${GREEN}✓ npm $(npm --version)${NC}"

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠ Firebase CLI not found. Installing...${NC}"
    npm install -g firebase-tools
fi
echo -e "${GREEN}✓ Firebase CLI installed${NC}"

# Navigate to functions folder
echo ""
echo -e "${BLUE}2. Installing dependencies...${NC}"
cd functions
npm install
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Build TypeScript
echo ""
echo -e "${BLUE}3. Building TypeScript...${NC}"
npm run build
echo -e "${GREEN}✓ TypeScript compiled${NC}"

# Prompt for Twilio credentials
echo ""
echo -e "${BLUE}4. Writing functions/.env with OTP credentials...${NC}"
echo ""
echo "Please enter your Twilio credentials (get from https://www.twilio.com/console)"
echo "Press Enter to skip the optional email OTP settings."
echo ""

read -p "Enter Twilio Account SID: " TWILIO_ACCOUNT_SID
read -p "Enter Twilio Auth Token: " TWILIO_AUTH_TOKEN
read -p "Enter Twilio Phone Number (e.g., +1234567890): " TWILIO_PHONE_NUMBER
read -p "Enter Resend API Key (optional): " RESEND_API_KEY
read -p "Enter From Email (optional, default otp@swiftcart.com): " FROM_EMAIL

cat > .env <<EOF
TWILIO_ACCOUNT_SID=$TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=$TWILIO_AUTH_TOKEN
TWILIO_PHONE_NUMBER=$TWILIO_PHONE_NUMBER
EOF

if [ -n "$RESEND_API_KEY" ]; then
    echo "RESEND_API_KEY=$RESEND_API_KEY" >> .env
fi

if [ -n "$FROM_EMAIL" ]; then
    echo "FROM_EMAIL=$FROM_EMAIL" >> .env
fi

echo -e "${GREEN}✓ functions/.env written${NC}"

# Deploy
echo -e "${BLUE}5. Deploying Cloud Functions...${NC}"
firebase deploy --only functions

echo ""
echo -e "${GREEN}=================================================="
echo "✅ Deployment Complete!"
echo "==================================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Test SMS sending by opening your Flutter app"
echo "2. Open the custom Phone OTP screen"
echo "3. Enter a phone number and click 'Send OTP'"
echo "4. Check your phone for the SMS"
echo "5. View logs: firebase functions:log"
echo ""
echo -e "${YELLOW}Don't forget to update Firestore Rules!${NC}"
echo "See FUNCTIONS_DEPLOYMENT_GUIDE.md for security rules"
echo ""
