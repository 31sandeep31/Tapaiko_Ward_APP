import 'package:flutter/material.dart';

import '../../../../data/boundary_repository.dart';
import '../../../../data/models.dart';
import '../../../../data/settings_repository.dart';
import '../../../../domain/admin.dart';
import '../../../core/formatting.dart';
import '../../../core/theme.dart';
import '../view_models/search_view_model.dart';

export '../view_models/search_view_model.dart' show SearchSelection,
    SelectProvince, SelectDistrict, SelectMunicipality, SelectRecent;

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.repository,
    required this.settings,
  });

  final BoundaryRepository repository;
  final SettingsRepository settings;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchViewModel vm = SearchViewModel(widget.repository);
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    vm.dispose();
    super.dispose();
  }

  void _pick(SearchSelection s) => Navigator.of(context).pop(s);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: vm,
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.lg, Space.sm),
                child: Hero(
                  tag: 'search-bar',
                  child: Material(
                    color: scheme.surfaceContainerHigh,
                    shape: const StadiumBorder(),
                    child: SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: l10n.back,
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _text,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onChanged: vm.setQuery,
                              onSubmitted: (_) {
                                final first = vm.firstResult;
                                if (first != null) _pick(first);
                              },
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: l10n.searchHint,
                                border: InputBorder.none,
                                filled: false,
                                isCollapsed: true,
                              ),
                            ),
                          ),
                          if (vm.query.isNotEmpty)
                            IconButton(
                              tooltip: l10n.clearSearch,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _text.clear();
                                vm.setQuery('');
                              },
                            ),
                          const SizedBox(width: Space.xs),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _TypeFilters(vm: vm),
              const Divider(),
              Expanded(
                child: vm.query.trim().isEmpty
                    ? _BrowseList(vm: vm, settings: widget.settings, onPick: _pick)
                    : _Results(vm: vm, onPick: _pick),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeFilters extends StatelessWidget {
  const _TypeFilters({required this.vm});

  final SearchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final types = [
      (null, l10n.searchFilterAll),
      (LocalLevelType.metropolitan, l10n.typeMetropolitan),
      (LocalLevelType.subMetropolitan, l10n.typeSubMetropolitan),
      (LocalLevelType.municipality, l10n.typeMunicipality),
      (LocalLevelType.rural, l10n.typeRural),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        children: [
          for (final (type, label) in types)
            Padding(
              padding: const EdgeInsets.only(right: Space.sm),
              child: FilterChip(
                label: Text(label),
                selected: vm.type == type,
                showCheckmark: false,
                onSelected: (_) => vm.setType(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrowseList extends StatelessWidget {
  const _BrowseList({required this.vm, required this.settings, required this.onPick});

  final SearchViewModel vm;
  final SettingsRepository settings;
  final ValueChanged<SearchSelection> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final recents = vm.type == null ? settings.recents : const <RecentPlace>[];
    final all = vm.allOfType;
    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.lg),
      itemCount: (recents.isEmpty ? 0 : recents.length + 1) + 2 + all.length,
      itemBuilder: (context, i) {
        if (recents.isNotEmpty) {
          if (i == 0) return _Header(l10n.recentPlaces);
          if (i <= recents.length) {
            final r = recents[i - 1];
            return ListTile(
              leading: const _LeadingIcon(Icons.history_rounded),
              title: Text(r.wardNo == null
                  ? r.localLevel
                  : '${r.localLevel} · ${context.wardLabel(r.wardNo!)}'),
              subtitle: Text(
                  '${context.typeLabel(LocalLevelType.parse(r.type))} · ${r.district}'),
              onTap: () => onPick(SelectRecent(r)),
            );
          }
          i -= recents.length + 1;
        }
        if (i == 0) return _Header('${l10n.searchAllLocalLevels} · ${context.digits('${all.length}')}');
        if (i == 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
            child: Text(l10n.searchTipWard,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        final m = all[i - 2];
        return _MunicipalityTile(m: m, query: '', onPick: onPick);
      },
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.vm, required this.onPick});

  final SearchViewModel vm;
  final ValueChanged<SearchSelection> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = vm.results;
    if (r.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: Space.md),
              Text(l10n.searchNoResults(vm.query.trim()),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Space.sm),
              Text(l10n.searchTipWard,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    final q = vm.textQuery;
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Space.lg),
      children: [
        if (r.provinces.isNotEmpty) ...[
          _Header(l10n.searchSectionProvinces),
          for (final p in r.provinces)
            ListTile(
              leading: const _LeadingIcon(Icons.flag_outlined),
              title: _Highlighted(context.provinceLabel(p), q),
              subtitle: Text(l10n.districtsCount(vm.repository.districtsOf(p).length)),
              onTap: () => onPick(SelectProvince(p)),
            ),
        ],
        if (r.districts.isNotEmpty) ...[
          _Header(l10n.searchSectionDistricts),
          for (final d in r.districts)
            ListTile(
              leading: const _LeadingIcon(Icons.map_outlined),
              title: _Highlighted(d.name, q),
              subtitle: Text(
                  '${l10n.levelDistrict} · ${context.provinceLabel(d.province)}'),
              onTap: () => onPick(SelectDistrict(d)),
            ),
        ],
        if (r.municipalities.isNotEmpty) ...[
          _Header(l10n.searchSectionLocalLevels),
          for (final m in r.municipalities)
            _MunicipalityTile(m: m, query: q, wardNo: vm.wardNo, onPick: onPick),
        ],
      ],
    );
  }
}

class _MunicipalityTile extends StatelessWidget {
  const _MunicipalityTile({
    required this.m,
    required this.query,
    required this.onPick,
    this.wardNo,
  });

  final Municipality m;
  final String query;
  final String? wardNo;
  final ValueChanged<SearchSelection> onPick;

  @override
  Widget build(BuildContext context) {
    final type = LocalLevelType.parse(m.typeGn);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: _LeadingIcon(switch (type) {
        LocalLevelType.metropolitan || LocalLevelType.subMetropolitan =>
          Icons.location_city_rounded,
        LocalLevelType.municipality => Icons.apartment_rounded,
        _ => Icons.holiday_village_outlined,
      }),
      title: _Highlighted(m.gaPaNaPa, query),
      subtitle: Text('${context.typeLabel(type)} · ${m.districtTitle}'),
      trailing: wardNo == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(context.wardLabel(wardNo!),
                  style: TextStyle(
                      color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
            ),
      onTap: () => onPick(SelectMunicipality(m, wardNo: wardNo)),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      child: Icon(icon, size: 22),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, Space.sm),
      child: Semantics(
        header: true,
        child: Text(text,
            style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Bolds the part of [text] that matches [query].
class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, this.query);

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final i = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
    if (i < 0) return Text(text);
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(TextSpan(children: [
      TextSpan(text: text.substring(0, i)),
      TextSpan(
        text: text.substring(i, i + q.length),
        style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary),
      ),
      TextSpan(text: text.substring(i + q.length)),
    ]));
  }
}
