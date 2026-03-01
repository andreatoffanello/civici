#!/usr/bin/env python3
"""
Enrich civici.json with street names from OpenStreetMap
and add island data (Murano, Burano, Lido).
"""

import json
import time
import urllib.request
import urllib.parse
import sys
import os
from typing import Optional

OVERPASS_URL = "https://overpass-api.de/api/interpreter"

# Bounding box for Venice centro storico (covers all 6 sestieri + Giudecca)
VENICE_BBOX = "45.42,12.30,45.45,12.37"

# Island bounding boxes
ISLANDS = {
    "MU": {"name": "Murano",  "bbox": "45.45,12.34,45.47,12.36"},
    "BU": {"name": "Burano",  "bbox": "45.482,12.41,45.492,12.425"},
    "LI": {"name": "Lido",    "bbox": "45.37,12.33,45.42,12.40"},
}

# Map OSM addr:place values to our sestiere codes
PLACE_TO_CODE = {
    "san marco": "SM",
    "s. marco": "SM",
    "castello": "CS",
    "cannaregio": "CN",
    "dorsoduro": "DD",
    "san polo": "SP",
    "s. polo": "SP",
    "santa croce": "SC",
    "s. croce": "SC",
    "giudecca": "GD",
    "murano": "MU",
    "burano": "BU",
    "lido": "LI",
    "lido di venezia": "LI",
}


def overpass_query(query: str) -> dict:
    """Execute an Overpass API query and return JSON results."""
    data = urllib.parse.urlencode({"data": query}).encode("utf-8")
    req = urllib.request.Request(OVERPASS_URL, data=data)
    req.add_header("User-Agent", "DoVe-App/1.0")

    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            print(f"  Attempt {attempt+1} failed: {e}")
            if attempt < 2:
                time.sleep(5 * (attempt + 1))

    print(f"  FAILED after 3 attempts")
    return {"elements": []}


def fetch_venice_streets() -> dict:
    """Fetch all house numbers with street names for Venice centro storico."""
    print("Downloading Venice centro storico civici from OSM...")
    query = f"""
    [out:json][timeout:120];
    (
      node["addr:housenumber"](bbox:{VENICE_BBOX});
    );
    out body qt;
    """.replace("bbox:", "")

    # Fix: Overpass uses (south,west,north,east) directly in the filter
    query = f"""
    [out:json][timeout:120];
    (
      node["addr:housenumber"]({VENICE_BBOX});
    );
    out body qt;
    """

    result = overpass_query(query)
    elements = result.get("elements", [])
    print(f"  Got {len(elements)} civici from OSM")
    return result


def fetch_island_civici(code: str, info: dict) -> dict:
    """Fetch all house numbers for an island."""
    print(f"Downloading {info['name']} civici from OSM...")
    query = f"""
    [out:json][timeout:120];
    (
      node["addr:housenumber"]({info['bbox']});
    );
    out body qt;
    """
    result = overpass_query(query)
    elements = result.get("elements", [])
    print(f"  Got {len(elements)} civici for {info['name']}")
    return result


def resolve_sestiere(tags: dict, lat: float, lon: float) -> Optional[str]:
    """Determine sestiere code from OSM tags or coordinates."""
    # Try addr:place first
    place = tags.get("addr:place", "").lower().strip()
    if place in PLACE_TO_CODE:
        return PLACE_TO_CODE[place]

    # Try addr:suburb
    suburb = tags.get("addr:suburb", "").lower().strip()
    if suburb in PLACE_TO_CODE:
        return PLACE_TO_CODE[suburb]

    # Try addr:hamlet (used in Burano)
    hamlet = tags.get("addr:hamlet", "").lower().strip()
    if hamlet in PLACE_TO_CODE:
        return PLACE_TO_CODE[hamlet]

    return None


def get_street_name(tags: dict) -> Optional[str]:
    """Extract street name from OSM tags."""
    street = tags.get("addr:street", "").strip()
    if street:
        return street
    return None


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    json_path = os.path.join(project_root, "ios", "DoVe", "Resources", "Data", "civici.json")

    # Load existing data
    print(f"Loading {json_path}...")
    with open(json_path, "r") as f:
        civici = json.load(f)

    # Count existing entries
    total_existing = sum(len(v) for v in civici.values())
    print(f"Existing: {total_existing} civici across {list(civici.keys())}")

    # Phase 1: Enrich existing sestieri with street names from OSM
    print("\n=== Phase 1: Enriching with street names ===")
    time.sleep(2)  # Be nice to Overpass
    osm_venice = fetch_venice_streets()

    # Build lookup: (sestiere_code, number) -> street_name
    street_lookup = {}
    unmatched_sestiere = 0

    for elem in osm_venice.get("elements", []):
        tags = elem.get("tags", {})
        number = tags.get("addr:housenumber", "").strip()
        if not number:
            continue

        code = resolve_sestiere(tags, elem.get("lat", 0), elem.get("lon", 0))
        street = get_street_name(tags)

        if code and street and code in civici:
            key = (code, number)
            if key not in street_lookup:
                street_lookup[key] = street

    print(f"  Found {len(street_lookup)} street name matches")

    # Apply street names to existing data
    enriched = 0
    for code, numbers in civici.items():
        for number, data in numbers.items():
            key = (code, number)
            if key in street_lookup:
                if isinstance(data, dict) and "lat" in data:
                    data["via"] = street_lookup[key]
                    enriched += 1

    print(f"  Enriched {enriched} civici with street names")

    # Phase 2: Add island data
    print("\n=== Phase 2: Adding islands ===")

    for code, info in ISLANDS.items():
        time.sleep(3)  # Be nice to Overpass
        osm_data = fetch_island_civici(code, info)

        island_civici = {}
        for elem in osm_data.get("elements", []):
            tags = elem.get("tags", {})
            number = tags.get("addr:housenumber", "").strip()
            if not number:
                continue

            lat = elem.get("lat")
            lon = elem.get("lon")
            if not lat or not lon:
                continue

            entry = {
                "lat": round(lat, 6),
                "lng": round(lon, 6)
            }

            street = get_street_name(tags)
            if street:
                entry["via"] = street

            # Avoid duplicates - keep first occurrence
            if number not in island_civici:
                island_civici[number] = entry

        if island_civici:
            civici[code] = island_civici
            print(f"  Added {len(island_civici)} civici for {info['name']} ({code})")

    # Save enriched data
    total_new = sum(len(v) for v in civici.values())
    print(f"\n=== Summary ===")
    print(f"Before: {total_existing} civici")
    print(f"After:  {total_new} civici")
    print(f"Street names added: {enriched}")
    print(f"Sestieri/islands: {list(civici.keys())}")

    print(f"\nSaving to {json_path}...")
    with open(json_path, "w") as f:
        json.dump(civici, f, ensure_ascii=False, indent=4)

    print("Done!")


if __name__ == "__main__":
    main()
