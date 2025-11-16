# Publishing to pub.dev

## Pre-Publishing Checklist

Before publishing, ensure:

1. ✅ All tests pass: `flutter test`
2. ✅ Code is formatted: `flutter format .`
3. ✅ Analysis passes: `flutter analyze`
4. ✅ Version is correct in `pubspec.yaml`
5. ✅ CHANGELOG.md is updated
6. ✅ README.md is complete and accurate
7. ✅ LICENSE file is present
8. ✅ Repository URLs in `pubspec.yaml` are correct ✅ (Already updated)

## Steps to Publish

### 1. Commit All Changes

```bash
git add .
git commit -m "Prepare for initial release v0.1.0"
```

### 3. Create a Git Tag (Optional but Recommended)

```bash
git tag v0.1.0
git push origin v0.1.0
```

### 4. Verify Package

Run a dry-run to check for issues:

```bash
flutter pub publish --dry-run
```

This will:
- Validate the package structure
- Check for common issues
- Show what will be published
- **Note**: It will warn about uncommitted changes - commit first!

### 5. Publish to pub.dev

**Important**: You need a pub.dev account to publish.

1. **Create/Login to pub.dev account**:
   - Go to https://pub.dev
   - Sign in with Google account
   - Verify your email

2. **Get your OAuth token**:
   ```bash
   dart pub token add https://pub.dev
   ```
   This will open a browser to authorize the token.

3. **Publish the package**:
   ```bash
   flutter pub publish
   ```

4. **Confirm publication**:
   - Review the package contents shown
   - Type `y` to confirm
   - Wait for publication to complete

### 6. Verify Publication

After publishing:
- Visit https://pub.dev/packages/flutter_biometric_crypto
- Verify all information is correct
- Test installation: `flutter pub add flutter_biometric_crypto`

## Post-Publishing

1. **Update README** with the pub.dev badge:
   ```markdown
   [![pub package](https://img.shields.io/pub/v/flutter_biometric_crypto.svg)](https://pub.dev/packages/flutter_biometric_crypto)
   ```

2. **Create a GitHub Release**:
   - Go to your GitHub repository
   - Create a new release
   - Tag: `v0.1.0`
   - Title: `v0.1.0 - Initial Release`
   - Copy relevant CHANGELOG.md content

3. **Share the package**:
   - Update your project's README
   - Share on social media/forums if desired

## Troubleshooting

### "Package already exists"
- The package name `flutter_biometric_crypto` might be taken
- Check https://pub.dev/packages/flutter_biometric_crypto
- If taken, choose a different name and update `pubspec.yaml`

### "Unauthorized"
- Make sure you're logged in: `dart pub token list`
- Re-authenticate: `dart pub token add https://pub.dev`

### "Validation failed"
- Check the error message
- Common issues:
  - Missing LICENSE file
  - Invalid pubspec.yaml format
  - Missing required fields
  - Uncommitted git changes

### "Version already exists"
- Update version in `pubspec.yaml`
- Update `CHANGELOG.md`
- Try publishing again

## Version Management

Follow semantic versioning (semver):
- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.2.0): New features, backward compatible
- **PATCH** (0.1.1): Bug fixes, backward compatible

Update version in:
1. `pubspec.yaml`
2. `CHANGELOG.md`
3. Git tag (optional)

## Important Notes

- **Once published, you cannot delete a package version**
- **Package names are permanent** - choose carefully
- **Review everything before publishing** - it's public forever
- **Test the package** after publishing to ensure it works

## Next Steps After Publishing

1. Monitor for issues/feedback
2. Respond to issues on pub.dev
3. Plan next version features
4. Update documentation as needed

