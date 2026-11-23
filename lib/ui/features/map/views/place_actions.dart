import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/admin.dart';
import '../../../../domain/geometry.dart';
import '../../../core/formatting.dart';

/// Human-readable address of a ward or municipality, localised.
String placeAddress(
  BuildContext context,
  MunicipalityInfo m, {
  String? wardNo,
}) {
  final l10n = context.l10n;
  final first = [
    if (wardNo != null) context.wardLabel(wardNo),
    '${m.name} ${context.typeLabel(m.type)}',
  ].join(', ');
  final second = [
    '${m.district.name} ${l10n.levelDistrict}',
    context.provinceLabel(m.province),
    l10n.nepal,
  ].join(', ');
  return '$first\n$second';
}

/// Best point to represent a place: the dropped pin, else a point inside
/// the ward (or municipality).
LatLng? placePoint(MunicipalityInfo m, {LatLng? pin, Map<String, dynamic>? ward}) {
  if (pin != null) return pin;
  final g = ward ?? m.feature.geometry;
  return g == null ? null : labelPoint(g);
}

String coordinatesText(LatLng p) =>
    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

Uri mapsLink(LatLng p) => Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}');

Future<void> sharePlace(
  BuildContext context,
  MunicipalityInfo m, {
  String? wardNo,
  LatLng? point,
}) async {
  final l10n = context.l10n;
  final text = [
    placeAddress(context, m, wardNo: wardNo),
    if (point != null) mapsLink(point).toString(),
    '— ${l10n.sharedFrom}',
  ].join('\n');
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    text: text,
    sharePositionOrigin:
        box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  ));
}

Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(context.l10n.copied),
      duration: const Duration(seconds: 2),
    ));
}

/// Opens turn-by-turn directions in the user's maps app.
Future<void> openDirections(LatLng p) async {
  final google = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}');
  if (await launchUrl(google, mode: LaunchMode.externalApplication)) return;
  await launchUrl(Uri.parse('geo:${p.latitude},${p.longitude}'));
}

Future<void> openLink(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
