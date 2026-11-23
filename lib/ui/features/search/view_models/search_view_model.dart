import 'package:flutter/foundation.dart';

import '../../../../data/boundary_repository.dart';
import '../../../../data/models.dart';
import '../../../../data/settings_repository.dart';
import '../../../../domain/admin.dart';

/// What the user picked in search, returned to the map.
sealed class SearchSelection {
  const SearchSelection();
}

class SelectProvince extends SearchSelection {
  const SelectProvince(this.province);
  final ProvinceInfo province;
}

class SelectDistrict extends SearchSelection {
  const SelectDistrict(this.district);
  final DistrictInfo district;
}

class SelectMunicipality extends SearchSelection {
  const SelectMunicipality(this.municipality, {this.wardNo});
  final Municipality municipality;
  final String? wardNo;
}

class SelectRecent extends SearchSelection {
  const SelectRecent(this.place);
  final RecentPlace place;
}

class SearchResults {
  const SearchResults(this.provinces, this.districts, this.municipalities);

  final List<ProvinceInfo> provinces;
  final List<DistrictInfo> districts;
  final List<Municipality> municipalities;

  bool get isEmpty =>
      provinces.isEmpty && districts.isEmpty && municipalities.isEmpty;
}

class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this.repository);

  final BoundaryRepository repository;

  static const maxMunicipalities = 60;

  String _query = '';
  LocalLevelType? _type;
  SearchResults _results = const SearchResults([], [], []);

  String get query => _query;
  LocalLevelType? get type => _type;
  SearchResults get results => _results;

  /// Query with a trailing ward number removed ("Kathmandu 5" -> "Kathmandu").
  String textQuery = '';

  /// Ward number typed after the name, if any.
  String? wardNo;

  List<Municipality> get allOfType => _type == null
      ? repository.municipalities
      : repository.municipalities
          .where((m) => LocalLevelType.parse(m.typeGn) == _type)
          .toList();

  SearchSelection? get firstResult {
    final r = _results;
    if (r.municipalities.isNotEmpty) {
      return SelectMunicipality(r.municipalities.first, wardNo: wardNo);
    }
    if (r.districts.isNotEmpty) return SelectDistrict(r.districts.first);
    if (r.provinces.isNotEmpty) return SelectProvince(r.provinces.first);
    return null;
  }

  void setQuery(String q) {
    _query = q;
    _search();
  }

  void setType(LocalLevelType? t) {
    _type = t;
    _search();
  }

  void _search() {
    final raw = _query.trim();
    final match = RegExp(r'^(.*?)[\s,]*(?:ward\s*(?:no\.?)?\s*)?(\d{1,2})$',
            caseSensitive: false)
        .firstMatch(raw);
    if (match != null && match.group(1)!.trim().isNotEmpty) {
      textQuery = match.group(1)!.trim();
      wardNo = int.parse(match.group(2)!).toString();
    } else {
      textQuery = raw;
      wardNo = null;
    }
    final q = textQuery.toLowerCase();
    if (q.isEmpty) {
      _results = const SearchResults([], [], []);
      notifyListeners();
      return;
    }

    final provinces = _type != null || wardNo != null
        ? <ProvinceInfo>[]
        : repository.provinces
            .where((p) =>
                p.shortName.toLowerCase().contains(q) ||
                p.fullName.toLowerCase().contains(q))
            .toList();
    final districts = _type != null || wardNo != null
        ? <DistrictInfo>[]
        : (repository.districts
              .where((d) => d.name.toLowerCase().contains(q))
              .toList()
          ..sort((a, b) => _rank(a.name, q).compareTo(_rank(b.name, q))));

    final scored = <(int, Municipality)>[];
    for (final m in allOfType) {
      final name = m.gaPaNaPa.toLowerCase();
      var score = _rank(m.gaPaNaPa, q);
      if (score == 3) {
        // Also match by district or province, ranked lower.
        if (m.district.toLowerCase().contains(q)) {
          score = 4;
        } else if (m.province.toLowerCase().contains(q)) {
          score = 5;
        } else {
          continue;
        }
      }
      scored.add((score * 1000 + name.length, m));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));

    _results = SearchResults(
      provinces,
      districts,
      scored.take(maxMunicipalities).map((e) => e.$2).toList(),
    );
    notifyListeners();
  }

  /// 0 exact, 1 prefix, 2 word prefix / contains, 3 no match.
  static int _rank(String text, String q) {
    final t = text.toLowerCase();
    if (t == q) return 0;
    if (t.startsWith(q)) return 1;
    if (t.contains(q)) return 2;
    return 3;
  }
}
