#!/usr/bin/env python3
"""
Scraper per le farmacie di turno di Venezia centro storico e isole.
Fonte: Ordine dei Farmacisti della provincia di Venezia (ordinefarmacistivenezia.it)
Licenza dati: ODC-BY 1.0

Questo script:
1. Scarica i turni settimanali dal JSON ufficiale dell'Ordine
2. Incrocia i dati con le coordinate geocodificate da civici.json
3. Produce un farmacie.json con turni aggiornati per l'app DoVe
"""

import json
import re
import os
import sys
from datetime import datetime, timedelta
from html import unescape
from pathlib import Path

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    print("Installing dependencies...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests", "beautifulsoup4"])
    import requests
    from bs4 import BeautifulSoup

BASE_URL = "https://www.ordinefarmacistivenezia.it"
TURNI_URL = f"{BASE_URL}/farmacie-di-turno.html"

# Base directory — works both locally and in CI
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent

# Geocoding data
CIVICI_PATH = REPO_ROOT / "ios" / "DoVe" / "Resources" / "Data" / "civici.json"
ZONE_PATH = REPO_ROOT / "ios" / "DoVe" / "Resources" / "Data" / "zone_normali.json"

# Output paths
DOCS_API_PATH = REPO_ROOT / "docs" / "api" / "farmacie.json"
ANDROID_PATH = REPO_ROOT / "android" / "app" / "src" / "main" / "assets" / "farmacie.json"
IOS_PATH = REPO_ROOT / "ios" / "DoVe" / "Resources" / "Data" / "farmacie.json"

# Sestiere code mapping from address prefixes
SESTIERE_MAP = {
    'cannaregio': 'CN',
    'castello': 'CS',
    'dorsoduro': 'DD',
    'giudecca': 'GD',
    'santa croce': 'SC',
    'san marco': 'SM',
    's.marco': 'SM',
    'san polo': 'SP',
    's.polo': 'SP',
}

ZONA_MAP = {
    'lido': 'LI',
    'murano': 'MU',
    'burano': 'BU',
    'pellestrina': 'PE',
    "sant'erasmo": 'SE',
    'sacca fisola': 'SF',
}

# Standard Italian pharmacy hours (used as default)
STANDARD_HOURS = {
    "weekday": {"open": "8:45", "close": "19:30"},
    "saturday": {"open": "8:45", "close": "12:30"},
    "sunday": None
}

# Known pharmacy data with geocoded coordinates (base registry)
# This is populated from our existing farmacie.json
KNOWN_PHARMACIES = []


def load_geocoding_data():
    """Load civici and zone normali data for geocoding."""
    with open(CIVICI_PATH) as f:
        civici = json.load(f)
    with open(ZONE_PATH) as f:
        zone = json.load(f)
    return civici, zone


def extract_sestiere_and_number(address):
    """Parse sestiere/zona code and civic number from address."""
    addr_lower = address.lower().strip()

    # Try sestiere match
    for prefix, code in SESTIERE_MAP.items():
        if addr_lower.startswith(prefix) or f' {prefix} ' in addr_lower:
            match = re.search(r'n\.?\s*(\d+)', address, re.IGNORECASE)
            if match:
                return code, None, match.group(1)

    # Special cases
    if 'frezzeria' in addr_lower:
        match = re.search(r'n\.?\s*(\d+)', address)
        if match:
            return 'SM', None, match.group(1)

    if 'giudecca' in addr_lower:
        match = re.search(r'n\.?\s*(\d+)', address)
        if match:
            return 'GD', None, match.group(1)

    if 'sacca fisola' in addr_lower:
        match = re.search(r'n\.?\s*(\d+)', address)
        if match:
            return None, 'SF', match.group(1)

    # Try zona match for islands
    for keyword, code in ZONA_MAP.items():
        if keyword in addr_lower:
            match = re.search(r'n\.?\s*(\d+)', address)
            if match:
                return None, code, match.group(1)

    return None, None, None


def geocode(civici, zone, sestiere_code, zona_code, civic_number):
    """Look up coordinates from civici data."""
    if sestiere_code and civic_number:
        sestiere_data = civici.get(sestiere_code, {})
        coords = sestiere_data.get(civic_number)
        if coords:
            return coords['lat'], coords['lng']
        # Try base number without /suffix
        base = civic_number.split('/')[0]
        coords = sestiere_data.get(base)
        if coords:
            return coords['lat'], coords['lng']

    if zona_code and civic_number:
        zona_data = zone.get(zona_code, {})
        for street, numbers in zona_data.items():
            if isinstance(numbers, dict):
                coords = numbers.get(civic_number)
                if coords:
                    return coords['lat'], coords['lng']

    return None, None


def fetch_csrf_token(session):
    """Visit turni page and extract the CSRF token from export links."""
    resp = session.get(TURNI_URL, timeout=30)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, 'html.parser')

    # Find JSON export link
    for a in soup.find_all('a', href=True):
        href = a['href']
        if 'task=export' in href and 'type=json' in href:
            # Extract the CSRF token parameter
            match = re.search(r'([a-f0-9]{32})=1', href)
            if match:
                return match.group(1)

    return None


def fetch_turni_json(session, csrf_token, start_date):
    """Fetch turni JSON export for a given week start date."""
    date_str = start_date.strftime('%Y-%m-%d')
    params = {
        'task': 'export',
        'date': date_str,
        'type': 'json',
    }
    if csrf_token:
        params[csrf_token] = '1'

    resp = session.get(TURNI_URL, params=params, timeout=30)
    resp.raise_for_status()

    data = resp.json()
    return data


def clean_pharmacy_name(name):
    """Clean pharmacy name from HTML entities and normalize."""
    name = unescape(name)
    # Remove common suffixes
    for suffix in [' SRL', ' srl', ' Srl', ' S.R.L.', ' sas', ' SAS', ' Sas',
                   ' s.a.s.', ' snc', ' SNC', ' Snc', ' s.n.c.']:
        name = name.replace(suffix, '')
    # Remove "Farmacia " prefix
    name = re.sub(r'^Farmacia\s+', '', name, flags=re.IGNORECASE)
    # Remove "Comunale " prefix quotes
    name = name.replace('&quot;', '"').replace('"', '')
    return name.strip()


def normalize_phone(phone):
    """Normalize phone number to +39XXXXXXXXXX format."""
    phone = re.sub(r'[^\d+]', '', phone.replace(' ', ''))
    if not phone.startswith('+'):
        phone = '+39' + phone
    return phone


def match_turni_to_pharmacy(shift, known_pharmacies):
    """Match a turno shift entry to a known pharmacy by phone or address."""
    shift_phone = normalize_phone(shift['pharmacy_phone'])

    # Try phone match first (most reliable)
    for p in known_pharmacies:
        if p['phone'] == shift_phone:
            return p

    # Try address match
    shift_addr = shift['pharmacy_address'].lower()
    for p in known_pharmacies:
        p_addr = p['address'].lower()
        # Extract civic numbers
        shift_num = re.search(r'n\.?\s*(\d+)', shift_addr)
        p_num = re.search(r'(\d+)', p_addr)
        if shift_num and p_num and shift_num.group(1) == p_num.group(1):
            # Same civic number, check sestiere
            if p.get('sestiereCode') and p['sestiereCode'].lower()[:2] in shift_addr:
                return p

    return None


def load_known_pharmacies():
    """Load existing pharmacy data (from the last generated file or bundled data)."""
    for path in [DOCS_API_PATH, IOS_PATH, ANDROID_PATH]:
        if path.exists():
            with open(path) as f:
                data = json.load(f)
                if isinstance(data, dict) and 'pharmacies' in data:
                    return data['pharmacies']
                elif isinstance(data, list):
                    return data
    return []


def scrape_pharmacy_registry(session):
    """Scrape base pharmacy data from the farmacie.html registry page."""
    pharmacies = []
    page = 0

    while True:
        params = {'start': page * 20}
        resp = session.get(f"{BASE_URL}/farmacie.html", params=params, timeout=30)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, 'html.parser')

        # Find pharmacy cards/rows
        rows = soup.select('.items-row, .cat-list-row, .item')
        if not rows:
            # Try alternative selectors
            rows = soup.select('[itemprop="itemListElement"], .list-group-item')

        if not rows and page > 0:
            break

        found = 0
        for row in rows:
            name_el = row.select_one('h2 a, h3 a, .item-title a, a')
            if name_el:
                name = name_el.get_text(strip=True)
                if name:
                    pharmacies.append({
                        'name': name,
                        'raw_html': str(row)
                    })
                    found += 1

        if found == 0:
            break

        page += 1
        if page > 20:  # Safety limit
            break

    return pharmacies


def build_pharmacy_from_shift(shift, civici, zone):
    """Create a pharmacy entry from a turno shift when no match is found."""
    name = clean_pharmacy_name(shift['pharmacy_name'])
    address = shift['pharmacy_address']
    phone = normalize_phone(shift['pharmacy_phone'])

    sestiere_code, zona_code, civic_number = extract_sestiere_and_number(address)

    # Determine area from city name
    city = shift.get('pharmacy_city', '').upper()
    if not zona_code:
        city_zona_map = {
            'LIDO DI VENEZIA': 'LI', 'LIDO': 'LI',
            'MURANO': 'MU', 'BURANO': 'BU',
            'PELLESTRINA': 'PE', 'GIUDECCA': 'GD',
        }
        zona_code = city_zona_map.get(city)

    lat, lng = geocode(civici, zone, sestiere_code, zona_code, civic_number)

    # Clean address to just "Sestiere NNNN" format
    clean_addr = address
    if sestiere_code:
        sestiere_names = {
            'CN': 'Cannaregio', 'CS': 'Castello', 'DD': 'Dorsoduro',
            'GD': 'Giudecca', 'SC': 'Santa Croce', 'SM': 'San Marco', 'SP': 'San Polo'
        }
        if civic_number:
            clean_addr = f"{sestiere_names.get(sestiere_code, '')} {civic_number}"

    return {
        'name': name,
        'address': clean_addr,
        'sestiereCode': sestiere_code,
        'zonaCode': zona_code if not sestiere_code else None,
        'phone': phone,
        'lat': lat or 0.0,
        'lng': lng or 0.0,
    }


def main():
    print("=== Scraper Farmacie di Turno - Venezia ===")
    print(f"Data: {datetime.now().strftime('%Y-%m-%d %H:%M')}")

    # Load geocoding data
    print("\nCaricamento dati geocodifica...")
    civici, zone = load_geocoding_data()

    # Load known pharmacies
    print("Caricamento farmacie note...")
    known = load_known_pharmacies()
    print(f"  {len(known)} farmacie note caricate")

    # Create session
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'DoVe-Venice-App/1.0 (github.com/andreatoffanello/civici)',
        'Accept': 'application/json, text/html',
    })

    # Fetch CSRF token
    print("\nFetch token CSRF dalla pagina turni...")
    csrf_token = fetch_csrf_token(session)
    if csrf_token:
        print(f"  Token: {csrf_token[:8]}...")
    else:
        print("  ATTENZIONE: nessun token trovato, provo senza")

    # Fetch turni for current week and next week
    today = datetime.now()
    # Find the start of current week (Thursday, since turni weeks start on Thursday in Venice)
    # Actually, let's just fetch the current date and next week
    current_monday = today - timedelta(days=today.weekday())
    weeks_to_fetch = [
        current_monday - timedelta(days=3),  # Cover any overlap
        current_monday + timedelta(days=4),  # Next week
        current_monday + timedelta(days=11), # Week after
    ]

    all_shifts = []
    seen_urls = set()

    for week_start in weeks_to_fetch:
        date_str = week_start.strftime('%Y-%m-%d')
        if date_str in seen_urls:
            continue
        seen_urls.add(date_str)

        print(f"\nFetch turni settimana {date_str}...")
        try:
            data = fetch_turni_json(session, csrf_token, week_start)
            shifts = data.get('shifts', [])
            # Filter only Venezia e isole
            venice_shifts = [s for s in shifts if s.get('area') == 'Venezia e isole']
            print(f"  {len(venice_shifts)} turni Venezia e isole (su {len(shifts)} totali)")
            all_shifts.extend(venice_shifts)
        except Exception as e:
            print(f"  Errore: {e}")

    if not all_shifts:
        print("\nERRORE: nessun turno trovato!")
        if known:
            print("Uso i dati esistenti senza aggiornare i turni")
        else:
            sys.exit(1)

    # Deduplicate shifts
    shift_key = lambda s: (s['date'], s['pharmacy_phone'].replace(' ', ''))
    unique_shifts = {}
    for s in all_shifts:
        key = shift_key(s)
        unique_shifts[key] = s
    all_shifts = list(unique_shifts.values())
    print(f"\n{len(all_shifts)} turni unici trovati")

    # Build turni per pharmacy (by phone)
    turni_by_phone = {}
    for s in all_shifts:
        phone = normalize_phone(s['pharmacy_phone'])
        if phone not in turni_by_phone:
            turni_by_phone[phone] = {
                'shift_data': s,
                'dates': []
            }
        turni_by_phone[phone]['dates'].append(s['date'])

    # Build final pharmacy list
    # Start with known pharmacies, add turni dates
    pharmacies = []
    matched_phones = set()

    for i, p in enumerate(known):
        entry = dict(p)
        entry['id'] = f"ph_{i+1:02d}"

        # Find turni for this pharmacy
        phone = p.get('phone', '')
        turni_info = turni_by_phone.get(phone)
        if turni_info:
            entry['turpiDates'] = sorted(set(turni_info['dates']))
            matched_phones.add(phone)
        else:
            entry['turpiDates'] = []

        # Add standard hours
        entry['hours'] = STANDARD_HOURS

        pharmacies.append(entry)

    # Add any turno pharmacies not in our known list
    for phone, info in turni_by_phone.items():
        if phone not in matched_phones:
            shift = info['shift_data']
            print(f"\n  Nuova farmacia dai turni: {shift['pharmacy_name']} ({shift['pharmacy_address']})")
            new_pharmacy = build_pharmacy_from_shift(shift, civici, zone)
            new_pharmacy['id'] = f"ph_{len(pharmacies)+1:02d}"
            new_pharmacy['turpiDates'] = sorted(set(info['dates']))
            new_pharmacy['hours'] = STANDARD_HOURS
            pharmacies.append(new_pharmacy)

    # Build output
    output = {
        "lastUpdated": datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
        "source": "Ordine dei Farmacisti della provincia di Venezia",
        "license": "ODC-BY 1.0",
        "pharmacies": pharmacies
    }

    # Write to all output paths
    json_text = json.dumps(output, ensure_ascii=False, indent=2)

    for path in [DOCS_API_PATH, ANDROID_PATH, IOS_PATH]:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, 'w') as f:
            f.write(json_text)
        print(f"\nScritto: {path}")

    # Summary
    with_turni = sum(1 for p in pharmacies if p.get('turpiDates'))
    total_turni_dates = sum(len(p.get('turpiDates', [])) for p in pharmacies)
    geocoded = sum(1 for p in pharmacies if p.get('lat', 0) != 0)

    print(f"\n=== Riepilogo ===")
    print(f"Farmacie totali: {len(pharmacies)}")
    print(f"Geocodificate: {geocoded}")
    print(f"Con turni: {with_turni}")
    print(f"Turni totali: {total_turni_dates}")
    print(f"Ultimo aggiornamento: {output['lastUpdated']}")


if __name__ == '__main__':
    main()
