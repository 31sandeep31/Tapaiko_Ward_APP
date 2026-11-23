import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus { granted, denied, deniedForever, serviceOff }

class LocationFix {
  const LocationFix(this.point, this.accuracyMeters);

  final LatLng point;
  final double accuracyMeters;
}

/// Thin wrapper over geolocator so the map view model can be tested.
class LocationService {
  const LocationService();

  Future<LocationStatus> status() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceOff;
    }
    return _map(await Geolocator.checkPermission());
  }

  /// Asks for permission if it hasn't been decided yet.
  Future<LocationStatus> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _map(permission);
  }

  /// Current position; falls back to the last known fix if a fresh one
  /// can't be obtained in time. Returns null when neither is available.
  Future<LocationFix?> current() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationFix(LatLng(p.latitude, p.longitude), p.accuracy);
    } on TimeoutException {
      return _lastKnown();
    } catch (_) {
      return _lastKnown();
    }
  }

  Future<LocationFix?> _lastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      if (p == null) return null;
      return LocationFix(LatLng(p.latitude, p.longitude), p.accuracy);
    } catch (_) {
      return null;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false; // e.g. not supported on web
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  static LocationStatus _map(LocationPermission p) => switch (p) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          LocationStatus.granted,
        LocationPermission.deniedForever => LocationStatus.deniedForever,
        _ => LocationStatus.denied,
      };
}
