import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:tapaiko_ward/data/boundary_repository.dart';
import 'package:tapaiko_ward/data/data_service.dart';

import 'fake_data_cache.dart';

/// Rectangle polygon geometry from lng/lat extents.
Map<String, dynamic> box(double west, double south, double east, double north) => {
      'type': 'Polygon',
      'coordinates': [
        [
          [west, south],
          [west, north],
          [east, north],
          [east, south],
          [west, south],
        ],
      ],
    };

Map<String, dynamic> feature(Map<String, dynamic> props, Map<String, dynamic> geometry) =>
    {'type': 'Feature', 'properties': props, 'geometry': geometry};

String collection(List<Map<String, dynamic>> features) =>
    jsonEncode({'type': 'FeatureCollection', 'features': features});

const testCodes = [
  {
    'STATE_CODE': 1,
    'DISTRICT': 'BHOJPUR',
    'GaPa_NaPa': 'Hatuwagadhi',
    'Type_GN': 'Gaunpalika',
    'Province': 'Koshi Pradesh',
    'DISTRICT_CODE': 10,
    'MUNICIPALITY_CODE': 5,
  },
  {
    'STATE_CODE': 1,
    'DISTRICT': 'BHOJPUR',
    'GaPa_NaPa': 'Bhojpur',
    'Type_GN': 'Nagarpalika',
    'Province': 'Koshi Pradesh',
    'DISTRICT_CODE': 10,
    'MUNICIPALITY_CODE': 1,
  },
  {
    'STATE_CODE': 3,
    'DISTRICT': 'KATHMANDU',
    'GaPa_NaPa': 'Kathmandu',
    'Type_GN': 'Mahanagarpalika',
    'Province': 'Bagmati Pradesh',
    'DISTRICT_CODE': 27,
    'MUNICIPALITY_CODE': 1,
  },
];

/// Bundled assets: Koshi province and Bhojpur district both cover
/// lng 86–88, lat 26–28.
Map<String, String> testAssets() => {
      BoundaryRepository.provincesAsset: collection([
        feature({'Province': 'Koshi Pradesh', 'name': 'Koshi'}, box(86, 26, 88, 28)),
      ]),
      BoundaryRepository.districtsAsset: collection([
        feature({
          'Province': 'Koshi Pradesh',
          'ProvinceShort': 'Koshi',
          'District': 'Bhojpur',
          'name': 'Bhojpur',
        }, box(86, 26, 88, 28)),
      ]),
      BoundaryRepository.localLevelCodesAsset: jsonEncode(testCodes),
    };

/// Server files: Hatuwagadhi is the west half of Bhojpur with two wards
/// (ward 1 south, ward 2 north). The east half (Bhojpur municipality) has
/// no ward file on the server.
FakeDataCache testCache() => FakeDataCache()
  ..store['locallevels/Bhojpur.json'] = collection([
    feature({
      'Province': 'Koshi Pradesh',
      'District': 'Bhojpur',
      'LocalLevel': 'Hatuwagadhi',
      'Type': 'Gaunpalika',
      'name': 'Hatuwagadhi',
    }, box(86, 26, 87, 28)),
    feature({
      'Province': 'Koshi Pradesh',
      'District': 'Bhojpur',
      'LocalLevel': 'Bhojpur',
      'Type': 'Nagarpalika',
      'name': 'Bhojpur',
    }, box(87, 26, 88, 28)),
  ])
  ..store['wards/Bhojpur_Hatuwagadhi.json'] = collection([
    feature({'GaPa_NaPa': 'Hatuwagadhi', 'Ward_Num': 2, 'name': '2'},
        box(86, 27, 87, 28)),
    feature({'GaPa_NaPa': 'Hatuwagadhi', 'Ward_Num': 1, 'name': '1'},
        box(86, 26, 87, 27)),
  ]);

/// HTTP client that answers 404 to everything (cache misses).
http.Client notFoundClient() =>
    http_testing.MockClient((_) async => http.Response('not found', 404));

BoundaryRepository testRepository({FakeDataCache? cache, http.Client? client}) {
  final assets = testAssets();
  return BoundaryRepository(
    data: DataService(cache: cache ?? testCache(), client: client ?? notFoundClient()),
    assets: (key) async => assets[key]!,
  );
}
