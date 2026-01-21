# TestFlight Upload Setup Guide

## Prerequisites

Before running the upload script, ensure you have:

### 1. App Store Connect Setup
- [ ] Apple Developer Program membership (paid)
- [ ] App created in [App Store Connect](https://appstoreconnect.apple.com)
  - Bundle ID: `com.vm.power.reminders`
  - App name: Power Reminders

### 2. Local Machine Setup
- [ ] Xcode installed with Command Line Tools
- [ ] Signed into Xcode with your Apple ID (Xcode > Settings > Accounts)
- [ ] Valid iOS Distribution certificate in Keychain

### 3. Signing Configuration
The project uses **automatic signing** with Team ID: `JL84E9GK95`

To verify your signing setup:
```bash
# Check available signing identities
security find-identity -v -p codesigning

# You should see something like:
# "Apple Distribution: Your Name (JL84E9GK95)"
```

## Usage

### Quick Start
```bash
cd ios
./scripts/upload-to-testflight.sh
```

### With App-Specific Password
If you prefer not to use Xcode keychain authentication:

1. Generate an app-specific password at https://appleid.apple.com/account/manage
2. Run:
```bash
export APPLE_ID='your-email@example.com'
export APP_SPECIFIC_PWD='xxxx-xxxx-xxxx-xxxx'
./scripts/upload-to-testflight.sh
```

## Troubleshooting

### "No signing certificate" error
1. Open Xcode
2. Go to Settings > Accounts
3. Select your team and click "Download Manual Profiles"
4. Or click "Manage Certificates" and create a new Distribution certificate

### "App ID not found" error
Create the App ID in App Store Connect:
1. Go to https://appstoreconnect.apple.com
2. Click "+" to add a new app
3. Use Bundle ID: `com.vm.power.reminders`

### "Upload failed" error
Try manual upload:
1. Install **Transporter** from the Mac App Store
2. Find the IPA at `ios/build/export/PowerReminders.ipa`
3. Drag the IPA into Transporter

### Build number conflicts
The script uses `manageAppVersionAndBuildNumber` to auto-increment.
If you need a specific build number, edit `project.yml` and regenerate:
```bash
xcodegen generate
```

## After Upload

1. Wait 10-30 minutes for processing
2. Check App Store Connect > TestFlight
3. Add internal/external testers or enable Public Link
4. Testers will receive an email invitation

## Version Management

Edit `ios/project.yml` to update version:
```yaml
settings:
  MARKETING_VERSION: 1.0.0      # App version (shown to users)
  CURRENT_PROJECT_VERSION: 1     # Build number (auto-managed if using script)
```

Then regenerate:
```bash
xcodegen generate
```
