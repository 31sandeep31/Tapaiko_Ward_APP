"""Builds the small, bundled boundary assets the app ships with.

The live site serves full-detail GeoJSON (province.json alone is ~6 MB). The
app bundles a *simplified* copy of the province and district layers so the
first screen renders instantly, works offline, and the "find my ward" lookup
can skip downloading the large province/district files entirely (exact
containment is then decided with the full-detail municipality + ward files).

Usage (from the repo root):

    python tool/build_boundary_assets.py

Requires: shapely (pip install shapely).
"""

from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

from shapely.geometry import mapping, shape

BASE_URL = 'https://maps.sandeepkafle.com.np/data/'
ROOT = Path(__file__).resolve().parent.parent
OUT_GEO = ROOT / 'assets' / 'geo'
OUT_DATA = ROOT / 'assets' / 'data'

# Simplification tolerance in degrees (~111 km per degree).
PROVINCE_TOLERANCE = 0.004   # ~400 m: country-level view
DISTRICT_TOLERANCE = 0.0015  # ~150 m: province-level view
DECIMALS = 4                 # ~11 m precision is plenty after simplifying


def fetch_text(path: str) -> str:
    url = BASE_URL + urllib.parse.quote(path)
    with urllib.request.urlopen(url, timeout=120) as resp:
        text = resp.read().decode('utf-8')
    return text[1:] if text.startswith('﻿') else text


def fetch_json(path: str):
    return json.loads(fetch_text(path))


def round_coords(obj):
    if isinstance(obj, (list, tuple)):
        if obj and isinstance(obj[0], (int, float)):
            return [round(obj[0], DECIMALS), round(obj[1], DECIMALS)]
        return [round_coords(x) for x in obj]
    return obj


def simplify(geometry: dict, tolerance: float) -> dict:
    geom = shape(geometry).simplify(tolerance, preserve_topology=True)
    if geom.is_empty:
        geom = shape(geometry)
    out = mapping(geom)
    return {'type': out['type'], 'coordinates': round_coords(out['coordinates'])}


def write(path: Path, obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(obj, ensure_ascii=False, separators=(',', ':'))
    path.write_text(text, encoding='utf-8')
    print(f'wrote {path.relative_to(ROOT)} ({len(text) / 1024:.0f} KB)')


def main() -> int:
    provinces = fetch_json('province.json')
    province_features = []
    district_features = []
    for pf in provinces['features']:
        props = pf['properties']
        short = props['name']
        province_features.append({
            'type': 'Feature',
            'properties': {'Province': props['Province'], 'name': short},
            'geometry': simplify(pf['geometry'], PROVINCE_TOLERANCE),
        })
        districts = fetch_json(f'districts/{short}.json')
        for df in districts['features']:
            dp = df['properties']
            district_features.append({
                'type': 'Feature',
                'properties': {
                    'Province': dp.get('Province', props['Province']),
                    'ProvinceShort': short,
                    'District': dp.get('District', dp.get('name')),
                    'name': dp.get('name', dp.get('District')),
                },
                'geometry': simplify(df['geometry'], DISTRICT_TOLERANCE),
            })
        print(f'{short}: {len(districts["features"])} districts')

    write(OUT_GEO / 'provinces.json',
          {'type': 'FeatureCollection', 'features': province_features})
    write(OUT_GEO / 'districts.json',
          {'type': 'FeatureCollection', 'features': district_features})

    codes = json.loads(fetch_text('locallevelcodes.json'))
    write(OUT_DATA / 'locallevelcodes.json', codes)
    print(f'{len(district_features)} districts, {len(codes)} local levels')
    return 0


if __name__ == '__main__':
    sys.exit(main())
