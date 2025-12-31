# GitHub Actions Workflows

This project uses GitHub Actions for continuous integration and automated releases.

## Workflows

### 🧪 Test (`test.yml`)

**Triggers:** Push to `main`, Pull Requests

Runs the unit test suite on macOS runners.

```bash
xcodebuild test -scheme Arrstatus -destination 'platform=macOS' -only-testing:ArrstatusTests
```

### 🔨 Build (`build.yml`)

**Triggers:** Push to `main`, Pull Requests

Builds the app in Debug configuration to verify compilation.

```bash
xcodebuild build -scheme Arrstatus -configuration Debug
```

### 📦 Release (`release.yml`)

**Triggers:** Tags starting with `v*` (e.g., `v1.0.0`)

Builds a Release configuration, packages the app as a ZIP, and creates a GitHub Release.

#### Creating a Release

1. Update version in Xcode project
2. Commit changes
3. Create and push a tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

4. GitHub Actions will automatically build and create a release

## Code Signing

Currently, workflows build **unsigned** apps for development/testing. This is fine for personal use but macOS will show security warnings.

### Adding Code Signing (Optional)

To create signed releases:

1. **Export Signing Certificate:**
   - Open Keychain Access
   - Export your Developer ID Application certificate as `.p12`
   - Base64 encode: `base64 -i certificate.p12 | pbcopy`

2. **Add GitHub Secrets:**
   - Go to repository Settings → Secrets and variables → Actions
   - Add secrets:
     - `MACOS_CERTIFICATE`: Base64-encoded certificate
     - `MACOS_CERTIFICATE_PASSWORD`: Certificate password
     - `APPLE_TEAM_ID`: Your team ID (e.g., `MPCN37D7MN`)

3. **Update `release.yml`:**

   Add before "Build Release" step:

   ```yaml
   - name: Import Code Signing Certificate
     env:
       CERTIFICATE_BASE64: ${{ secrets.MACOS_CERTIFICATE }}
       CERTIFICATE_PASSWORD: ${{ secrets.MACOS_CERTIFICATE_PASSWORD }}
     run: |
       # Create temporary keychain
       KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
       KEYCHAIN_PASSWORD=$(openssl rand -base64 32)

       security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
       security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
       security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

       # Import certificate
       echo $CERTIFICATE_BASE64 | base64 --decode > certificate.p12
       security import certificate.p12 -k $KEYCHAIN_PATH -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
       security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

       # Set as default keychain
       security list-keychain -d user -s $KEYCHAIN_PATH
       rm -f certificate.p12
   ```

   Then modify "Build Release" step to use signing:

   ```yaml
   - name: Build Release
     env:
       TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
     run: |
       xcodebuild archive \
         -scheme Arrstatus \
         -configuration Release \
         -archivePath "$RUNNER_TEMP/Arrstatus.xcarchive" \
         DEVELOPMENT_TEAM="$TEAM_ID" \
         CODE_SIGN_IDENTITY="Developer ID Application" \
         | xcpretty || true
   ```

### Notarization (Optional)

For distribution outside the Mac App Store, Apple requires notarization:

1. Create app-specific password at appleid.apple.com
2. Add `APPLE_ID` and `APPLE_APP_PASSWORD` secrets
3. Add notarization step after exporting app
4. Submit to Apple notary service
5. Staple notarization ticket to app

See Apple's documentation for detailed notarization steps.

## Requirements

- **Runner:** macOS 15 (uses `macos-15` runner)
- **Xcode:** 16.2 (automatically selected in workflows)
- **Permissions:** Workflows need `contents: write` for releases (default)

## Troubleshooting

### Tests Fail in CI but Pass Locally

- Ensure test suite doesn't depend on local environment
- Check for hardcoded paths or credentials
- Verify tests use mocked/stubbed services

### Build Fails with Signing Errors

- Verify `CODE_SIGN_IDENTITY=""` is set for unsigned builds
- Check that signing secrets are properly configured for signed builds

### Release Not Created

- Ensure tag starts with `v` (e.g., `v1.0.0`)
- Check Actions tab for workflow run details
- Verify `GITHUB_TOKEN` has proper permissions
