<script setup lang="ts">
import { computed, ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import TrendChart from '../../components/TrendChart.vue';
import { useSession } from '../../state/session';
import { dateKey, formatTime, formatDay, formatFull, showError } from '../../utils/format';

const session = useSession();
onShow(() => session.boot().catch(showError));

const today = computed(() => dateKey());
const symptomFilter = ref('全部');
const trendMetrics = ['疼痛', '乏力', '睡眠', '心情', '食欲', '体温', '体重'];
const trendMetric = ref('疼痛');
const trendDays = ref(7);

function timeOf(record: any) {
  return record.measuredAt || record.createdAt || record.recordDate;
}

const scoreLabels: Record<string, string> = {
  painScore: '疼痛', fatigueScore: '乏力', sleepScore: '睡眠', moodScore: '心情', appetiteScore: '食欲',
};

// —— 汇总磁贴 ——
const latestTemp = computed(() => session.data.body.find((r: any) => r.temperature !== null && r.temperature !== undefined) || null);
const latestWeight = computed(() => session.data.body.find((r: any) => r.weight !== null && r.weight !== undefined) || null);

// —— 今天的体温 ——
const todayTemps = computed(() => session.data.body
  .filter((r: any) => r.temperature !== null && r.temperature !== undefined && r.recordDate === today.value)
  .map((r: any) => ({ id: r.id, temp: r.temperature, time: formatTime(timeOf(r)), note: r.note || '' }))
  .sort((a: any, b: any) => b.time.localeCompare(a.time)));

// —— 用药 ——
const todayMedications = computed(() => session.data.medications
  .filter((m: any) => dateKey(m.takenAt) === today.value)
  .sort((a: any, b: any) => +new Date(b.takenAt) - +new Date(a.takenAt)));
const recentMedications = computed(() => {
  const cutoff = Date.now() - 7 * 86400000;
  return session.data.medications
    .filter((m: any) => dateKey(m.takenAt) !== today.value && +new Date(m.takenAt) >= cutoff)
    .sort((a: any, b: any) => +new Date(b.takenAt) - +new Date(a.takenAt));
});
function medMeta(m: any) {
  return [m.dosage, m.note].filter(Boolean).join(' · ');
}

// —— 症状 ——
const todaySymptoms = computed(() => session.data.symptoms.filter((s: any) => dateKey(s.happenedAt) === today.value));
const symptomTags = computed(() => ['全部', ...Array.from(new Set(session.data.symptoms.map((s: any) => s.tag).filter(Boolean)))]);
function matchFilter(s: any) { return symptomFilter.value === '全部' || s.tag === symptomFilter.value; }
const filteredToday = computed(() => todaySymptoms.value.filter(matchFilter)
  .sort((a: any, b: any) => +new Date(b.happenedAt) - +new Date(a.happenedAt)));
const filteredRecent = computed(() => {
  const cutoff = Date.now() - 7 * 86400000;
  return session.data.symptoms
    .filter((s: any) => dateKey(s.happenedAt) !== today.value && +new Date(s.happenedAt) >= cutoff && matchFilter(s))
    .sort((a: any, b: any) => +new Date(b.happenedAt) - +new Date(a.happenedAt));
});

// —— 评分记录 ——
const scoreRows = computed(() => {
  const rows: any[] = [];
  for (const r of session.data.body as any[]) {
    const scores = Object.entries(scoreLabels)
      .filter(([field]) => r[field] !== null && r[field] !== undefined && r[field] !== '')
      .map(([field, label]) => ({ label, value: r[field] }));
    if (!scores.length) continue;
    rows.push({ id: r.id, date: formatDay(r.createdAt || r.recordDate), time: formatTime(r.createdAt || r.recordDate), scores, note: r.note || '' });
    if (rows.length >= 8) break;
  }
  return rows;
});

function goCompose(type: string) {
  uni.navigateTo({ url: `/pages/compose/index?type=${type}` });
}

// —— 全部记录：四类记录的完整历史，支持时间范围过滤与关键字搜索 ——
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
const allOpen = ref(false);
const allKind = ref('symptom');
const allDays = ref<number | null>(30);
const allFrom = ref('');
const allTo = ref('');
const allQuery = ref('');

function openAll(kind: string) {
  allKind.value = kind;
  allOpen.value = true;
}
function pickAllDays(days: number | null) {
  allDays.value = days;
  allFrom.value = '';
  allTo.value = '';
}
function resetAllFilter() {
  allDays.value = 30;
  allFrom.value = '';
  allTo.value = '';
  allQuery.value = '';
}
// 去掉小数末尾的 .0，让 38.0 显示成 38
function trimNumber(value: any) {
  const text = String(value ?? '').trim();
  return text.endsWith('.0') ? text.slice(0, -2) : text;
}

const allSource = computed(() => {
  const kind = allKind.value;
  const rows: any[] = [];
  if (kind === 'symptom') {
    for (const s of session.data.symptoms as any[]) {
      rows.push({ id: s.id, kind, time: s.happenedAt, title: s.tag, subtitle: s.note || '' });
    }
  } else if (kind === 'medication') {
    for (const m of session.data.medications as any[]) {
      rows.push({ id: m.id, kind, time: m.takenAt, title: m.name, subtitle: medMeta(m) });
    }
  } else if (kind === 'vital') {
    for (const r of session.data.body as any[]) {
      const parts: string[] = [];
      for (const [field, meta] of Object.entries(vitalFieldLabels)) {
        const value = r[field];
        if (value === null || value === undefined || value === '') continue;
        parts.push(`${meta[0]} ${trimNumber(value)}${meta[1]}`);
      }
      if (!parts.length) continue;
      rows.push({ id: r.id, kind, time: timeOf(r), title: parts.join(' · '), subtitle: r.note || '' });
    }
  } else {
    for (const r of session.data.body as any[]) {
      const parts = Object.entries(scoreLabels)
        .filter(([field]) => r[field] !== null && r[field] !== undefined && r[field] !== '')
        .map(([field, label]) => `${label} ${trimNumber(r[field])}`);
      if (!parts.length) continue;
      rows.push({ id: r.id, kind, time: r.createdAt || r.recordDate, title: parts.join(' · '), subtitle: r.note || '' });
    }
  }
  return rows.sort((a, b) => +new Date(b.time) - +new Date(a.time));
});

const allFiltered = computed(() => {
  let rows = allSource.value;
  if (allFrom.value || allTo.value) {
    const start = allFrom.value ? +new Date(`${allFrom.value}T00:00:00`) : null;
    const end = allTo.value ? +new Date(`${allTo.value}T23:59:59`) : null;
    rows = rows.filter((row) => {
      const at = +new Date(row.time);
      if (start !== null && at < start) return false;
      if (end !== null && at > end) return false;
      return true;
    });
  } else if (allDays.value) {
    const cutoff = Date.now() - allDays.value * 86400000;
    rows = rows.filter((row) => +new Date(row.time) >= cutoff);
  }
  const query = allQuery.value.trim().toLowerCase();
  if (query) {
    rows = rows.filter((row) => `${row.title} ${row.subtitle}`.toLowerCase().includes(query));
  }
  return rows;
});

const allGroups = computed(() => {
  const groups = new Map<string, any[]>();
  for (const row of allFiltered.value) {
    const key = dateKey(row.time);
    const list = groups.get(key) ?? [];
    list.push({ ...row, clock: formatTime(row.time) });
    groups.set(key, list);
  }
  const yesterday = dateKey(new Date(Date.now() - 86400000).toISOString());
  return Array.from(groups, ([day, items]) => ({
    day,
    label: day === today.value ? '今天' : day === yesterday ? '昨天' : day,
    items,
  }));
});
</script>

<template><view class="page"><PageHero eyebrow="BODY NOTES" title="身体" subtitle="只记录变化，不替你下结论。复诊时，把更清楚的信息交给医生。" :profile="session.isAuthed.value" />
  <view v-if="!session.hasSpace.value" class="card empty">登录并创建陪伴空间后，这里会显示身体记录。</view>
  <template v-else>
    <!-- 汇总磁贴 -->
    <view class="tile-grid">
      <view class="tile rose"><text class="tile-label">最新体温</text><text class="tile-value">{{ latestTemp ? latestTemp.temperature : '—' }}<text v-if="latestTemp" class="unit">℃</text></text><text class="tile-sub">{{ latestTemp ? formatFull(timeOf(latestTemp)) : '还没记过' }}</text></view>
      <view class="tile gold"><text class="tile-label">最新体重</text><text class="tile-value">{{ latestWeight ? latestWeight.weight : '—' }}<text v-if="latestWeight" class="unit">kg</text></text><text class="tile-sub">{{ latestWeight ? formatFull(timeOf(latestWeight)) : '还没记过' }}</text></view>
      <view class="tile amber"><text class="tile-label">今日症状</text><text class="tile-value">{{ todaySymptoms.length }}<text class="unit">次</text></text><text class="tile-sub">{{ todaySymptoms.length ? '见下方症状' : '今天还没有' }}</text></view>
    </view>

    <!-- 变化趋势 -->
    <view class="card">
      <view class="card-title"><text>变化趋势</text>
        <text class="link" @click="openAll('vital')">查看全部 ›</text>
        <view class="day-toggle">
          <text class="chip" :class="{ active: trendDays === 7 }" @click="trendDays = 7">7 天</text>
          <text class="chip" :class="{ active: trendDays === 30 }" @click="trendDays = 30">30 天</text>
        </view>
      </view>
      <view class="chips">
        <text v-for="m in trendMetrics" :key="m" class="chip" :class="{ active: trendMetric === m }" @click="trendMetric = m">{{ m }}</text>
      </view>
      <TrendChart :records="session.data.body" :metric="trendMetric" :days="trendDays" />
    </view>

    <!-- 今天的体温 -->
    <view v-if="todayTemps.length" class="card">
      <view class="card-title"><text>今天的体温</text><text class="tag">{{ todayTemps.length }} 次</text></view>
      <view class="temp-readings">
        <view v-for="t in todayTemps" :key="t.id" class="temp-reading"><text class="temp-num">{{ t.temp }}<text class="unit">℃</text></text><text class="temp-clock">{{ t.time }}</text><text v-if="t.note" class="temp-note">{{ t.note }}</text></view>
      </view>
    </view>

    <!-- 用药记录 -->
    <view class="card">
      <view class="card-title"><text>用药记录</text><text class="link" @click="openAll('medication')">查看全部 ›</text><text class="tag">{{ todayMedications.length ? `今天 ${todayMedications.length} 次` : '今天还没记' }}</text></view>
      <view v-if="!todayMedications.length && !recentMedications.length" class="empty">还没有用药记录。点右下角「＋」记一次服药，别忘了吃药。</view>
      <template v-if="todayMedications.length">
        <text class="subhead">今天</text>
        <button v-for="m in todayMedications" :key="m.id" class="log-row" @click="goCompose('medication')"><text class="log-time">{{ formatTime(m.takenAt) }}</text><view class="log-main"><text class="log-title">{{ m.name }}</text><text v-if="medMeta(m)" class="log-meta">{{ medMeta(m) }}</text></view><text class="arrow">›</text></button>
      </template>
      <template v-if="recentMedications.length">
        <text class="subhead">最近 7 天</text>
        <button v-for="m in recentMedications" :key="m.id" class="log-row" @click="goCompose('medication')"><text class="log-time">{{ formatDay(m.takenAt) }} {{ formatTime(m.takenAt) }}</text><view class="log-main"><text class="log-title">{{ m.name }}</text><text v-if="medMeta(m)" class="log-meta">{{ medMeta(m) }}</text></view><text class="arrow">›</text></button>
      </template>
    </view>

    <!-- 症状记录 -->
    <view class="card">
      <view class="card-title"><text>症状记录</text><text class="link" @click="openAll('symptom')">查看全部 ›</text><text class="tag">可查看</text></view>
      <view v-if="symptomTags.length > 1" class="chips">
        <text v-for="tag in symptomTags" :key="tag" class="chip" :class="{ active: symptomFilter === tag }" @click="symptomFilter = tag">{{ tag }}</text>
      </view>
      <view v-if="!filteredToday.length && !filteredRecent.length" class="empty">没有匹配的症状记录。</view>
      <template v-if="filteredToday.length">
        <text class="subhead">今天</text>
        <view v-for="s in filteredToday" :key="s.id" class="log-row"><text class="log-time">{{ formatTime(s.happenedAt) }}</text><view class="log-main"><text class="log-title">{{ s.tag }}</text><text v-if="s.note" class="log-meta">{{ s.note }}</text></view></view>
      </template>
      <template v-if="filteredRecent.length">
        <text class="subhead">最近 7 天</text>
        <view v-for="s in filteredRecent" :key="s.id" class="log-row"><text class="log-time">{{ formatDay(s.happenedAt) }} {{ formatTime(s.happenedAt) }}</text><view class="log-main"><text class="log-title">{{ s.tag }}</text><text v-if="s.note" class="log-meta">{{ s.note }}</text></view></view>
      </template>
    </view>

    <!-- 评分记录 -->
    <view class="card">
      <view class="card-title"><text>评分记录</text><text class="link" @click="openAll('score')">查看全部 ›</text><text class="tag">最近 {{ scoreRows.length }} 条</text></view>
      <view v-if="!scoreRows.length" class="empty">还没有评分记录。</view>
      <view v-for="row in scoreRows" :key="row.id" class="score-row">
        <view class="score-date"><text class="sd-day">{{ row.date }}</text><text class="sd-time">{{ row.time }}</text></view>
        <view class="score-pills">
          <text v-for="sc in row.scores" :key="sc.label" class="score-pill">{{ sc.label }} {{ sc.value }}</text>
        </view>
      </view>
    </view>

    <view class="card boundary">身体记录不能替代医生判断。如症状明显加重，请及时联系医生或医院。</view>
    <ComposeFab type="body" />

    <!-- 全部记录 -->
    <view v-if="allOpen" class="sheet-mask" @click="allOpen = false">
      <view class="sheet" @click.stop>
        <view class="sheet-head">
          <text class="sheet-title">全部记录</text>
          <text class="sheet-close" @click="allOpen = false">关闭</text>
        </view>
        <view class="chips">
          <text v-for="(label, kind) in recordKindLabels" :key="kind" class="chip" :class="{ active: allKind === kind }" @click="allKind = kind">{{ label }}</text>
        </view>
        <view class="chips">
          <text class="chip" :class="{ active: !allFrom && !allTo && allDays === 7 }" @click="pickAllDays(7)">7 天</text>
          <text class="chip" :class="{ active: !allFrom && !allTo && allDays === 30 }" @click="pickAllDays(30)">30 天</text>
          <text class="chip" :class="{ active: !allFrom && !allTo && allDays === 90 }" @click="pickAllDays(90)">90 天</text>
          <text class="chip" :class="{ active: !allFrom && !allTo && !allDays }" @click="pickAllDays(null)">全部</text>
        </view>
        <view class="range-row">
          <picker mode="date" :value="allFrom" @change="allFrom = $event.detail.value">
            <text class="range-pick">{{ allFrom || '开始日期' }}</text>
          </picker>
          <text class="range-sep">至</text>
          <picker mode="date" :value="allTo" @change="allTo = $event.detail.value">
            <text class="range-pick">{{ allTo || '结束日期' }}</text>
          </picker>
        </view>
        <input v-model="allQuery" class="search-input" type="text" :placeholder="`搜索${recordKindLabels[allKind]}内容或备注`" />
        <view class="sheet-meta">
          <text>{{ allFiltered.length === allSource.length ? `共 ${allSource.length} 条` : `筛选出 ${allFiltered.length} 条 / 共 ${allSource.length} 条` }}</text>
          <text v-if="allFrom || allTo || allQuery || allDays !== 30" class="link" @click="resetAllFilter">重置筛选</text>
        </view>
        <scroll-view scroll-y class="sheet-scroll">
          <view v-if="!allFiltered.length" class="empty">这个时间范围内没有{{ recordKindLabels[allKind] }}记录。</view>
          <template v-for="group in allGroups" :key="group.day">
            <text class="subhead">{{ group.label }} · {{ group.items.length }} 条</text>
            <view v-for="row in group.items" :key="`${row.kind}-${row.id}-${row.time}`" class="log-row">
              <text class="log-time">{{ row.clock }}</text>
              <view class="log-main">
                <text class="log-title">{{ row.title }}</text>
                <text v-if="row.subtitle" class="log-meta">{{ row.subtitle }}</text>
              </view>
            </view>
          </template>
        </scroll-view>
      </view>
    </view>
  </template>
</view></template>
