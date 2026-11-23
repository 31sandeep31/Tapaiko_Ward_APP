import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../domain/geometry.dart';
import '../../../core/map_styles.dart';
import '../view_models/map_view_model.dart';

/// Pre-computed label for an area on the map.
class AreaLabel {
  AreaLabel({
    required this.id,
    required this.text,
    required this.point,
    required this.bounds,
    required this.color,
    required this.compact,
  });

  final String id;
  final String text;
  final LatLng point;
  final LatLngBounds bounds;
  final Color color;

  /// Ward numbers use a compact badge.
  final bool compact;
  Size? _size;
}

Color colorForArea(MapArea area) {
  final key = area.colorKey;
  if (key.startsWith('#')) {
    final n = int.tryParse(key.substring(1)) ?? 1;
    return provinceColors[(n - 1).clamp(0, provinceColors.length - 1)];
  }
  return areaColor(key);
}

List<Polygon> buildAreaPolygons(List<MapArea> areas, {required bool dark}) {
  final polygons = <Polygon>[];
  for (final area in areas) {
    final g = area.feature.geometry;
    if (g == null) continue;
    final color = colorForArea(area);
    for (final p in polygonsOf(g)) {
      polygons.add(Polygon(
        points: p.outer,
        holePointsList: p.holes.isEmpty ? null : p.holes,
        color: color.withValues(alpha: dark ? 0.24 : 0.16),
        borderColor: color.withValues(alpha: dark ? 0.95 : 0.85),
        borderStrokeWidth: 1.4,
      ));
    }
  }
  return polygons;
}

List<AreaLabel> buildAreaLabels(
  List<MapArea> areas, {
  required String Function(MapArea) textOf,
  required bool compact,
}) {
  final labels = <AreaLabel>[];
  for (final area in areas) {
    final g = area.feature.geometry;
    final text = textOf(area);
    if (g == null || text.isEmpty) continue;
    final point = labelPoint(g);
    final bounds = geometryBounds(g);
    if (point == null || bounds == null) continue;
    labels.add(AreaLabel(
      id: area.id,
      text: text,
      point: point,
      bounds: bounds,
      color: colorForArea(area),
      compact: compact,
    ));
  }
  // Larger areas win label collisions.
  labels.sort((a, b) => boundsArea(b.bounds).compareTo(boundsArea(a.bounds)));
  return labels;
}

/// Polygons outlining the focused area; the layer dims everything outside.
List<Polygon> buildFocusPolygons(
    Map<String, dynamic>? geometry, Color border) {
  if (geometry == null) return const [];
  return [
    for (final p in polygonsOf(geometry))
      Polygon(
        points: p.outer,
        holePointsList: p.holes.isEmpty ? null : p.holes,
        borderColor: border,
        borderStrokeWidth: 2.2,
      ),
  ];
}

/// Selected ward: white halo under a strong primary outline, readable on
/// any base map.
List<Polygon> buildSelectionPolygons(
    Map<String, dynamic>? geometry, ColorScheme scheme) {
  if (geometry == null) return const [];
  final rings = polygonsOf(geometry);
  return [
    for (final p in rings)
      Polygon(
        points: p.outer,
        holePointsList: p.holes.isEmpty ? null : p.holes,
        borderColor: Colors.white.withValues(alpha: 0.9),
        borderStrokeWidth: 6,
      ),
    for (final p in rings)
      Polygon(
        points: p.outer,
        holePointsList: p.holes.isEmpty ? null : p.holes,
        color: scheme.primary.withValues(alpha: 0.22),
        borderColor: scheme.primary,
        borderStrokeWidth: 3,
      ),
  ];
}

/// Draws area names, hiding labels that collide or don't fit their area at
/// the current zoom. Rebuilds on every camera change.
class AreaLabelLayer extends StatelessWidget {
  const AreaLabelLayer({super.key, required this.labels, this.selectedId});

  final List<AreaLabel> labels;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final viewport = Offset.zero & camera.nonRotatedSize;
    final placed = <Rect>[];
    final markers = <Marker>[];

    // Draw the selected label first so it always wins.
    final ordered = [
      ...labels.where((l) => l.id == selectedId),
      ...labels.where((l) => l.id != selectedId),
    ];

    for (final label in ordered) {
      final center = camera.latLngToScreenOffset(label.point);
      if (!viewport.inflate(60).contains(center)) continue;
      final size = label._size ??= _measure(label, scaler);
      final selected = label.id == selectedId;

      final nw = camera.latLngToScreenOffset(label.bounds.northWest);
      final se = camera.latLngToScreenOffset(label.bounds.southEast);
      final areaWidth = (se.dx - nw.dx).abs();
      final areaHeight = (se.dy - nw.dy).abs();
      // Hide labels that clearly don't fit their area at this zoom.
      final tooSmall = label.compact
          ? areaWidth < size.width * 0.9 || areaHeight < size.height * 1.2
          : areaWidth < size.width * 0.45;
      if (!selected && tooSmall) continue;

      final rect = Rect.fromCenter(
              center: center, width: size.width, height: size.height)
          .inflate(4);
      if (placed.any(rect.overlaps)) continue;
      placed.add(rect);

      markers.add(Marker(
        point: label.point,
        width: size.width,
        height: size.height,
        child: IgnorePointer(
          child: _AreaLabelChip(label: label, selected: selected),
        ),
      ));
    }
    return MarkerLayer(markers: markers);
  }

  static Size _measure(AreaLabel label, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: label.text, style: _AreaLabelChip.textStyle(label)),
      maxLines: 2,
      textScaler: scaler.clamp(maxScaleFactor: 1.3),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 140);
    final w = painter.width + (label.compact ? 12 : 16);
    final h = painter.height + (label.compact ? 6 : 8);
    return Size(label.compact ? w.clamp(24, 200) : w, h);
  }
}

class _AreaLabelChip extends StatelessWidget {
  const _AreaLabelChip({required this.label, required this.selected});

  final AreaLabel label;
  final bool selected;

  static TextStyle textStyle(AreaLabel label) => TextStyle(
        fontSize: label.compact ? 12 : 12.5,
        fontWeight: label.compact ? FontWeight.w700 : FontWeight.w600,
        height: 1.15,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : scheme.surface.withValues(alpha: 0.92);
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(label.compact ? 12 : 8),
        border: Border.all(
          color: selected ? scheme.onPrimary : label.color.withValues(alpha: 0.9),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Center(
        child: Text(
          label.text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.3),
          style: textStyle(label).copyWith(color: fg),
        ),
      ),
    );
  }
}

/// Dropped pin with a small bounce when it appears.
class DroppedPin extends StatelessWidget {
  const DroppedPin({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, -18 * (1 - t)),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Icon(
        Icons.location_on,
        size: 46,
        color: scheme.tertiary,
        shadows: const [Shadow(color: Colors.black45, blurRadius: 6)],
      ),
    );
  }
}

/// The user's GPS position: blue dot with a white ring.
class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});

  static const blue = Color(0xFF1A73E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
    );
  }
}
