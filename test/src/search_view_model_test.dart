import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapaiko_ward/domain/admin.dart';
import 'package:tapaiko_ward/ui/features/search/view_models/search_view_model.dart';

import '../helpers/fixtures.dart';

void main() {
  late SearchViewModel vm;

  setUp(() async {
    final repo = testRepository();
    await repo.init();
    vm = SearchViewModel(repo);
  });

  test('matches municipalities, districts and provinces', () {
    vm.setQuery('bhoj');
    check(vm.results.districts.map((d) => d.name)).deepEquals(['Bhojpur']);
    // Name match ranks above a district-only match.
    check(vm.results.municipalities.map((m) => m.gaPaNaPa).toList())
        .deepEquals(['Bhojpur', 'Hatuwagadhi']);

    vm.setQuery('koshi');
    check(vm.results.provinces).length.equals(1);
  });

  test('parses a trailing ward number', () {
    vm.setQuery('Kathmandu 5');
    check(vm.textQuery).equals('Kathmandu');
    check(vm.wardNo).equals('5');
    check(vm.results.municipalities.single.gaPaNaPa).equals('Kathmandu');

    final first = vm.firstResult;
    check(first).isA<SelectMunicipality>();
    check((first as SelectMunicipality).wardNo).equals('5');

    vm.setQuery('hatuwagadhi ward no. 03');
    check(vm.wardNo).equals('3');
  });

  test('filters by local level type', () {
    vm.setType(LocalLevelType.metropolitan);
    check(vm.allOfType.map((m) => m.gaPaNaPa)).deepEquals(['Kathmandu']);
    vm.setQuery('bhoj');
    check(vm.results.municipalities).isEmpty();
  });

  test('returns empty results for no match', () {
    vm.setQuery('zzz');
    check(vm.results.isEmpty).isTrue();
    check(vm.firstResult).isNull();
  });
}
