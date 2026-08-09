import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'data_service.dart';
import 'models.dart';
import 'municipality_service.dart';

/// Returned to the map screen: what the user picked and its boundary geometry.
class MapSelection {
  MapSelection({
    required this.title,
    required this.subtitle,
    this.geometry,
    this.municipality,
  });

  final String title;
  final String subtitle;
  final Map<String, dynamic>? geometry;
  final Municipality? municipality;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.data});

  final DataService data;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final MunicipalityService _service;
  List<Municipality> _all = [];
  List<Municipality> _visible = [];
  final Set<String> _types = {};
  String? _activeType;
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = MunicipalityService(widget.data);
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await _service.municipalities();
      if (!mounted) return;
      setState(() {
        _all = all;
        _visible = all;
        _types
          ..clear()
          ..addAll(all.map((m) => m.typeGn).where((t) => t.isNotEmpty));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    setState(() {
      _visible = _all.where((m) {
        if (_activeType != null && m.typeGn != _activeType) return false;
        if (q.isEmpty) return true;
        return m.gaPaNaPa.toLowerCase().contains(q) ||
            m.district.toLowerCase().contains(q) ||
            m.province.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _selectMunicipality(Municipality m) async {
    Navigator.of(context).pop(
      MapSelection(
        title: m.gaPaNaPa,
        subtitle: '${m.typeGn} · ${m.district} · ${m.province}',
        municipality: m,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchMunicipalityTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) {
                    _query = v;
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _query = '';
                              _applyFilter();
                            },
                          ),
                  ),
                ),
              ),
              if (_types.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _chip(null, l10n.allTypes),
                      for (final t in _types) _chip(t, t),
                    ],
                  ),
                ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String? type, String label) {
    final active = _activeType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) {
          _activeType = type;
          _applyFilter();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context)!.couldNotLoadMunicipalities),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    if (_visible.isEmpty) {
      return Center(
          child: Text(AppLocalizations.of(context)!
              .noMatchingMunicipalities));
    }
    return ListView.builder(
      itemCount: _visible.length,
      itemBuilder: (ctx, i) {
        final m = _visible[i];
        return ListTile(
          leading: CircleAvatar(
            child: Icon(_typeIcon(m.typeGn)),
          ),
          title: Text(m.gaPaNaPa),
          subtitle: Text('${m.typeGn} · ${m.district} · ${m.province}'),
          onTap: () => _selectMunicipality(m),
        );
      },
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        _ when type.contains('Mahanagarpalika') => Icons.location_city,
        _ when type.contains('Upamahanagarpalika') => Icons.location_city,
        _ when type.contains('Nagarpalika') => Icons.apartment,
        _ => Icons.home_work,
      };
}
