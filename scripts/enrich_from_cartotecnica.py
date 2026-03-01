#!/usr/bin/env python3
"""
Enrich civici.json with street names from Comune di Venezia's Carta Tecnica (Shapefile).
Matches by civic number + coordinate proximity.
"""

import json
import math
import os
import re
import shapefile
from pyproj import Transformer

SHP_PATH = "/tmp/venezia_shp/strato03/Strato03_GestioneViabilita_Indirizzi/Tema0301_ToponimiNumeriCivici/CIVICO"

# Transform from Gauss-Boaga (EPSG:3004) to WGS84 (EPSG:4326)
transformer = Transformer.from_crs("EPSG:3004", "EPSG:4326", always_xy=True)

# Venice centro storico street type prefixes
VENICE_PREFIXES = {
    'CALLE', 'CAMPO', 'FONDAMENTA', 'RIO', 'SALIZADA', 'RUGA',
    'CAMPIELLO', 'CORTE', 'LISTA', 'RIVA', 'SOTOPORTEGO', 'RAMO',
    'PONTE', 'SESTIERE', 'PISCINA', 'FONDACO', 'SPADARIA',
    'FREZZARIA', 'MERCERIA', 'MARZARIA', 'PIAZZA', 'PIAZZETTA',
    'CROSERA', 'BARBARIA', 'BORGOLOCO', 'RUGAGIUFFA',
}


def haversine_m(lat1, lon1, lat2, lon2):
    """Distance in meters between two lat/lng points."""
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))


def extract_street_name(indirizzo):
    """Extract street name from INDIRIZZO field, removing the house number at the end."""
    if not indirizzo:
        return None

    # Remove trailing number (with optional letter suffix like 6/A)
    # Pattern: street name followed by number at end
    cleaned = re.sub(r'\s*,?\s*\d+(/[A-Za-z]+)?\s*$', '', indirizzo.strip())
    if cleaned and cleaned != indirizzo.strip():
        return cleaned.strip()
    return None


def is_venice_address(indirizzo):
    """Check if address looks like Venice centro storico (not Mestre/terraferma)."""
    if not indirizzo:
        return False
    first_word = indirizzo.split()[0]
    # Mestre/Lido style addresses
    if first_word in ('VIA', 'VIALE', 'PIAZZALE', 'CORSO', 'LARGO', 'VICOLO', 'VILLAGGIO'):
        return False
    return True


def main():
    json_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                             "ios", "DoVe", "Resources", "Data", "civici.json")

    print(f"Loading {json_path}...")
    with open(json_path) as f:
        civici = json.load(f)

    # Count existing street names
    existing_via = 0
    total_civici = 0
    for code in civici:
        for num, data in civici[code].items():
            total_civici += 1
            if isinstance(data, dict) and 'via' in data:
                existing_via += 1
    print(f"Current: {total_civici} civici, {existing_via} with street names")

    # Build lookup from our data: (number_str) -> [(sestiere_code, lat, lng), ...]
    our_civici = {}
    for code, numbers in civici.items():
        for num, data in numbers.items():
            if isinstance(data, dict) and 'lat' in data:
                key = num
                if key not in our_civici:
                    our_civici[key] = []
                our_civici[key].append((code, data['lat'], data['lng']))

    # Read shapefile
    print(f"Reading {SHP_PATH}...")
    sf = shapefile.Reader(SHP_PATH)
    records = list(zip(sf.iterRecords(), sf.iterShapes()))
    print(f"Shapefile has {len(records)} records")

    # Process shapefile records
    matched = 0
    skipped_non_venice = 0
    skipped_no_match = 0

    for rec, shape in records:
        indirizzo = rec['INDIRIZZO']
        civico_num = rec['CIVICO_NUM'].strip()
        civico_sub = rec['CIVICO_SUB'].strip()

        if not is_venice_address(indirizzo):
            skipped_non_venice += 1
            continue

        street_name = extract_street_name(indirizzo)
        if not street_name:
            continue

        # Build the number key as it appears in our data
        # Handle sub-numbers (e.g., 6/A)
        if civico_sub and civico_sub != '_':
            num_key = f"{civico_num}/{civico_sub}"
        else:
            num_key = civico_num

        # Also try just the base number
        candidates = our_civici.get(num_key, [])
        if not candidates and civico_sub and civico_sub != '_':
            candidates = our_civici.get(civico_num, [])

        if not candidates:
            skipped_no_match += 1
            continue

        # Convert shapefile coordinates to WGS84
        if not shape.points:
            continue
        x, y = shape.points[0]
        lon, lat = transformer.transform(x, y)

        # Find closest match among our civici with same number
        best_code = None
        best_dist = float('inf')

        for code, our_lat, our_lng in candidates:
            dist = haversine_m(lat, lon, our_lat, our_lng)
            if dist < best_dist:
                best_dist = dist
                best_code = code

        # Accept if within 50 meters
        if best_code and best_dist < 50:
            entry = civici[best_code].get(num_key) or civici[best_code].get(civico_num)
            if entry and isinstance(entry, dict) and 'via' not in entry:
                # Title case the street name
                entry['via'] = street_name.title()
                matched += 1

    # Count final stats
    final_via = 0
    for code in civici:
        for num, data in civici[code].items():
            if isinstance(data, dict) and 'via' in data:
                final_via += 1

    print(f"\n=== Results ===")
    print(f"Shapefile records: {len(records)}")
    print(f"Skipped (non-Venice): {skipped_non_venice}")
    print(f"Skipped (no number match): {skipped_no_match}")
    print(f"New street names matched: {matched}")
    print(f"Total with street names: {final_via}/{total_civici} ({100*final_via/total_civici:.1f}%)")

    # Per-sestiere stats
    print(f"\nPer sestiere:")
    for code in ['CN', 'CS', 'DD', 'GD', 'SC', 'SM', 'SP', 'MU', 'BU', 'TO', 'MZ']:
        if code not in civici:
            continue
        total = len(civici[code])
        with_via = sum(1 for v in civici[code].values() if isinstance(v, dict) and 'via' in v)
        print(f"  {code}: {with_via}/{total} ({100*with_via/total:.1f}%)")

    print(f"\nSaving...")
    with open(json_path, 'w') as f:
        json.dump(civici, f, ensure_ascii=False, indent=4)
    print("Done!")


if __name__ == "__main__":
    main()
