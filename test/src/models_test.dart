import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapaiko_ward/data/models.dart';

void main() {
  group('Municipality', () {
    test('fromJson maps locallevelcodes.json keys', () {
      final m = Municipality.fromJson({
        'STATE_CODE': 1,
        'DISTRICT': 'BHOJPUR',
        'GaPa_NaPa': 'Hatuwagadhi',
        'Type_GN': 'Gaunpalika',
        'Province': 'Koshi Pradesh',
        'DISTRICT_CODE': 7,
        'MUNICIPALITY_CODE': 5,
      });
      check(m.stateCode).equals(1);
      check(m.district).equals('BHOJPUR');
      check(m.gaPaNaPa).equals('Hatuwagadhi');
      check(m.typeGn).equals('Gaunpalika');
      check(m.province).equals('Koshi Pradesh');
      check(m.districtCode).equals(7);
      check(m.municipalityCode).equals(5);
    });

    test('fromJson fills defaults for missing keys', () {
      final m = Municipality.fromJson(const {});
      check(m.stateCode).equals(0);
      check(m.district).equals('');
      check(m.gaPaNaPa).equals('');
      check(m.typeGn).equals('');
      check(m.province).equals('');
      check(m.districtCode).equals(0);
      check(m.municipalityCode).equals(0);
    });

    test('toJson round-trips all fields', () {
      final m = Municipality(
        stateCode: 1,
        district: 'BHOJPUR',
        gaPaNaPa: 'Hatuwagadhi',
        typeGn: 'Gaunpalika',
        province: 'Koshi Pradesh',
        districtCode: 7,
        municipalityCode: 5,
      );
      final again = Municipality.fromJson(m.toJson());
      check(again.stateCode).equals(m.stateCode);
      check(again.district).equals(m.district);
      check(again.gaPaNaPa).equals(m.gaPaNaPa);
      check(again.typeGn).equals(m.typeGn);
      check(again.province).equals(m.province);
      check(again.districtCode).equals(m.districtCode);
      check(again.municipalityCode).equals(m.municipalityCode);
    });
  });

  group('GeoFeature', () {
    test('fromJson keeps geometry and properties', () {
      final f = GeoFeature.fromJson({
        'type': 'Feature',
        'properties': {'name': 'Koshi'},
        'geometry': {'type': 'Polygon', 'coordinates': []},
      });
      check(f['name']).equals('Koshi');
      check(f.geometry).isNotNull();
      check(f.toJson()).containsKey('geometry');
    });

    test('fromJson defaults missing geometry/properties', () {
      final f = GeoFeature.fromJson(const {'type': 'Feature'});
      check(f.properties).isEmpty();
      check(f.geometry).isNull();
    });
  });

  group('GeoCollection', () {
    test('fromJson parses nested features', () {
      final c = GeoCollection.fromJson({
        'type': 'FeatureCollection',
        'features': [
          {
            'properties': {'name': 'A'},
            'geometry': {'type': 'Polygon', 'coordinates': []},
          },
          {
            'properties': {'name': 'B'},
            'geometry': null,
          },
        ],
      });
      check(c.features).length.equals(2);
      check(c.features[0]['name']).equals('A');
    });

    test('toJson round-trips', () {
      final c = GeoCollection.fromJson({
        'features': [
          {
            'properties': {'name': 'A'},
            'geometry': {'type': 'Polygon', 'coordinates': []},
          },
        ],
      });
      final again = GeoCollection.fromJson(c.toJson());
      check(again.features).length.equals(1);
      check(again.features[0]['name']).equals('A');
    });
  });
}
