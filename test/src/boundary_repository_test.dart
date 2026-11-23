import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:latlong2/latlong.dart';
import 'package:tapaiko_ward/data/data_service.dart';
import 'package:tapaiko_ward/data/models.dart';
import 'package:tapaiko_ward/domain/admin.dart';

import '../helpers/fake_data_cache.dart';
import '../helpers/fixtures.dart';

void main() {
  group('BoundaryRepository', () {
    test('init loads bundled provinces, districts and local levels', () async {
      final repo = testRepository();
      await repo.init();

      check(repo.provinces).length.equals(1);
      check(repo.provinces.first.number).equals(1);
      check(repo.provinces.first.fullName).equals('Koshi Pradesh');
      check(repo.districts.single.name).equals('Bhojpur');
      check(repo.municipalities).length.equals(3);
      check(repo.districtsOf(repo.provinces.first)).length.equals(1);
      check(repo.municipalitiesOf(repo.districts.single)).length.equals(2);
      check(repo.municipalityCountOf(repo.provinces.first)).equals(2);
    });

    test('identify finds the municipality and ward at a point', () async {
      final repo = testRepository();
      final result = await repo.identify(const LatLng(27.5, 86.5));

      check(result).isA<IdentifyFound>();
      final found = result as IdentifyFound;
      check(found.municipality.name).equals('Hatuwagadhi');
      check(found.municipality.type).equals(LocalLevelType.rural);
      check(found.municipality.district.name).equals('Bhojpur');
      check(found.municipality.codes?.municipalityCode).equals(5);
      check(wardNumberOf(found.ward!)).equals('2');
      // Wards come back sorted by number.
      check(found.municipality.wards.map(wardNumberOf).toList())
          .deepEquals(['1', '2']);
    });

    test('identify returns a municipality without ward when it has none',
        () async {
      final repo = testRepository();
      final result = await repo.identify(const LatLng(27.5, 87.5));

      final found = result as IdentifyFound;
      check(found.municipality.name).equals('Bhojpur');
      check(found.municipality.wards).isEmpty();
      check(found.ward).isNull();
    });

    test('identify reports points outside Nepal', () async {
      final repo = testRepository();
      check(await repo.identify(const LatLng(51.5, -0.1)))
          .isA<IdentifyOutsideNepal>();
      // Inside Nepal's box but not near any (test) district.
      check(await repo.identify(const LatLng(29.5, 81.0)))
          .isA<IdentifyOutsideNepal>();
    });

    test('identify surfaces network errors', () async {
      final client = http_testing.MockClient(
          (_) async => throw http.ClientException('offline'));
      final repo = testRepository(cache: FakeDataCache(), client: client);

      await check(repo.identify(const LatLng(27.5, 86.5)))
          .throws<NetworkException>();
    });

    test('municipalityFor resolves a search result to its boundary', () async {
      final repo = testRepository();
      await repo.init();
      final m = repo.municipalities.firstWhere((m) => m.gaPaNaPa == 'Hatuwagadhi');

      final info = await repo.municipalityFor(m);
      check(info).isNotNull();
      check(info!.wards).length.equals(2);
      check(info.ward('1')).isNotNull();
    });

    test('municipalityFor returns null when the district is unknown', () async {
      final repo = testRepository();
      await repo.init();
      final m = repo.municipalities.firstWhere((m) => m.gaPaNaPa == 'Kathmandu');

      check(await repo.municipalityFor(m)).isNull();
    });

    test('municipalityFor applies spelling aliases', () async {
      final cache = testCache()
        ..store['locallevels/Bhojpur.json'] = collection([
          feature({'District': 'Bhojpur', 'name': 'Byas'}, box(86, 26, 88, 28)),
        ]);
      final repo = testRepository(cache: cache);
      await repo.init();
      // Pretend the official list spells it "Vyas" in Tanahu-style alias.
      final m = Municipality(
        stateCode: 1,
        district: 'BHOJPUR',
        gaPaNaPa: 'byas',
        typeGn: 'Nagarpalika',
        province: 'Koshi Pradesh',
        districtCode: 10,
        municipalityCode: 9,
      );
      final info = await repo.municipalityFor(m);
      check(info?.name).equals('Byas');
    });

    test('codesFor matches official names case-insensitively', () async {
      final repo = testRepository();
      await repo.init();
      check(repo.codesFor('Bhojpur', 'HATUWAGADHI')?.municipalityCode).equals(5);
      check(repo.codesFor('Bhojpur', 'Nowhere')).isNull();
    });

    test('municipalityByName reopens a recent place', () async {
      final repo = testRepository();
      await repo.init();
      final info = await repo.municipalityByName('Bhojpur', 'Hatuwagadhi');
      check(info?.wards).isNotNull().length.equals(2);
    });
  });

  group('LocalLevelType.parse', () {
    test('distinguishes all four types', () {
      check(LocalLevelType.parse('Mahanagarpalika')).equals(LocalLevelType.metropolitan);
      check(LocalLevelType.parse('Upamahanagarpalika'))
          .equals(LocalLevelType.subMetropolitan);
      check(LocalLevelType.parse('Nagarpalika')).equals(LocalLevelType.municipality);
      check(LocalLevelType.parse('Gaunpalika')).equals(LocalLevelType.rural);
      check(LocalLevelType.parse(null)).equals(LocalLevelType.other);
    });
  });
}
