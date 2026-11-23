import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/boundary_repository.dart';
import '../../../../data/census_service.dart';
import '../../../../data/data_service.dart';
import '../../../../data/location_service.dart';
import '../../../../data/models.dart';
import '../../../../data/settings_repository.dart';
import '../../../../domain/admin.dart';
import '../../../../domain/geometry.dart';

/// What the map is busy doing (drives the progress indicator and copy).
enum BusyKind { none, locating, identifying, loading }

/// One-off problems surfaced as a snackbar.
enum MapIssue {
  offline,
  server,
  outsideNepal,
  notFound,
  noWardAtSpot,
  boundaryUnavailable,
  locationOff,
  locationDenied,
  locationDeniedForever,
  locationFailed,
}

class MapNotice {
  MapNotice(this.issue, {this.arg}) : id = _next++;
  static int _next = 0;

  final MapIssue issue;
  final String? arg;
  final int id;
}

/// Asks the view to move the camera.
class CameraRequest {
  CameraRequest.bounds(LatLngBounds this.bounds, {this.onlyIfHidden = false})
      : center = null,
        zoom = null,
        id = _next++;

  CameraRequest.point(LatLng this.center, this.zoom)
      : bounds = null,
        onlyIfHidden = false,
        id = _next++;

  static int _next = 0;

  final LatLngBounds? bounds;
  final LatLng? center;
  final double? zoom;

  /// Skip the move when [bounds] is already fully on screen.
  final bool onlyIfHidden;
  final int id;
}

/// An area drawn on the map at the current level.
class MapArea {
  const MapArea({
    required this.id,
    required this.label,
    required this.feature,
    required this.colorKey,
  });

  final String id;
  final String label;
  final GeoFeature feature;

  /// Seed for the area's colour (name, or province number).
  final String colorKey;
}

class MapViewModel extends ChangeNotifier {
  MapViewModel({
    required BoundaryRepository boundaries,
    required CensusService census,
    required SettingsRepository settings,
    LocationService location = const LocationService(),
  })  : _repo = boundaries,
        _census = census,
        _settings = settings,
        _location = location;

  final BoundaryRepository _repo;
  final CensusService _census;
  final SettingsRepository _settings;
  final LocationService _location;

  bool _disposed = false;
  int _token = 0;

  bool ready = false;
  bool loadFailed = false;
  AdminLevel level = AdminLevel.country;
  ProvinceInfo? province;
  DistrictInfo? district;
  MunicipalityInfo? municipality;
  GeoFeature? selectedWard;

  /// Full-detail local levels of [district]; null while loading/unavailable.
  List<GeoFeature>? districtLocalLevels;

  LatLng? pin;
  LocationFix? userLocation;

  CensusData? census;
  bool censusLoading = false;

  BusyKind busy = BusyKind.none;
  MapNotice? notice;
  CameraRequest? camera;
  List<MapArea> areas = const [];

  BoundaryRepository get repository => _repo;
  SettingsRepository get settings => _settings;
  LocationService get location => _location;

  List<ProvinceInfo> get provinces => _repo.provinces;

  String? get selectedWardNo =>
      selectedWard == null ? null : wardNumberOf(selectedWard!);

  /// Outline of the area currently in focus (everything else is dimmed).
  GeoFeature? get focusOutline => switch (level) {
        AdminLevel.country => null,
        AdminLevel.province => province?.feature,
        AdminLevel.district => district?.feature,
        AdminLevel.municipality => municipality?.feature,
      };

  // ---- Lifecycle ----

  Future<void> init() async {
    try {
      await _repo.init();
      ready = true;
      loadFailed = false;
      _showCountry(moveCamera: false);
      _notify();
      if (_settings.locateOnStart) unawaited(locateMe(silent: true));
    } catch (_) {
      loadFailed = true;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ---- Navigation ----

  void showCountry() {
    _showCountry();
    _notify();
  }

  void _showCountry({bool moveCamera = true}) {
    _token++;
    level = AdminLevel.country;
    province = null;
    district = null;
    municipality = null;
    selectedWard = null;
    districtLocalLevels = null;
    pin = null;
    census = null;
    busy = BusyKind.none;
    areas = [
      for (final p in _repo.provinces)
        MapArea(
          id: 'p:${p.shortName}',
          label: p.shortName,
          feature: p.feature,
          colorKey: '#${p.number}',
        ),
    ];
    if (moveCamera) camera = CameraRequest.bounds(nepalBounds);
  }

  void selectProvince(ProvinceInfo p) {
    _token++;
    level = AdminLevel.province;
    province = p;
    district = null;
    municipality = null;
    selectedWard = null;
    districtLocalLevels = null;
    pin = null;
    census = null;
    busy = BusyKind.none;
    areas = [
      for (final d in _repo.districtsOf(p))
        MapArea(
          id: 'd:${d.name}',
          label: d.name,
          feature: d.feature,
          colorKey: d.name,
        ),
    ];
    if (p.bounds != null) camera = CameraRequest.bounds(p.bounds!);
    _notify();
  }

  Future<void> selectDistrict(DistrictInfo d) async {
    final token = ++_token;
    level = AdminLevel.district;
    province = d.province;
    district = d;
    municipality = null;
    selectedWard = null;
    pin = null;
    census = null;
    districtLocalLevels = null;
    // Until the detailed boundaries arrive, show the bundled outline.
    areas = [
      MapArea(
          id: 'd:${d.name}', label: '', feature: d.feature, colorKey: d.name),
    ];
    busy = BusyKind.loading;
    if (d.bounds != null) camera = CameraRequest.bounds(d.bounds!);
    _notify();

    try {
      final features = await _repo.localLevelsOf(d);
      if (token != _token) return;
      districtLocalLevels = features;
      areas = [
        for (final f in features)
          MapArea(
            id: 'l:${d.name}/${f['name']}',
            label: f['name'] as String? ?? '',
            feature: f,
            colorKey: f['name'] as String? ?? '',
          ),
      ];
    } catch (e) {
      if (token != _token) return;
      notice = MapNotice(_issueFor(e));
    }
    busy = BusyKind.none;
    _notify();
  }

  /// Opens a local level picked from the district list or search.
  Future<void> openMunicipality(Municipality m, {String? wardNo}) async {
    final token = ++_token;
    busy = BusyKind.loading;
    _notify();
    try {
      final info = await _repo.municipalityFor(m);
      if (token != _token) return;
      if (info == null) {
        busy = BusyKind.none;
        notice = MapNotice(MapIssue.boundaryUnavailable, arg: m.gaPaNaPa);
        _notify();
        return;
      }
      _showMunicipality(info, ward: wardNo == null ? null : info.ward(wardNo));
    } catch (e) {
      if (token != _token) return;
      busy = BusyKind.none;
      notice = MapNotice(_issueFor(e));
      _notify();
    }
  }

  /// Opens a local level from its boundary feature (district map/list).
  Future<void> openLocalLevelFeature(GeoFeature feature) async {
    final d = district;
    if (d == null) return;
    final token = ++_token;
    busy = BusyKind.loading;
    _notify();
    try {
      final info = await _repo.municipalityFromFeature(d, feature);
      if (token != _token) return;
      _showMunicipality(info);
    } catch (e) {
      if (token != _token) return;
      busy = BusyKind.none;
      notice = MapNotice(_issueFor(e));
      _notify();
    }
  }

  Future<void> openRecent(RecentPlace r) async {
    final token = ++_token;
    busy = BusyKind.loading;
    _notify();
    try {
      final info = await _repo.municipalityByName(r.district, r.localLevel);
      if (token != _token) return;
      if (info == null) {
        busy = BusyKind.none;
        notice = MapNotice(MapIssue.boundaryUnavailable, arg: r.localLevel);
        _notify();
        return;
      }
      _showMunicipality(info,
          ward: r.wardNo == null ? null : info.ward(r.wardNo!));
    } catch (e) {
      if (token != _token) return;
      busy = BusyKind.none;
      notice = MapNotice(_issueFor(e));
      _notify();
    }
  }

  void _showMunicipality(
    MunicipalityInfo info, {
    GeoFeature? ward,
    LatLng? pinAt,
    bool cameraOnlyIfHidden = false,
  }) {
    final sameMunicipality = municipality == info;
    level = AdminLevel.municipality;
    province = info.province;
    district = info.district;
    municipality = info;
    selectedWard = ward;
    pin = pinAt;
    busy = BusyKind.none;
    areas = [
      for (final w in info.wards)
        MapArea(
          id: 'w:${info.district.name}/${info.name}/${wardNumberOf(w)}',
          label: wardNumberOf(w),
          feature: w,
          colorKey: '${info.name}${wardNumberOf(w)}',
        ),
    ];
    final focus = ward?.geometry ?? info.feature.geometry;
    final b = focus == null ? null : geometryBounds(focus);
    if (b != null) {
      camera = CameraRequest.bounds(b, onlyIfHidden: cameraOnlyIfHidden);
    }
    _settings.addRecent(RecentPlace(
      district: info.district.name,
      localLevel: info.name,
      type: info.type.raw,
      wardNo: ward == null ? null : wardNumberOf(ward),
    ));
    if (!sameMunicipality) {
      census = null;
      unawaited(_loadCensus(info));
    }
    _notify();
  }

  Future<void> _loadCensus(MunicipalityInfo info) async {
    final codes = info.codes;
    if (codes == null) return;
    censusLoading = true;
    _notify();
    final data = await _census.fetchByCodes(codes);
    if (municipality != info) return;
    census = data;
    censusLoading = false;
    _notify();
  }

  void selectWard(GeoFeature ward) {
    final info = municipality;
    if (info == null) return;
    _token++;
    selectedWard = ward;
    pin = null;
    final b = ward.geometry == null ? null : geometryBounds(ward.geometry!);
    if (b != null) camera = CameraRequest.bounds(b, onlyIfHidden: true);
    _settings.addRecent(RecentPlace(
      district: info.district.name,
      localLevel: info.name,
      type: info.type.raw,
      wardNo: wardNumberOf(ward),
    ));
    _notify();
  }

  void clearWard() {
    selectedWard = null;
    pin = null;
    final b = municipality?.bounds;
    if (b != null) camera = CameraRequest.bounds(b);
    _notify();
  }

  /// Goes up one level. Returns false when already at the country view.
  bool goBack() {
    switch (level) {
      case AdminLevel.country:
        return false;
      case AdminLevel.province:
        showCountry();
      case AdminLevel.district:
        selectProvince(district!.province);
      case AdminLevel.municipality:
        if (selectedWard != null || pin != null) {
          clearWard();
        } else {
          selectDistrict(municipality!.district);
        }
    }
    return true;
  }

  // ---- Identify ----

  /// Identifies the ward at [point] (map tap or GPS fix).
  Future<void> identifyAt(LatLng point, {bool fromGps = false}) async {
    if (!ready) return;
    final token = ++_token;
    pin = fromGps ? null : point;
    busy = BusyKind.identifying;
    _notify();
    try {
      final result = await _repo.identify(point);
      if (token != _token) return;
      switch (result) {
        case IdentifyFound(:final municipality, :final ward):
          _showMunicipality(
            municipality,
            ward: ward,
            pinAt: fromGps ? null : point,
            cameraOnlyIfHidden: !fromGps,
          );
          if (ward == null && municipality.wards.isNotEmpty) {
            notice = MapNotice(MapIssue.noWardAtSpot);
            _notify();
          }
        case IdentifyOutsideNepal():
          busy = BusyKind.none;
          pin = null;
          notice = MapNotice(MapIssue.outsideNepal);
          _notify();
        case IdentifyNotFound():
          busy = BusyKind.none;
          pin = null;
          notice = MapNotice(MapIssue.notFound);
          _notify();
      }
    } catch (e) {
      if (token != _token) return;
      busy = BusyKind.none;
      pin = null;
      notice = MapNotice(_issueFor(e));
      _notify();
    }
  }

  /// Finds the user's location and identifies their ward.
  ///
  /// With [silent], nothing is requested or reported: it only runs when
  /// permission was granted earlier (used when the app opens).
  Future<void> locateMe({bool silent = false}) async {
    if (busy == BusyKind.locating) return;
    final status = silent ? await _location.status() : await _location.request();
    if (status != LocationStatus.granted) {
      if (!silent) {
        notice = MapNotice(switch (status) {
          LocationStatus.serviceOff => MapIssue.locationOff,
          LocationStatus.deniedForever => MapIssue.locationDeniedForever,
          _ => MapIssue.locationDenied,
        });
        _notify();
      }
      return;
    }
    final token = ++_token;
    busy = BusyKind.locating;
    _notify();
    final fix = await _location.current();
    if (token != _token) return;
    if (fix == null) {
      busy = BusyKind.none;
      if (!silent) notice = MapNotice(MapIssue.locationFailed);
      _notify();
      return;
    }
    userLocation = fix;
    camera = CameraRequest.point(fix.point, 15);
    _notify();
    await identifyAt(fix.point, fromGps: true);
  }

  MapIssue _issueFor(Object e) => switch (e) {
        NetworkException() => MapIssue.offline,
        HttpStatusException() => MapIssue.server,
        _ => MapIssue.server,
      };
}
