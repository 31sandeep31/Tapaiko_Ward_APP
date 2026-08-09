import 'package:checks/checks.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapaiko_ward/src/geometry.dart';

const squareRing = [
  [80.0, 26.0],
  [80.0, 30.0],
  [88.0, 30.0],
  [88.0, 26.0],
  [80.0, 26.0],
];

Map<String, dynamic> polygon(List<List<dynamic>> rings) => {
      'type': 'Polygon',
      'coordinates': rings,
    };

void main() {
  group('pointInRing', () {
    test('is true for a point inside the ring', () {
      check(pointInRing(const LatLng(28.0, 84.0), squareRing)).isTrue();
    });

    test('is false for a point outside the ring', () {
      check(pointInRing(const LatLng(20.0, 84.0), squareRing)).isFalse();
    });
  });

  group('pointInGeometry', () {
    test('Polygon contains an interior point', () {
      final g = polygon([squareRing]);
      check(pointInGeometry(const LatLng(28.0, 84.0), g)).isTrue();
    });

    test('Polygon hole excludes an interior point', () {
      final g = polygon([
        squareRing,
        [
          [83.5, 27.5],
          [83.5, 28.5],
          [84.5, 28.5],
          [84.5, 27.5],
          [83.5, 27.5],
        ],
      ]);
      check(pointInGeometry(const LatLng(28.0, 84.0), g)).isFalse();
      check(pointInGeometry(const LatLng(28.0, 81.0), g)).isTrue();
    });

    test('MultiPolygon matches when any polygon contains the point', () {
      final g = {
        'type': 'MultiPolygon',
        'coordinates': [
          [
            [
              [70.0, 10.0],
              [70.0, 12.0],
              [72.0, 12.0],
              [72.0, 10.0],
              [70.0, 10.0],
            ],
          ],
          [squareRing],
        ],
      };
      check(pointInGeometry(const LatLng(28.0, 84.0), g)).isTrue();
      check(pointInGeometry(const LatLng(11.0, 71.0), g)).isTrue();
      check(pointInGeometry(const LatLng(50.0, 50.0), g)).isFalse();
    });

    test('unknown geometry type is never matched', () {
      final g = {'type': 'Point', 'coordinates': [84.0, 28.0]};
      check(pointInGeometry(const LatLng(28.0, 84.0), g)).isFalse();
    });
  });

  group('geometryBounds', () {
    test('computes the bounding box of a Polygon', () {
      final b = geometryBounds(polygon([squareRing]));
      check(b).isNotNull();
      check(b!.south).equals(26.0);
      check(b.north).equals(30.0);
      check(b.west).equals(80.0);
      check(b.east).equals(88.0);
    });

    test('returns null for empty geometry', () {
      final b = geometryBounds(const {'type': 'Polygon', 'coordinates': []});
      check(b).isNull();
    });
  });

  group('geometryCenter', () {
    test('returns the midpoint of the bounding box', () {
      final c = geometryCenter(polygon([squareRing]));
      check(c).isNotNull();
      check(c!.latitude).equals(28.0);
      check(c.longitude).equals(84.0);
    });

    test('returns null when geometry is empty', () {
      final c = geometryCenter(const {'type': 'Polygon', 'coordinates': []});
      check(c).isNull();
    });
  });

  group('outerRings', () {
    test('returns the outer ring of a Polygon', () {
      final rings = outerRings(polygon([squareRing]));
      check(rings).length.equals(1);
      check(rings.first).length.equals(squareRing.length);
      check(rings.first.first.latitude).equals(26.0);
      check(rings.first.first.longitude).equals(80.0);
    });

    test('returns one ring per polygon in a MultiPolygon', () {
      final g = {
        'type': 'MultiPolygon',
        'coordinates': [
          [squareRing],
          [squareRing],
        ],
      };
      check(outerRings(g)).length.equals(2);
    });

    test('returns empty for a Polygon with no rings', () {
      check(outerRings(const {'type': 'Polygon', 'coordinates': []})).isEmpty();
    });
  });
}
