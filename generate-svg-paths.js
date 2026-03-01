const fs = require('fs');
const path = require('path');

const DIR = path.join(__dirname, 'web/public/data/sestieri');
const NAMES = ['cannaregio', 'castello', 'dorsoduro', 'giudecca', 'sanmarco', 'sanpolo', 'santacroce'];

const WIDTH = 600;
const HEIGHT = 400;
const PADDING = 20;

// Mercator projection
function lonToX(lon) {
  return (lon + 180) / 360;
}
function latToY(lat) {
  const sinLat = Math.sin((lat * Math.PI) / 180);
  return 0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI);
}

// Read all coordinates and compute global bounds
const allCoords = {};

NAMES.forEach(name => {
  const geojson = JSON.parse(fs.readFileSync(path.join(DIR, name + '.json'), 'utf8'));
  const rings = [];
  geojson.features.forEach(feat => {
    const geom = feat.geometry;
    let polygons;
    if (geom.type === 'Polygon') {
      polygons = [geom.coordinates];
    } else if (geom.type === 'MultiPolygon') {
      polygons = geom.coordinates;
    } else {
      return;
    }
    polygons.forEach(poly => {
      poly.forEach(ring => {
        rings.push(ring.map(([lon, lat]) => [lonToX(lon), latToY(lat)]));
      });
    });
  });
  allCoords[name] = rings;
});

// Global bounding box
let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
Object.values(allCoords).forEach(rings => {
  rings.forEach(ring => {
    ring.forEach(([x, y]) => {
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    });
  });
});

const projW = maxX - minX;
const projH = maxY - minY;

// Fit into viewBox with padding, preserving aspect ratio
const availW = WIDTH - 2 * PADDING;
const availH = HEIGHT - 2 * PADDING;
const scale = Math.min(availW / projW, availH / projH);
const offsetX = PADDING + (availW - projW * scale) / 2;
const offsetY = PADDING + (availH - projH * scale) / 2;

function toSVG(px, py) {
  return [
    (px - minX) * scale + offsetX,
    (py - minY) * scale + offsetY,
  ];
}

// Simplify: skip points closer than minDist pixels to the last kept point
function simplifyRing(ring, minDist) {
  if (ring.length < 4) return ring;
  const out = [ring[0]];
  for (let i = 1; i < ring.length - 1; i++) {
    const [lx, ly] = out[out.length - 1];
    const [cx, cy] = ring[i];
    const dx = cx - lx;
    const dy = cy - ly;
    if (dx * dx + dy * dy >= minDist * minDist) {
      out.push(ring[i]);
    }
  }
  out.push(ring[ring.length - 1]);
  return out;
}

// Build SVG path data
const MIN_DIST = 2;
const result = {};

NAMES.forEach(name => {
  const parts = [];
  allCoords[name].forEach(ring => {
    const svgRing = ring.map(([x, y]) => toSVG(x, y));
    const simplified = simplifyRing(svgRing, MIN_DIST);
    if (simplified.length < 3) return;
    const d = simplified.map(([x, y], i) => {
      const cmd = i === 0 ? 'M' : 'L';
      return cmd + x.toFixed(1) + ',' + y.toFixed(1);
    }).join(' ');
    parts.push(d + ' Z');
  });
  result[name] = parts.join(' ');
});

// Stats to stderr
NAMES.forEach(name => {
  const rings = allCoords[name];
  const origPts = rings.reduce((s, r) => s + r.length, 0);
  const svgD = result[name];
  const simplPts = (svgD.match(/[ML]/g) || []).length;
  process.stderr.write(name + ': ' + origPts + ' pts -> ' + simplPts + ' simplified pts\n');
});

console.log(JSON.stringify(result, null, 2));
