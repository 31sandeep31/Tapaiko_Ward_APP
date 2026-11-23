import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'data/boundary_repository.dart';
import 'data/census_service.dart';
import 'data/data_service.dart';
import 'data/settings_repository.dart';
import 'data/tile_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  TileCache.configure();

  final settings = await SettingsRepository.load();
  final data = DataService();
  final boundaries = BoundaryRepository(data: data);
  // Start parsing the bundled outlines while the first frame renders.
  unawaited(boundaries.init().catchError((_) {}));

  runApp(TapaikoWardApp(
    deps: AppDependencies(
      data: data,
      boundaries: boundaries,
      census: CensusService(data),
      settings: settings,
    ),
  ));
}
