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

  Map<String, dynamic> toJson() =>
      {'features': features.map((f) => f.toJson()).toList()};
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

  Map<String, dynamic> toJson() => {
        if (geometry != null) 'geometry': geometry,
        'properties': properties,
      };

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

  /// Proper-case district name ("BHOJPUR" -> "Bhojpur").
  String get districtTitle => district
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

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

  Map<String, dynamic> toJson() => {
        'STATE_CODE': stateCode,
        'DISTRICT': district,
        'GaPa_NaPa': gaPaNaPa,
        'Type_GN': typeGn,
        'Province': province,
        'DISTRICT_CODE': districtCode,
        'MUNICIPALITY_CODE': municipalityCode,
      };
}
