#!/usr/bin/env python3
"""
Converte i dati GTFS ufficiali ACTV + Alilaguna in un JSON ottimizzato
per l'app DoVe — tabellone partenze vaporetti a Venezia.

Fonti:
- ACTV navigazione: https://actv.avmspa.it/sites/default/files/attachments/opendata/navigazione/actv_nav.zip
- Alilaguna: http://www.alilaguna.it/attuale/alilaguna.zip

Output: vaporetti.json con fermate, linee e orari per giorno della settimana.
"""

from __future__ import annotations

import csv
import io
import json
import os
import ssl
import sys
import zipfile
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from urllib.request import urlopen, Request

# --- Config ---

ACTV_URL = "https://actv.avmspa.it/sites/default/files/attachments/opendata/navigazione/actv_nav.zip"
ALILAGUNA_URL = "http://www.alilaguna.it/attuale/alilaguna.zip"

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent

DOCS_API_PATH = REPO_ROOT / "docs" / "api" / "vaporetti.json"
IOS_PATH = REPO_ROOT / "ios" / "DoVe" / "Resources" / "Data" / "vaporetti.json"

# Fermate "deposito" o "a richiesta" da escludere
EXCLUDE_PATTERNS = ["Deposito", "A RICHIESTA", "A RICHIEST", "Capannone"]



def download_gtfs(url: str) -> dict[str, list[dict]]:
    """Scarica e parsa un file GTFS zip in memoria."""
    print(f"  Scaricando {url}...")
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    # Follow redirects (urllib doesn't handle 308 automatically)
    max_redirects = 5
    current_url = url
    for _ in range(max_redirects):
        req = Request(current_url, headers={"User-Agent": "DoVe-App/1.0"})
        try:
            resp = urlopen(req, timeout=30, context=ctx)
            break
        except __import__('urllib').error.HTTPError as e:
            if e.code in (301, 302, 307, 308) and e.headers.get("Location"):
                current_url = e.headers["Location"]
                print(f"  Redirect → {current_url}")
            else:
                raise
    else:
        raise RuntimeError(f"Too many redirects for {url}")

    data = resp.read()
    print(f"  Scaricato: {len(data) / 1024:.0f} KB")

    result = {}
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        for name in zf.namelist():
            if name.endswith(".txt"):
                key = name.replace(".txt", "")
                with zf.open(name) as f:
                    text = f.read().decode("utf-8-sig")
                    reader = csv.DictReader(io.StringIO(text))
                    result[key] = list(reader)
    return result


def clean_stop_name(name: str) -> str:
    """Pulisce il nome fermata: rimuove virgolette CSV rotte."""
    return name.strip().strip('"').strip()


def is_excluded(name: str) -> bool:
    """Verifica se la fermata va esclusa (depositi, a richiesta)."""
    return any(p.lower() in name.lower() for p in EXCLUDE_PATTERNS)


def parse_time(t: str) -> tuple[int, int] | None:
    """Parsa orario GTFS (HH:MM:SS) in (ore, minuti). Gestisce ore > 24."""
    if not t or not t.strip():
        return None
    parts = t.strip().split(":")
    if len(parts) < 2:
        return None
    return int(parts[0]), int(parts[1])


def time_to_minutes(h: int, m: int) -> int:
    """Converte ore:minuti in minuti dalla mezzanotte."""
    return h * 60 + m


def format_time(h: int, m: int) -> str:
    """Formatta orario per display. Gestisce ore > 24 (servizio notturno)."""
    display_h = h % 24
    return f"{display_h:02d}:{m:02d}"


def build_service_day_map(calendar: list[dict]) -> dict[str, set[int]]:
    """
    Mappa service_id → set di giorni della settimana (0=lun, 6=dom).
    """
    day_fields = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    result = {}
    for row in calendar:
        sid = row["service_id"]
        days = set()
        for i, field in enumerate(day_fields):
            if row.get(field, "0") == "1":
                days.add(i)
        result[sid] = days
    return result


def _extract_base_name(name: str) -> str:
    """
    Estrae il nome base di una fermata, rimuovendo la lettera del pontile.
    'Rialto "A' → 'Rialto'
    'F.te Nove "D' → 'F.te Nove'
    'S. Giorgio' → 'S. Giorgio' (invariato)
    """
    import re
    # Pattern: nome seguito da spazio e "lettera o "lettera"
    m = re.match(r'^(.+?)\s*"[A-Z]"?\s*$', name)
    if m:
        return m.group(1).strip()
    return name


def _extract_dock_letter(name: str) -> str:
    """
    Estrae la lettera del pontile dal nome fermata.
    'Rialto "A' → 'A'
    'F.te Nove "D' → 'D'
    'S. Giorgio' → '' (nessun pontile)
    """
    import re
    m = re.match(r'^.+?\s*"([A-Z])"?\s*$', name)
    return m.group(1) if m else ""


def parse_stops(stops_raw: list[dict], source: str) -> tuple[dict, dict]:
    """
    Parsa le fermate GTFS, raggruppando automaticamente i pontili
    per nome base (es. Rialto "A", "B", "C", "D" → Rialto).
    """
    stations = {}
    children = defaultdict(list)
    all_stops_info = []

    for s in stops_raw:
        stop_id = s["stop_id"].strip()
        name = clean_stop_name(s["stop_name"])
        lat = float(s["stop_lat"]) if s.get("stop_lat") else 0.0
        lng = float(s["stop_lon"]) if s.get("stop_lon") else 0.0
        parent = s.get("parent_station", "").strip()

        if is_excluded(name):
            continue

        all_stops_info.append({
            "id": stop_id, "name": name, "lat": lat, "lng": lng, "parent": parent,
        })

        if parent:
            children[parent].append(stop_id)

    # Build index for child info
    child_info = {si["id"]: si for si in all_stops_info}

    # Prima: gestisci parent_station esplicito (Alilaguna)
    for si in all_stops_info:
        if not si["parent"]:
            # Potrebbe essere una stazione madre (con figli) o fermata singola
            sid = si["id"]
            if sid in [c for cs in children.values() for c in cs]:
                continue  # È un figlio elencato altrove, skip

            # Per-pontile dock info
            docks_info = {}
            for child_id in children.get(sid, []):
                ci = child_info.get(child_id)
                if ci:
                    letter = _extract_dock_letter(ci["name"])
                    if letter:
                        docks_info[child_id] = {"letter": letter, "lat": ci["lat"], "lng": ci["lng"]}

            stations[sid] = {
                "id": sid,
                "name": si["name"],
                "lat": si["lat"],
                "lng": si["lng"],
                "source": source,
                "pontili": children.get(sid, [sid]),
                "docks_info": docks_info,
            }

    # Se non ci sono parent (ACTV), raggruppa per nome base
    has_parents = any(si["parent"] for si in all_stops_info)
    if not has_parents:
        # Raggruppa per nome base
        base_groups = defaultdict(list)
        for si in all_stops_info:
            if is_excluded(si["name"]):
                continue
            base = _extract_base_name(si["name"])
            base_groups[base].append(si)

        stations = {}
        for base_name, group in base_groups.items():
            # Usa il primo come rappresentante
            rep = group[0]
            # Coordinate: media dei pontili
            avg_lat = sum(s["lat"] for s in group) / len(group)
            avg_lng = sum(s["lng"] for s in group) / len(group)
            station_id = f"actv_{base_name.replace(' ', '_').replace('.', '').lower()}"

            # Per-pontile dock info (letter + coordinates)
            docks_info = {}
            for s in group:
                letter = _extract_dock_letter(s["name"])
                if letter:
                    docks_info[s["id"]] = {"letter": letter, "lat": s["lat"], "lng": s["lng"]}

            stations[station_id] = {
                "id": station_id,
                "name": base_name,
                "lat": round(avg_lat, 6),
                "lng": round(avg_lng, 6),
                "source": source,
                "pontili": [s["id"] for s in group],
                "docks_info": docks_info,
            }

    # Build stop_to_station mapping
    stop_to_station = {}
    for sid, st in stations.items():
        for p in st["pontili"]:
            stop_to_station[p] = sid
        stop_to_station[sid] = sid

    return stations, stop_to_station


def build_departures(
    stop_times: list[dict],
    trips: list[dict],
    routes: list[dict],
    service_day_map: dict[str, set[int]],
    valid_stop_ids: set[str],
    source: str,
) -> dict:
    """
    Costruisce le partenze per fermata, raggruppate per giorno e linea.

    Ritorna: {stop_id: {day_index: [{line, headsign, time, minutes}]}}
    """
    # Index trips by trip_id
    trip_index = {}
    for t in trips:
        trip_index[t["trip_id"]] = t

    # Index routes by route_id
    route_index = {}
    for r in routes:
        route_index[r["route_id"]] = r

    # Raccogli partenze per stop
    departures = defaultdict(lambda: defaultdict(list))

    for st in stop_times:
        stop_id = st["stop_id"].strip()
        if stop_id not in valid_stop_ids:
            continue

        trip_id = st["trip_id"].strip()
        trip = trip_index.get(trip_id)
        if not trip:
            continue

        dep_time = parse_time(st.get("departure_time", ""))
        if not dep_time:
            continue

        route_id = trip["route_id"]
        route = route_index.get(route_id, {})
        service_id = trip["service_id"]
        days = service_day_map.get(service_id, set())

        line_name = route.get("route_short_name", route_id).strip()
        headsign = trip.get("trip_headsign", "").strip().strip('"')
        color = route.get("route_color", "000000").strip()
        text_color = route.get("route_text_color", "FFFFFF").strip()

        h, m = dep_time
        minutes = time_to_minutes(h, m)
        time_str = format_time(h, m)

        dep_entry = {
            "line": line_name,
            "headsign": headsign,
            "time": time_str,
            "minutes": minutes,
            "color": f"#{color}" if not color.startswith("#") else color,
            "textColor": f"#{text_color}" if not text_color.startswith("#") else text_color,
            "source": source,
            "tripId": trip_id,
        }

        for day in days:
            departures[stop_id][day].append(dep_entry)

    # Ordina per orario
    for stop_id in departures:
        for day in departures[stop_id]:
            departures[stop_id][day].sort(key=lambda d: d["minutes"])

    return departures


def _haversine_m(lat1, lng1, lat2, lng2):
    """Distanza approssimata in metri tra due punti."""
    from math import radians, sin, cos, sqrt, atan2
    R = 6371000
    dlat = radians(lat2 - lat1)
    dlng = radians(lng2 - lng1)
    a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng/2)**2
    return R * 2 * atan2(sqrt(a), sqrt(1-a))


def _normalize_name(name: str) -> str:
    """Normalizza nome fermata per matching."""
    n = name.lower().replace('"', '').replace("'", "").replace(".", "").strip()
    # Rimuovi lettere pontile alla fine: "rialto a" → "rialto"
    parts = n.rsplit(" ", 1)
    if len(parts) == 2 and len(parts[1]) == 1 and parts[1].isalpha():
        n = parts[0]
    # Alias comuni
    n = n.replace("s. marco-san zaccaria", "s zaccaria")
    n = n.replace("s zaccaria", "s zaccaria")
    n = n.replace("fte nove", "f.te nove").replace("f.te nove", "fondamente nove")
    n = n.replace("lido (sme)", "lido sme").replace("lido sme", "lido santa maria elisabetta")
    return n


def merge_stations(
    actv_stations: dict, ali_stations: dict,
    actv_s2s: dict, ali_s2s: dict,
) -> tuple[list[dict], dict]:
    """
    Unisce le fermate ACTV e Alilaguna per prossimità geografica (< 300m).
    Ritorna (stations_list, merged_stop_to_station).
    """
    MERGE_RADIUS_M = 300

    merged = dict(actv_stations)
    merged_s2s = dict(actv_s2s)

    for ali_id, ali_st in ali_stations.items():
        # Cerca la stazione ACTV più vicina
        best_match = None
        best_dist = MERGE_RADIUS_M + 1

        for actv_id, actv_st in merged.items():
            if actv_st["source"] != "actv":
                continue
            dist = _haversine_m(ali_st["lat"], ali_st["lng"], actv_st["lat"], actv_st["lng"])
            if dist < best_dist:
                best_dist = dist
                best_match = actv_id

        if best_match and best_dist <= MERGE_RADIUS_M:
            # Unisci pontili Alilaguna nella stazione ACTV
            existing = merged[best_match]
            for p in ali_st["pontili"]:
                if p not in existing["pontili"]:
                    existing["pontili"].append(p)
                    merged_s2s[p] = best_match
            # Merge docks_info
            if "docks_info" not in existing:
                existing["docks_info"] = {}
            existing["docks_info"].update(ali_st.get("docks_info", {}))
        else:
            # Fermata solo Alilaguna
            merged[ali_id] = ali_st
            for p in ali_st["pontili"]:
                merged_s2s[p] = ali_id

    return list(merged.values()), merged_s2s


def merge_departures(actv_deps: dict, ali_deps: dict) -> dict:
    """Unisce le partenze ACTV e Alilaguna per stop_id."""
    merged = defaultdict(lambda: defaultdict(list))

    for deps in [actv_deps, ali_deps]:
        for stop_id, days in deps.items():
            for day, entries in days.items():
                merged[stop_id][day].extend(entries)

    # Ri-ordina
    for stop_id in merged:
        for day in merged[stop_id]:
            merged[stop_id][day].sort(key=lambda d: d["minutes"])

    return merged


def parse_shapes(shapes_raw: list[dict]) -> dict[str, list[list[float]]]:
    """
    Parsa shapes.txt GTFS in un dizionario shape_id → [[lat, lng], ...].
    Coordinate ordinate per shape_pt_sequence.
    """
    shape_points = defaultdict(list)
    for row in shapes_raw:
        sid = row["shape_id"].strip()
        seq = int(row["shape_pt_sequence"])
        lat = float(row["shape_pt_lat"])
        lon = float(row["shape_pt_lon"])
        shape_points[sid].append((seq, [round(lat, 6), round(lon, 6)]))

    result = {}
    for sid, points in shape_points.items():
        points.sort(key=lambda x: x[0])
        result[sid] = [p[1] for p in points]
    return result


def build_route_directions(
    routes_raw: list[dict],
    trips_raw: list[dict],
    stop_times_raw: list[dict],
    shapes: dict[str, list[list[float]]],
    stop_to_station: dict[str, str],
    stations: dict[str, dict],
    source: str,
) -> dict[str, list[dict]]:
    """
    Per ogni route, costruisce le directions (andata/ritorno) con:
    - headsign
    - stopIds (ordinati, mappati a station ID)
    - shape (coordinate polyline)
    """
    # Index trips by route_id and direction
    route_trips = defaultdict(lambda: defaultdict(list))
    for t in trips_raw:
        rid = t["route_id"].strip()
        direction = int(t.get("direction_id", 0))
        route_trips[rid][direction].append(t)

    # Index stop_times by trip_id
    trip_stop_times = defaultdict(list)
    for st in stop_times_raw:
        tid = st["trip_id"].strip()
        trip_stop_times[tid].append(st)

    result = {}
    for r in routes_raw:
        route_id = r["route_id"].strip()
        directions = []

        for direction_id in sorted(route_trips.get(route_id, {}).keys()):
            trips = route_trips[route_id][direction_id]
            if not trips:
                continue

            # Pick trip with most stops as representative
            best_trip = None
            best_count = 0
            for t in trips[:20]:  # Check first 20 trips
                tid = t["trip_id"]
                count = len(trip_stop_times.get(tid, []))
                if count > best_count:
                    best_count = count
                    best_trip = t

            if not best_trip:
                continue

            trip_id = best_trip["trip_id"]
            headsign = best_trip.get("trip_headsign", "").strip().strip('"')
            shape_id = best_trip.get("shape_id", "").strip()

            # Get ordered stops for this trip
            stops_for_trip = trip_stop_times.get(trip_id, [])
            stops_for_trip.sort(key=lambda x: int(x.get("stop_sequence", 0)))

            # Map pontile stop_ids to station IDs, dedup keeping order
            ordered_station_ids = []
            seen = set()
            for st in stops_for_trip:
                stop_id = st["stop_id"].strip()
                station_id = stop_to_station.get(stop_id)
                if station_id and station_id not in seen:
                    seen.add(station_id)
                    ordered_station_ids.append(station_id)

            # Get shape coordinates
            shape_coords = shapes.get(shape_id, [])

            # If no shape (e.g. Alilaguna), generate from station coordinates
            if not shape_coords and ordered_station_ids:
                shape_coords = []
                for sid in ordered_station_ids:
                    st = stations.get(sid)
                    if st:
                        shape_coords.append([round(st["lat"], 6), round(st["lng"], 6)])

            if ordered_station_ids:
                directions.append({
                    "id": direction_id,
                    "headsign": headsign,
                    "stopIds": ordered_station_ids,
                    "shape": shape_coords,
                })

        if directions:
            result[route_id] = directions

    return result


def build_routes_list(
    actv_routes: list[dict], ali_routes: list[dict],
    actv_directions: dict = None, ali_directions: dict = None,
) -> list[dict]:
    """Costruisce la lista di tutte le linee con directions."""
    if actv_directions is None:
        actv_directions = {}
    if ali_directions is None:
        ali_directions = {}

    routes = []
    for r in actv_routes + ali_routes:
        route_id = r["route_id"].strip()
        name = r.get("route_short_name", route_id).strip()
        color = r.get("route_color", "000000").strip()
        text_color = r.get("route_text_color", "FFFFFF").strip()
        source = "alilaguna" if r.get("agency_id") == "ALILAGUNA" else "actv"

        all_dirs = actv_directions if source == "actv" else ali_directions
        directions = all_dirs.get(route_id, [])

        routes.append({
            "id": route_id,
            "name": name,
            "longName": r.get("route_long_name", "").strip().strip('"'),
            "color": f"#{color}" if not color.startswith("#") else color,
            "textColor": f"#{text_color}" if not text_color.startswith("#") else text_color,
            "source": source,
            "directions": directions,
        })
    return routes


def build_stop_departures(
    station: dict, all_departures: dict, pontile_to_station: dict
) -> dict[str, list[list]]:
    """
    Raccoglie tutte le partenze per una stazione (da tutti i suoi pontili).
    Formato compatto: ogni partenza = ["HH:MM", "linea", "direzione"]
    Giorni identici vengono raggruppati: "mon,tue,wed,thu,fri" → unica lista.
    """
    DAY_NAMES = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

    collected = defaultdict(list)
    for pontile in station["pontili"]:
        if pontile in all_departures:
            for day_idx, deps in all_departures[pontile].items():
                collected[day_idx].extend(deps)

    # Anche la stazione stessa potrebbe avere partenze (se non ha figli)
    station_id = station["id"]
    if station_id in all_departures:
        for day_idx, deps in all_departures[station_id].items():
            collected[day_idx].extend(deps)

    # Deduplica, ordina, compatta
    per_day = {}
    for day_idx in range(7):
        deps = collected.get(day_idx, [])
        seen = set()
        unique = []
        for d in deps:
            key = (d["line"], d["time"], d["headsign"])
            if key not in seen:
                seen.add(key)
                unique.append(d)
        unique.sort(key=lambda d: d["minutes"])
        # Formato compatto: ["HH:MM", "linea", "direzione", "tripId"]
        compact = [[d["time"], d["line"], d["headsign"], d["tripId"]] for d in unique]
        if compact:
            per_day[day_idx] = compact

    # Raggruppa giorni con orari identici
    result = {}
    used = set()
    for day_idx in range(7):
        if day_idx in used or day_idx not in per_day:
            continue
        same_days = [day_idx]
        for other in range(day_idx + 1, 7):
            if other not in used and other in per_day:
                if per_day[day_idx] == per_day[other]:
                    same_days.append(other)
        for d in same_days:
            used.add(d)
        key = ",".join(DAY_NAMES[d] for d in same_days)
        result[key] = per_day[day_idx]

    return result


def build_trips(
    actv_feed: dict, ali_feed: dict,
    stop_to_station: dict[str, str],
) -> dict[str, list[list]]:
    """
    Costruisce i trip: per ogni trip_id, la lista ordinata di [stationId, "HH:MM", "dock"].
    Deduplica stazioni consecutive (pontili diversi della stessa stazione).
    """
    trips = {}

    for feed in [actv_feed, ali_feed]:
        # Build stop_id → dock letter mapping from stops.txt
        stop_dock = {}
        for s in feed.get("stops", []):
            sid = s["stop_id"].strip()
            name = clean_stop_name(s["stop_name"])
            dock = _extract_dock_letter(name)
            if dock:
                stop_dock[sid] = dock

        # Index stop_times by trip_id
        trip_stops = defaultdict(list)
        for st in feed.get("stop_times", []):
            tid = st["trip_id"].strip()
            seq = int(st.get("stop_sequence", 0))
            dep_time = parse_time(st.get("departure_time", ""))
            stop_id = st["stop_id"].strip()
            station_id = stop_to_station.get(stop_id)
            if dep_time and station_id:
                h, m = dep_time
                dock = stop_dock.get(stop_id, "")
                trip_stops[tid].append((seq, station_id, format_time(h, m), dock))

        for tid, stops in trip_stops.items():
            stops.sort(key=lambda x: x[0])
            # Dedup consecutive same station (keep first dock)
            compact = []
            prev_sid = None
            for _, sid, time_str, dock in stops:
                if sid != prev_sid:
                    compact.append([sid, time_str, dock])
                    prev_sid = sid
            if compact:
                trips[tid] = compact

    return trips


def build_output(
    stations: list[dict],
    all_departures: dict,
    routes: list[dict],
    trips: dict[str, list[list]],
    actv_feed: dict,
    ali_feed: dict,
) -> dict:
    """Costruisce il JSON finale ottimizzato per l'app."""

    # Mappa pontile → station ID per aggregare partenze
    pontile_to_station = {}
    for st in stations:
        for p in st["pontili"]:
            pontile_to_station[p] = st["id"]

    stops_output = []
    for st in stations:
        departures = build_stop_departures(st, all_departures, pontile_to_station)

        # Calcola le linee che servono questa fermata (formato compatto: [time, line, headsign])
        lines_serving = set()
        for day_deps in departures.values():
            for d in day_deps:
                lines_serving.add(d[1])

        # Skip fermate senza partenze
        if not departures:
            continue

        # Build per-dock info with lines (merge same-letter docks nearby)
        dock_by_letter: dict[str, dict] = {}
        for pontile_id, dock_info in st.get("docks_info", {}).items():
            dock_lines = set()
            if pontile_id in all_departures:
                for day_deps in all_departures[pontile_id].values():
                    for d in day_deps:
                        dock_lines.add(d["line"])
            if not dock_lines:
                continue
            letter = dock_info["letter"]
            if letter in dock_by_letter:
                # Merge lines into existing dock with same letter
                dock_by_letter[letter]["lines"].update(dock_lines)
            else:
                dock_by_letter[letter] = {
                    "letter": letter,
                    "lat": dock_info["lat"],
                    "lng": dock_info["lng"],
                    "lines": dock_lines,
                }
        docks_output = [
            {**d, "lines": sorted(d["lines"])}
            for d in sorted(dock_by_letter.values(), key=lambda d: d["letter"])
        ]

        stop_entry = {
            "id": st["id"],
            "name": st["name"],
            "lat": st["lat"],
            "lng": st["lng"],
            "lines": sorted(lines_serving),
            "departures": departures,
        }
        if docks_output:
            stop_entry["docks"] = docks_output

        stops_output.append(stop_entry)

    # Ordina fermate per nome
    stops_output.sort(key=lambda s: s["name"])

    # Validity range
    actv_feed_info = actv_feed.get("feed_info", [{}])
    ali_feed_info = ali_feed.get("feed_info", [{}])

    actv_end = actv_feed_info[0].get("feed_end_date", "") if actv_feed_info else ""
    ali_end = ali_feed_info[0].get("feed_end_date", "") if ali_feed_info else ""

    # Filtra solo i trip referenziati dalle partenze
    referenced_trips = set()
    for s in stops_output:
        for day_deps in s["departures"].values():
            for d in day_deps:
                if len(d) >= 4:
                    referenced_trips.add(d[3])
    filtered_trips = {tid: stops for tid, stops in trips.items() if tid in referenced_trips}

    return {
        "lastUpdated": datetime.now(tz=__import__('datetime').timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "trips": filtered_trips,
        "sources": {
            "actv": {
                "name": "ACTV S.p.A. — Navigazione",
                "url": ACTV_URL,
                "license": "Open Data",
                "validUntil": actv_end,
            },
            "alilaguna": {
                "name": "Alilaguna S.p.A.",
                "url": ALILAGUNA_URL,
                "license": "Open Data",
                "validUntil": ali_end,
            },
        },
        "routes": routes,
        "stops": stops_output,
    }


def main():
    print("=== DoVe Vaporetti — GTFS → JSON ===\n")

    # 1. Scarica GTFS
    print("[1/5] Scaricando GTFS ACTV navigazione...")
    actv = download_gtfs(ACTV_URL)

    print("[2/5] Scaricando GTFS Alilaguna...")
    ali = download_gtfs(ALILAGUNA_URL)

    # 2. Parsa calendario
    print("[3/5] Processando dati...")
    actv_service_days = build_service_day_map(actv.get("calendar", []))
    ali_service_days = build_service_day_map(ali.get("calendar", []))

    # 3. Parsa fermate
    actv_stations, actv_s2s = parse_stops(actv.get("stops", []), "actv")
    ali_stations, ali_s2s = parse_stops(ali.get("stops", []), "alilaguna")

    # Raccogli tutti gli stop_id validi (pontili + stazioni)
    actv_valid_stops = set(actv_s2s.keys())
    ali_valid_stops = set(ali_s2s.keys())

    # 4. Costruisci partenze
    actv_departures = build_departures(
        actv.get("stop_times", []),
        actv.get("trips", []),
        actv.get("routes", []),
        actv_service_days,
        actv_valid_stops,
        "actv",
    )
    ali_departures = build_departures(
        ali.get("stop_times", []),
        ali.get("trips", []),
        ali.get("routes", []),
        ali_service_days,
        ali_valid_stops,
        "alilaguna",
    )

    # 5. Unisci stazioni e partenze
    stations, merged_s2s = merge_stations(actv_stations, ali_stations, actv_s2s, ali_s2s)
    all_departures = merge_departures(actv_departures, ali_departures)

    # 5b. Parsa shapes e costruisci directions per route
    actv_shapes = parse_shapes(actv.get("shapes", []))
    ali_shapes = parse_shapes(ali.get("shapes", []))

    # Merged station dict for lookups
    stations_dict = {s["id"]: s for s in stations}

    actv_directions = build_route_directions(
        actv.get("routes", []),
        actv.get("trips", []),
        actv.get("stop_times", []),
        actv_shapes,
        merged_s2s,
        stations_dict,
        "actv",
    )
    ali_directions = build_route_directions(
        ali.get("routes", []),
        ali.get("trips", []),
        ali.get("stop_times", []),
        ali_shapes,
        merged_s2s,
        stations_dict,
        "alilaguna",
    )

    routes = build_routes_list(
        actv.get("routes", []), ali.get("routes", []),
        actv_directions, ali_directions,
    )

    print(f"  Fermate: {len(stations)}")
    print(f"  Linee: {len(routes)}")

    # 5c. Costruisci trips
    all_trips = build_trips(actv, ali, merged_s2s)
    print(f"  Trips: {len(all_trips)}")

    # 6. Costruisci output
    print("[4/5] Costruendo JSON...")
    output = build_output(stations, all_departures, routes, all_trips, actv, ali)

    print(f"  Fermate con partenze: {len(output['stops'])}")
    total_deps = sum(
        sum(len(deps) for deps in s["departures"].values())
        for s in output["stops"]
    )
    print(f"  Partenze totali: {total_deps}")

    # 7. Salva
    print("[5/5] Salvando file...")

    for path in [DOCS_API_PATH, IOS_PATH]:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(output, f, ensure_ascii=False, separators=(",", ":"))
        size_kb = path.stat().st_size / 1024
        print(f"  {path.relative_to(REPO_ROOT)} ({size_kb:.0f} KB)")

    print(f"\nFatto! {len(output['stops'])} fermate, {len(output['routes'])} linee.")


if __name__ == "__main__":
    main()
