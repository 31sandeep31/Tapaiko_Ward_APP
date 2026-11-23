import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapaiko_ward/data/census_service.dart';
import 'package:tapaiko_ward/data/location_service.dart';
import 'package:tapaiko_ward/data/settings_repository.dart';
import 'package:tapaiko_ward/domain/admin.dart';
import 'package:tapaiko_ward/ui/features/map/view_models/map_view_model.dart';

import '../helpers/fixtures.dart';

class FakeLocation extends LocationService {
  FakeLocation(this.statusValue, [this.fix]);

  LocationStatus statusValue;
  LocationFix? fix;

  @override
  Future<LocationStatus> status() async => statusValue;

  @override
  Future<LocationStatus> request() async => statusValue;

  @override
  Future<LocationFix?> current() async => fix;
}

void main() {
  late SettingsRepository settings;

  Future<MapViewModel> createVm({LocationService? location}) async {
    final repo = testRepository();
    final vm = MapViewModel(
      boundaries: repo,
      census: CensusService(repo.data, client: notFoundClient()),
      settings: settings,
      location: location ?? FakeLocation(LocationStatus.denied),
    );
    await vm.init();
    return vm;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({'locate_on_start': false});
    settings = await SettingsRepository.load();
  });

  test('starts at the country level with province areas', () async {
    final vm = await createVm();
    check(vm.ready).isTrue();
    check(vm.level).equals(AdminLevel.country);
    check(vm.areas).length.equals(1);
  });

  test('tapping the map identifies the ward and records a recent place',
      () async {
    final vm = await createVm();
    await vm.identifyAt(const LatLng(26.5, 86.5));

    check(vm.level).equals(AdminLevel.municipality);
    check(vm.municipality?.name).equals('Hatuwagadhi');
    check(vm.selectedWardNo).equals('1');
    check(vm.pin).equals(const LatLng(26.5, 86.5));
    check(vm.areas).length.equals(2);
    check(settings.recents.first.wardNo).equals('1');
  });

  test('back goes up one level at a time', () async {
    final vm = await createVm();
    await vm.identifyAt(const LatLng(26.5, 86.5));

    check(vm.goBack()).isTrue(); // close ward
    check(vm.selectedWard).isNull();
    check(vm.level).equals(AdminLevel.municipality);

    check(vm.goBack()).isTrue(); // -> district
    await pumpEventQueue();
    check(vm.level).equals(AdminLevel.district);
    check(vm.districtLocalLevels).isNotNull().length.equals(2);

    check(vm.goBack()).isTrue(); // -> province
    check(vm.level).equals(AdminLevel.province);
    check(vm.goBack()).isTrue(); // -> country
    check(vm.level).equals(AdminLevel.country);
    check(vm.goBack()).isFalse();
  });

  test('outside Nepal raises a notice', () async {
    final vm = await createVm();
    await vm.identifyAt(const LatLng(51.5, -0.1));
    check(vm.notice?.issue).equals(MapIssue.outsideNepal);
    check(vm.level).equals(AdminLevel.country);
  });

  test('locateMe reports denied permission', () async {
    final vm = await createVm(location: FakeLocation(LocationStatus.deniedForever));
    await vm.locateMe();
    check(vm.notice?.issue).equals(MapIssue.locationDeniedForever);
  });

  test('locateMe identifies the ward at the GPS fix', () async {
    final vm = await createVm(
      location: FakeLocation(
        LocationStatus.granted,
        const LocationFix(LatLng(27.5, 86.5), 12),
      ),
    );
    await vm.locateMe();
    check(vm.userLocation?.point).equals(const LatLng(27.5, 86.5));
    check(vm.selectedWardNo).equals('2');
    check(vm.pin).isNull();
  });

  test('silent locate does nothing without permission', () async {
    final vm = await createVm();
    await vm.locateMe(silent: true);
    check(vm.notice).isNull();
    check(vm.busy).equals(BusyKind.none);
  });
}
