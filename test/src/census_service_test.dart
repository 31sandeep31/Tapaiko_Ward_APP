import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapaiko_ward/data/census_service.dart';
import 'package:tapaiko_ward/data/data_service.dart';

import '../helpers/fake_data_cache.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
import 'census_service_test.mocks.dart';

const codesJson = [
  {
    'STATE_CODE': 1,
    'DISTRICT': 'BHOJPUR',
    'GaPa_NaPa': 'Hatuwagadhi',
    'Type_GN': 'Gaunpalika',
    'Province': 'Koshi Pradesh',
    'DISTRICT_CODE': 7,
    'MUNICIPALITY_CODE': 5,
  },
];

String censusBody() => jsonEncode({
      'success': true,
      'data': {
        'series': [
          {'name': 'male', 'data': [100, 200]},
          {'name': 'female', 'data': [110, 210]},
        ],
      },
    });

void main() {
  group('CensusService', () {
    late MockClient client;
    late FakeDataCache cache;
    late CensusService service;

    setUp(() {
      client = MockClient();
      cache = FakeDataCache()..store['locallevelcodes.json'] = jsonEncode(codesJson);
      service = CensusService(
        DataService(client: client, cache: cache),
        client: client,
      );
    });

    test('resolves codes case-insensitively and parses the census series',
        () async {
      when(client.get(any)).thenAnswer((_) async => http.Response(censusBody(), 200));

      final census = await service.fetchFor(
        province: 'koshi pradesh',
        district: 'bhojpur',
        municipality: 'hatuwagadhi',
      );

      check(census).isNotNull();
      check(census!.totalMale).equals(300);
      check(census.totalFemale).equals(320);
      check(census.totalPopulation).equals(620);
      check(census.wardCount).equals(2);
      check(census.wardPopulation(1)).equals(210);
      check(census.wardPopulation(2)).equals(410);
      check(census.wardPopulation(3)).isNull();
      check(census.wardPopulation(0)).isNull();
    });

    test('returns null when no municipality code matches', () async {
      final census = await service.fetchFor(
        province: 'unknown',
        district: 'unknown',
        municipality: 'unknown',
      );
      check(census).isNull();
      verifyNever(client.get(any));
    });

    test('returns null on a non-200 response', () async {
      when(client.get(any)).thenAnswer((_) async => http.Response('oops', 500));

      final census = await service.fetchFor(
        province: 'Koshi Pradesh',
        district: 'BHOJPUR',
        municipality: 'Hatuwagadhi',
      );
      check(census).isNull();
    });

    test('returns null when the API reports failure', () async {
      when(client.get(any)).thenAnswer(
          (_) async => http.Response(jsonEncode({'success': false}), 200));

      final census = await service.fetchFor(
        province: 'Koshi Pradesh',
        district: 'BHOJPUR',
        municipality: 'Hatuwagadhi',
      );
      check(census).isNull();
    });

    test('returns null when the series is empty', () async {
      when(client.get(any)).thenAnswer((_) async => http.Response(
          jsonEncode({'success': true, 'data': {'series': []}}), 200));

      final census = await service.fetchFor(
        province: 'Koshi Pradesh',
        district: 'BHOJPUR',
        municipality: 'Hatuwagadhi',
      );
      check(census).isNull();
    });
  });
}
