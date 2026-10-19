import fs from "node:fs";

export class Font {
  constructor(path, index = 0) {
    const b = (this.buf = fs.readFileSync(path));
    let base = 0;
    if (b.toString("latin1", 0, 4) === "ttcf") {
      const num = b.readUInt32BE(8);
      base = b.readUInt32BE(12 + 4 * Math.min(index, num - 1));
    }
    this.base = base;
    const numTables = b.readUInt16BE(base + 4);
    this.tables = {};
    for (let i = 0; i < numTables; i++) {
      const off = base + 12 + i * 16;
      const tag = b.toString("latin1", off, off + 4);
      this.tables[tag] = { offset: b.readUInt32BE(off + 8), length: b.readUInt32BE(off + 12) };
    }
    const head = this.tables.head.offset;
    this.unitsPerEm = b.readUInt16BE(head + 18);
    this.indexToLocFormat = b.readInt16BE(head + 50);
    this.numGlyphs = b.readUInt16BE(this.tables.maxp.offset + 4);
    const hhea = this.tables.hhea.offset;
    this.numHMetrics = b.readUInt16BE(hhea + 34);
    this.ascent = b.readInt16BE(hhea + 4);
    this.descent = b.readInt16BE(hhea + 6);
    this.locaOff = this.tables.loca.offset;
    this.glyfOff = this.tables.glyf.offset;
    this._cmap = this._parseCmap();
    this._cache = new Map();
  }

  _parseCmap() {
    const b = this.buf, off = this.tables.cmap.offset;
    const n = b.readUInt16BE(off + 2);
    let best = null, bestScore = -1;
    for (let i = 0; i < n; i++) {
      const rec = off + 4 + i * 8;
      const pid = b.readUInt16BE(rec), eid = b.readUInt16BE(rec + 2);
      const sub = off + b.readUInt32BE(rec + 4);
      const fmt = b.readUInt16BE(sub);
      let score = 0;
      if (fmt === 12 && pid === 3 && eid === 10) score = 100;
      else if (fmt === 4 && pid === 3 && eid === 1) score = 90;
      else if (fmt === 4 && pid === 0) score = 80;
      else if (fmt === 12) score = 70;
      else if (fmt === 4) score = 60;
      if (score > bestScore) { bestScore = score; best = { sub, fmt }; }
    }
    return best;
  }

  glyphIndex(cp) {
    const b = this.buf, { sub, fmt } = this._cmap;
    if (!sub) return 0;
    if (fmt === 4) {
      if (cp > 0xffff) return 0;
      const segX2 = b.readUInt16BE(sub + 6);
      const seg = segX2 / 2;
      const endOff = sub + 14, startOff = endOff + segX2 + 2, deltaOff = startOff + segX2, rangeOff = deltaOff + segX2;
      for (let i = 0; i < seg; i++) {
        const end = b.readUInt16BE(endOff + i * 2);
        if (cp > end) continue;
        const start = b.readUInt16BE(startOff + i * 2);
        if (cp < start) return 0;
        const delta = b.readInt16BE(deltaOff + i * 2);
        const ro = b.readUInt16BE(rangeOff + i * 2);
        if (ro === 0) return (cp + delta) & 0xffff;
        const gi = b.readUInt16BE(rangeOff + i * 2 + ro + (cp - start) * 2);
        return gi === 0 ? 0 : (gi + delta) & 0xffff;
      }
      return 0;
    }
    if (fmt === 12) {
      const nGroups = b.readUInt32BE(sub + 12);
      let lo = 0, hi = nGroups - 1;
      while (lo <= hi) {
        const mid = (lo + hi) >> 1;
        const g = sub + 16 + mid * 12;
        const s = b.readUInt32BE(g), e = b.readUInt32BE(g + 4), sg = b.readUInt32BE(g + 8);
        if (cp < s) hi = mid - 1;
        else if (cp > e) lo = mid + 1;
        else return sg + (cp - s);
      }
      return 0;
    }
    return 0;
  }

  advance(gid) {
    const b = this.buf;
    const idx = Math.min(gid, this.numHMetrics - 1);
    return b.readUInt16BE(this.tables.hmtx.offset + idx * 4);
  }

  glyphRange(gid) {
    const b = this.buf;
    let a, c;
    if (this.indexToLocFormat === 0) {
      a = b.readUInt16BE(this.locaOff + gid * 2) * 2;
      c = b.readUInt16BE(this.locaOff + gid * 2 + 2) * 2;
    } else {
      a = b.readUInt32BE(this.locaOff + gid * 4);
      c = b.readUInt32BE(this.locaOff + gid * 4 + 4);
    }
    return [this.glyfOff + a, this.glyfOff + c];
  }

  // returns array of contours: [{x,y}] in font units
  contours(gid) {
    if (this._cache.has(gid)) return this._cache.get(gid);
    const res = this._contours(gid, 0);
    this._cache.set(gid, res);
    return res;
  }

  _contours(gid, depth) {
    if (depth > 5 || gid >= this.numGlyphs) return [];
    const b = this.buf;
    const [start, end] = this.glyphRange(gid);
    if (end <= start) return [];
    const n = b.readInt16BE(start);
    if (n > 0) {
      const endPts = [];
      for (let i = 0; i < n; i++) endPts.push(b.readUInt16BE(start + 10 + i * 2));
      let p = start + 10 + n * 2;
      const il = b.readUInt16BE(p); p += 2 + il;
      const total = endPts[endPts.length - 1] + 1;
      const flags = new Uint8Array(total);
      let f = 0;
      while (f < total) {
        const fl = b[p++];
        flags[f++] = fl;
        if (fl & 8) { let r = b[p++]; while (r-- > 0 && f < total) flags[f++] = fl; }
      }
      const xs = new Int32Array(total), ys = new Int32Array(total);
      let x = 0;
      for (let i = 0; i < total; i++) {
        const fl = flags[i];
        if (fl & 2) { const d = b[p++]; x += fl & 16 ? d : -d; }
        else if (!(fl & 16)) { x += b.readInt16BE(p); p += 2; }
        xs[i] = x;
      }
      let y = 0;
      for (let i = 0; i < total; i++) {
        const fl = flags[i];
        if (fl & 4) { const d = b[p++]; y += fl & 32 ? d : -d; }
        else if (!(fl & 32)) { y += b.readInt16BE(p); p += 2; }
        ys[i] = y;
      }
      const out = [];
      let s = 0;
      for (const e of endPts) {
        const c = [];
        for (let i = s; i <= e; i++) c.push({ x: xs[i], y: ys[i], on: !!(flags[i] & 1) });
        out.push(c);
        s = e + 1;
      }
      return out;
    }
    // composite
    let p = start + 10, out = [];
    for (;;) {
      const fl = b.readUInt16BE(p); const gi = b.readUInt16BE(p + 2); p += 4;
      let a1, a2;
      if (fl & 1) { a1 = b.readInt16BE(p); a2 = b.readInt16BE(p + 2); p += 4; }
      else { a1 = b.readInt8(p); a2 = b.readInt8(p + 1); p += 2; }
      let dx = 0, dy = 0;
      if (fl & 2) { dx = a1; dy = a2; }
      let m = [1, 0, 0, 1];
      if (fl & 8) { const s2 = b.readInt16BE(p) / 16384; p += 2; m = [s2, 0, 0, s2]; }
      else if (fl & 0x40) { const sx = b.readInt16BE(p) / 16384, sy = b.readInt16BE(p + 2) / 16384; p += 4; m = [sx, 0, 0, sy]; }
      else if (fl & 0x80) { const a = b.readInt16BE(p) / 16384, bb = b.readInt16BE(p + 2) / 16384, c = b.readInt16BE(p + 4) / 16384, d = b.readInt16BE(p + 6) / 16384; p += 8; m = [a, bb, c, d]; }
      const sub = this._contours(gi, depth + 1);
      for (const c of sub) out.push(c.map(pt => ({ x: m[0] * pt.x + m[2] * pt.y + dx, y: m[1] * pt.x + m[3] * pt.y + dy, on: pt.on })));
      if (!(fl & 0x20)) break;
    }
    return out;
  }
}

// flatten a contour (quadratic beziers) into polygon points, in device coords
export function flatten(contour, scale, ox, oy, steps = 8) {
  const pts = contour;
  if (!pts.length) return [];
  const T = p => [ox + p.x * scale, oy - p.y * scale];
  let startIdx = 0;
  while (startIdx < pts.length && !pts[startIdx].on) startIdx++;
  let cur;
  if (startIdx === pts.length) {
    const a = pts[0], bb = pts[1 % pts.length];
    cur = { x: (a.x + bb.x) / 2, y: (a.y + bb.y) / 2, on: true };
  } else cur = pts[startIdx];
  const poly = [T(cur)];
  const n = pts.length;
  for (let k = 1; k <= n; k++) {
    const p = pts[(startIdx + k) % n];
    if (p.on) { poly.push(T(p)); cur = p; }
    else {
      const nx = pts[(startIdx + k + 1) % n];
      const end = nx.on ? nx : { x: (p.x + nx.x) / 2, y: (p.y + nx.y) / 2, on: true };
      const a = T(cur), b2 = T(p), c2 = T(end);
      for (let s = 1; s <= steps; s++) {
        const t = s / steps, u = 1 - t;
        poly.push([u * u * a[0] + 2 * u * t * b2[0] + t * t * c2[0], u * u * a[1] + 2 * u * t * b2[1] + t * t * c2[1]]);
      }
      cur = end;
      if (!nx.on) k++;
    }
  }
  return poly;
}
