<script setup lang="ts">
import { ref, watch, onMounted, getCurrentInstance, nextTick } from 'vue';

const props = defineProps<{ records: any[]; metric: string; days: number }>();

const fields: Record<string, string> = {
  疼痛: 'painScore', 乏力: 'fatigueScore', 睡眠: 'sleepScore', 心情: 'moodScore', 食欲: 'appetiteScore', 体温: 'temperature', 体重: 'weight',
};
const measureMetrics = ['体温', '体重'];
const canvasId = 'trendCanvas';
const canvasH = 190;
const canvasW = ref(320);
const baseWidth = ref(320);
const hasData = ref(false);
const countLabel = ref('');
const instance = getCurrentInstance();

function pad(n: number) { return String(n).padStart(2, '0'); }
function dateKeyOf(v: any) {
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) return '';
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
}
function trimDecimal(v: number) {
  const s = v.toFixed(1);
  return s.endsWith('.0') ? s.slice(0, -2) : s;
}
function tickLabel(v: number) { return v === Math.round(v) ? String(Math.round(v)) : trimDecimal(v); }
function valueLabel(v: number) {
  if (props.metric === '体温') return v.toFixed(1);
  if (props.metric === '体重') return trimDecimal(v);
  return String(Math.round(v));
}

function buildPoints() {
  const field = fields[props.metric];
  const isMeasure = measureMetrics.includes(props.metric);
  const cutoff = Date.now() - props.days * 86400000;
  if (isMeasure) {
    const list: { t: number; v: number }[] = [];
    for (const r of props.records) {
      const raw = r[field];
      const at = r.measuredAt || r.createdAt || r.recordDate;
      const t = new Date(at).getTime();
      if (raw === null || raw === undefined || raw === '' || Number.isNaN(t) || t < cutoff) continue;
      list.push({ t, v: Number(raw) });
    }
    list.sort((a, b) => a.t - b.t);
    let lastDay = '';
    return list.map((e) => {
      const d = new Date(e.t);
      const day = `${d.getMonth() + 1}/${d.getDate()}`;
      if (props.metric === '体温') {
        const time = `${pad(d.getHours())}:${pad(d.getMinutes())}`;
        const label = day === lastDay ? `\n${time}` : `${day}\n${time}`;
        lastDay = day;
        return { label, value: e.v as number | null };
      }
      return { label: day, value: e.v as number | null };
    });
  }
  const byDay: Record<string, number> = {};
  for (const r of props.records) {
    const raw = r[field];
    if (raw === null || raw === undefined || raw === '') continue;
    const key = (r.recordDate || dateKeyOf(r.createdAt) || '').toString();
    if (!(key in byDay)) byDay[key] = Number(raw);
  }
  const pts: { label: string; value: number | null }[] = [];
  const now = Date.now();
  for (let off = props.days - 1; off >= 0; off--) {
    const d = new Date(now - off * 86400000);
    const key = dateKeyOf(d);
    pts.push({ label: `${d.getMonth() + 1}/${d.getDate()}`, value: key in byDay ? byDay[key] : null });
  }
  return pts;
}

function draw() {
  const points = buildPoints();
  hasData.value = points.some((p) => p.value !== null && p.value !== undefined);
  const measured = measureMetrics.includes(props.metric);
  const cnt = points.filter((p) => p.value !== null && p.value !== undefined).length;
  countLabel.value = `${props.metric} · ${cnt} ${measured ? '次记录' : '天有记录'}`;
  const perPoint = props.metric === '体温' ? 46 : 34;
  canvasW.value = Math.max(baseWidth.value, points.length * perPoint + 54);
  if (!hasData.value) return;
  nextTick(() => {
    const ctx = uni.createCanvasContext(canvasId, instance?.proxy as any);
    drawChart(ctx, points);
    ctx.draw();
  });
}

function drawChart(ctx: any, points: { label: string; value: number | null }[]) {
  const W = canvasW.value; const H = canvasH;
  const padLeft = 30; const padRight = 12; const padTop = 14; const padBottom = 44;
  const values = points.filter((p) => p.value != null).map((p) => p.value as number);
  let min = 0; let max = 10; let yTicks = [0, 2, 4, 6, 8, 10];
  if (props.metric === '体温') { min = 34; max = 42; yTicks = [34, 36, 38, 40, 42]; }
  else if (props.metric === '体重') {
    const lo = values.length ? Math.floor(Math.min(...values)) - 1 : 40;
    const hi = values.length ? Math.ceil(Math.max(...values)) + 1 : 80;
    min = lo === hi ? lo - 1 : lo; max = lo === hi ? hi + 1 : hi;
    yTicks = [0, 1, 2, 3, 4].map((i) => Math.round((min + (max - min) / 4 * i) * 10) / 10);
  }
  if (max <= min) max = min + 1;
  const plotW = W - padLeft - padRight; const plotH = H - padTop - padBottom;
  const step = points.length > 1 ? plotW / (points.length - 1) : 0;
  const px = (i: number) => padLeft + (points.length > 1 ? i * step : plotW / 2);
  const py = (v: number) => padTop + (1 - (v - min) / (max - min)) * plotH;
  const baseY = H - padBottom;

  ctx.clearRect(0, 0, W, H);
  ctx.setFontSize(10);
  ctx.setTextBaseline('middle');
  for (const t of yTicks) {
    const y = py(t);
    ctx.beginPath(); ctx.setStrokeStyle('#eadbca'); ctx.setLineWidth(1);
    ctx.moveTo(padLeft, y); ctx.lineTo(W - padRight, y); ctx.stroke();
    ctx.setFillStyle('#9a8d7f'); ctx.setTextAlign('right');
    ctx.fillText(tickLabel(t), padLeft - 4, y);
  }
  ctx.beginPath(); ctx.setStrokeStyle('#d8cabb'); ctx.setLineWidth(1);
  ctx.moveTo(padLeft, baseY); ctx.lineTo(W - padRight, baseY);
  ctx.moveTo(padLeft, padTop); ctx.lineTo(padLeft, baseY); ctx.stroke();

  const dots: { x: number; y: number; v: number }[] = [];
  ctx.setTextAlign('center'); ctx.setTextBaseline('top'); ctx.setFillStyle('#9a8d7f'); ctx.setFontSize(9);
  for (let i = 0; i < points.length; i++) {
    const parts = points[i].label.split('\n');
    let ly = baseY + 6;
    for (const part of parts) { if (part) ctx.fillText(part, px(i), ly); ly += 12; }
    if (points[i].value != null) dots.push({ x: px(i), y: py(points[i].value as number), v: points[i].value as number });
  }
  if (dots.length > 1) {
    const grad = ctx.createLinearGradient(0, padTop, 0, padTop + plotH);
    grad.addColorStop(0, 'rgba(113,131,106,0.32)');
    grad.addColorStop(1, 'rgba(113,131,106,0.0)');
    ctx.beginPath();
    ctx.moveTo(dots[0].x, baseY);
    for (const d of dots) ctx.lineTo(d.x, d.y);
    ctx.lineTo(dots[dots.length - 1].x, baseY);
    ctx.closePath();
    ctx.setFillStyle(grad); ctx.fill();
    ctx.beginPath(); ctx.setStrokeStyle('#71836a'); ctx.setLineWidth(2); ctx.setLineJoin('round');
    ctx.moveTo(dots[0].x, dots[0].y);
    for (let i = 1; i < dots.length; i++) ctx.lineTo(dots[i].x, dots[i].y);
    ctx.stroke();
  }
  ctx.setFillStyle('#71836a');
  for (const d of dots) { ctx.beginPath(); ctx.arc(d.x, d.y, 3, 0, Math.PI * 2); ctx.fill(); }
  ctx.setFillStyle('#312b27'); ctx.setFontSize(9); ctx.setTextAlign('center'); ctx.setTextBaseline('bottom');
  for (const d of dots) ctx.fillText(valueLabel(d.v), d.x, d.y - 6);
}

onMounted(() => {
  try {
    const info = (uni as any).getWindowInfo ? (uni as any).getWindowInfo() : uni.getSystemInfoSync();
    baseWidth.value = Math.round((info.windowWidth || 375) * 638 / 750);
  } catch (e) { baseWidth.value = 320; }
  draw();
});
watch(() => [props.metric, props.days, props.records.length], () => draw());
</script>

<template>
  <view>
    <view v-if="!hasData" class="empty">最近 {{ days }} 天还没有{{ metric }}记录。</view>
    <template v-else>
      <scroll-view scroll-x class="trend-scroll">
        <canvas :canvas-id="canvasId" class="trend-canvas" :style="{ width: canvasW + 'px', height: canvasH + 'px' }" />
      </scroll-view>
      <text class="trend-count">{{ countLabel }}</text>
    </template>
  </view>
</template>

<style scoped lang="scss">
.trend-scroll { width: 100%; }
.trend-canvas { display: block; }
.trend-count { display: block; margin-top: 8rpx; text-align: center; color: #766b62; font-size: 22rpx; }
.empty { padding: 44rpx 12rpx; color: #766b62; font-size: 26rpx; text-align: center; }
</style>
