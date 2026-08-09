import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// GeoJSON geometry is always [lng, lat] order.
List<double> toLngLat(List<dynamic> coord) =>
    [coord[0].toDouble(), coord[1].toDouble()];

LatLng toLatLng(List<dynamic> coord) =>
    LatLng(coord[1].toDouble(), coord[0].toDouble());

/// Ray-casting point-in-polygon on a single ring (list of [lng, lat]).
/// Handles holes: pass the outer ring as `rings.first` and holes after it.
bool pointInRing(LatLng point, List<dynamic> ring) {
  bool inside = false;
  int j = ring.length - 1;
  for (int i = 0; i < ring.length; j = i++) {
    final a = toLngLat(ring[i]);
    final b = toLngLat(ring[j]);
    final intersect = ((a[1] > point.latitude) != (b[1] > point.latitude)) &&
        (point.longitude <
            (b[0] - a[0]) * (point.latitude - a[1]) / (b[1] - a[1]) + a[0]);
    if (intersect) inside = !inside;
  }
  return inside;
}

/// Point-in-polygon against a GeoJSON geometry (Polygon or MultiPolygon).
bool pointInGeometry(LatLng point, Map<String, dynamic> geometry) {
  final coords = geometry['coordinates'] as List<dynamic>;
  return switch (geometry['type']) {
    'Polygon' => _pointInPolygonRings(coords, point),
    'MultiPolygon' => coords.any((polygon) =>
        _pointInPolygonRings(polygon as List<dynamic>, point)),
    _ => false,
  };
}

bool _pointInPolygonRings(List<dynamic> rings, LatLng point) {
  if (rings.isEmpty) return false;
  if (!pointInRing(point, rings.first as List<dynamic>)) return false;
  for (var i = 1; i < rings.length; i++) {
    if (pointInRing(point, rings[i] as List<dynamic>)) return false;
  }
  return true;
}

/// Approximate centroid (centre of bounding box) of a GeoJSON geometry,
/// used for placing name labels.
LatLng? geometryCenter(Map<String, dynamic> geometry) {
  final b = geometryBounds(geometry);
  if (b == null) return null;
  return LatLng((b.north + b.south) / 2, (b.east + b.west) / 2);
}

/// Bounding box of a GeoJSON geometry (Polygon or MultiPolygon).
LatLngBounds? geometryBounds(Map<String, dynamic> geometry) {  double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
  var found = false;
  void walk(List<dynamic> coords) {
    for (final c in coords) {
      if (c is List<dynamic> && c.isNotEmpty && c.first is num) {
        final p = toLngLat(c);
        if (p[1] < minLat) minLat = p[1];
        if (p[1] > maxLat) maxLat = p[1];
        if (p[0] < minLng) minLng = p[0];
        if (p[0] > maxLng) maxLng = p[0];
        found = true;
      } else if (c is List<dynamic>) {
        walk(c);
      }
    }
  }

  walk((geometry['coordinates'] as List<dynamic>?) ?? const []);
  if (!found) return null;
  return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}

/// Flattens a GeoJSON geometry into outer rings only (for rendering with
/// flutter_map Polygon, which takes a single outline without holes).
List<List<LatLng>> outerRings(Map<String, dynamic> geometry) {
  final coords = geometry['coordinates'] as List<dynamic>;
  final type = geometry['type'];
  final rings = <List<LatLng>>[];
  if (type == 'Polygon') {
    if (coords.isNotEmpty) {
      rings.add(_ringToLatLngs(coords.first as List<dynamic>));
    }
  } else if (type == 'MultiPolygon') {
    for (final polygon in coords) {
      final poly = polygon as List<dynamic>;
      if (poly.isNotEmpty) {
        rings.add(_ringToLatLngs(poly.first as List<dynamic>));
      }
    }
  }
  return rings;
}

List<LatLng> _ringToLatLngs(List<dynamic> ring) =>
    ring.map((c) => toLatLng(c as List<dynamic>)).toList();
