# Releasing to Google Play

## 1. Signing key (one time)

The upload key lives **outside git**:

- `android/upload-keystore.jks` – the upload keystore (alias `upload`)
- `android/key.properties` – its passwords

Both are git-ignored. **Back them up now** (password manager / encrypted
drive). If the upload key is lost you must ask Google Play support to reset it.

When you create the app in Play Console, keep **Play App Signing** enabled
(the default). Google holds the app signing key; you only sign uploads.

To create a new key on another machine instead:

```bash
keytool -genkeypair -v -keystore android/upload-keystore.jks -storetype PKCS12 -keyalg RSA -keysize 4096 -validity 10000 -alias upload
```

and write `android/key.properties`:

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../upload-keystore.jks
```

Without `key.properties` release builds fall back to the debug key, which
Play Console rejects.

## 2. Bump the version

In `pubspec.yaml`, `version: 1.0.0+1` → `name+code`. The code after `+`
must increase on every upload (e.g. `1.0.1+2`).

## 3. Build the bundle

```bash
flutter test
```

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 4. Upload

Play Console → your app → Testing → Internal testing → Create release →
upload the `.aab`. Promote to Closed/Open testing, then Production.

New personal developer accounts must run a **closed test with at least 12
testers for 14 days** before production access is granted.

Store listing text, graphics and the Data safety / App content answers are
in `store/listing.md`.

## Regenerating assets

- Boundary outlines bundled in `assets/`: `python tool/build_boundary_assets.py`
- Icons, splash and store graphics: `python tool/build_icons.py`
