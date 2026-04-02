@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM SwiftCart Custom OTP - Cloud Functions Deployment Script
REM Version: 2.0 | Platform: Windows
REM ============================================================

REM ANSI Color Setup (Windows 10+)
for /f "delims=" %%i in ('echo prompt $E^| cmd') do set "ESC=%%i"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "CYAN=%ESC%[96m"
set "BOLD=%ESC%[1m"
set "RESET=%ESC%[0m"

REM Log file setup
set "LOG_FILE=deploy_log_%DATE:~-4%%DATE:~3,2%%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.txt"
set "LOG_FILE=%LOG_FILE: =0%"

REM Deployment start time
set "START_TIME=%TIME%"

call :header
call :log "Deployment started at %DATE% %TIME%"

REM ── STEP 1: Prerequisites ─────────────────────────────────
call :step "1/6" "Checking prerequisites"

call :check_node     || exit /b 1
call :check_npm      || exit /b 1
call :check_firebase || exit /b 1
call :check_firebase_login || exit /b 1

REM ── STEP 2: Project validation ────────────────────────────
call :step "2/6" "Validating project structure"

if not exist "firebase.json" (
    call :error "firebase.json not found. Are you in the project root?"
    exit /b 1
)
if not exist "functions" (
    call :error "functions\ folder not found."
    exit /b 1
)
if not exist "functions\package.json" (
    call :error "functions\package.json not found."
    exit /b 1
)
call :success "Project structure validated"

REM ── STEP 3: Install dependencies ──────────────────────────
call :step "3/6" "Installing dependencies"

cd functions
call npm install --prefer-offline 2>&1 | tee -a "..\%LOG_FILE%"
if errorlevel 1 (
    call :error "Failed to install npm dependencies"
    cd ..
    exit /b 1
)
cd ..
call :success "Dependencies installed"

REM ── STEP 4: Build TypeScript ──────────────────────────────
call :step "4/6" "Building TypeScript"

cd functions
call npm run build 2>&1 | tee -a "..\%LOG_FILE%"
if errorlevel 1 (
    call :error "TypeScript build failed. Run 'npm run build' in /functions for details."
    cd ..
    exit /b 1
)
cd ..
call :success "TypeScript compiled successfully"

REM ── STEP 5: Credentials setup ─────────────────────────────
call :step "5/6" "Configuring OTP credentials"

echo %CYAN%  Twilio credentials: https://www.twilio.com/console%RESET%
echo %CYAN%  Resend credentials: https://resend.com/api-keys%RESET%
echo.

REM Twilio Account SID
:ask_sid
set /p TWILIO_ACCOUNT_SID="  Twilio Account SID (ACxxxxxxxx): "
if "%TWILIO_ACCOUNT_SID%"=="" (
    call :warn "Twilio Account SID is required."
    goto ask_sid
)
echo %TWILIO_ACCOUNT_SID% | findstr /r "^AC[a-zA-Z0-9]*$" >nul
if errorlevel 1 (
    call :warn "SID should start with 'AC'. Re-enter or press Enter to continue anyway."
    set /p CONFIRM_SID="  Continue with this SID? (y/n): "
    if /i "!CONFIRM_SID!" neq "y" goto ask_sid
)

REM Twilio Auth Token
:ask_token
set /p TWILIO_AUTH_TOKEN="  Twilio Auth Token: "
if "%TWILIO_AUTH_TOKEN%"=="" (
    call :warn "Twilio Auth Token is required."
    goto ask_token
)

REM Twilio Phone Number
:ask_phone
set /p TWILIO_PHONE_NUMBER="  Twilio Phone Number (e.g. +1234567890): "
if "%TWILIO_PHONE_NUMBER%"=="" (
    call :warn "Twilio Phone Number is required."
    goto ask_phone
)
echo %TWILIO_PHONE_NUMBER% | findstr /r "^\+[0-9]*$" >nul
if errorlevel 1 (
    call :warn "Phone number should start with '+' and contain only digits."
    set /p CONFIRM_PHONE="  Continue anyway? (y/n): "
    if /i "!CONFIRM_PHONE!" neq "y" goto ask_phone
)

REM Optional fields
set /p RESEND_API_KEY="  Resend API Key (optional, press Enter to skip): "
set /p FROM_EMAIL="  From Email (optional, default: otp@swiftcart.com): "
if "%FROM_EMAIL%"=="" set "FROM_EMAIL=otp@swiftcart.com"

REM Write .env file
set "ENV_FILE=functions\.env"

REM Backup existing .env
if exist "%ENV_FILE%" (
    copy "%ENV_FILE%" "%ENV_FILE%.bak" >nul
    call :warn "Existing .env backed up to functions\.env.bak"
)

(
    echo # SwiftCart OTP - Auto-generated %DATE% %TIME%
    echo TWILIO_ACCOUNT_SID=%TWILIO_ACCOUNT_SID%
    echo TWILIO_AUTH_TOKEN=%TWILIO_AUTH_TOKEN%
    echo TWILIO_PHONE_NUMBER=%TWILIO_PHONE_NUMBER%
    if not "%RESEND_API_KEY%"=="" echo RESEND_API_KEY=%RESEND_API_KEY%
    echo FROM_EMAIL=%FROM_EMAIL%
) > "%ENV_FILE%"

if errorlevel 1 (
    call :error "Failed to write %ENV_FILE%"
    exit /b 1
)
call :success ".env written to functions\.env"

REM ── STEP 6: Deploy ────────────────────────────────────────
call :step "6/6" "Deploying to Firebase"

echo.
echo %YELLOW%  Project: %BOLD%SwiftCart%RESET%
echo %YELLOW%  Target : Cloud Functions only%RESET%
echo.
set /p DEPLOY_CONFIRM="  Proceed with deployment? (y/n): "
if /i "%DEPLOY_CONFIRM%" neq "y" (
    call :warn "Deployment cancelled by user."
    exit /b 0
)

call firebase deploy --only functions 2>&1 | tee -a "%LOG_FILE%"
if errorlevel 1 (
    call :error "Deployment failed. Check %LOG_FILE% for details."
    exit /b 1
)

REM ── Summary ───────────────────────────────────────────────
call :footer
call :log "Deployment completed at %DATE% %TIME%"

echo   Log saved to: %LOG_FILE%
echo.
endlocal
exit /b 0


REM ══════════════════════════════════════════════════════════
REM  HELPER FUNCTIONS
REM ══════════════════════════════════════════════════════════

:header
echo.
echo %BOLD%%CYAN%  ╔══════════════════════════════════════════════════════╗%RESET%
echo %BOLD%%CYAN%  ║     SwiftCart Custom OTP — Cloud Deployment v2.0    ║%RESET%
echo %BOLD%%CYAN%  ╚══════════════════════════════════════════════════════╝%RESET%
echo.
exit /b 0

:footer
echo.
echo %BOLD%%GREEN%  ╔══════════════════════════════════════════════════════╗%RESET%
echo %BOLD%%GREEN%  ║              DEPLOYMENT COMPLETE  ✓                 ║%RESET%
echo %BOLD%%GREEN%  ╚══════════════════════════════════════════════════════╝%RESET%
echo.
echo %CYAN%  Next steps:%RESET%
echo   1. Open Flutter app and navigate to Phone OTP screen
echo   2. Enter a phone number and tap 'Send OTP'
echo   3. Verify SMS is received on your device
echo   4. Monitor logs: %BOLD%firebase functions:log%RESET%
echo   5. Update Firestore Rules — see FUNCTIONS_DEPLOYMENT_GUIDE.md
echo.
exit /b 0

:step
echo.
echo %BOLD%%CYAN%  ── Step %~1: %~2%RESET%
call :log "STEP [%~1] %~2"
exit /b 0

:success
echo   %GREEN%[✓] %~1%RESET%
call :log "OK: %~1"
exit /b 0

:warn
echo   %YELLOW%[!] %~1%RESET%
call :log "WARN: %~1"
exit /b 0

:error
echo.
echo   %RED%[✗] ERROR: %~1%RESET%
echo.
call :log "ERROR: %~1"
exit /b 0

:log
echo [%DATE% %TIME%] %~1 >> "%LOG_FILE%"
exit /b 0

:check_node
for /f "tokens=*" %%v in ('node --version 2^>nul') do set "NODE_VER=%%v"
if "%NODE_VER%"=="" (
    call :error "Node.js not found. Install from https://nodejs.org/ (v18+)"
    exit /b 1
)
for /f "tokens=1 delims=v." %%m in ("%NODE_VER:~1%") do set "NODE_MAJOR=%%m"
if %NODE_MAJOR% LSS 18 (
    call :error "Node.js v18+ required. Found %NODE_VER%"
    exit /b 1
)
call :success "Node.js %NODE_VER%"
exit /b 0

:check_npm
for /f "tokens=*" %%v in ('npm --version 2^>nul') do set "NPM_VER=%%v"
if "%NPM_VER%"=="" (
    call :error "npm not found."
    exit /b 1
)
call :success "npm v%NPM_VER%"
exit /b 0

:check_firebase
for /f "tokens=*" %%v in ('firebase --version 2^>nul') do set "FB_VER=%%v"
if "%FB_VER%"=="" (
    call :warn "Firebase CLI not found. Installing globally..."
    call npm install -g firebase-tools
    if errorlevel 1 (
        call :error "Failed to install Firebase CLI."
        exit /b 1
    )
)
call :success "Firebase CLI v%FB_VER%"
exit /b 0

:check_firebase_login
firebase projects:list >nul 2>&1
if errorlevel 1 (
    call :warn "Not logged into Firebase. Launching login..."
    call firebase login
    if errorlevel 1 (
        call :error "Firebase login failed."
        exit /b 1
    )
)
call :success "Firebase authenticated"
exit /b 0
