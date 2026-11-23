import 'data/boundary_repository.dart';
import 'data/census_service.dart';
import 'data/data_service.dart';
import 'data/settings_repository.dart';

/// App-wide services, created once in `main` and passed down.
class AppDependencies {
  AppDependencies({
    required this.data,
    required this.boundaries,
    required this.census,
    required this.settings,
  });

  final DataService data;
  final BoundaryRepository boundaries;
  final CensusService census;
  final SettingsRepository settings;

  static const contactEmail = 'ward@sandeepkafle.com.np';

  static const playStoreId = 'com.tapaiko.tapaiko_ward';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$playStoreId';
}
