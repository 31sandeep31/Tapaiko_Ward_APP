# Tapaiko Ward (तपाईंको वडा)

Android app to find the **ward**, **municipality**, **district** and
**province** of any place in Nepal: tap the map, use your location, or search
all 753 local levels.

Flutter + `flutter_map`, Material 3, English and Nepali.

## Features

- **Tap anywhere** to identify that spot's ward (with a dropped pin).
- **Find my ward** with GPS (permission explained first, used on-device only).
- **Search** local levels, districts and provinces; type `Kathmandu 5` to jump
  straight to ward 5.
- **Browse** province → district → local level → ward from the bottom panel;
  system back goes up one level.
- **Census 2021 population** per ward and municipality.
- **Share / copy / directions** for a ward.
- **Offline**: province and district outlines plus the list of local levels
  ship with the app; municipality/ward boundaries and map tiles are cached
  after first use.
- Map styles: automatic, streets, light, dark, terrain, satellite.
- Light/dark theme, English/नेपाली, tablet side-panel layout.

## Project layout

```
lib/
  main.dart, app.dart, app_dependencies.dart
  data/      services + repositories (boundaries, census, cache, settings, location)
  domain/    admin models, geometry (point-in-polygon, label placement)
  ui/core/   theme, map styles, formatting
  ui/features/{map,search,settings,onboarding}/{view_models,views}
assets/      bundled simplified outlines + locallevelcodes.json
store/       Play Store listing, privacy policy, graphics, RELEASE.md
tool/        build_boundary_assets.py, build_icons.py
```

## Data

Boundary files come from `https://maps.sandeepkafle.com.np/data/`
(`locallevels/{district}.json`, `wards/{district}_{locallevel}.json`).
Identification uses the bundled district outlines to pick candidates, then
the full-detail municipality and ward files for exact containment, so the
6 MB province file and 2.5 MB district files are never downloaded.

Quirks handled in `BoundaryRepository`: ward files use `Rukum` for
Rukum East/West; a few official names differ from the boundary files
(Vyas/Byas, Shuddhodhan/Suddhodhan, Shuvakalika/Kalika,
Dodhara Chandani/Mahakali).

## Develop

```bash
flutter pub get
```

```bash
flutter test
```

```bash
flutter run
```

## Release

See [store/RELEASE.md](store/RELEASE.md). Short version:

```bash
flutter build appbundle --release
```
