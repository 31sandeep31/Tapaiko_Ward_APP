# Graph Report - E:/projects/maps/maps-apk  (2026-08-09)

## Corpus Check
- Corpus is ~17,215 words - fits in a single context window. You may not need a graph.

## Summary
- 473 nodes · 590 edges · 27 communities (24 shown, 3 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 10 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Map Screen Logic
- App Localizations
- Data Cache & Service
- Search Screen
- Ward Lookup & Municipality
- English Localizations
- Point-in-Polygon Geometry
- Project Docs & Dependencies
- Service Unit Tests
- Admin Models
- App Entrypoint & Theme
- Census Population Service
- Models & Ward Lookup Tests
- Census Test Mocks
- Data Service Test Mocks
- Search Screen Test Mocks
- Web App Manifest
- Mockito SmartFakes
- Map Screen Widgets
- Widget Previews
- Mockito Mock Clients
- Android MainActivity
- Integration Test Driver
- Launcher Icon

## God Nodes (most connected - your core abstractions)
1. `TAPAIKO WARD (Nepal ward-finder Android app)` - 12 edges
2. `tapaiko_ward package (pubspec)` - 10 edges
3. `AppLocalizations` - 6 edges
4. `DataService` - 6 edges
5. `DataCache` - 5 edges
6. `Nepal admin hierarchy data model (province → district → locallevel → ward)` - 5 edges
7. `Generated app_localizations.dart` - 4 edges
8. `_AppLocalizationsDelegate` - 3 edges
9. `MapScreen` - 3 edges
10. `_MapScreenState` - 3 edges

## Surprising Connections (you probably didn't know these)
- `TAPAIKO WARD Flutter web bootstrap page` --conceptually_related_to--> `TAPAIKO WARD (Nepal ward-finder Android app)`  [INFERRED]
  web/index.html → README.md
- `tapaiko_ward package (pubspec)` --conceptually_related_to--> `TAPAIKO WARD (Nepal ward-finder Android app)`  [INFERRED]
  pubspec.yaml → README.md
- `TAPAIKO WARD (Nepal ward-finder Android app)` --references--> `geolocator dependency`  [EXTRACTED]
  README.md → pubspec.yaml
- `flutter_map dependency` --conceptually_related_to--> `flutter_map rendering library`  [INFERRED]
  pubspec.yaml → README.md
- `tapaiko_ward package (pubspec)` --conceptually_related_to--> `Generated app_localizations.dart`  [INFERRED]
  pubspec.yaml → l10n.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flutter localization generation pipeline** — pubspec_flutter_localizations, pubspec_intl, l10n_app_localizations, pubspec_tapaiko_ward [INFERRED 0.85]
- **Ward-identification data pipeline (hierarchy + alias + pin)** — readme_data_model, readme_locallevelcodes, readme_ward_district_aliases, readme_point_in_polygon [INFERRED 0.75]

## Communities (27 total, 3 thin omitted)

### Community 0 - "Map Screen Logic"
Cohesion: 0.03
Nodes (73): census_service.dart, Color, IconData, int?, LatLngBounds?, _baseLayer, _baseLayers, breadcrumb (+65 more)

### Community 1 - "App Localizations"
Cohesion: 0.05
Nodes (42): app_localizations_en.dart, class, allTypes, AppLocalizations, _AppLocalizationsDelegate, appTitle, baseLayer, couldNotLoadMap (+34 more)

### Community 2 - "Data Cache & Service"
Cohesion: 0.05
Nodes (37): dart:io, data_cache.dart, data_cache_io.dart, Directory?, DataCache, createCache, _dir, _DiskCache (+29 more)

### Community 3 - "Search Screen"
Cohesion: 0.06
Nodes (32): MapScreen, _MapScreenState, _activeType, _all, _applyFilter, build, _buildBody, _chip (+24 more)

### Community 4 - "Ward Lookup & Municipality"
Cohesion: 0.07
Nodes (27): data_service.dart, geometry.dart, _data, focusFor, geometry, _loadWards, municipalities, MunicipalityFocus (+19 more)

### Community 5 - "English Localizations"
Cohesion: 0.07
Nodes (26): app_localizations.dart, allTypes, appTitle, baseLayer, couldNotLoadMap, couldNotLoadMunicipalities, districtLabel, female (+18 more)

### Community 6 - "Point-in-Polygon Geometry"
Cohesion: 0.07
Nodes (25): b, coords, found, geometryBounds, geometryCenter, inside, j, outerRings (+17 more)

### Community 7 - "Project Docs & Dependencies"
Cohesion: 0.12
Nodes (24): flutter_lints rule set (incl. prefer_single_quotes), app_en.arb template, Generated app_localizations.dart, flutter_lints dev dependency, flutter_localizations dependency, flutter_map dependency, geolocator dependency, http dependency (+16 more)

### Community 8 - "Service Unit Tests"
Cohesion: 0.11
Nodes (20): census_service_test.mocks.dart, Client, data_service_test.mocks.dart, Exception, ../helpers/fake_data_cache.dart, package:http/http.dart, package:mockito/annotations.dart, package:mockito/mockito.dart (+12 more)

### Community 9 - "Admin Models"
Cohesion: 0.10
Nodes (19): district, districtCode, features, fromJson, gaPaNaPa, GeoCollection, GeoFeature, geometry (+11 more)

### Community 10 - "App Entrypoint & Theme"
Cohesion: 0.12
Nodes (16): main, ../l10n/app_localizations.dart, build, _buildTheme, main, _seed, TapaikoWardApp, package:flutter_localizations/flutter_localizations.dart (+8 more)

### Community 11 - "Census Population Service"
Cohesion: 0.12
Nodes (15): int get, _baseUrl, CensusData, CensusService, _client, _data, female, fetchFor (+7 more)

### Community 12 - "Models & Ward Lookup Tests"
Cohesion: 0.17
Nodes (10): dart:convert, package:checks/checks.dart, package:tapaiko_ward/src/data_service.dart, package:tapaiko_ward/src/models.dart, package:tapaiko_ward/src/ward_lookup.dart, main, _box, collection (+2 more)

### Community 13 - "Census Test Mocks"
Cohesion: 0.18
Nodes (10): dart:async, close, delete, head, patch, post, put, read (+2 more)

### Community 14 - "Data Service Test Mocks"
Cohesion: 0.18
Nodes (10): dart:typed_data, close, delete, head, patch, post, put, read (+2 more)

### Community 15 - "Search Screen Test Mocks"
Cohesion: 0.18
Nodes (10): package:mockito/src/dummies.dart, close, delete, head, patch, post, put, read (+2 more)

### Community 16 - "Web App Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 17 - "Mockito SmartFakes"
Cohesion: 0.33
Nodes (9): _i1.SmartFake, _i2.Response, _i2.StreamedResponse, _FakeResponse_0, _FakeStreamedResponse_1, _FakeResponse_0, _FakeStreamedResponse_1, _FakeResponse_0 (+1 more)

### Community 18 - "Map Screen Widgets"
Cohesion: 0.22
Nodes (9): _CensusSummary, _FeatureLabel, _GenderBar, _InfoRow, _MunicipalitySheet, _ResultSheet, _StatusCard, _WardNumbersSheet (+1 more)

### Community 19 - "Widget Previews"
Cohesion: 0.29
Nodes (7): @Preview, censusSummaryPreview, featureLabelPreview, genderBarPreview, statusCardPreview, wardLabelPreview, wardNumbersPreview

### Community 20 - "Mockito Mock Clients"
Cohesion: 0.60
Nodes (5): _i1.Mock, _i2.Client, MockClient, MockClient, MockClient

## Knowledge Gaps
- **297 isolated node(s):** `main`, `localeName`, `delegate`, `localizationsDelegates`, `supportedLocales` (+292 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `DataService` connect `Data Cache & Service` to `Map Screen Logic`, `Search Screen`, `Census Population Service`, `Ward Lookup & Municipality`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Why does `FakeDataCache` connect `Data Cache & Service` to `Service Unit Tests`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `TAPAIKO WARD (Nepal ward-finder Android app)` (e.g. with `tapaiko_ward package (pubspec)` and `TAPAIKO WARD Flutter web bootstrap page`) actually correct?**
  _`TAPAIKO WARD (Nepal ward-finder Android app)` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `tapaiko_ward package (pubspec)` (e.g. with `Generated app_localizations.dart` and `TAPAIKO WARD (Nepal ward-finder Android app)`) actually correct?**
  _`tapaiko_ward package (pubspec)` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `main`, `localeName`, `delegate` to the rest of the system?**
  _297 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Map Screen Logic` be split into smaller, more focused modules?**
  _Cohesion score 0.02702702702702703 - nodes in this community are weakly interconnected._
- **Should `App Localizations` be split into smaller, more focused modules?**
  _Cohesion score 0.04983388704318937 - nodes in this community are weakly interconnected._