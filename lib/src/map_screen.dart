import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';

import 'census_service.dart';
import 'data_service.dart';
import 'geometry.dart';
import 'models.dart';
import 'municipality_service.dart';
import 'search_screen.dart';
import 'ward_lookup.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// Base layers matching the web app's layer chooser.
const _baseLayers = <String, String>{
  'OpenStreetMap': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  'Google Maps': 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
  'Google Satellite': 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
};

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final DataService _data = DataService();
  final WardLookup _lookup = WardLookup(DataService());

  String _baseLayer = 'OpenStreetMap';

  /// 0=province, 1=district, 2=locallevel, 3=ward
  int _level = 0;

  GeoFeature? _province;
  String _provinceShort = '';
  String _districtName = '';
  String _localLevelName = '';
  String _localLevelDistrict = '';

  List<GeoFeature> _levelFeatures = [];
  List<Polygon> _levelPolygons = [];
  List<Polygon> _highlightPolygons = [];
  CensusData? _census;
  bool _loading = true;
  bool _mapReady = false;
  LatLngBounds? _pendingFit;
  String? _error;
  bool _locating = false;
  String _status = '';
  LatLng? _pinPoint;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await _data.getJson('province.json');
      final features = (json['features'] as List<dynamic>? ?? const [])
          .map((e) => GeoFeature.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _levelFeatures = features;
        _levelPolygons = _featuresToPolygons(features);
        _loading = false;
        _level = 0;
        _province = null;
        _provinceShort = '';
        _districtName = '';
        _localLevelName = '';
        _localLevelDistrict = '';
        _census = null;
        _status = 'Tap a province to start. '
            'Long-press anywhere to identify a location.';
      });
      _requestFit(
          LatLngBounds(const LatLng(26.3, 80.0), const LatLng(30.5, 88.3)));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _requestFit(LatLngBounds bounds) {
    if (_mapReady) {
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
    } else {
      _pendingFit = bounds;
    }
  }

  Color _featureColor(String name) {
    const palette = [
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFE91E63),
      Color(0xFF3F51B5),
      Color(0xFF8BC34A),
      Color(0xFFFFC107),
      Color(0xFFF44336),
    ];
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return palette[h % palette.length];
  }

  List<Polygon> _featuresToPolygons(List<GeoFeature> features) {
    final polygons = <Polygon>[];
    for (final f in features) {
      final name = f['name'] as String? ?? '';
      final geometry = f.geometry;
      if (geometry == null) continue;
      final color = _featureColor(name);
      for (final ring in outerRings(geometry)) {
        polygons.add(Polygon(
          points: ring,
          color: color.withValues(alpha: 0.28),
          borderColor: color.withValues(alpha: 0.85),
          borderStrokeWidth: 1.2,
        ));
      }
    }
    return polygons;
  }

  List<Polygon> _polygonsFor(Map<String, dynamic>? geometry) {
    if (geometry == null) return const [];
    return outerRings(geometry)
        .map((ring) => Polygon(
              points: ring,
              color: const Color(0x88FFB300),
              borderColor: const Color(0xFFFF8F00),
              borderStrokeWidth: 2.5,
            ))
        .toList();
  }

  List<Marker> _labels() {
    final camera = _mapReady ? _mapController.camera : null;
    final placed = <Rect>[];
    final markers = <Marker>[];

    final features = List.of(_levelFeatures)
      ..sort((a, b) => _featureArea(b).compareTo(_featureArea(a)));

    for (final f in features) {
      final geometry = f.geometry;
      if (geometry == null) continue;
      final center = geometryCenter(geometry);
      if (center == null) continue;
      final label = _level == 3
          ? (f['name'] as String? ??
              (f['Ward_Num']?.toString() ?? '?'))
          : (f['name'] as String? ?? '');
      if (label.isEmpty) continue;

      final size = _labelSize(label);
      Rect? screen;
      if (camera != null) {
        try {
          final p = camera.latLngToScreenPoint(center);
          screen = Rect.fromCenter(
            center: Offset(p.x.toDouble(), p.y.toDouble()),
            width: size.width,
            height: size.height,
          ).inflate(3);
        } catch (_) {
          screen = null;
        }
      }
      if (screen != null) {
        if (placed.any(screen.overlaps)) continue;
        placed.add(screen);
      }

      markers.add(Marker(
        point: center,
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        rotate: false,
        child: IgnorePointer(
          child: _FeatureLabel(
            text: label,
            level: _level,
            color: _featureColor(f['name'] as String? ?? ''),
          ),
        ),
      ));
    }
    return markers;
  }

  /// Bounding-box area in degrees, used to prioritise larger features so
  /// their labels win when labels collide.
  double _featureArea(GeoFeature f) {
    final g = f.geometry;
    if (g == null) return 0;
    final b = geometryBounds(g);
    if (b == null) return 0;
    return (b.east - b.west) * (b.north - b.south);
  }

  /// Measures a label the same way [_FeatureLabel] renders it, so collision
  /// detection matches the on-screen box (2-line wrap, ellipsis).
  Size _labelSize(String text) {
    final isWard = _level == 3;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: isWard ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.1,
        ),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 170);
    // Padding + border + margin slack so the marker's tight 30x30-style box
    // never clips the rendered label.
    final padH = (isWard ? 3 : 6) * 2.0 + 6;
    final padV = (isWard ? 1 : 2) * 2.0 + 6;
    return Size(painter.width + padH, painter.height + padV);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Drill-down: province → district → local level → ward ----

  Future<void> _onMapTap(LatLng point) async {
    if (_loading) return;
    try {
      switch (_level) {
        case 0:
          await _selectProvince(point);
        case 1:
          await _selectDistrict(point);
        case 2:
          await _selectLocalLevel(point);
        case 3:
          await _selectWard(point);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('Lookup failed: $e');
    }
  }

  Future<void> _selectProvince(LatLng point) async {
    setState(() {
      _locating = true;
      _status = 'Identifying province…';
    });
    final province = await _lookup.findProvince(point);
    if (!mounted) return;
    if (province == null) {
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('No province found at this point (outside Nepal?).');
      return;
    }
    final districts = await _lookup.loadDistricts(province['name'] as String? ?? '');
    if (!mounted) return;
    setState(() {
      _province = province;
      _provinceShort = province['name'] as String? ?? '';
      _districtName = '';
      _localLevelName = '';
      _localLevelDistrict = '';
      _level = 1;
      _locating = false;
      _census = null;
      _status = 'Tap a district in ${province['Province'] ?? _provinceShort}.';
      _levelFeatures = districts;
      _levelPolygons = _featuresToPolygons(districts);
      _highlightPolygons = _polygonsFor(province.geometry);
    });
    _fitTo(province.geometry);
  }

  Future<void> _selectDistrict(LatLng point) async {
    if (_provinceShort.isEmpty) {
      _showMessage('Select a province first.');
      return;
    }
    setState(() {
      _locating = true;
      _status = 'Identifying district…';
    });
    final district =
        await _lookup.findDistrict(point, _provinceShort);
    if (!mounted) return;
    if (district == null) {
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('No district found at this point.');
      return;
    }
    final districtName = district['District'] as String? ??
        district['name'] as String? ??
        '';
    final localLevels = await _lookup.loadLocalLevels(districtName);
    if (!mounted) return;
    setState(() {
      _districtName = districtName;
      _localLevelName = '';
      _localLevelDistrict = '';
      _level = 2;
      _locating = false;
      _census = null;
      _status = 'Tap a municipality in $districtName.';
      _levelFeatures = localLevels;
      _levelPolygons = _featuresToPolygons(localLevels);
      _highlightPolygons = _polygonsFor(district.geometry);
    });
    _fitTo(district.geometry);
  }

  Future<void> _selectLocalLevel(LatLng point) async {
    if (_districtName.isEmpty) {
      _showMessage('Select a district first.');
      return;
    }
    setState(() {
      _locating = true;
      _status = 'Identifying municipality…';
    });
    final localLevel =
        await _lookup.findLocalLevel(point, _districtName);
    if (!mounted) return;
    if (localLevel == null) {
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('No municipality found at this point.');
      return;
    }
    final llName = localLevel['name'] as String? ?? '';
    final llDistrict =
        localLevel['District'] as String? ?? _districtName;
    final wards = await _lookup.loadWards(llDistrict, llName);
    if (!mounted) return;
    final wardNos = wards
        .map((w) => w['name'] as String? ??
            (w['Ward_Num']?.toString() ?? '?'))
        .toList();
    setState(() {
      _localLevelName = llName;
      _localLevelDistrict = llDistrict;
      _level = 3;
      _locating = false;
      _status = 'Tap a ward in $llName, or pick one below.';
      _levelFeatures = wards;
      _levelPolygons = _featuresToPolygons(wards);
      _highlightPolygons = _polygonsFor(localLevel.geometry);
    });
    _fitTo(localLevel.geometry);
    _loadCensus(localLevel, llName);
    _showWardNumbers(llName, wardNos, wards);
  }

  Future<void> _loadCensus(GeoFeature localLevel, String llName) async {
    final provinceName = localLevel['Province'] as String? ?? '';
    final districtName = localLevel['District'] as String? ?? _districtName;
    final census = await CensusService(_data)
        .fetchFor(
            province: provinceName,
            district: districtName,
            municipality: llName);
    if (!mounted || !identical(_level, 3)) return;
    setState(() => _census = census);
  }

  Future<void> _selectWard(LatLng point) async {
    if (_localLevelName.isEmpty) {
      _showMessage('Select a municipality first.');
      return;
    }
    setState(() {
      _locating = true;
      _status = 'Identifying ward…';
    });
    final ward = await _lookup
        .findWard(point, _localLevelDistrict, _localLevelName);
    if (!mounted) return;
    if (ward == null) {
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('No ward found at this point.');
      return;
    }
    final wardNo = ward['name'] as String? ??
        (ward['Ward_Num']?.toString() ?? '');
    setState(() {
      _locating = false;
      _status = '';
      _highlightPolygons = _polygonsFor(ward.geometry);
    });
    _fitTo(ward.geometry);
    _showWardResult(wardNo, ward);
  }

  // ---- Results & sheets ----

  void _showWardResult(String wardNo, GeoFeature ward) {
    final result = WardResult(
      wardNo: wardNo,
      municipality:
          ward['GaPa_NaPa'] as String? ?? _localLevelName,
      type: ward['Type_GN'] as String? ?? '',
      district: _districtName,
      province: _province?['Province'] as String? ?? _provinceShort,
      wardGeometry: ward.geometry ?? const {},
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ResultSheet(result: result, census: _census),
    );
  }

  void _showWardNumbers(
      String llName, List<String> wardNos, List<GeoFeature> wards) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _WardNumbersSheet(
        municipalityName: llName,
        districtName: _districtName,
        wardNos: wardNos,
        onPick: (index) {
          Navigator.of(ctx).pop();
          final ward = wards[index];
          final wardNo = wardNos[index];
          setState(() => _highlightPolygons = _polygonsFor(ward.geometry));
          _fitTo(ward.geometry);
          _showWardResult(wardNo, ward);
        },
      ),
    );
  }

  void _fitTo(Map<String, dynamic>? geometry) {
    final bounds = geometryBounds(geometry ?? const {});
    if (bounds != null) {
      _requestFit(bounds);
    }
  }

  void _pickBaseLayer() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(ctx)!.baseLayer,
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  for (final name in _baseLayers.keys)
                    ButtonSegment(value: name, label: Text(name)),
                ],
                selected: {_baseLayer},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  Navigator.of(ctx).pop();
                  setState(() => _baseLayer = selection.first);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Long-press: drop a pin at the given point and identify the full
  /// admin hierarchy (province → district → municipality → ward) there.
  Future<void> _pinAndIdentify(LatLng point) async {
    if (_locating) return;
    setState(() {
      _pinPoint = point;
      _locating = true;
      _status = AppLocalizations.of(context)!.identifyingLocation;
    });
    try {
      final result = await _lookup.identify(point);
      if (!mounted) return;
      setState(() {
        _locating = false;
        _status = '';
        _highlightPolygons = _polygonsFor(result?.wardGeometry);
      });
      if (result == null) {
        _showMessage('No ward found at this point (outside Nepal?).');
        return;
      }
      final census = await CensusService(_data).fetchFor(
        province: result.province,
        district: result.district,
        municipality: result.municipality,
      );
      if (!mounted) return;
      _showResult(result, census: census);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('Lookup failed: $e');
    }
  }

  Future<void> _findMyWard() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _status = 'Getting your location…';
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _status = '';
        });
        _showMessage('Location permission denied. Enable it in settings.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      _mapController.move(point, 15);
      setState(() => _status = 'Identifying your ward…');
      final result = await _lookup.identify(point);
      if (!mounted) return;
      setState(() {
        _locating = false;
        _status = '';
        _highlightPolygons = _polygonsFor(result?.wardGeometry);
      });
      if (result == null) {
        _showMessage('No ward found at this point (outside Nepal?).');
        return;
      }
      _showResult(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('Could not determine location: $e');
    }
  }

  void _showResult(WardResult result, {CensusData? census}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) =>
          _ResultSheet(result: result, census: census ?? _census),
    );
  }

  Future<void> _openSearch() async {
    final selection = await Navigator.of(context).push<MapSelection>(
      MaterialPageRoute(
        builder: (_) => SearchScreen(data: _data),
      ),
    );
    if (selection == null || !mounted) return;

    setState(() {
      _status = 'Locating ${selection.title}…';
      _locating = true;
    });

    try {
      if (selection.municipality == null) {
        if (mounted) {
          setState(() {
            _locating = false;
            _status = '';
          });
        }
        _showMessage('Could not resolve municipality.');
        return;
      }
      final focus =
          await MunicipalityService(_data).focusFor(selection.municipality!);
      if (!mounted) return;
      setState(() {
        _locating = false;
        _status = '';
        _highlightPolygons = _polygonsFor(focus?.geometry);
      });
      if (focus == null) {
        _showMessage('Could not load boundary for ${selection.title}.');
        return;
      }
      final bounds = geometryBounds(focus.geometry);
      if (bounds != null) {
        _requestFit(bounds);
      }
      _showMunicipalitySheet(selection, focus);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _status = '';
      });
      _showMessage('Search failed: $e');
    }
  }

  void _showMunicipalitySheet(MapSelection selection, MunicipalityFocus focus) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _MunicipalitySheet(
        selection: selection,
        focus: focus,
        onPickWard: (ward) {
          Navigator.of(ctx).pop();
          final bounds = geometryBounds(ward.geometry);
          if (bounds != null) {
            _requestFit(bounds);
          }
          setState(() => _highlightPolygons = _polygonsFor(ward.geometry));
          _showMessage('Ward ${ward.wardNo} of ${selection.title}');
        },
      ),
    );
  }

  String get _breadcrumb {
    final parts = <String>['Nepal'];
    if (_province != null) {
      parts.add(_province?['Province'] as String? ?? _provinceShort);
    }
    if (_districtName.isNotEmpty) parts.add(_districtName);
    if (_localLevelName.isNotEmpty) parts.add(_localLevelName);
    return parts.join(' › ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            tooltip: l10n.baseLayer,
            onPressed: _pickBaseLayer,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.searchWardTooltip,
            onPressed: _openSearch,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(28.3949, 84.1240),
              initialZoom: 7,
              minZoom: 5,
              maxZoom: 18,
              onTap: (tapPosition, point) => _onMapTap(point),
              onLongPress: (tapPosition, point) => _pinAndIdentify(point),
              onMapReady: () {
                setState(() => _mapReady = true);
                final pending = _pendingFit;
                if (pending != null) {
                  _pendingFit = null;
                  _mapController.fitCamera(CameraFit.bounds(bounds: pending));
                }
              },
            ),
            children: [
              TileLayer(
                key: ValueKey(_baseLayer),
                urlTemplate: _baseLayers[_baseLayer],
                userAgentPackageName: 'com.tapaiko.ward',
              ),
              TweenAnimationBuilder<double>(
                key: ValueKey('level-$_level'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) =>
                    Opacity(opacity: value, child: child),
                child: Stack(
                  children: [
                    PolygonLayer(polygons: _levelPolygons),
                    PolygonLayer(polygons: _highlightPolygons),
                    MarkerLayer(markers: _labels()),
                    if (_pinPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pinPoint!,
                            width: 44,
                            height: 44,
                            alignment: Alignment.topCenter,
                            child: const IgnorePointer(
                              child: Icon(
                                Icons.location_pin,
                                size: 44,
                                color: Color(0xFFD32F2F),
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 12),
                    Text(l10n.couldNotLoadMap),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadProvinces,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            ),
          if (_status.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _StatusCard(
                breadcrumb: _breadcrumb,
                status: _status,
                loading: _locating,
              ),
            ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton.extended(
              onPressed: _locating ? null : _findMyWard,
              icon: const Icon(Icons.my_location),
              label: Text(l10n.findMyWard),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: IgnorePointer(
              ignoring: _level == 0,
              child: AnimatedScale(
                scale: _level > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _level > 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: FloatingActionButton(
                    heroTag: 'back',
                    tooltip: l10n.goBack,
                    onPressed: () {
                      setState(() {
                        _level = 0;
                        _province = null;
                        _provinceShort = '';
                        _districtName = '';
                        _localLevelName = '';
                        _localLevelDistrict = '';
                        _status = l10n.tapAProvince;
                      });
                      _loadProvinces();
                    },
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLabel extends StatelessWidget {
  const _FeatureLabel({
    required this.text,
    required this.level,
    required this.color,
  });

  final String text;
  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isWard = level == 3;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: EdgeInsets.symmetric(
          horizontal: isWard ? 3 : 6, vertical: isWard ? 1 : 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isWard ? 0.75 : 0.9),
        borderRadius: BorderRadius.circular(isWard ? 4 : 6),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isWard ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          height: 1.1,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.breadcrumb,
    required this.status,
    required this.loading,
  });

  final String breadcrumb;
  final String status;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading) ...[
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(breadcrumb,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Text(
                      status,
                      key: ValueKey(status),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardNumbersSheet extends StatelessWidget {
  const _WardNumbersSheet({
    required this.municipalityName,
    required this.districtName,
    required this.wardNos,
    required this.onPick,
  });

  final String municipalityName;
  final String districtName;
  final List<String> wardNos;
  final void Function(int index) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(municipalityName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('$districtName · ${wardNos.length} wards',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 56,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: wardNos.length,
                itemBuilder: (ctx, i) => InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPick(i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(wardNos[i],
                        style: theme.textTheme.titleMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.result, this.census});

  final WardResult result;
  final CensusData? census;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.yourWard, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              l10n.ward(result.wardNo),
              style: theme.textTheme.headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (census != null)
              _CensusSummary(
                census: census!,
                wardNo: int.tryParse(result.wardNo),
              ),
            _InfoRow(icon: Icons.location_city, label: l10n.municipalityLabel,
                value: result.municipality),
            if (result.type.isNotEmpty)
              _InfoRow(icon: Icons.apartment, label: l10n.typeLabel,
                  value: result.type),
            _InfoRow(icon: Icons.map, label: l10n.districtLabel,
                value: result.district),
            _InfoRow(icon: Icons.flag, label: l10n.provinceLabel,
                value: result.province),
          ],
        ),
      ),
    );
  }
}

class _CensusSummary extends StatelessWidget {
  const _CensusSummary({required this.census, this.wardNo});

  final CensusData census;
  final int? wardNo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final wardPop =
        wardNo == null ? null : census.wardPopulation(wardNo!);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.population,
                  style: theme.textTheme.labelMedium),
              const Spacer(),
              Text(_fmt(wardPop ?? census.totalPopulation),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          _GenderBar(label: l10n.male, count: census.totalMale,
              total: census.totalPopulation,
              color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          _GenderBar(label: l10n.female, count: census.totalFemale,
              total: census.totalPopulation,
              color: theme.colorScheme.tertiary),
        ],
      ),
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _GenderBar extends StatelessWidget {
  const _GenderBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frac = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: theme.textTheme.bodySmall)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
            width: 70,
            child: Text(_fmt(count),
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall)),
      ],
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _MunicipalitySheet extends StatelessWidget {
  const _MunicipalitySheet({
    required this.selection,
    required this.focus,
    required this.onPickWard,
  });

  final MapSelection selection;
  final MunicipalityFocus focus;
  final void Function(WardSummary ward) onPickWard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wards = focus.wards
        .map((f) => WardSummary(
              wardNo: f['name'] as String? ??
                  (f['Ward_Num']?.toString() ?? '?'),
              geometry: f.geometry ?? const {},
            ))
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(selection.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(selection.subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('${wards.length} wards',
                style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            if (wards.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                    AppLocalizations.of(context)!.noWardBoundaries),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: wards.length,
                  itemBuilder: (ctx, i) {
                    final w = wards[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.numbers),
                      title: Text('Ward ${w.wardNo}'),
                      onTap: () => onPickWard(w),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// ---- Widget previews (flutter widget-preview start) ----

@Preview(name: 'Feature label - district', group: 'Map')
Widget featureLabelPreview() => const _FeatureLabel(
    text: 'Bhojpur', level: 1, color: Color(0xFF2196F3));

@Preview(name: 'Feature label - ward', group: 'Map')
Widget wardLabelPreview() =>
    const _FeatureLabel(text: '5', level: 3, color: Color(0xFF4CAF50));

@Preview(name: 'Status card', group: 'Map')
Widget statusCardPreview() => const _StatusCard(
    breadcrumb: 'Nepal � Koshi Pradesh � Bhojpur',
    status: 'Tap a district in Koshi Pradesh.',
    loading: true);

@Preview(name: 'Census summary', group: 'Map')
Widget censusSummaryPreview() => _CensusSummary(
    census: CensusData(male: const [120, 210], female: const [135, 225]),
    wardNo: 1);

@Preview(name: 'Gender bar', group: 'Map')
Widget genderBarPreview() =>
    const _GenderBar(label: 'Male', count: 330, total: 690, color: Color(0xFF2196F3));

@Preview(name: 'Ward numbers sheet', group: 'Map')
Widget wardNumbersPreview() => _WardNumbersSheet(
    municipalityName: 'Hatuwagadhi',
    districtName: 'Bhojpur',
    wardNos: const ['1', '2', '3', '4', '5'],
    onPick: (index) {});
