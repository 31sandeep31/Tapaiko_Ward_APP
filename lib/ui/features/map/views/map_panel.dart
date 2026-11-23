import 'package:flutter/material.dart';

import '../../../../data/census_service.dart';
import '../../../../data/settings_repository.dart';
import '../../../../domain/admin.dart';
import '../../../../data/models.dart';
import '../../../core/formatting.dart';
import '../../../core/map_styles.dart';
import '../../../core/theme.dart';
import '../view_models/map_view_model.dart';
import 'place_actions.dart';

/// Content of the map's bottom sheet (or side sheet on wide screens).
class MapPanel extends StatelessWidget {
  const MapPanel({
    super.key,
    required this.vm,
    required this.scrollController,
    required this.showHandle,
  });

  final MapViewModel vm;
  final ScrollController scrollController;
  final bool showHandle;

  String get _panelKey => [
        vm.level.name,
        vm.province?.shortName,
        vm.district?.name,
        vm.municipality?.name,
        vm.selectedWardNo,
      ].join('/');

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final Widget content;
        if (vm.loadFailed) {
          content = _ErrorContent(onRetry: vm.init);
        } else if (!vm.ready) {
          content = const _LoadingContent();
        } else {
          content = switch (vm.level) {
            AdminLevel.country => _ExploreContent(vm: vm),
            AdminLevel.province => _ProvinceContent(vm: vm),
            AdminLevel.district => _DistrictContent(vm: vm),
            AdminLevel.municipality => _MunicipalityContent(vm: vm),
          };
        }
        return CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (showHandle) const _DragHandle() else const SizedBox(height: 8),
                  _BusyBar(busy: vm.busy),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  Space.lg, Space.xs, Space.lg, Space.xl + bottomInset),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  switchInCurve: Motion.emphasizedDecelerate,
                  switchOutCurve: Motion.emphasizedAccelerate,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  ),
                  child: KeyedSubtree(key: ValueKey(_panelKey), child: content),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BusyBar extends StatelessWidget {
  const _BusyBar({required this.busy});

  final BusyKind busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = switch (busy) {
      BusyKind.none => null,
      BusyKind.locating => l10n.findingYourLocation,
      BusyKind.identifying => l10n.identifyingPlace,
      BusyKind.loading => l10n.loadingArea,
    };
    return AnimatedSize(
      duration: Motion.short,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.lg, Space.sm),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const LinearProgressIndicator(minHeight: 4),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(Space.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        const SizedBox(height: Space.lg),
        Icon(Icons.cloud_off_rounded,
            size: 40, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: Space.sm),
        Text(l10n.loadFailed, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Space.lg),
        FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Explore (country level)

class _ExploreContent extends StatelessWidget {
  const _ExploreContent({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final recents = vm.settings.recents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.exploreTitle,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.xs),
        Text(l10n.exploreSubtitle,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: Space.lg),
        FilledButton.icon(
          onPressed: vm.busy == BusyKind.locating ? null : vm.locateMe,
          icon: const Icon(Icons.my_location_rounded),
          label: Text(l10n.useMyLocation),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        if (recents.isNotEmpty) ...[
          _SectionHeader(l10n.recentPlaces),
          for (final r in recents) _RecentTile(place: r, onTap: () => vm.openRecent(r)),
        ],
        _SectionHeader(l10n.browseProvinces),
        for (final p in vm.provinces)
          _AreaTile(
            color: provinceColors[p.number - 1],
            leadingText: context.digits('${p.number}'),
            title: context.provinceLabel(p),
            subtitle:
                '${l10n.districtsCount(vm.repository.districtsOf(p).length)} · '
                '${l10n.localLevelsCount(vm.repository.municipalityCountOf(p))}',
            onTap: () => vm.selectProvince(p),
          ),
        const SizedBox(height: Space.lg),
        const _Disclaimer(),
      ],
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.place, required this.onTap});

  final RecentPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.typeLabel(LocalLevelType.parse(place.type));
    final ward = place.wardNo;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.xs),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: const Icon(Icons.history_rounded),
      ),
      title: Text(ward == null
          ? place.localLevel
          : '${place.localLevel} · ${context.wardLabel(ward)}'),
      subtitle: Text('$type · ${place.district}'),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Province & district

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({
    required this.vm,
    required this.overline,
    required this.title,
    this.subtitle,
  });

  final MapViewModel vm;
  final String overline;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: l10n.back,
          onPressed: vm.goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: Space.xs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(overline.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary, letterSpacing: 0.8)),
                Text(title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.close,
          onPressed: vm.showCountry,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

/// "Nepal › Koshi › Bhojpur" — each crumb jumps to that level.
class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final crumbs = <(String, VoidCallback?)>[
      (context.l10n.nepal, vm.showCountry),
      if (vm.province != null && vm.level != AdminLevel.province)
        (context.provinceShortLabel(vm.province!), () => vm.selectProvince(vm.province!)),
      if (vm.district != null && vm.level == AdminLevel.municipality)
        (vm.district!.name, () => vm.selectDistrict(vm.district!)),
    ];
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 52, top: Space.xs),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: crumbs[i].$2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(crumbs[i].$1,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.primary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProvinceContent extends StatelessWidget {
  const _ProvinceContent({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = vm.province!;
    final districts = vm.repository.districtsOf(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LevelHeader(
          vm: vm,
          overline: l10n.provinceNumber(context.digits('${p.number}')),
          title: context.provinceLabel(p),
          subtitle: '${l10n.districtsCount(districts.length)} · '
              '${l10n.localLevelsCount(vm.repository.municipalityCountOf(p))}',
        ),
        _Breadcrumbs(vm: vm),
        _SectionHeader(l10n.districtsHeader),
        for (final d in districts)
          _AreaTile(
            color: areaColor(d.name),
            title: d.name,
            subtitle: l10n.localLevelsCount(vm.repository.municipalitiesOf(d).length),
            onTap: () => vm.selectDistrict(d),
          ),
      ],
    );
  }
}

class _DistrictContent extends StatelessWidget {
  const _DistrictContent({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = vm.district!;
    final locals = vm.repository.municipalitiesOf(d);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LevelHeader(
          vm: vm,
          overline: l10n.levelDistrict,
          title: d.name,
          subtitle:
              '${context.provinceLabel(d.province)} · ${l10n.localLevelsCount(locals.length)}',
        ),
        _Breadcrumbs(vm: vm),
        _SectionHeader(l10n.localLevelsHeader),
        for (final m in locals)
          _AreaTile(
            color: areaColor(BoundaryNames.boundaryName(d.name, m.gaPaNaPa)),
            title: m.gaPaNaPa,
            subtitle: context.typeLabel(LocalLevelType.parse(m.typeGn)),
            onTap: () => vm.openMunicipality(m),
          ),
      ],
    );
  }
}

/// Map colours are keyed by the boundary-file name, which differs from the
/// official list for a few local levels.
abstract final class BoundaryNames {
  static const _aliases = {
    ('Tanahu', 'Vyas'): 'Byas',
    ('Kapilbastu', 'Shuddhodhan'): 'Suddhodhan',
    ('Kalikot', 'Shuvakalika'): 'Kalika',
    ('Kanchanpur', 'Dodhara Chandani'): 'Mahakali',
  };

  static String boundaryName(String district, String name) =>
      _aliases[(district, name)] ?? name;
}

// ---------------------------------------------------------------------------
// Municipality & ward

class _MunicipalityContent extends StatelessWidget {
  const _MunicipalityContent({required this.vm});

  final MapViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final m = vm.municipality!;
    final ward = vm.selectedWard;
    final wardNo = vm.selectedWardNo;
    final point = placePoint(m, pin: vm.pin, ward: ward?.geometry);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wardNo == null)
          _LevelHeader(
            vm: vm,
            overline: context.typeLabel(m.type),
            title: m.name,
            subtitle: '${m.district.name} · ${context.provinceLabel(m.province)}',
          )
        else
          _WardHeader(vm: vm, municipality: m, wardNo: wardNo),
        if (wardNo == null) _Breadcrumbs(vm: vm),
        const SizedBox(height: Space.md),
        _ActionsRow(
          onShare: () => sharePlace(context, m, wardNo: wardNo, point: point),
          onCopy: () => copyText(context, placeAddress(context, m, wardNo: wardNo)),
          onDirections: point == null ? null : () => openDirections(point),
        ),
        const SizedBox(height: Space.lg),
        _CensusCard(
          census: vm.census,
          loading: vm.censusLoading,
          wardNo: int.tryParse(wardNo ?? ''),
          municipalityName: m.name,
          available: m.codes != null,
        ),
        _SectionHeader(
          wardNo == null ? l10n.wardsHeader : l10n.otherWardsIn(m.name),
          trailing: l10n.wardsCount(m.wards.length),
        ),
        if (m.wards.isEmpty)
          Text(l10n.noWardData,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else ...[
          if (wardNo == null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(l10n.pickWardHint,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          _WardGrid(
            wards: m.wards,
            selected: wardNo,
            onSelect: vm.selectWard,
          ),
        ],
        _SectionHeader(l10n.location),
        _InfoTile(
          icon: Icons.flag_outlined,
          label: l10n.levelProvince,
          value: context.provinceLabel(m.province),
          onTap: () => vm.selectProvince(m.province),
        ),
        _InfoTile(
          icon: Icons.map_outlined,
          label: l10n.levelDistrict,
          value: m.district.name,
          onTap: () => vm.selectDistrict(m.district),
        ),
        _InfoTile(
          icon: Icons.location_city_outlined,
          label: context.typeLabel(m.type),
          value: m.name,
          onTap: wardNo == null ? null : vm.clearWard,
        ),
        if (vm.pin != null)
          _InfoTile(
            icon: Icons.pin_drop_outlined,
            label: l10n.coordinates,
            value: coordinatesText(vm.pin!),
            trailing: const Icon(Icons.copy_rounded, size: 20),
            onTap: () => copyText(context, coordinatesText(vm.pin!)),
          ),
        const SizedBox(height: Space.lg),
        const _Disclaimer(),
      ],
    );
  }
}

class _WardHeader extends StatelessWidget {
  const _WardHeader({
    required this.vm,
    required this.municipality,
    required this.wardNo,
  });

  final MapViewModel vm;
  final MunicipalityInfo municipality;
  final String wardNo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final m = municipality;
    return Semantics(
      container: true,
      label: '${context.wardLabel(wardNo)}, ${m.name} ${context.typeLabel(m.type)}, '
          '${m.district.name}, ${context.provinceLabel(m.province)}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 76,
              height: 84,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.wardLabel.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer, letterSpacing: 1)),
                  FittedBox(
                    child: Text(context.digits(wardNo),
                        style: theme.textTheme.displaySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                            height: 1.05)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(context.typeLabel(m.type),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${m.district.name} · ${context.provinceLabel(m.province)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.close,
            onPressed: vm.clearWard,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.onShare,
    required this.onCopy,
    required this.onDirections,
  });

  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback? onDirections;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Natural-width buttons in a horizontal strip, so long labels (and
    // Nepali text) never get cut off on narrow phones.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded, size: 20),
            label: Text(l10n.share),
          ),
          const SizedBox(width: Space.sm),
          FilledButton.tonalIcon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_rounded, size: 20),
            label: Text(l10n.directions),
          ),
          const SizedBox(width: Space.sm),
          OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: Text(l10n.copy),
          ),
        ],
      ),
    );
  }
}

class _CensusCard extends StatelessWidget {
  const _CensusCard({
    required this.census,
    required this.loading,
    required this.wardNo,
    required this.municipalityName,
    required this.available,
  });

  final CensusData? census;
  final bool loading;
  final int? wardNo;
  final String municipalityName;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final c = census;

    Widget body;
    if (c == null) {
      body = loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: Space.sm),
              child: LinearProgressIndicator(),
            )
          : Text(l10n.populationUnavailable,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant));
    } else {
      final w = wardNo;
      final wardPop = w == null ? null : c.wardPopulation(w);
      final male = w == null || wardPop == null ? c.totalMale : c.wardMale(w)!;
      final female =
          w == null || wardPop == null ? c.totalFemale : c.wardFemale(w)!;
      final total = male + female;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.number(total),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(wardPop != null ? l10n.wardPopulation : l10n.totalPopulationOf(municipalityName),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: Space.md),
          _SplitBar(male: male, female: female),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              _Legend(color: scheme.primary, label: l10n.male, value: context.number(male)),
              const SizedBox(width: Space.lg),
              _Legend(color: scheme.tertiary, label: l10n.female, value: context.number(female)),
            ],
          ),
          if (wardPop != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              '${l10n.totalPopulationOf(municipalityName)}: ${context.number(c.totalPopulation)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      );
    }

    if (!available && c == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: Space.sm),
                Text(l10n.population, style: theme.textTheme.titleSmall),
                const Spacer(),
                Text(l10n.census2021,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: Space.sm),
            AnimatedSize(duration: Motion.medium, child: body),
          ],
        ),
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.male, required this.female});

  final int male;
  final int female;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = male + female;
    final m = total == 0 ? 1 : male;
    final f = total == 0 ? 1 : female;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(flex: m, child: ColoredBox(color: scheme.primary)),
            const SizedBox(width: 2),
            Expanded(flex: f, child: ColoredBox(color: scheme.tertiary)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ', style: theme.textTheme.bodySmall),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _WardGrid extends StatelessWidget {
  const _WardGrid({
    required this.wards,
    required this.selected,
    required this.onSelect,
  });

  final List<GeoFeature> wards;
  final String? selected;
  final void Function(GeoFeature ward) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final w in wards)
          Builder(builder: (context) {
            final no = wardNumberOf(w);
            final isSelected = no == selected;
            return Semantics(
              button: true,
              selected: isSelected,
              label: context.wardLabel(no),
              child: Material(
                color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelect(w),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Center(
                      child: ExcludeSemantics(
                        child: Text(
                          context.digits(no),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? scheme.onPrimary : scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          if (trailing != null)
            Text(trailing!,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leadingText,
  });

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? leadingText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.xs),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: leadingText == null
            ? null
            : Text(leadingText!,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.xs),
      leading: Icon(icon),
      title: Text(label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(value,
          style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
      trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
      onTap: onTap,
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded,
            size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(context.l10n.disclaimerShort,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
