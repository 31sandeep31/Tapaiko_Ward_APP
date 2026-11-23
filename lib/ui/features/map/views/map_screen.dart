import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app_dependencies.dart';
import '../../../../data/models.dart';
import '../../../../data/settings_repository.dart';
import '../../../../domain/admin.dart';
import '../../../core/formatting.dart';
import '../../../core/map_styles.dart';
import '../../../core/theme.dart';
import '../../search/views/search_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../view_models/map_view_model.dart';
import 'map_layers.dart';
import 'map_panel.dart';
import 'place_actions.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const _midExtent = 0.42;
  static const _maxExtent = 0.92;
  static const _sideSheetWidth = 400.0;
  static const _wideBreakpoint = 840.0;

  late final MapViewModel vm;
  final _map = MapController();
  final _sheet = DraggableScrollableController();
  final _sideScroll = ScrollController();

  bool _mapReady = false;
  CameraRequest? _pendingCamera;
  int _lastCameraId = -1;
  int _lastNoticeId = -1;
  String _lastPanelKey = '';
  AnimationController? _camAnim;
  double _sheetExtent = _midExtent;
  Size _screen = Size.zero;
  bool _wide = false;

  // Memoised map geometry (rebuilt only when the data changes).
  List<MapArea>? _memoAreas;
  Brightness? _memoBrightness;
  Locale? _memoLocale;
  List<Polygon> _areaPolygons = const [];
  List<AreaLabel> _areaLabels = const [];
  GeoFeature? _memoFocus;
  List<Polygon> _focusPolygons = const [];
  GeoFeature? _memoWard;
  List<Polygon> _wardPolygons = const [];

  @override
  void initState() {
    super.initState();
    vm = MapViewModel(
      boundaries: widget.deps.boundaries,
      census: widget.deps.census,
      settings: widget.deps.settings,
    )..addListener(_onVmChanged);
    _sheet.addListener(() {
      if (_sheet.isAttached && (_sheet.size - _sheetExtent).abs() > 0.002) {
        setState(() => _sheetExtent = _sheet.size);
      }
    });
    vm.init();
  }

  @override
  void dispose() {
    _camAnim?.dispose();
    vm.removeListener(_onVmChanged);
    vm.dispose();
    _sheet.dispose();
    _sideScroll.dispose();
    super.dispose();
  }

  // ---- View-model side effects ----

  void _onVmChanged() {
    final cam = vm.camera;
    if (cam != null && cam.id != _lastCameraId) {
      _lastCameraId = cam.id;
      _applyCamera(cam);
    }
    final notice = vm.notice;
    if (notice != null && notice.id != _lastNoticeId) {
      _lastNoticeId = notice.id;
      _showNotice(notice);
    }
    final key = '${vm.level.name}/${vm.municipality?.name}/${vm.selectedWardNo}';
    if (key != _lastPanelKey) {
      _lastPanelKey = key;
      if (vm.selectedWard != null) HapticFeedback.lightImpact();
      _revealSheet();
      if (_wide && _sideScroll.hasClients) _sideScroll.jumpTo(0);
    }
  }

  /// Raises a collapsed sheet so new content is visible.
  void _revealSheet() {
    if (_wide || !_sheet.isAttached) return;
    if (_sheet.size < _midExtent - 0.01) {
      _sheet.animateTo(_midExtent,
          duration: Motion.medium, curve: Motion.emphasizedDecelerate);
    }
  }

  void _showNotice(MapNotice n) {
    final l10n = context.l10n;
    final loc = vm.location;
    final (String text, SnackBarAction? action) = switch (n.issue) {
      MapIssue.offline => (l10n.offlineError, null),
      MapIssue.server => (l10n.serverError, null),
      MapIssue.outsideNepal => (l10n.outsideNepal, null),
      MapIssue.notFound => (l10n.placeNotFound, null),
      MapIssue.noWardAtSpot => (l10n.noWardAtSpot, null),
      MapIssue.boundaryUnavailable => (l10n.boundaryUnavailable(n.arg ?? ''), null),
      MapIssue.locationOff => (
          l10n.locationServiceOff,
          SnackBarAction(label: l10n.turnOn, onPressed: loc.openLocationSettings),
        ),
      MapIssue.locationDenied => (
          l10n.locationDenied,
          SnackBarAction(label: l10n.retry, onPressed: vm.locateMe),
        ),
      MapIssue.locationDeniedForever => (
          l10n.locationDeniedForever,
          SnackBarAction(label: l10n.openSettings, onPressed: loc.openAppSettings),
        ),
      MapIssue.locationFailed => (
          l10n.locationFailed,
          SnackBarAction(label: l10n.retry, onPressed: vm.locateMe),
        ),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));
  }

  // ---- Camera ----

  EdgeInsets _cameraPadding() {
    final top = MediaQuery.paddingOf(context).top + 84;
    if (_wide) {
      return EdgeInsets.fromLTRB(_sideSheetWidth + 40, top, 40, 32);
    }
    final sheetPx = math.min(_sheetExtent, 0.6) * _screen.height;
    return EdgeInsets.fromLTRB(28, top, 28, sheetPx + 24);
  }

  void _applyCamera(CameraRequest req) {
    if (!_mapReady) {
      _pendingCamera = req;
      return;
    }
    final camera = _map.camera;
    final padding = _cameraPadding();
    final MapCamera target;
    if (req.bounds != null) {
      if (req.onlyIfHidden && _isVisible(req.bounds!, padding)) return;
      target = CameraFit.bounds(bounds: req.bounds!, padding: padding, maxZoom: 16.5)
          .fit(camera);
    } else {
      target = CameraFit.coordinates(
        coordinates: [req.center!],
        padding: padding,
        maxZoom: req.zoom ?? 15,
        minZoom: req.zoom ?? 15,
      ).fit(camera);
    }
    _animateTo(target.center, target.zoom);
  }

  bool _isVisible(LatLngBounds b, EdgeInsets padding) {
    final camera = _map.camera;
    if (camera.zoom < 11) return false;
    final rect = padding.deflateRect(Offset.zero & camera.nonRotatedSize);
    final nw = camera.latLngToScreenOffset(b.northWest);
    final se = camera.latLngToScreenOffset(b.southEast);
    return rect.contains(nw) && rect.contains(se);
  }

  void _animateTo(LatLng center, double zoom) {
    _camAnim?.dispose();
    final start = _map.camera;
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _camAnim = ctrl;
    final curve = CurvedAnimation(parent: ctrl, curve: Motion.emphasized);

    // "Fly": zoom out a little mid-way when travelling far.
    final dist = (start.projectAtZoom(center) - start.projectAtZoom(start.center)).distance;
    final diag = start.nonRotatedSize.longestSide;
    final bump = dist > diag ? math.min(2.0, math.log(dist / diag) / math.ln2 + 0.5) : 0.0;

    ctrl.addListener(() {
      final t = curve.value;
      final lat = start.center.latitude + (center.latitude - start.center.latitude) * t;
      final lng = start.center.longitude + (center.longitude - start.center.longitude) * t;
      final z = start.zoom + (zoom - start.zoom) * t - bump * math.sin(math.pi * ctrl.value);
      _map.move(LatLng(lat, lng), z);
    });
    ctrl.forward();
  }

  void _stopCamera() {
    if (_camAnim?.isAnimating ?? false) _camAnim!.stop();
  }

  // ---- Map geometry memo ----

  void _updateGeometry(ColorScheme scheme, bool darkTiles) {
    final brightness = darkTiles ? Brightness.dark : Brightness.light;
    final locale = Localizations.localeOf(context);
    if (!identical(_memoAreas, vm.areas) ||
        _memoBrightness != brightness ||
        _memoLocale != locale) {
      _memoAreas = vm.areas;
      _memoBrightness = brightness;
      _memoLocale = locale;
      _areaPolygons = buildAreaPolygons(vm.areas, dark: darkTiles);
      final isWard = vm.level == AdminLevel.municipality;
      _areaLabels = buildAreaLabels(
        vm.areas,
        compact: isWard,
        textOf: (a) {
          if (isWard) return context.digits(a.label);
          if (vm.level == AdminLevel.country) {
            return context.l10n.provinceShort(a.label);
          }
          return a.label;
        },
      );
    }
    final focus = vm.focusOutline;
    if (!identical(_memoFocus, focus)) {
      _memoFocus = focus;
      _focusPolygons = buildFocusPolygons(
          focus?.geometry, darkTiles ? Colors.white : const Color(0xFF1B1B1F));
    }
    final ward = vm.selectedWard;
    if (!identical(_memoWard, ward)) {
      _memoWard = ward;
      _wardPolygons = buildSelectionPolygons(ward?.geometry, scheme);
    }
  }

  // ---- Navigation ----

  Future<void> _openSearch() async {
    final selection = await Navigator.of(context).push<SearchSelection>(
      PageRouteBuilder(
        transitionDuration: Motion.medium,
        reverseTransitionDuration: Motion.short,
        pageBuilder: (_, _, _) => SearchScreen(
          repository: widget.deps.boundaries,
          settings: widget.deps.settings,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Motion.emphasized),
          child: child,
        ),
      ),
    );
    if (selection == null || !mounted) return;
    switch (selection) {
      case SelectProvince(:final province):
        vm.selectProvince(province);
      case SelectDistrict(:final district):
        vm.selectDistrict(district);
      case SelectMunicipality(:final municipality, :final wardNo):
        vm.openMunicipality(municipality, wardNo: wardNo);
      case SelectRecent(:final place):
        vm.openRecent(place);
    }
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(deps: widget.deps),
    ));
  }

  void _pickMapStyle() {
    final settings = widget.deps.settings;
    final l10n = context.l10n;
    final styles = <(MapStyle, String, IconData)>[
      (MapStyle.auto, l10n.styleAuto, Icons.brightness_auto_outlined),
      (MapStyle.streets, l10n.styleStreets, Icons.map_outlined),
      (MapStyle.light, l10n.styleLight, Icons.light_mode_outlined),
      (MapStyle.dark, l10n.styleDark, Icons.dark_mode_outlined),
      (MapStyle.terrain, l10n.styleTerrain, Icons.terrain_outlined),
      (MapStyle.satellite, l10n.styleSatellite, Icons.satellite_alt_outlined),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
          child: ListenableBuilder(
            listenable: settings,
            builder: (ctx, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: Space.sm, bottom: Space.md),
                  child: Text(l10n.mapStyle,
                      style: Theme.of(ctx).textTheme.titleLarge),
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: Space.sm,
                  crossAxisSpacing: Space.sm,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final (style, label, icon) in styles)
                      _StyleOption(
                        icon: icon,
                        label: label,
                        selected: settings.mapStyle == style,
                        onTap: () {
                          settings.mapStyle = style;
                          Navigator.of(ctx).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mq = MediaQuery.of(context);
    _screen = mq.size;
    _wide = mq.size.width >= _wideBreakpoint;

    return ListenableBuilder(
      listenable: Listenable.merge([vm, widget.deps.settings]),
      builder: (context, _) {
        final source = tileSourceFor(widget.deps.settings.mapStyle, theme.brightness);
        _updateGeometry(scheme, source.isDark);
        final minExtent = ((96 + mq.padding.bottom) / mq.size.height).clamp(0.08, 0.3);
        final overlayVisible = _wide || _sheetExtent < 0.65;
        final sheetPx = _wide ? 0.0 : _sheetExtent * mq.size.height;

        return PopScope(
          canPop: vm.level == AdminLevel.country,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) vm.goBack();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: (source.isDark || theme.brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                .copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  Positioned.fill(child: _buildMap(source, scheme)),
                  // Top scrim so the status bar stays legible over the map.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: mq.padding.top + 24,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.surface.withValues(alpha: 0.7),
                              scheme.surface.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: mq.padding.top + Space.sm,
                    left: Space.lg,
                    right: Space.lg,
                    child: Align(
                      alignment: _wide ? Alignment.topLeft : Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: _wide ? _sideSheetWidth : 720),
                        child: _SearchPill(onTap: _openSearch, onSettings: _openSettings),
                      ),
                    ),
                  ),
                  // Map controls float above the sheet.
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 60),
                    right: Space.lg,
                    bottom: sheetPx + Space.lg,
                    child: AnimatedOpacity(
                      opacity: overlayVisible ? 1 : 0,
                      duration: Motion.short,
                      child: IgnorePointer(
                        ignoring: !overlayVisible,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'layers',
                              tooltip: context.l10n.mapStyle,
                              backgroundColor: scheme.surfaceContainerHigh,
                              foregroundColor: scheme.onSurface,
                              onPressed: _pickMapStyle,
                              child: const Icon(Icons.layers_outlined),
                            ),
                            const SizedBox(height: Space.md),
                            FloatingActionButton(
                              heroTag: 'locate',
                              tooltip: context.l10n.myLocation,
                              onPressed: vm.busy == BusyKind.locating ? null : vm.locateMe,
                              child: vm.busy == BusyKind.locating
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5))
                                  : const Icon(Icons.my_location_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 60),
                    left: _wide ? _sideSheetWidth + Space.xxl : Space.md,
                    bottom: sheetPx + Space.sm,
                    child: AnimatedOpacity(
                      opacity: overlayVisible ? 1 : 0,
                      duration: Motion.short,
                      child: _Attribution(source: source),
                    ),
                  ),
                  if (_wide) _buildSideSheet(scheme, mq) else _buildBottomSheet(minExtent),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheet(double minExtent) {
    return DraggableScrollableSheet(
      controller: _sheet,
      initialChildSize: _midExtent,
      minChildSize: minExtent,
      maxChildSize: _maxExtent,
      snap: true,
      snapSizes: const [_midExtent],
      builder: (context, scrollController) {
        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: scheme.surfaceContainerLow,
          elevation: 8,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: MapPanel(vm: vm, scrollController: scrollController, showHandle: true),
        );
      },
    );
  }

  Widget _buildSideSheet(ColorScheme scheme, MediaQueryData mq) {
    return Positioned(
      left: Space.lg,
      top: mq.padding.top + 80,
      bottom: Space.lg + mq.padding.bottom,
      width: _sideSheetWidth,
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 6,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: MapPanel(vm: vm, scrollController: _sideScroll, showHandle: false),
      ),
    );
  }

  Widget _buildMap(TileSource source, ColorScheme scheme) {
    final darkTiles = source.isDark;
    final labelSelectedId = vm.selectedWard == null || vm.municipality == null
        ? null
        : 'w:${vm.municipality!.district.name}/${vm.municipality!.name}/${vm.selectedWardNo}';
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: nepalCenter,
        initialZoom: 6.6,
        minZoom: 5,
        maxZoom: 18.5,
        backgroundColor: darkTiles ? const Color(0xFF1E1F22) : const Color(0xFFE8EAED),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(const LatLng(22, 74), const LatLng(34, 94)),
        ),
        onPointerDown: (_, _) => _stopCamera(),
        onTap: (_, point) {
          HapticFeedback.selectionClick();
          vm.identifyAt(point);
        },
        onLongPress: (_, point) {
          HapticFeedback.mediumImpact();
          vm.identifyAt(point);
        },
        onMapReady: () {
          _mapReady = true;
          final pending = _pendingCamera;
          _pendingCamera = null;
          // Frame Nepal for this screen size on first load.
          _applyCamera(pending ?? CameraRequest.bounds(nepalBounds));
        },
      ),
      children: [
        TileLayer(
          key: ValueKey(source.urlTemplate),
          urlTemplate: source.urlTemplate,
          subdomains: source.subdomains,
          maxNativeZoom: source.maxNativeZoom,
          retinaMode: source.retina && MediaQuery.devicePixelRatioOf(context) > 1.5,
          userAgentPackageName: 'com.tapaiko.tapaiko_ward',
        ),
        if (_focusPolygons.isNotEmpty)
          PolygonLayer(
            polygons: _focusPolygons,
            invertedFill: Colors.black.withValues(alpha: darkTiles ? 0.35 : 0.14),
            polygonLabels: false,
          ),
        PolygonLayer(polygons: _areaPolygons, polygonLabels: false),
        if (_wardPolygons.isNotEmpty)
          PolygonLayer(polygons: _wardPolygons, polygonLabels: false),
        if (vm.userLocation != null)
          CircleLayer(circles: [
            CircleMarker(
              point: vm.userLocation!.point,
              radius: vm.userLocation!.accuracyMeters.clamp(10, 500),
              useRadiusInMeter: true,
              color: UserLocationDot.blue.withValues(alpha: 0.14),
              borderColor: UserLocationDot.blue.withValues(alpha: 0.4),
              borderStrokeWidth: 1,
            ),
          ]),
        AreaLabelLayer(labels: _areaLabels, selectedId: labelSelectedId),
        MarkerLayer(markers: [
          if (vm.userLocation != null)
            Marker(
              point: vm.userLocation!.point,
              width: 22,
              height: 22,
              child: const UserLocationDot(),
            ),
          if (vm.pin != null)
            Marker(
              key: ValueKey(vm.pin),
              point: vm.pin!,
              width: 46,
              height: 46,
              alignment: Alignment.topCenter,
              child: const IgnorePointer(child: DroppedPin()),
            ),
        ]),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap, required this.onSettings});

  final VoidCallback onTap;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Hero(
      tag: 'search-bar',
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 3,
        shadowColor: Colors.black54,
        surfaceTintColor: Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: Space.lg),
                Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(
                    context.l10n.searchPlaceholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.settings,
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
                const SizedBox(width: Space.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.source});

  final TileSource source;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => openLink(source.attributionUrl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.6, minHeight: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '© ${source.attribution}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 28,
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
              const SizedBox(height: Space.sm),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? scheme.onPrimaryContainer : scheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
