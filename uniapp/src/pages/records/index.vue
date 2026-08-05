<script setup lang="ts">
import { computed, ref } from 'vue';
import { onLoad, onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import { useSession } from '../../state/session';
import { dateKey, formatTime, showError } from '../../utils/format';

const session = useSession();
onShow(() => session.boot().catch(showError));

const recordKindLabels: Record<string, string> = {
  symptom: '症状', medication: '用药', vital: '体征', score: '评分',
};
const vitalFieldLabels: Record<string, [string, string]> = {
  temperature: ['体温', '℃'],
  weight: ['体重', 'kg'],
  systolic: ['收缩压', 'mmHg'],
  diastolic: ['舒张压', 'mmHg'],
  heartRate: ['心率', '次/分'],
  bloodSugar: ['血糖', 'mmol/L'],
};
const scoreLabels: Record<string, string> = {
  painScore: '疼痛', fatigueScore: '乏力', sleepScore: '睡眠', moodScore: '心情', appetiteScore: '食欲',
};

const kind = ref('symptom');
const days = ref<number | null>(30); // null = 全部；默认 30 天
const from = ref('');
const to = ref('');
const query = ref('');

onLoad((options: any) => {
  if (options?.kind && recordKindLabels[options.kind]) kind.value = options.kind;
});

const today = computed(() => dateKey());

function pickDays(value: number | null) {
  days.value = value;
  from.value = '';
  to.value = '';
}
function resetFilter() {
  days.value = 30;
  from.value = '';
  to.value = '';
  query.value = '';
}
// 去掉小数末尾的 .0，让 38.0 显示成 38
function trimNumber(value: any) {
  const text = String(value ?? '').trim();
  return text.endsWith('.0') ? text.slice(0, -2) : text;
}
function timeOf(record: any) {
  return record.measuredAt || record.createdAt || record.recordDate;
}

const source = computed(() => {
  const rows: any[] = [];
  if (kind.value === 'symptom') {
    for (const s of session.data.symptoms as any[]) {
      rows.push({ id: s.id, kind: kind.value, time: s.happenedAt, title: s.tag, subtitle: s.note || '' });
    }
  } else if (kind.value === 'medication') {
    for (const m of session.data.medications as any[]) {
      const meta = [m.dosage, m.note].filter(Boolean).join(' · ');
      rows.push({ id: m.id, kind: kind.value, time: m.takenAt, title: m.name, subtitle: meta });
    }
  } else if (kind.value === 'vital') {
    for (const r of session.data.body as any[]) {
      const parts: string[] = [];
      for (const [field, meta] of Object.entries(vitalFieldLabels)) {
        const value = r[field];
        if (value === null || value === undefined || value === '') continue;
        parts.push(`${meta[0]} ${trimNumber(value)}${meta[1]}`);
      }
      if (!parts.length) continue;
      rows.push({ id: r.id, kind: kind.value, time: timeOf(r), title: parts.join(' · '), subtitle: r.note || '' });
    }
  } else {
    for (const r of session.data.body as any[]) {
      const parts = Object.entries(scoreLabels)
        .filter(([field]) => r[field] !== null && r[field] !== undefined && r[field] !== '')
        .map(([field, label]) => `${label} ${trimNumber(r[field])}`);
      if (!parts.length) continue;
      rows.push({ id: r.id, kind: kind.value, time: r.createdAt || r.recordDate, title: parts.join(' · '), subtitle: r.note || '' });
    }
  }
  return rows.sort((a, b) => +new Date(b.time) - +new Date(a.time));
});

const filtered = computed(() => {
  let rows = source.value;
  if (from.value || to.value) {
    const start = from.value ? +new Date(`${from.value}T00:00:00`) : null;
    const end = to.value ? +new Date(`${to.value}T23:59:59`) : null;
    rows = rows.filter((row) => {
      const at = +new Date(row.time);
      if (start !== null && at < start) return false;
      if (end !== null && at > end) return false;
      return true;
    });
  } else if (days.value) {
    const cutoff = Date.now() - days.value * 86400000;
    rows = rows.filter((row) => +new Date(row.time) >= cutoff);
  }
  const q = query.value.trim().toLowerCase();
  if (q) rows = rows.filter((row) => `${row.title} ${row.subtitle}`.toLowerCase().includes(q));
  return rows;
});

const groups = computed(() => {
  const map = new Map<string, any[]>();
  for (const row of filtered.value) {
    const key = dateKey(row.time);
    const list = map.get(key) ?? [];
    list.push({ ...row, clock: formatTime(row.time) });
    map.set(key, list);
  }
  const yesterday = dateKey(new Date(Date.now() - 86400000).toISOString());
  return Array.from(map, ([day, items]) => ({
    day,
    label: day === today.value ? '今天' : day === yesterday ? '昨天' : day,
    items,
  }));
});

function goBack() {
  uni.navigateBack();
}
</script>

<template><view class="page">
  <PageHero eyebrow="ALL RECORDS" title="全部记录" subtitle="按类别和时间查看完整历史，复诊时翻给医生看。" :profile="false" />

  <view class="card">
    <view class="card-title"><text>筛选</text><text class="link" @click="goBack">‹ 返回</text></view>

    <text class="filter-label">类别</text>
    <view class="chips">
      <text v-for="(label, k) in recordKindLabels" :key="k" class="chip" :class="{ active: kind === k }" @click="kind = k">{{ label }}</text>
    </view>

    <text class="filter-label">时间</text>
    <view class="chips">
      <text class="chip" :class="{ active: !from && !to && days === 7 }" @click="pickDays(7)">7 天</text>
      <text class="chip" :class="{ active: !from && !to && days === 30 }" @click="pickDays(30)">30 天</text>
      <text class="chip" :class="{ active: !from && !to && days === 90 }" @click="pickDays(90)">90 天</text>
      <text class="chip" :class="{ active: !from && !to && !days }" @click="pickDays(null)">全部</text>
    </view>
    <view class="range-row">
      <picker mode="date" :value="from" @change="from = $event.detail.value">
        <text class="range-pick">{{ from || '开始日期' }}</text>
      </picker>
      <text class="range-sep">至</text>
      <picker mode="date" :value="to" @change="to = $event.detail.value">
        <text class="range-pick">{{ to || '结束日期' }}</text>
      </picker>
    </view>

    <input v-model="query" class="search-input" type="text" :placeholder="`搜索${recordKindLabels[kind]}内容或备注`" />

    <view class="sheet-meta">
      <text>{{ filtered.length === source.length ? `共 ${source.length} 条` : `筛选出 ${filtered.length} 条 / 共 ${source.length} 条` }}</text>
      <text v-if="from || to || query || days !== 30" class="link" @click="resetFilter">重置筛选</text>
    </view>
  </view>

  <view class="card">
    <view v-if="!filtered.length" class="empty">这个时间范围内没有{{ recordKindLabels[kind] }}记录。</view>
    <template v-for="group in groups" :key="group.day">
      <text class="subhead">{{ group.label }} · {{ group.items.length }} 条</text>
      <view v-for="row in group.items" :key="`${row.kind}-${row.id}-${row.time}`" class="log-row">
        <text class="log-time">{{ row.clock }}</text>
        <view class="log-main">
          <text class="log-title">{{ row.title }}</text>
          <text v-if="row.subtitle" class="log-meta">{{ row.subtitle }}</text>
        </view>
      </view>
    </template>
  </view>
</view></template>
