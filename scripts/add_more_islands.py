#!/usr/bin/env python3
"""Add Torcello, Sant'Erasmo, Vignole, Certosa to civici.json."""

import json
import time
import urllib.request
import urllib.parse
import os

OVERPASS_URL = "https://overpass-api.de/api/interpreter"

ISLANDS = {
    "TO": {"name": "Torcello",     "bbox": "45.495,12.41,45.51,12.44"},
    "SE": {"name": "Sant'Erasmo",  "bbox": "45.44,12.37,45.47,12.42"},
}


def overpass_query(query):
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
    return {"elements": []}


def main():
    json_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                             "ios", "DoVe", "Resources", "Data", "civici.json")

    with open(json_path, "r") as f:
        civici = json.load(f)

    total_before = sum(len(v) for v in civici.values())
    print(f"Current: {total_before} civici, zones: {list(civici.keys())}")

    for code, info in ISLANDS.items():
        time.sleep(3)
        print(f"\nDownloading {info['name']}...")
        query = f"""[out:json][timeout:120];(node["addr:housenumber"]({info['bbox']}););out body qt;"""
        result = overpass_query(query)

        island_civici = {}
        for elem in result.get("elements", []):
            tags = elem.get("tags", {})
            number = tags.get("addr:housenumber", "").strip()
            lat = elem.get("lat")
            lon = elem.get("lon")
            if not number or not lat or not lon:
                continue

            entry = {"lat": round(lat, 6), "lng": round(lon, 6)}
            street = tags.get("addr:street", "").strip()
            if street:
                entry["via"] = street

            # For Sant'Erasmo bbox, separate by addr:place/hamlet
            place = (tags.get("addr:place", "") or tags.get("addr:hamlet", "")).lower().strip()

            if code == "SE":
                # This bbox covers Sant'Erasmo, Vignole, Certosa, and La Vignole
                if "vignole" in place or "la vignole" in place:
                    sub_code = "VI"
                elif "certosa" in place:
                    sub_code = "CE"
                else:
                    sub_code = "SE"

                if sub_code not in civici:
                    civici[sub_code] = {}
                if number not in civici[sub_code]:
                    civici[sub_code][number] = entry
            else:
                if number not in island_civici:
                    island_civici[number] = entry

        if code != "SE" and island_civici:
            civici[code] = island_civici
            print(f"  Added {len(island_civici)} civici for {info['name']} ({code})")

    # Print stats for SE sub-islands
    for sub in ["SE", "VI", "CE"]:
        if sub in civici:
            print(f"  {sub}: {len(civici[sub])} civici")

    total_after = sum(len(v) for v in civici.values())
    print(f"\nBefore: {total_before}, After: {total_after}")
    print(f"Zones: {list(civici.keys())}")

    with open(json_path, "w") as f:
        json.dump(civici, f, ensure_ascii=False, indent=4)
    print("Saved!")


if __name__ == "__main__":
    main()
