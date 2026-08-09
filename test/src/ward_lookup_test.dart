import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapaiko_ward/src/data_service.dart';
import 'package:tapaiko_ward/src/ward_lookup.dart';

import '../helpers/fake_data_cache.dart';

const _box = [
  [80.0, 26.0],
  [80.0, 30.0],
  [88.0, 30.0],
  [88.0, 26.0],
  [80.0, 26.0],
];

Map<String, dynamic> feature(String name, Map<String, dynamic> props) => {
      'type': 'Feature',
      'properties': props,
      'geometry': {'type': 'Polygon', 'coordinates': [_box]},
    };

String collection(List<Map<String, dynamic>> features) =>
    jsonEncode({'type': 'FeatureCollection', 'features': features});

void main() {
  group('WardLookup', () {
    late FakeDataCache cache;
    late WardLookup lookup;

    setUp(() {
      cache = FakeDataCache()
        ..store['province.json'] = collection([
          feature('Koshi', {'Province': 'Koshi Pradesh', 'name': 'Koshi'}),
        ])
        ..store['districts/Koshi.json'] = collection([
          feature('Bhojpur', {'District': 'Bhojpur', 'name': 'Bhojpur'}),
        ])
        ..store['locallevels/Bhojpur.json'] = collection([
          feature('Hatuwagadhi', {
            'District': 'Bhojpur',
            'Province': 'Koshi Pradesh',
            'name': 'Hatuwagadhi',
          }),
        ])
        ..store['wards/Bhojpur_Hatuwagadhi.json'] = collection([
          feature('5', {
            'District': 'Bhojpur',
            'GaPa_NaPa': 'Hatuwagadhi',
            'Type_GN': 'Gaunpalika',
            'Ward_Num': 5,
            'name': '5',
          }),
        ]);
      lookup = WardLookup(DataService(cache: cache));
    });

    test('identify drills down province → district → local level → ward',
        () async {
      final result = await lookup.identify(const LatLng(28.0, 84.0));

      check(result).isNotNull();
      check(result!.wardNo).equals('5');
      check(result.municipality).equals('Hatuwagadhi');
      check(result.type).equals('Gaunpalika');
      check(result.district).equals('Bhojpur');
      check(result.province).equals('Koshi Pradesh');
      check(result.wardGeometry).containsKey('type');
    });

    test('identify returns null when the point is outside the province',
        () async {
      final result = await lookup.identify(const LatLng(50.0, 50.0));
      check(result).isNull();
    });

    test('loadDistricts returns the district features', () async {
      final districts = await lookup.loadDistricts('Koshi');
      check(districts).length.equals(1);
      check(districts.first['name']).equals('Bhojpur');
    });

    test('loadLocalLevels returns the local level features', () async {
      final levels = await lookup.loadLocalLevels('Bhojpur');
      check(levels).length.equals(1);
      check(levels.first['name']).equals('Hatuwagadhi');
    });

    test('loadWards reads the ward file', () async {
      final wards = await lookup.loadWards('Bhojpur', 'Hatuwagadhi');
      check(wards).length.equals(1);
      check(wards.first['Ward_Num']).equals(5);
    });

    test('loadWards resolves the Rukum alias', () async {
      cache.store['wards/Rukum_Fake.json'] = collection([
        feature('1', {'District': 'Rukum East', 'name': '1'}),
      ]);

      final wards = await lookup.loadWards('Rukum East', 'Fake');
      check(wards).length.equals(1);

      final wardsWest = await lookup.loadWards('Rukum West', 'Fake');
      check(wardsWest).length.equals(1);
    });
  });
}
