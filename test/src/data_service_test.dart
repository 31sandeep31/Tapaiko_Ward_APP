import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapaiko_ward/src/data_service.dart';

import '../helpers/fake_data_cache.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
import 'data_service_test.mocks.dart';

void main() {
  group('DataService', () {
    late MockClient client;
    late FakeDataCache cache;
    late DataService service;

    setUp(() {
      client = MockClient();
      cache = FakeDataCache();
      service = DataService(client: client, cache: cache);
    });

    test('fetches over HTTP, caches the text, and returns parsed JSON',
        () async {
      final uri = Uri.parse('${DataService.baseUrl}province.json');
      when(client.get(uri)).thenAnswer(
          (_) async => http.Response('{"features":[]}', 200));

      final json = await service.getJson('province.json');

      check(json).containsKey('features');
      verify(client.get(uri)).called(1);
      check(cache.store).containsKey('province.json');
    });

    test('serves repeat lookups from the in-memory JSON cache', () async {
      final uri = Uri.parse('${DataService.baseUrl}province.json');
      when(client.get(uri)).thenAnswer(
          (_) async => http.Response('{"features":[]}', 200));

      await service.getJson('province.json');
      await service.getJson('province.json');

      verify(client.get(uri)).called(1);
    });

    test('serves files from the cache without hitting the network', () async {
      await cache.write('locallevelcodes.json', '[{"STATE_CODE":1}]');

      final list = await service.getMunicipalities();

      check(list).length.equals(1);
      check(list.first.stateCode).equals(1);
      verifyNever(client.get(any));
    });

    test('strips the UTF-8 BOM from locallevelcodes.json', () async {
      when(client.get(any)).thenAnswer(
          (_) async => http.Response.bytes(utf8.encode('\uFEFF[]'), 200));

      final list = await service.getMunicipalities();

      check(list).isEmpty();
    });

    test('throws when the response is not 200', () async {
      when(client.get(any)).thenAnswer((_) async => http.Response('nope', 404));

      await check(service.getJson('province.json')).throws<Exception>();
    });
  });
}
