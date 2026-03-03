# Tellsla Build Fix Summary

## Problem
CodeMagic builds were failing with:
```
No Accounts: Add a new account in Accounts settings.
No profiles for 'app.rork.tellsla' were found
```

**Root Cause:** Xcode on CodeMagic builder had no Apple Developer account configured, so `-allowProvisioningUpdates` couldn't auto-generate provisioning profiles.

---

## Solution Applied

### 1. **CodeMagic iOS Signing Configuration** ✅
Added native CodeMagic signing config to `codemagic.yaml`:
```yaml
environment:
  ios_signing:
    distribution_type: app_store
    bundle_identifier: app.rork.tellsla
```
This tells CodeMagic to:
- Auto-fetch provisioning profiles from App Store Connect
- Auto-fetch certificates from App Store Connect
- Inject them into the Xcode build environment

### 2. **App Store Connect API Key Setup** ✅
- Private key is decoded and stored in `~/.appstoreconnect/private_keys/`
- Proper file permissions (600) applied
- xcrun altool can now use the API key for TestFlight upload

### 3. **Build & Archive with Auto-Provisioning** ✅
```bash
xcodebuild archive -allowProvisioningUpdates
```
Now this will work because:
- CodeMagic has configured the iOS signing environment
- Provisioning profiles + certificates are available
- `DEVELOPMENT_TEAM = 894G4S5K4R` is set in Xcode project

### 4. **TestFlight Upload via API** ✅
```bash
xcrun altool --upload-app --apiKey WBU777B3N3 --apiIssuer 23c1e19b-ffc3-4fe0-a48d-395c84ca3c0b
```

---

## Files Changed
1. **codemagic.yaml** — Added `ios_signing` config, simplified build steps
2. **build.xcconfig** — Build settings override for CI/CD (optional reference)
3. **fix-codesign.sh** — Script for local manual fixes if needed

---

## What Changed in Detail

### Before (Broken)
- ❌ No `ios_signing` configuration in CodeMagic
- ❌ `-allowProvisioningUpdates` with no account = instant fail
- ❌ Credentials not properly staged

### After (Fixed)
- ✅ `ios_signing` tells CodeMagic to manage provisioning
- ✅ `-allowProvisioningUpdates` now has credentials to work with
- ✅ API key properly decoded and available
- ✅ TestFlight upload uses App Store Connect API

---

## Next Build

When CodeMagic runs (push to main), it will:

1. **Clone repo** → gets codemagic.yaml with ios_signing config
2. **Setup Xcode** → xcode: latest
3. **Fetch signing credentials** → CodeMagic auto-fetches from App Store Connect using your team ID
4. **Build & Archive** → `xcodebuild archive -allowProvisioningUpdates` (now has creds)
5. **Export IPA** → Creates unsigned archive, then exports to signed IPA
6. **Upload to TestFlight** → Uses App Store Connect API key
7. **Notify** → Email to axiomops@proton.me

**Expected result:** ✅ Green build, IPA uploaded to TestFlight

---

## If It Still Fails

1. **Check CodeMagic settings** → Verify App Store Connect API key is configured (Team ID: 894G4S5K4R)
2. **Check logs** → Look for provisioning profile errors vs. API key errors
3. **Fallback:** If CodeMagic signing fails, can use fastlane for certified provisioning

---

## Git Commit
```
99f5fe0 fix: Use CodeMagic ios_signing config for proper TestFlight provisioning
```
