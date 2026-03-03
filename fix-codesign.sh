#!/bin/bash
set -e

# This script converts CODE_SIGN_STYLE from Automatic to Manual
# and disables provisioning profile validation for CI/CD builds

PBXPROJ="Tellsla.xcodeproj/project.pbxproj"

echo "🔧 Converting CODE_SIGN_STYLE from Automatic to Manual..."

# Backup original
cp "$PBXPROJ" "$PBXPROJ.bak"

# Replace CODE_SIGN_STYLE = Automatic with CODE_SIGN_STYLE = Manual
sed -i '' 's/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Manual;/g' "$PBXPROJ"

# Add CODE_SIGN_IDENTITY for Release builds
# (iOS Distribution identity for TestFlight)
sed -i '' '/CURRENT_PROJECT_VERSION = 1;/a\
				CODE_SIGN_IDENTITY = "Apple Distribution";' "$PBXPROJ"

echo "✅ Fixed CODE_SIGN_STYLE to Manual"
echo "✅ Set CODE_SIGN_IDENTITY to Apple Distribution"
echo ""
echo "Verify changes:"
grep -A 2 "CODE_SIGN_STYLE = Manual" "$PBXPROJ" | head -10 || echo "No matches"
