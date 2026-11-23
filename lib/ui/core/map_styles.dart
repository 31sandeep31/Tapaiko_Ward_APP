import 'package:flutter/material.dart';

import '../../data/settings_repository.dart';

/// Tile source for a base map style. Keep every provider in this one file
/// so it's easy to swap to a keyed commercial provider later.
class TileSource {
  const TileSource({
    required this.urlTemplate,
    required this.attribution,
    required this.attributionUrl,
    this.labelsUrlTemplate,
    this.subdomains = const [],
    this.maxNativeZoom = 19,
    this.retina = false,
    this.isDark = false,
  });

  final String urlTemplate;

  /// Optional transparent label layer drawn above the boundary overlays.
  final String? labelsUrlTemplate;
  final String attribution;
  final String attributionUrl;
  final List<String> subdomains;
  final int maxNativeZoom;

  /// Whether the URL has an `{r}` placeholder for @2x tiles.
  final bool retina;

  /// Dark imagery: overlays should use lighter outlines.
  final bool isDark;
}

const _osm = TileSource(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  attribution: 'OpenStreetMap contributors',
  attributionUrl: 'https://www.openstreetmap.org/copyright',
);

// Esri gray canvas: key-free light/dark base maps with a separate label
// layer. (CARTO basemaps now require an API key.)
const _esriCredit = 'Esri, HERE, Garmin, OpenStreetMap contributors';
const _esriTerms =
    'https://www.esri.com/en-us/legal/terms/full-master-agreement';

const _grayLight = TileSource(
  urlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
  labelsUrlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
  maxNativeZoom: 16,
  attribution: _esriCredit,
  attributionUrl: _esriTerms,
);

const _grayDark = TileSource(
  urlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
  labelsUrlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
  maxNativeZoom: 16,
  isDark: true,
  attribution: _esriCredit,
  attributionUrl: _esriTerms,
);

const _topo = TileSource(
  urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
  maxNativeZoom: 17,
  attribution: 'OpenStreetMap contributors, SRTM | © OpenTopoMap (CC-BY-SA)',
  attributionUrl: 'https://opentopomap.org/about',
);

const _satellite = TileSource(
  urlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  maxNativeZoom: 18,
  isDark: true,
  attribution: 'Esri, Maxar, Earthstar Geographics',
  attributionUrl: 'https://www.esri.com/en-us/legal/terms/full-master-agreement',
);

TileSource tileSourceFor(MapStyle style, Brightness brightness) =>
    switch (style) {
      MapStyle.auto => brightness == Brightness.dark ? _grayDark : _osm,
      MapStyle.streets => _osm,
      MapStyle.light => _grayLight,
      MapStyle.dark => _grayDark,
      MapStyle.terrain => _topo,
      MapStyle.satellite => _satellite,
    };

/// Overlay palette for neighbouring areas. Muted hues that read well over
/// both light and dark base maps.
const areaPalette = <Color>[
  Color(0xFF3F6FD8),
  Color(0xFF2E9E6A),
  Color(0xFFE08A1E),
  Color(0xFF9B51C9),
  Color(0xFF0E9AA7),
  Color(0xFFD9466F),
  Color(0xFF6C7A1F),
  Color(0xFFB5652B),
  Color(0xFF5560C4),
  Color(0xFF3A8F3A),
];

Color areaColor(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return areaPalette[h % areaPalette.length];
}

/// Fixed colours for the seven provinces (index = province number - 1).
const provinceColors = <Color>[
  Color(0xFF3F6FD8),
  Color(0xFFE08A1E),
  Color(0xFFD9466F),
  Color(0xFF2E9E6A),
  Color(0xFF9B51C9),
  Color(0xFF0E9AA7),
  Color(0xFFB5652B),
];
