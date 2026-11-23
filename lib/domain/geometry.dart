import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// GeoJSON geometry is always [lng, lat] order.
List<double> toLngLat(List<dynamic> coord) =>
    [(coord[0] as num).toDouble(), (coord[1] as num).toDouble()];

LatLng toLatLng(List<dynamic> coord) =>
    LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble());

/// Ray-casting point-in-polygon on a single ring (list of [lng, lat]).
/// Handles holes: pass the outer ring as `rings.first` and holes after it.
bool pointInRing(LatLng point, List<dynamic> ring) {
  bool inside = false;
  int j = ring.length - 1;
  for (int i = 0; i < ring.length; j = i++) {
    final a = toLngLat(ring[i] as List<dynamic>);
    final b = toLngLat(ring[j] as List<dynamic>);
    final intersect = ((a[1] > point.latitude) != (b[1] > point.latitude)) &&
        (point.longitude <
            (b[0] - a[0]) * (point.latitude - a[1]) / (b[1] - a[1]) + a[0]);
    if (intersect) inside = !inside;
  }
  return inside;
}

/// Point-in-polygon against a GeoJSON geometry (Polygon or MultiPolygon).
bool pointInGeometry(LatLng point, Map<String, dynamic> geometry) {
  final coords = geometry['coordinates'] as List<dynamic>?;
  if (coords == null) return false;
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

/// Approximate centroid (centre of bounding box) of a GeoJSON geometry.
LatLng? geometryCenter(Map<String, dynamic> geometry) {
  final b = geometryBounds(geometry);
  if (b == null) return null;
  return LatLng((b.north + b.south) / 2, (b.east + b.west) / 2);
}

/// Bounding box of a GeoJSON geometry (Polygon or MultiPolygon).
LatLngBounds? geometryBounds(Map<String, dynamic> geometry) {
  double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
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

/// One renderable polygon: outer ring plus its holes.
class PolygonRings {
  PolygonRings(this.outer, this.holes);

  final List<LatLng> outer;
  final List<List<LatLng>> holes;
}

/// Splits a GeoJSON geometry into polygons (outer ring + holes) ready to
/// render with flutter_map.
List<PolygonRings> polygonsOf(Map<String, dynamic> geometry) {
  final coords = geometry['coordinates'] as List<dynamic>?;
  if (coords == null) return const [];
  PolygonRings? convert(List<dynamic> rings) {
    if (rings.isEmpty) return null;
    return PolygonRings(
      _ringToLatLngs(rings.first as List<dynamic>),
      [
        for (var i = 1; i < rings.length; i++)
          _ringToLatLngs(rings[i] as List<dynamic>),
      ],
    );
  }

  return switch (geometry['type']) {
    'Polygon' => [?convert(coords)],
    'MultiPolygon' => [
        for (final p in coords) ?convert(p as List<dynamic>),
      ],
    _ => const [],
  };
}

/// Flattens a GeoJSON geometry into outer rings only.
List<List<LatLng>> outerRings(Map<String, dynamic> geometry) =>
    polygonsOf(geometry).map((p) => p.outer).toList();

List<LatLng> _ringToLatLngs(List<dynamic> ring) =>
    ring.map((c) => toLatLng(c as List<dynamic>)).toList();

/// A point guaranteed to lie inside the geometry's largest polygon, used to
/// place name labels (a bounding-box centre can fall outside concave shapes).
///
/// Scans a horizontal line through the ring's centroid and returns the
/// midpoint of the widest interior segment.
LatLng? labelPoint(Map<String, dynamic> geometry) {
  final polygons = polygonsOf(geometry);
  if (polygons.isEmpty) return null;
  var best = polygons.first.outer;
  var bestArea = _ringArea(best).abs();
  for (final p in polygons.skip(1)) {
    final a = _ringArea(p.outer).abs();
    if (a > bestArea) {
      best = p.outer;
      bestArea = a;
    }
  }
  if (best.length < 3) return best.isEmpty ? null : best.first;

  double minLat = 90, maxLat = -90;
  for (final p in best) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
  }

  LatLng? bestPoint;
  var bestWidth = -1.0;
  // Try a few scanlines around the middle and keep the widest segment.
  for (final t in const [0.5, 0.4, 0.6, 0.3, 0.7]) {
    final lat = minLat + (maxLat - minLat) * t;
    final xs = <double>[];
    for (var i = 0, j = best.length - 1; i < best.length; j = i++) {
      final a = best[i], b = best[j];
      if ((a.latitude > lat) != (b.latitude > lat)) {
        xs.add(a.longitude +
            (lat - a.latitude) *
                (b.longitude - a.longitude) /
                (b.latitude - a.latitude));
      }
    }
    xs.sort();
    for (var k = 0; k + 1 < xs.length; k += 2) {
      final w = xs[k + 1] - xs[k];
      if (w > bestWidth) {
        bestWidth = w;
        bestPoint = LatLng(lat, (xs[k] + xs[k + 1]) / 2);
      }
    }
    // A segment at the middle that's at least 40% as wide as the ring is
    // good enough; skip the rest.
    if (t == 0.5 && bestPoint != null) {
      double minLng = 180, maxLng = -180;
      for (final p in best) {
        minLng = math.min(minLng, p.longitude);
        maxLng = math.max(maxLng, p.longitude);
      }
      if (bestWidth >= (maxLng - minLng) * 0.4) break;
    }
  }
  return bestPoint ?? geometryCenter(geometry);
}

double _ringArea(List<LatLng> ring) {
  var sum = 0.0;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    sum += (ring[j].longitude * ring[i].latitude) -
        (ring[i].longitude * ring[j].latitude);
  }
  return sum / 2;
}

/// Bounding-box area in square degrees; used to rank features.
double boundsArea(LatLngBounds? b) =>
    b == null ? 0 : (b.east - b.west) * (b.north - b.south);

/// Squared distance (in degrees) from [p] to the centre of [b].
double distanceToBoundsCenter(LatLng p, LatLngBounds b) {
  final dLat = p.latitude - (b.north + b.south) / 2;
  final dLng = p.longitude - (b.east + b.west) / 2;
  return dLat * dLat + dLng * dLng;
}

/// Whether [b] contains [p] after growing it by [margin] degrees.
bool boundsContains(LatLngBounds b, LatLng p, {double margin = 0}) =>
    p.latitude >= b.south - margin &&
    p.latitude <= b.north + margin &&
    p.longitude >= b.west - margin &&
    p.longitude <= b.east + margin;
