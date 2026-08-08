# TAPAIKO WARD

Android app: find your **ward number**, **municipality**, district and province in
Nepal by tapping the map or using your current location. Also search any of the
753 municipalities and their wards.

Flutter + `flutter_map` app. Boundary data is fetched from the live site
(`https://maps.sandeepkafle.com.np/data/`) and cached on-device, mirroring the
`maps-clone` web app's data layout and `WARD_DISTRICT_ALIASES` quirk.

## Features

- **Find my ward** — GPS location → point-in-polygon through the admin
  hierarchy (province → district → local level → ward).
- **Tap to identify** — tap anywhere on the map to identify that point.
- **Search** — search 753 municipalities by name / district / province / type;
  drill into a municipality's wards from the result sheet.
- **Offline cache** — every fetched GeoJSON file is cached under the app's
  documents dir; repeat lookups work offline.

## Data model (same as maps-clone)

- `province.json` → `districts/{province}.json` → `locallevels/{district}.json`
  → `wards/{district}_{locallevel}.json`
- `locallevelcodes.json` stores `DISTRICT` in **ALL CAPS**, but filenames use
  proper case; `MunicipalityService` resolves the real district name by
  case-insensitive match before opening the locallevels file.
- Ward files are stored under the legacy name `Rukum` for `Rukum East`/`Rukum West`.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.19)
- Android Studio (or command-line Android SDK) with a connected device/emulator
- Python not required (nothing is served locally; all data comes from the live site)

## Build the APK

```powershell
cd E:\projects\maps\maps-apk

# 1. Generate the Android platform project (first time only)
flutter create . --platforms android

# 2. Fetch packages
flutter pub get

# 3. Run on device / emulator
flutter run

# 4. Build a release APK
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk
```

### AndroidManifest.xml

The generated manifest needs these permissions (add under `<manifest>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

The app requests location permission at runtime via `geolocator`.

## Layout

```
lib/
  main.dart                     app entry
  src/
    data_service.dart           fetch + disk-cache GeoJSON from live site
    geometry.dart               point-in-polygon, bounds, ring conversion
    models.dart                 GeoCollection / GeoFeature / Municipality / WardResult
    ward_lookup.dart            hierarchical point → ward identification
    municipality_service.dart   locallevelcodes.json → real geometry
    search_screen.dart          municipality search UI
    map_screen.dart             map + result sheets
```

## Known limitations

- Point-in-polygon loads the province file (6 MB) on first identification;
  subsequent lookups hit the disk cache.
- No KML/screenshot features (web-only for now).
- Boundary data is served from the existing maps-clone deployment; it must
  stay reachable or the app shows a load error (cached data still works).
