/// Plain data models mirroring the GeoJSON + locallevelcodes.json files.
library;

class GeoCollection {
  GeoCollection(this.features);

  final List<GeoFeature> features;

  factory GeoCollection.fromJson(Map<String, dynamic> json) {
    final list = (json['features'] as List<dynamic>?) ?? const [];
    return GeoCollection(
      list.map((e) => GeoFeature.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class GeoFeature {
  GeoFeature({required this.properties, this.geometry});

  final Map<String, dynamic> properties;
  final Map<String, dynamic>? geometry;

  factory GeoFeature.fromJson(Map<String, dynamic> json) {
    return GeoFeature(
      properties: (json['properties'] as Map<String, dynamic>?) ?? const {},
      geometry: json['geometry'] as Map<String, dynamic>?,
    );
  }

  Object? operator [](String key) => properties[key];
}

class Municipality {
  Municipality({
    required this.stateCode,
    required this.district,
    required this.gaPaNaPa,
    required this.typeGn,
    required this.province,
    required this.districtCode,
    required this.municipalityCode,
  });

  final int stateCode;
  final String district; // UPPERCASE in locallevelcodes.json
  final String gaPaNaPa;
  final String typeGn;
  final String province;
  final int districtCode;
  final int municipalityCode;

  factory Municipality.fromJson(Map<String, dynamic> json) {
    return Municipality(
      stateCode: (json['STATE_CODE'] as num?)?.toInt() ?? 0,
      district: (json['DISTRICT'] as String?) ?? '',
      gaPaNaPa: (json['GaPa_NaPa'] as String?) ?? '',
      typeGn: (json['Type_GN'] as String?) ?? '',
      province: (json['Province'] as String?) ?? '',
      districtCode: (json['DISTRICT_CODE'] as num?)?.toInt() ?? 0,
      municipalityCode: (json['MUNICIPALITY_CODE'] as num?)?.toInt() ?? 0,
    );
  }
}

class WardResult {
  WardResult({
    required this.wardNo,
    required this.municipality,
    required this.type,
    required this.district,
    required this.province,
    required this.wardGeometry,
  });

  final String wardNo;
  final String municipality;
  final String type;
  final String district;
  final String province;
  final Map<String, dynamic> wardGeometry;
}
