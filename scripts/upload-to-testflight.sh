#!/bin/bash

# =============================================================================
# TestFlight Upload Script for PowerReminders
# =============================================================================
# This script builds, archives, and uploads the iOS app to TestFlight.
#
# Prerequisites:
#   - Xcode Command Line Tools installed
#   - Valid Apple Developer account
#   - App configured in App Store Connect
#   - Valid signing certificates and provisioning profiles
#
# Usage:
#   ./scripts/upload-to-testflight.sh
#
# Environment Variables (optional):
#   APPLE_ID          - Your Apple ID email
#   APP_SPECIFIC_PWD  - App-specific password for upload
#   TEAM_ID           - App Store Connect Team ID (if multiple teams)
# =============================================================================

set -e  # Exit on error

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_PATH="$PROJECT_DIR/PowerReminders.xcodeproj/project.xcworkspace"
PROJECT_PATH="$PROJECT_DIR/PowerReminders.xcodeproj"
SCHEME="PowerReminders"
CONFIGURATION="Release"
ARCHIVE_DIR="$PROJECT_DIR/build/archives"
EXPORT_DIR="$PROJECT_DIR/build/export"
ARCHIVE_PATH="$ARCHIVE_DIR/PowerReminders-$(date +%Y%m%d-%H%M%S).xcarchive"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
print_step() {
    echo -e "\n${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is required but not installed."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Pre-flight Checks
# -----------------------------------------------------------------------------
print_step "Running pre-flight checks..."

# Check required tools
check_command "xcodebuild"
check_command "xcrun"

# Check Xcode is installed
if ! xcode-select -p &> /dev/null; then
    print_error "Xcode Command Line Tools not found. Install with: xcode-select --install"
    exit 1
fi

print_success "All required tools found"

# -----------------------------------------------------------------------------
# Check for XcodeGen and regenerate project if needed
# -----------------------------------------------------------------------------
if command -v xcodegen &> /dev/null && [ -f "$PROJECT_DIR/project.yml" ]; then
    print_step "Regenerating Xcode project with XcodeGen..."
    cd "$PROJECT_DIR"
    xcodegen generate
    print_success "Project regenerated"
fi

# -----------------------------------------------------------------------------
# Clean Build Directory
# -----------------------------------------------------------------------------
print_step "Cleaning build directory..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$ARCHIVE_DIR"
mkdir -p "$EXPORT_DIR"
print_success "Build directory cleaned"

# -----------------------------------------------------------------------------
# Resolve Swift Package Dependencies
# -----------------------------------------------------------------------------
print_step "Resolving Swift Package dependencies..."
xcodebuild -resolvePackageDependencies \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -clonedSourcePackagesDirPath "$PROJECT_DIR/build/SourcePackages" \
    2>&1 | grep -E "(Resolved|Fetching|error:)" || true
print_success "Dependencies resolved"

# -----------------------------------------------------------------------------
# Build Archive
# -----------------------------------------------------------------------------
print_step "Building archive (this may take a few minutes)..."

xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination "generic/platform=iOS" \
    -clonedSourcePackagesDirPath "$PROJECT_DIR/build/SourcePackages" \
    CODE_SIGN_STYLE=Automatic \
    | grep -E "(Compiling|Linking|Signing|ARCHIVE SUCCEEDED|error:|warning:)" || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    print_error "Archive failed. Check the output above for errors."
    exit 1
fi

print_success "Archive created at: $ARCHIVE_PATH"

# -----------------------------------------------------------------------------
# Create Export Options Plist
# -----------------------------------------------------------------------------
print_step "Creating export options..."

EXPORT_OPTIONS_PATH="$EXPORT_DIR/ExportOptions.plist"

cat > "$EXPORT_OPTIONS_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
    <key>manageAppVersionAndBuildNumber</key>
    <true/>
</dict>
</plist>
EOF

print_success "Export options created"

# -----------------------------------------------------------------------------
# Export and Upload to App Store Connect
# -----------------------------------------------------------------------------
print_step "Exporting and uploading to App Store Connect..."

echo ""
echo "You will be prompted to authenticate with App Store Connect."
echo "Options for authentication:"
echo "  1. Sign in via Xcode (recommended) - uses your Xcode credentials"
echo "  2. App-specific password - set APPLE_ID and APP_SPECIFIC_PWD env vars"
echo ""

# Build the export command
EXPORT_CMD="xcodebuild -exportArchive \
    -archivePath \"$ARCHIVE_PATH\" \
    -exportOptionsPlist \"$EXPORT_OPTIONS_PATH\" \
    -exportPath \"$EXPORT_DIR\" \
    -allowProvisioningUpdates"

# Add authentication if environment variables are set
if [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PWD" ]; then
    print_step "Using provided Apple ID credentials..."
    EXPORT_CMD="$EXPORT_CMD \
        -authenticationKeyIssuer \"$APPLE_ID\" \
        APPLE_ID=\"$APPLE_ID\" \
        APP_SPECIFIC_PASSWORD=\"$APP_SPECIFIC_PWD\""
fi

# Run the export/upload
eval "$EXPORT_CMD" 2>&1 | grep -E "(Uploading|Upload|error:|warning:|exported)" || true

# Check if upload was successful
if [ $? -eq 0 ]; then
    print_success "Upload to App Store Connect completed!"
else
    print_error "Upload may have failed. Check the output above."
    echo ""
    echo "If authentication failed, try one of these methods:"
    echo ""
    echo "Method 1: Use Xcode credentials"
    echo "  - Open Xcode > Settings > Accounts"
    echo "  - Sign in with your Apple ID"
    echo "  - Re-run this script"
    echo ""
    echo "Method 2: Use App-specific password"
    echo "  1. Go to https://appleid.apple.com/account/manage"
    echo "  2. Generate an app-specific password"
    echo "  3. Run: export APPLE_ID='your-email@example.com'"
    echo "  4. Run: export APP_SPECIFIC_PWD='your-app-specific-password'"
    echo "  5. Re-run this script"
    echo ""
    echo "Method 3: Manual upload with Transporter"
    echo "  - Install Transporter from the Mac App Store"
    echo "  - The IPA is at: $EXPORT_DIR/PowerReminders.ipa"
    echo "  - Drag the IPA into Transporter to upload"
    exit 1
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "============================================================================="
echo -e "${GREEN}SUCCESS!${NC} Your app has been uploaded to App Store Connect."
echo "============================================================================="
echo ""
echo "Next steps:"
echo "  1. Go to App Store Connect: https://appstoreconnect.apple.com"
echo "  2. Navigate to your app > TestFlight"
echo "  3. Wait for the build to finish processing (usually 10-30 minutes)"
echo "  4. Add testers or enable Public Link"
echo ""
echo "Archive location: $ARCHIVE_PATH"
echo ""
