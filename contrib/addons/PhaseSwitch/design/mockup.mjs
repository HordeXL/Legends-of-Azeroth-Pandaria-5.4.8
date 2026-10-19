import fs from "node:fs";
import { Font } from "./ttf.mjs";
import { Canvas } from "./canvas.mjs";

const W = 960, H = 700;
const c = new Canvas(W, H, 3);
const reg = new Font("C:/Windows/Fonts/msyh.ttc", 0);
const bold = new Font("C:/Windows/Fonts/msyhbd.ttc", 0);

// ---------- palette ----------
const GOLD = [214, 178, 106];
const GOLD_HI = [244, 214, 150];
const GOLD_DIM = [138, 112, 66];
const TEXT = [232, 220, 196];
const TEXT_DIM = [150, 141, 122];
const TEXT_FAINT = [110, 103, 90];

// ---------- background (blurred game scene abstraction) ----------
for (let y = 0; y < H; y++) {
  const t = y / H;
  const r = 20 + 16 * (1 - t), g = 34 + 22 * (1 - t), b = 40 + 26 * (1 - t);
  c.rect(0, y, W, 1, [r, g, b]);
}
// warm sunset glow, top-left
c.fillShape(0, 0, W, H, (x, y) => {
  const d = Math.hypot((x - 120) / 520, (y + 40) / 360);
  return d < 1;
}, (x, y) => {
  const d = Math.hypot((x - 120) / 520, (y + 40) / 360);
  const a = Math.pow(1 - d, 2.2) * 0.55;
  return [214, 132, 62, a];
});
// cool glow, right
c.fillShape(0, 0, W, H, (x, y) => Math.hypot((x - 880) / 460, (y - 120) / 400) < 1, (x, y) => {
  const d = Math.hypot((x - 880) / 460, (y - 120) / 400);
  return [62, 96, 120, Math.pow(1 - d, 2) * 0.35];
});
// mountain silhouettes
const ridge = (baseY, amp, seed, col) => {
  c.fillShape(0, baseY - amp - 20, W, H, (x, y) => {
    const yy = baseY + Math.sin(x * 0.006 + seed) * amp * 0.45 + Math.sin(x * 0.017 + seed * 2.1) * amp * 0.25 + Math.sin(x * 0.043 + seed * 0.7) * amp * 0.1;
    return y > yy;
  }, col);
};
ridge(300, 70, 1.2, [26, 38, 46, 0.85]);
ridge(352, 52, 2.6, [21, 31, 38, 0.9]);
ridge(408, 40, 4.1, [16, 24, 30, 0.95]);
ridge(470, 26, 5.5, [11, 17, 22, 1]);
// vignette
c.fillShape(0, 0, W, H, () => true, (x, y) => {
  const d = Math.hypot((x - W / 2) / (W * 0.72), (y - H / 2) / (H * 0.78));
  return [0, 0, 0, Math.min(0.72, Math.max(0, (d - 0.35) * 1.15))];
});

// ---------- panel ----------
const P = { x: 160, y: 50, w: 640, h: 600, r: 12 };
const px = P.x, py = P.y, pw = P.w, ph = P.h;

// drop shadow
for (let i = 10; i >= 1; i--) {
  c.roundRect(px - i, py - i + 6, pw + i * 2, ph + i * 2, P.r + i, [0, 0, 0, 0.045]);
}
// outer gold frame
c.roundRect(px - 2, py - 2, pw + 4, ph + 4, P.r + 2, [78, 62, 38]);
c.roundRect(px - 1, py - 1, pw + 2, ph + 2, P.r + 1, GOLD_DIM);
// body gradient
c.gradient(px, py, pw, ph, [34, 30, 25], [19, 17, 14], true, P.r);
// inner top highlight
c.fillShape(px, py, px + pw, py + ph, (x, y) => {
  if (y > py + 2 || y < py) return false;
  const t = (x - px) / pw;
  return t > 0.1 && t < 0.9;
}, [255, 236, 190, 0.10]);

// corner ornaments
const diamond = (cx, cy, s, col) => c.fillPolygons([[[cx, cy - s], [cx + s, cy], [cx, cy + s], [cx - s, cy]]], col);
[[px + 10, py + 10], [px + pw - 10, py + 10], [px + 10, py + ph - 10], [px + pw - 10, py + ph - 10]]
  .forEach(([dx, dy]) => diamond(dx, dy, 3.2, GOLD));

// ---------- title bar ----------
const tbH = 58;
c.gradient(px + 2, py + 2, pw - 4, tbH, [58, 42, 28], [32, 25, 18], true, P.r - 2);
c.rect(px + 2, py + tbH - 1, pw - 4, 1, GOLD_DIM);
c.rect(px + 2, py + tbH, pw - 4, 1, [0, 0, 0, 0.55]);

c.drawText(bold, "位面切换", 25, px + 26, py + 38, GOLD_HI, { bold: 0.5 });
const tw = c.textWidth(bold, "位面切换", 25);
c.drawText(reg, "PHASE  SWITCH", 10, px + 26 + tw + 16, py + 36, [140, 118, 78], { tracking: 1.6 });

// close button
const cx0 = px + pw - 30, cy0 = py + 29;
c.circle(cx0, cy0, 13, [0, 0, 0, 0.35]);
c.ring(cx0, cy0, 13, 1, [150, 124, 78, 0.9]);
c.line(cx0 - 4.5, cy0 - 4.5, cx0 + 4.5, cy0 + 4.5, 1.6, [214, 190, 150]);
c.line(cx0 + 4.5, cy0 - 4.5, cx0 - 4.5, cy0 + 4.5, 1.6, [214, 190, 150]);

// ---------- zone info bar ----------
const ziY = py + tbH + 1;
c.rect(px + 2, ziY, pw - 4, 44, [16, 14, 12, 0.55]);
c.drawText(reg, "区域", 12, px + 26, ziY + 27, TEXT_FAINT);
c.drawText(reg, "锦绣谷", 14, px + 58, ziY + 28, TEXT);
c.drawText(reg, "Zone 5841", 11, px + 106, ziY + 27, TEXT_FAINT);
// separator dot
c.circle(px + 190, ziY + 23, 1.6, [90, 84, 72]);
c.drawText(reg, "当前位面掩码", 12, px + 206, ziY + 27, TEXT_FAINT);
c.drawText(bold, "1", 15, px + 288, ziY + 28, GOLD_HI, { bold: 0.4 });
c.drawText(reg, "可用位面 6", 12, px + pw - 116, ziY + 27, TEXT_FAINT);
c.rect(px + 2, ziY + 43, pw - 4, 1, [70, 58, 40, 0.8]);

// ---------- phase list ----------
const rows = [
  { name: "正常位面", desc: "默认位面 · 全部玩家与 NPC 可见", mask: 1, cur: true },
  { name: "金色山谷", desc: "前置任务「金色晨曦」完成后开放", mask: 2 },
  { name: "锦绣谷 · 煞染", desc: "煞之侵蚀阶段 · 仅事件期间生效", mask: 4 },
  { name: "魔古山宝库", desc: "团队副本前置位面 · 需 90 级", mask: 8 },
  { name: "影踪禅院", desc: "剧情位面 · 完成「影踪的试炼」", mask: 16 },
  { name: "卡拉克西 · 封印", desc: "螳螂妖封印阶段 · 声望解锁", mask: 32 },
];
const listX = px + 20, listW = pw - 40, rowH = 56, rowGap = 6;
let ry = ziY + 52;
const scrollTop = ry, scrollBottom = 0;

rows.forEach((row, i) => {
  const rx = listX, rw = listW, rh = rowH;
  if (row.cur) {
    c.roundRect(rx - 1, ry - 1, rw + 2, rh + 2, 7, [150, 118, 62, 0.85]);
    c.gradient(rx, ry, rw, rh, [62, 47, 28], [40, 31, 20], true, 6);
    c.rect(rx, ry + 8, 3, rh - 16, GOLD);
  } else {
    c.roundRect(rx, ry, rw, rh, 6, i % 2 ? [30, 27, 22] : [35, 31, 25]);
  }
  // icon
  const icx = rx + 28, icy = ry + rh / 2;
  if (row.cur) { c.circle(icx, icy, 10, [0, 0, 0, 0.35]); c.ring(icx, icy, 10, 1.4, GOLD); c.circle(icx, icy, 4, GOLD_HI); }
  else { c.circle(icx, icy, 10, [0, 0, 0, 0.25]); c.ring(icx, icy, 10, 1.2, [96, 84, 62]); }
  // name / desc
  c.drawText(bold, row.name, 15, rx + 52, ry + 24, row.cur ? GOLD_HI : TEXT, { bold: 0.3 });
  c.drawText(reg, row.desc, 11.5, rx + 52, ry + 41, row.cur ? [176, 160, 130] : TEXT_DIM);
  // mask
  const mt = "掩码 " + row.mask;
  const mw = c.textWidth(reg, mt, 12);
  c.drawText(reg, mt, 12, rx + rw - 22 - mw - (row.cur ? 52 : 0), ry + 32, row.cur ? [206, 186, 148] : TEXT_FAINT);
  if (row.cur) {
    const bw = 42, bx = rx + rw - 16 - bw, by = ry + rh / 2 - 10;
    c.roundRect(bx, by, bw, 20, 10, [150, 118, 62, 0.22]);
    c.roundRect(bx, by, bw, 20, 10, [0, 0, 0, 0]);
    c.strokeRoundRect(bx, by, bw, 20, 10, 1, [168, 134, 74, 0.9]);
    c.drawText(reg, "当前", 11, bx + 9, by + 14, GOLD_HI);
  }
  ry += rh + rowGap;
});
const listBottom = ry - rowGap;

// scrollbar
const sbX = px + pw - 13;
c.roundRect(sbX, scrollTop + 2, 5, listBottom - scrollTop - 4, 2.5, [24, 21, 17]);
c.roundRect(sbX, scrollTop + 2, 5, Math.min(64, listBottom - scrollTop - 4), 2.5, [104, 86, 56]);

// hint line
c.circle(px + 26, listBottom + 22, 2, [120, 100, 66]);
c.drawText(reg, "切换后立即刷新可见对象，无需重登或重载界面", 11, px + 34, listBottom + 26, [128, 120, 104]);

// ---------- footer / buttons ----------
const footY = py + ph - 78;
c.rect(px + 2, footY, pw - 4, 1, [70, 58, 40, 0.75]);
c.rect(px + 2, footY + 1, pw - 4, 77, [13, 11, 9, 0.45]);

const btn = (x, y, w, h, label, primary, enabled = true) => {
  if (primary) {
    c.roundRect(x, y, w, h, 6, [86, 68, 40]);
    c.gradient(x, y, w, h, [226, 190, 118], [176, 140, 76], true, 5);
    c.roundRect(x, y, w, h - 2, 5, [0, 0, 0, 0]);
    c.drawText(bold, label, 13.5, x + (w - c.textWidth(bold, label, 13.5)) / 2, y + h / 2 + 5, [40, 30, 14], { bold: 0.3 });
  } else {
    c.roundRect(x, y, w, h, 6, [56, 47, 33]);
    c.gradient(x, y, w, h, [50, 43, 32], [33, 28, 21], true, 5);
    c.drawText(reg, label, 13, x + (w - c.textWidth(reg, label, 13)) / 2, y + h / 2 + 5, enabled ? [208, 192, 160] : [110, 102, 88]);
  }
};
const by0 = footY + 13;
btn(px + 22, by0, 128, 32, "切换到此位面", true);
btn(px + 160, by0, 74, 32, "重置", false);
btn(px + 242, by0, 74, 32, "刷新", false);
c.drawText(reg, "左键切换 · 右键查看位面详情", 11, px + pw - 22 - c.textWidth(reg, "左键切换 · 右键查看位面详情", 11), by0 + 22, TEXT_FAINT);

// version footer inside panel
c.drawText(reg, "数据来源 phase_definitions", 10.5, px + 28, footY + 62, [96, 90, 78]);
const ver = "v1.0 · Eluna + AddOn";
c.drawText(reg, ver, 10.5, px + pw - 28 - c.textWidth(reg, ver, 10.5), footY + 62, [96, 90, 78]);

fs.writeFileSync("phase_switch_ui.png", c.toPNG());
console.log("written");
