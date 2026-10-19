import { encodePNG } from "./png.mjs";
import { flatten } from "./ttf.mjs";

const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);

export class Canvas {
  constructor(w, h, ss = 3) {
    this.w = w; this.h = h; this.ss = ss;
    this.W = w * ss; this.H = h * ss;
    this.buf = new Uint8ClampedArray(this.W * this.H * 4);
  }

  blend(x, y, c) {
    const i = (y * this.W + x) * 4;
    const a = c[3] === undefined ? 1 : c[3];
    if (a <= 0) return;
    const b = this.buf;
    if (a >= 1) { b[i] = c[0]; b[i + 1] = c[1]; b[i + 2] = c[2]; b[i + 3] = 255; return; }
    b[i] = b[i] + (c[0] - b[i]) * a;
    b[i + 1] = b[i + 1] + (c[1] - b[i + 1]) * a;
    b[i + 2] = b[i + 2] + (c[2] - b[i + 2]) * a;
    b[i + 3] = 255;
  }

  // test(x,y) in logical px, colorFn(x,y) -> [r,g,b,a]
  fillShape(x0, y0, x1, y1, test, color) {
    const ss = this.ss;
    const X0 = clamp(Math.floor(x0 * ss), 0, this.W - 1), X1 = clamp(Math.ceil(x1 * ss), 0, this.W);
    const Y0 = clamp(Math.floor(y0 * ss), 0, this.H - 1), Y1 = clamp(Math.ceil(y1 * ss), 0, this.H);
    const cf = typeof color === "function" ? color : () => color;
    for (let y = Y0; y < Y1; y++) {
      const ly = (y + 0.5) / ss;
      for (let x = X0; x < X1; x++) {
        if (test((x + 0.5) / ss, ly)) this.blend(x, y, cf((x + 0.5) / ss, ly));
      }
    }
  }

  rect(x, y, w, h, color) {
    this.fillShape(x, y, x + w, y + h, (px, py) => px >= x && px < x + w && py >= y && py < y + h, color);
  }

  roundRect(x, y, w, h, r, color, inset = 0) {
    const x0 = x + inset, y0 = y + inset, x1 = x + w - inset, y1 = y + h - inset;
    const rr = Math.max(0, Math.min(r - inset, (x1 - x0) / 2, (y1 - y0) / 2));
    const test = (px, py) => {
      if (px < x0 || px > x1 || py < y0 || py > y1) return false;
      const cx = px < x0 + rr ? x0 + rr : px > x1 - rr ? x1 - rr : px;
      const cy = py < y0 + rr ? y0 + rr : py > y1 - rr ? y1 - rr : py;
      const dx = px - cx, dy = py - cy;
      return dx * dx + dy * dy <= rr * rr;
    };
    this.fillShape(x0, y0, x1, y1, test, color);
  }

  strokeRoundRect(x, y, w, h, r, t, color) {
    this.roundRect(x, y, w, h, r, color);
    this.roundRect(x + t, y + t, w - 2 * t, h - 2 * t, Math.max(0, r - t), [0, 0, 0, 0]);
    // punch hole via alpha-0 trick is not valid; do explicit ring test instead
    const x0 = x, y0 = y, x1 = x + w, y1 = y + h;
    const rr = r, t2 = t;
    const insideOuter = (px, py, ox, oy, ow, oh, orr) => {
      if (px < ox || px > ox + ow || py < oy || py > oy + oh) return false;
      const cx = px < ox + orr ? ox + orr : px > ox + ow - orr ? ox + ow - orr : px;
      const cy = py < oy + orr ? oy + orr : py > oy + oh - orr ? oy + oh - orr : py;
      const dx = px - cx, dy = py - cy;
      return dx * dx + dy * dy <= orr * orr;
    };
    this.fillShape(x0, y0, x1, y1,
      (px, py) => insideOuter(px, py, x0, y0, w, h, rr) && !insideOuter(px, py, x0 + t2, y0 + t2, w - 2 * t2, h - 2 * t2, Math.max(0, rr - t2)),
      color);
  }

  gradient(x, y, w, h, c1, c2, vertical = true, r = 0) {
    const test = (px, py) => {
      if (px < x || px > x + w || py < y || py > y + h) return false;
      if (r <= 0) return true;
      const cx = px < x + r ? x + r : px > x + w - r ? x + w - r : px;
      const cy = py < y + r ? y + r : py > y + h - r ? y + h - r : py;
      const dx = px - cx, dy = py - cy;
      return dx * dx + dy * dy <= r * r;
    };
    this.fillShape(x, y, x + w, y + h, test, (px, py) => {
      const t = vertical ? (py - y) / h : (px - x) / w;
      return [c1[0] + (c2[0] - c1[0]) * t, c1[1] + (c2[1] - c1[1]) * t, c1[2] + (c2[2] - c1[2]) * t, 1];
    });
  }

  circle(cx, cy, rad, color) {
    this.fillShape(cx - rad, cy - rad, cx + rad, cy + rad,
      (px, py) => (px - cx) ** 2 + (py - cy) ** 2 <= rad * rad, color);
  }

  ring(cx, cy, rad, t, color) {
    this.fillShape(cx - rad, cy - rad, cx + rad, cy + rad, (px, py) => {
      const d = Math.hypot(px - cx, py - cy);
      return d <= rad && d >= rad - t;
    }, color);
  }

  line(x0, y0, x1, y1, t, color) {
    const minx = Math.min(x0, x1) - t, maxx = Math.max(x0, x1) + t;
    const miny = Math.min(y0, y1) - t, maxy = Math.max(y0, y1) + t;
    const vx = x1 - x0, vy = y1 - y0, len2 = vx * vx + vy * vy || 1;
    this.fillShape(minx, miny, maxx, maxy, (px, py) => {
      let u = ((px - x0) * vx + (py - y0) * vy) / len2;
      u = clamp(u, 0, 1);
      const dx = px - (x0 + u * vx), dy = py - (y0 + u * vy);
      return dx * dx + dy * dy <= (t / 2) * (t / 2);
    }, color);
  }

  fillPolygons(polys, color) {
    const ss = this.ss;
    const edges = [];
    let minY = Infinity, maxY = -Infinity;
    for (const poly of polys) {
      for (let i = 0; i < poly.length; i++) {
        const a = poly[i], b = poly[(i + 1) % poly.length];
        if (a[1] === b[1]) continue;
        edges.push([a[0] * ss, a[1] * ss, b[0] * ss, b[1] * ss, a[1] < b[1] ? 1 : -1]);
        minY = Math.min(minY, a[1], b[1]); maxY = Math.max(maxY, a[1], b[1]);
      }
    }
    if (!edges.length) return;
    const Y0 = clamp(Math.floor(minY * ss), 0, this.H), Y1 = clamp(Math.ceil(maxY * ss), 0, this.H);
    const xs = [];
    for (let y = Y0; y < Y1; y++) {
      const sy = y + 0.5;
      xs.length = 0;
      for (const e of edges) {
        const y0 = e[1], y1 = e[3];
        if ((sy >= y0 && sy < y1) || (sy >= y1 && sy < y0)) {
          const t = (sy - y0) / (y1 - y0);
          xs.push([e[0] + (e[2] - e[0]) * t, e[4]]);
        }
      }
      if (!xs.length) continue;
      xs.sort((a, b) => a[0] - b[0]);
      let wind = 0;
      for (let i = 0; i < xs.length - 1; i++) {
        wind += xs[i][1];
        if (wind !== 0) {
          const a = Math.max(0, Math.floor(xs[i][0])), b = Math.min(this.W, Math.ceil(xs[i + 1][0]));
          for (let x = a; x < b; x++) this.blend(x, y, color);
        }
      }
    }
  }

  textWidth(font, str, size, tracking = 0) {
    let w = 0;
    for (const ch of str) w += (font.advance(font.glyphIndex(ch.codePointAt(0))) / font.unitsPerEm) * size + tracking;
    return w;
  }

  drawText(font, str, size, x, baselineY, color, opts = {}) {
    const tracking = opts.tracking || 0;
    const bold = opts.bold || 0;
    const scale = size / font.unitsPerEm;
    let pen = x;
    const polys = [];
    for (const ch of str) {
      const gid = font.glyphIndex(ch.codePointAt(0));
      if (gid) {
        for (const c of font.contours(gid)) {
          const p = flatten(c, scale, pen, baselineY, 8);
          if (p.length > 2) polys.push(p);
        }
      }
      pen += (font.advance(gid) / font.unitsPerEm) * size + tracking;
    }
    if (bold > 0) {
      const shifted = polys.map(p => p.map(([px, py]) => [px + bold, py]));
      this.fillPolygons(polys.concat(shifted), color);
    } else this.fillPolygons(polys, color);
  }

  toPNG() {
    const ss = this.ss, w = this.w, h = this.h;
    const out = Buffer.alloc(w * h * 4);
    const n = ss * ss;
    for (let y = 0; y < h; y++) {
      for (let x = 0; x < w; x++) {
        let r = 0, g = 0, b = 0;
        for (let sy = 0; sy < ss; sy++) {
          for (let sx = 0; sx < ss; sx++) {
            const i = ((y * ss + sy) * this.W + (x * ss + sx)) * 4;
            r += this.buf[i]; g += this.buf[i + 1]; b += this.buf[i + 2];
          }
        }
        const o = (y * w + x) * 4;
        out[o] = r / n; out[o + 1] = g / n; out[o + 2] = b / n; out[o + 3] = 255;
      }
    }
    return encodePNG(w, h, out);
  }
}
