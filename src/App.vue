<script setup>
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { createApi } from './api';

import iconToday from './assets/icons/nav-today.svg';
import iconTimeline from './assets/icons/nav-timeline.svg';
import iconCalendar from './assets/icons/nav-calendar.svg';
import iconDoctor from './assets/icons/nav-doctor.svg';
import iconBody from './assets/icons/nav-body.svg';
import iconMessage from './assets/icons/nav-message.svg';
import iconFolder from './assets/icons/nav-folder.svg';
import iconChat from './assets/icons/action-chat.svg';
import iconPrivacy from './assets/icons/status-privacy.svg';
import iconWarning from './assets/icons/status-warning.svg';
import iconLock from './assets/icons/status-lock.svg';

const disclaimer =
  '仅用于陪伴协作和就诊整理；诊断、用药和治疗以医生意见为准。';

const navItems = [
  { id: 'today', label: '今天', icon: iconToday },
  { id: 'timeline', label: '时间线', icon: iconTimeline },
  { id: 'moments', label: '分享', icon: iconChat },
  { id: 'body', label: '身体', icon: iconBody },
  { id: 'notices', label: '注意', icon: iconWarning },
];

const view = ref('today');
const toastText = ref('');
const loading = ref(false);
const dialog = ref({
  open: false,
  mode: 'confirm',
  eyebrow: '',
  title: '',
  message: '',
  icon: iconLock,
  fields: [],
  values: {},
  confirmText: '确认',
  cancelText: '取消',
  danger: false,
  resolver: null,
});
const token = ref(localStorage.getItem('care-today-token') || '');
const currentUser = ref(JSON.parse(localStorage.getItem('care-today-user') || 'null'));
const activeSpaceId = ref(localStorage.getItem('care-today-space-id') || '');
const authMode = ref('login');
const authForm = ref({
  email: '',
  phone: '',
  nickname: '',
  password: '',
});
const spaceForm = ref({
  name: '今天',
  patientNickname: '',
  description: '',
});
const statusNote = ref('');
const statusDraft = ref('');
const messageDraft = ref('');
const questionDraft = ref('');
const noteDraft = ref('');
const composerOpen = ref(false);
const questionsOpen = ref(false);
const folderOpen = ref(false);
const membersOpen = ref(false);
const currentRole = ref(localStorage.getItem('care-today-role') || '');
const trendMetric = ref('疼痛');
const trendDays = ref(7);
const symptomFilter = ref('全部');
const bodyFormOpen = ref(false);
const symptomFormOpen = ref(false);
const symptomPresets = ['大便', '腹泻', '发烧', '乏力', '疼痛', '手脚发麻'];
const symptomDraft = ref({ tag: '', customTag: '', happenedAt: '', note: '' });
const symptoms = ref([]);
const detailItem = ref(null);
const detailEditing = ref(false);
const detailEditValues = ref({});
const invitePhone = ref('');
const privacyAccepted = ref(false);
const api = createApi(() => token.value);

const spaces = ref([]);
const activeSpace = ref(null);
const events = ref([]);
const bodyRecordItems = ref([]);

const bodyRecords = ref([
  { label: '疼痛', value: 3 },
  { label: '乏力', value: 6 },
  { label: '睡眠', value: 5 },
  { label: '心情', value: 4 },
  { label: '食欲', value: 5 },
]);
const scoreFieldByLabel = {
  疼痛: 'painScore',
  乏力: 'fatigueScore',
  睡眠: 'sleepScore',
  心情: 'moodScore',
  食欲: 'appetiteScore',
};

const questions = ref([]);
const messages = ref([]);
const notes = ref([]);
const notices = ref([]);
const members = ref([]);

const activeNav = computed(() => navItems.find((item) => item.id === view.value));
const isAuthed = computed(() => Boolean(token.value && currentUser.value));
const hasSpace = computed(() => Boolean(activeSpaceId.value));
const todayKey = computed(() => toDateKey(new Date()));
const todayLabel = computed(() => new Date().toLocaleDateString('zh-CN', { month: 'long', day: 'numeric' }));
const nextFutureEvent = computed(() => {
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);
  return upcomingEvents.value.find((event) => new Date(event.scheduledAt) >= startOfToday) || null;
});
const nextVisitLabel = computed(() => nextFutureEvent.value?.date || '待添加');
const nextVisitCountdown = computed(() => {
  if (!nextFutureEvent.value) return null;
  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);
  const eventDay = new Date(nextFutureEvent.value.scheduledAt);
  eventDay.setHours(0, 0, 0, 0);
  return Math.round((eventDay - startOfToday) / 86400000);
});
const todayEvents = computed(() => events.value.filter((event) => event.dateKey === todayKey.value));
const todayItems = computed(() =>
  todayEvents.value
    .map((event) => ({
      id: `event-${event.id}`,
      time: event.time,
      title: event.title,
      desc: event.note || event.place,
      tag: event.tag,
      at: event.scheduledAt,
    }))
    .sort((a, b) => new Date(a.at) - new Date(b.at))
);
const isPatient = computed(() => currentRole.value === 'PATIENT_ADMIN');
const activeNotices = computed(() =>
  notices.value.filter((notice) => {
    if (notice.archived) return false;
    if (notice.startsOn && notice.startsOn > todayKey.value) return false;
    if (notice.endsOn && notice.endsOn < todayKey.value) return false;
    return true;
  })
);
const archivedNotices = computed(() => notices.value.filter((notice) => notice.archived));
const todaySymptoms = computed(() => symptoms.value.filter((symptom) => symptom.dateKey === todayKey.value));
const recentSymptoms = computed(() => {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 7);
  return symptoms.value.filter(
    (symptom) => symptom.dateKey !== todayKey.value && new Date(symptom.happenedAt) >= cutoff
  );
});
const symptomFilterOptions = computed(() => {
  const tags = Array.from(new Set(symptoms.value.map((symptom) => symptom.tag).filter(Boolean)));
  return ['全部', ...tags.sort((a, b) => a.localeCompare(b, 'zh-CN'))];
});
const filterSymptoms = (items) => (
  symptomFilter.value === '全部' ? items : items.filter((symptom) => symptom.tag === symptomFilter.value)
);
const filteredTodaySymptoms = computed(() => filterSymptoms(todaySymptoms.value));
const filteredRecentSymptoms = computed(() => filterSymptoms(recentSymptoms.value));
const upcomingEvents = computed(() =>
  events.value.slice().sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt))
);
function bodyTimeOf(record) {
  return record.measuredAt || record.createdAt || record.recordDate;
}
const latestTempReading = computed(() => bodyRecordItems.value.find((r) => r.temperature !== null && r.temperature !== undefined) || null);
const latestWeightReading = computed(() => bodyRecordItems.value.find((r) => r.weight !== null && r.weight !== undefined) || null);
const todayTempReadings = computed(() =>
  bodyRecordItems.value
    .filter((r) => r.temperature !== null && r.temperature !== undefined && (r.recordDate === todayKey.value))
    .map((r) => ({
      id: r.id,
      raw: r,
      temp: r.temperature,
      time: new Date(bodyTimeOf(r)).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
      note: r.note || '',
      sortAt: bodyTimeOf(r),
    }))
    .sort((a, b) => new Date(b.sortAt) - new Date(a.sortAt))
);
const bodySummary = computed(() => [
  {
    label: '最新体温',
    value: latestTempReading.value ? `${latestTempReading.value.temperature}` : '—',
    unit: latestTempReading.value ? '℃' : '',
    sub: latestTempReading.value ? formatFullDateTime(bodyTimeOf(latestTempReading.value)) : '还没记过',
    accent: 'rose',
    kind: 'temperature',
    record: latestTempReading.value,
  },
  {
    label: '最新体重',
    value: latestWeightReading.value ? `${latestWeightReading.value.weight}` : '—',
    unit: latestWeightReading.value ? 'kg' : '',
    sub: latestWeightReading.value ? formatTimelineDate(bodyTimeOf(latestWeightReading.value)) + ' 记录' : '还没记过',
    accent: 'gold',
    kind: 'weight',
    record: latestWeightReading.value,
  },
  {
    label: '今日症状',
    value: `${todaySymptoms.value.length}`,
    unit: '次',
    sub: todaySymptoms.value.length ? '点下方查看' : '今天还没有',
    accent: 'amber',
    kind: 'symptoms',
    record: null,
  },
]);
const manageItem = ref(null);
const timelineItems = computed(() => {
  const items = [
    ...events.value.map((event) => ({
      id: `event-${event.id}`,
      kind: 'event',
      raw: event,
      type: '日程',
      title: event.title,
      meta: `${event.time} · ${event.place}`,
      detail: event.note || (event.needsCompanion ? '需要有人陪同' : '站内提醒'),
      at: event.scheduledAt,
      icon: iconCalendar,
      view: 'today',
      accent: 'rose',
      fields: [
        { label: '时间', value: formatFullDateTime(event.scheduledAt) },
        { label: '地点', value: event.place },
        { label: '陪同', value: event.needsCompanion ? '需要有人陪同' : '不需要陪同' },
        { label: '备注', value: event.note || '没有备注' },
      ],
    })),
    ...questions.value.map((question) => ({
      id: `question-${question.id}`,
      kind: 'question',
      raw: question,
      type: '问医生',
      title: question.text,
      meta: question.done ? '已问过医生' : question.important ? '重点问题' : '待复诊时确认',
      detail: question.answer || '还没有记录医生回复',
      at: question.createdAt,
      icon: iconDoctor,
      view: 'today',
      accent: 'blue',
      fields: [
        { label: '添加时间', value: formatFullDateTime(question.createdAt) },
        { label: '状态', value: `${question.done ? '已问过医生' : '待复诊时确认'}${question.important ? ' · 重点问题' : ''}` },
        { label: '医生答复', value: question.answer || '还没有记录医生回复' },
      ],
    })),
    ...messages.value.map((message) => ({
      id: `message-${message.id}`,
      kind: 'message',
      raw: message,
      type: '分享',
      title: message.text,
      meta: message.author,
      detail: '一条朋友圈动态',
      at: message.createdAt,
      icon: iconChat,
      view: 'moments',
      accent: 'rose',
      fields: [
        { label: '来自', value: message.author },
        { label: '时间', value: formatFullDateTime(message.createdAt) },
        { label: '内容', value: message.text },
      ],
    })),
    ...notes.value.map((note) => ({
      id: `note-${note.id}`,
      kind: 'note',
      raw: note,
      type: '资料',
      title: note.title,
      meta: `${note.type} · ${note.visibility}`,
      detail: note.content || '资料文本已保存',
      at: note.createdAt,
      icon: iconFolder,
      view: 'today',
      accent: 'sage',
      fields: [
        { label: '类型', value: note.type },
        { label: '可见范围', value: note.visibility },
        { label: '创建时间', value: formatFullDateTime(note.createdAt) },
        { label: '内容', value: note.content || '资料文本已保存' },
      ],
    })),
    ...notices.value.map(noticeTimelineItem),
  ];

  return items
    .filter((item) => item.at)
    .map((item) => ({
      ...item,
      dateLabel: formatTimelineDate(item.at),
      timeLabel: formatTimelineTime(item.at),
    }))
    .sort((a, b) => new Date(b.at) - new Date(a.at));
});
const timelineFutureItems = computed(() => timelineItems.value.filter((item) => isAfterToday(item.at)));
const timelinePastItems = computed(() => timelineItems.value.filter((item) => !isAfterToday(item.at)));
const bodyRecordPayload = computed(() => ({
  painScore: Number(bodyRecords.value.find((item) => item.label === '疼痛')?.value || 0),
  fatigueScore: Number(bodyRecords.value.find((item) => item.label === '乏力')?.value || 0),
  sleepScore: Number(bodyRecords.value.find((item) => item.label === '睡眠')?.value || 0),
  moodScore: Number(bodyRecords.value.find((item) => item.label === '心情')?.value || 0),
  appetiteScore: Number(bodyRecords.value.find((item) => item.label === '食欲')?.value || 0),
  note: statusDraft.value.trim(),
  recordDate: new Date().toISOString().slice(0, 10),
}));

const trendMetrics = ['疼痛', '乏力', '睡眠', '心情', '食欲', '体温', '体重'];
const trendMetricFields = {
  疼痛: 'painScore',
  乏力: 'fatigueScore',
  睡眠: 'sleepScore',
  心情: 'moodScore',
  食欲: 'appetiteScore',
  体温: 'temperature',
  体重: 'weight',
};
const scoreLabels = Object.keys(scoreFieldByLabel);
const measureMetrics = new Set(['体温', '体重']);
const trendPoints = computed(() => {
  const field = trendMetricFields[trendMetric.value];
  const isMeasure = measureMetrics.has(trendMetric.value);
  if (isMeasure) {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - trendDays.value);
    return bodyRecordItems.value
      .map((record) => {
        const raw = record[field];
        const at = bodyTimeOf(record);
        const date = new Date(at);
        if (raw === null || raw === undefined || raw === '' || Number.isNaN(date.getTime()) || date < cutoff) {
          return null;
        }
        const value = Number(raw);
        return Number.isNaN(value)
          ? null
          : {
              key: `${record.id}-${field}`,
              at: date,
              label: formatChartTime(date, trendMetric.value === '体温'),
              value,
            };
      })
      .filter(Boolean)
      .sort((a, b) => a.at - b.at)
      .map((point, index) => ({ ...point, index }));
  }

  // bodyRecordItems is sorted newest-first; keep the latest non-null value per day for score metrics.
  const byDay = new Map();
  for (const record of bodyRecordItems.value) {
    const raw = record[field];
    if (raw === null || raw === undefined || raw === '') continue;
    const key = record.recordDate || toDateKey(new Date(record.createdAt));
    if (!byDay.has(key)) {
      byDay.set(key, Number(raw));
    }
  }
  const today = new Date();
  const points = [];
  for (let offset = trendDays.value - 1; offset >= 0; offset -= 1) {
    const date = new Date(today);
    date.setDate(today.getDate() - offset);
    const key = toDateKey(date);
    const value = byDay.has(key) ? byDay.get(key) : null;
    points.push({
      index: points.length,
      key,
      label: date.toLocaleDateString('zh-CN', { month: 'numeric', day: 'numeric' }),
      value: value === null || Number.isNaN(value) ? null : value,
    });
  }
  return points;
});
const trendChart = computed(() => {
  const points = trendPoints.value;
  const width = Math.max(360, points.length * 30 + 54);
  const height = 190;
  const padLeft = 40;
  const padRight = 14;
  const padTop = 14;
  const padBottom = 46;
  const values = points.filter((point) => point.value !== null).map((point) => point.value);
  let min = 0;
  let max = 10;
  let yTicks = [0, 2, 4, 6, 8, 10];
  if (trendMetric.value === '体温') {
    min = 34;
    max = 42;
    yTicks = [34, 36, 38, 40, 42];
  } else if (trendMetric.value === '体重') {
    const low = values.length ? Math.floor(Math.min(...values)) - 1 : 40;
    const high = values.length ? Math.ceil(Math.max(...values)) + 1 : 80;
    min = low === high ? low - 1 : low;
    max = low === high ? high + 1 : high;
    yTicks = buildNumericTicks(min, max, 5);
  }
  if (max <= min) {
    max = min + 1;
  }
  const plotWidth = width - padLeft - padRight;
  const plotHeight = height - padTop - padBottom;
  const step = points.length > 1 ? plotWidth / (points.length - 1) : 0;
  const pointX = (point) => padLeft + (points.length > 1 ? point.index * step : plotWidth / 2);
  const pointY = (value) => padTop + (1 - (value - min) / (max - min)) * plotHeight;
  const dots = points
    .filter((point) => point.value !== null)
    .map((point) => ({
      ...point,
      x: pointX(point),
      y: pointY(point.value),
      valueLabel: formatChartValue(point.value, trendMetric.value),
    }));
  const baseY = height - padBottom;
  const area = dots.length > 1
    ? `${dots[0].x.toFixed(1)},${baseY} ` + dots.map((dot) => `${dot.x.toFixed(1)},${dot.y.toFixed(1)}`).join(' ') + ` ${dots[dots.length - 1].x.toFixed(1)},${baseY}`
    : '';
  const xTicks = points.map((point) => ({
    key: point.key,
    x: pointX(point),
    y1: padTop,
    y2: baseY,
    label: point.label,
  }));
  const resolvedYTicks = yTicks.map((tick) => ({
    key: tick,
    value: tick,
    label: formatTickValue(tick),
    y: pointY(tick),
  }));
  return {
    width,
    height,
    padLeft,
    padRight,
    padTop,
    padBottom,
    baseY,
    chartRight: width - padRight,
    min,
    max,
    unit: trendMetric.value === '体温' ? '℃' : trendMetric.value === '体重' ? 'kg' : '分',
    dots,
    line: dots.map((dot) => `${dot.x.toFixed(1)},${dot.y.toFixed(1)}`).join(' '),
    area,
    xTicks,
    yTicks: resolvedYTicks,
    firstLabel: points[0]?.label || '',
    lastLabel: points[points.length - 1]?.label || '',
    rangeLabel: values.length ? `${formatTickValue(min)}–${formatTickValue(max)}` : '暂无数据',
    countLabel: measureMetrics.has(trendMetric.value) ? `${dots.length} 次记录` : `${dots.length} 天有记录`,
  };
});

const scoreRecordRows = computed(() =>
  bodyRecordItems.value
    .map((record) => {
      const scores = scoreLabels
        .map((label) => ({ label, value: record[scoreFieldByLabel[label]] }))
        .filter((item) => item.value !== null && item.value !== undefined && item.value !== '');
      if (!scores.length) return null;
      return {
        id: record.id,
        date: formatTimelineDate(record.createdAt || record.recordDate),
        time: formatTimelineTime(record.createdAt || record.recordDate),
        scores,
        note: record.note || '',
      };
    })
    .filter(Boolean)
    .slice(0, 8)
);

onMounted(() => {
  const invite = new URLSearchParams(window.location.search).get('invite');
  if (invite) {
    localStorage.setItem('care-today-invite', invite);
  }
  if (isAuthed.value) {
    loadSpaces().then(acceptPendingInvite);
  }
});

function showToast(text) {
  toastText.value = text;
  window.clearTimeout(showToast.timer);
  showToast.timer = window.setTimeout(() => {
    toastText.value = '';
  }, 1900);
}

function go(nextView) {
  view.value = nextView;
  if (nextView !== 'timeline') {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
}

watch(view, async (next) => {
  if (next !== 'timeline') return;
  await nextTick();
  // 有未来安排时停在顶部，先让用户看到「接下来」；否则定位到今天
  if (timelineFutureItems.value.length) {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  } else {
    document.getElementById('timeline-today-divider')?.scrollIntoView({ block: 'center', behavior: 'smooth' });
  }
});

function isAfterToday(value) {
  const endOfToday = new Date();
  endOfToday.setHours(23, 59, 59, 999);
  return new Date(value) > endOfToday;
}

function noticeTimelineItem(notice) {
  return {
    id: `notice-${notice.id}`,
    kind: 'notice',
    raw: notice,
    type: '注意',
    title: notice.content,
    meta: `${notice.important ? '重要 · ' : ''}${noticeRangeLabel(notice)}`,
    detail: notice.detail || '添加了一条注意事项',
    at: notice.createdAt,
    dateLabel: formatTimelineDate(notice.createdAt),
    timeLabel: formatTimelineTime(notice.createdAt),
    icon: iconWarning,
    view: 'notices',
    accent: 'amber',
    fields: [
      { label: '生效期', value: noticeRangeLabel(notice) },
      { label: '重要程度', value: notice.important ? '重要' : '一般' },
      { label: '补充说明', value: notice.detail || '没有补充说明' },
      { label: '添加时间', value: formatFullDateTime(notice.createdAt) },
    ],
  };
}

function noticeRangeLabel(notice) {
  if (notice.startsOn && notice.endsOn) return `${notice.startsOn} 至 ${notice.endsOn}`;
  if (notice.startsOn) return `${notice.startsOn} 起生效`;
  if (notice.endsOn) return `${notice.endsOn} 前有效`;
  return '长期有效';
}

function openTimelineDetail(item) {
  detailItem.value = item;
  detailEditing.value = false;
  detailEditValues.value = {};
}

const detailEditors = {
  event: editEvent,
  question: editQuestion,
  message: editMessage,
  note: editNote,
  notice: editNotice,
};

const detailEditable = computed(() => Boolean(detailItem.value && detailEditors[detailItem.value.kind]));
const detailEditFields = computed(() => buildDetailEditFields(detailItem.value));

async function editFromDetail() {
  const item = detailItem.value;
  if (!item) return;
  const editor = detailEditors[item.kind];
  if (!editor) return;
  detailItem.value = null;
  await editor(item.raw);
}

function beginDetailEdit() {
  const fields = detailEditFields.value;
  detailEditValues.value = Object.fromEntries(fields.map((field) => [field.name, field.value ?? '']));
  detailEditing.value = true;
}

function cancelDetailEdit() {
  detailEditing.value = false;
  detailEditValues.value = {};
}

function buildDetailEditFields(item) {
  if (!item) return [];
  const raw = item.raw;
  if (item.kind === 'event') {
    return [
      { name: 'title', label: '标题', value: raw.title, required: true },
      { name: 'scheduledAt', label: '时间', value: toLocalInputDateTime(raw.scheduledAt), required: true, type: 'datetime-local' },
      { name: 'location', label: '地点', value: raw.location || '' },
      { name: 'note', label: '备注', value: raw.note || '', type: 'textarea', rows: 2 },
      { name: 'needsCompanion', label: '需要陪同', value: Boolean(raw.needsCompanion), type: 'checkbox' },
    ];
  }
  if (item.kind === 'question') {
    return [
      { name: 'text', label: '问题', value: raw.text, required: true, type: 'textarea', rows: 2 },
      { name: 'answer', label: '答复', value: raw.answer || '', type: 'textarea', rows: 2 },
      { name: 'important', label: '重点问题', value: Boolean(raw.important), type: 'checkbox' },
      { name: 'done', label: '已问过', value: Boolean(raw.done), type: 'checkbox' },
    ];
  }
  if (item.kind === 'message') {
    return [{ name: 'text', label: '内容', value: raw.text, required: true, type: 'textarea', rows: 3 }];
  }
  if (item.kind === 'note') {
    return [
      { name: 'title', label: '标题', value: raw.title, required: true },
      { name: 'content', label: '内容', value: raw.content || '', type: 'textarea', rows: 3 },
    ];
  }
  if (item.kind === 'notice') {
    return [
      { name: 'content', label: '内容', value: raw.content, required: true, type: 'textarea', rows: 2 },
      { name: 'detail', label: '补充', value: raw.detail || '', type: 'textarea', rows: 2 },
      { name: 'startsOn', label: '开始', value: raw.startsOn || '', type: 'date' },
      { name: 'endsOn', label: '结束', value: raw.endsOn || '', type: 'date' },
      { name: 'important', label: '重要', value: Boolean(raw.important), type: 'checkbox' },
    ];
  }
  return [];
}

async function saveDetailEdit() {
  const item = detailItem.value;
  if (!item) return;
  for (const field of detailEditFields.value) {
    if (field.required && !String(detailEditValues.value[field.name] || '').trim()) {
      showToast(`请填写${field.label}`);
      return;
    }
  }
  const values = { ...detailEditValues.value };
  await withLoading(async () => {
    if (item.kind === 'event') {
      const scheduledAt = new Date(values.scheduledAt);
      if (Number.isNaN(scheduledAt.getTime())) {
        showToast('请选择有效的日程时间');
        return;
      }
      await api.updateEvent(activeSpaceId.value, item.raw.id, {
        title: values.title.trim(),
        scheduledAt: scheduledAt.toISOString(),
        location: values.location?.trim() || '',
        note: values.note?.trim() || '',
        needsCompanion: Boolean(values.needsCompanion),
      });
      await loadEvents();
    } else if (item.kind === 'question') {
      await api.updateDoctorQuestion(activeSpaceId.value, item.raw.id, {
        question: values.text.trim(),
        doctorAnswer: values.answer ?? '',
        important: Boolean(values.important),
        asked: Boolean(values.done),
      });
      await loadQuestions();
    } else if (item.kind === 'message') {
      await api.updateMessage(activeSpaceId.value, item.raw.id, { text: values.text.trim() });
      await loadMessages();
    } else if (item.kind === 'note') {
      await api.updateNote(activeSpaceId.value, item.raw.id, {
        title: values.title.trim(),
        content: values.content ?? '',
      });
      await loadNotes();
    } else if (item.kind === 'notice') {
      await api.updateNotice(activeSpaceId.value, item.raw.id, {
        content: values.content.trim(),
        detail: values.detail ?? '',
        startsOn: values.startsOn || null,
        endsOn: values.endsOn || null,
        important: Boolean(values.important),
      });
      await loadNotices();
    }
    const updated = timelineItems.value.find((candidate) => candidate.id === item.id);
    detailItem.value = updated || null;
    detailEditing.value = false;
    detailEditValues.value = {};
    showToast('已更新');
  });
}

function closeDetail() {
  detailItem.value = null;
  detailEditing.value = false;
  detailEditValues.value = {};
}

function openManage(kind, raw) {
  let descriptor;
  if (kind === 'notice') {
    descriptor = {
      kind,
      raw,
      eyebrow: '注意事项',
      title: raw.content,
      icon: iconWarning,
      lines: [
        { label: '生效期', value: noticeRangeLabel(raw) },
        { label: '补充说明', value: raw.detail || '没有补充说明' },
        { label: '状态', value: raw.archived ? '已归档' : '生效中' },
      ],
      actions: [
        { label: raw.important ? '取消重要' : '设为重要', run: () => toggleNoticeImportant(raw) },
        { label: '编辑', run: () => editNotice(raw) },
        { label: raw.archived ? '恢复' : '归档', run: () => archiveNotice(raw) },
        { label: '删除', danger: true, run: () => deleteNotice(raw) },
      ],
    };
  } else if (kind === 'message') {
    descriptor = {
      kind,
      raw,
      eyebrow: '分享',
      title: raw.text,
      icon: iconChat,
      lines: [{ label: '时间', value: `${raw.author} · ${raw.time}` }],
      actions: [
        { label: '编辑', run: () => editMessage(raw) },
        { label: '删除', danger: true, run: () => deleteMessage(raw) },
      ],
    };
  } else if (kind === 'symptom') {
    descriptor = {
      kind,
      raw,
      eyebrow: '症状记录',
      title: raw.tag,
      icon: iconBody,
      lines: [
        { label: '发生时间', value: raw.timeLabel },
        { label: '补充说明', value: raw.note || '没有补充说明' },
      ],
      actions: [
        { label: '编辑', run: () => editSymptom(raw) },
        { label: '删除', danger: true, run: () => deleteSymptom(raw) },
      ],
    };
  } else {
    return;
  }
  manageItem.value = descriptor;
}

function closeManage() {
  manageItem.value = null;
}

async function runManageAction(action) {
  manageItem.value = null;
  await action.run();
}


async function withLoading(action) {
  loading.value = true;
  try {
    await action();
  } catch (error) {
    showToast(error.message || '请求失败');
  } finally {
    loading.value = false;
  }
}

async function submitAuth() {
  await withLoading(async () => {
    const email = authForm.value.email.trim();
    const phone = authForm.value.phone.trim();
    const payload = {
      email: email || undefined,
      phone: phone || undefined,
      password: authForm.value.password,
      ...(authMode.value === 'register' ? { nickname: authForm.value.nickname.trim() || defaultNickname(email, phone) } : {}),
    };
    const result = authMode.value === 'register' ? await api.register(payload) : await api.login(payload);
    token.value = result.token;
    currentUser.value = result.user;
    localStorage.setItem('care-today-token', result.token);
    localStorage.setItem('care-today-user', JSON.stringify(result.user));
    spaceForm.value.patientNickname = result.user.nickname;
    showToast(authMode.value === 'register' ? '注册成功' : '登录成功');
    await loadSpaces();
    await acceptPendingInvite();
  });
}

function defaultNickname(email, phone) {
  if (email) {
    return email.split('@')[0];
  }
  return phone || '新成员';
}

async function confirmLogout() {
  const confirmed = await openConfirmDialog({
    eyebrow: '退出登录',
    title: '确认退出当前账号？',
    message: '退出后本机不会继续保留登录状态，重新进入陪伴空间需要再次登录。',
    icon: iconLock,
    confirmText: '确认退出',
    danger: true,
  });
  if (confirmed) {
    logout();
  }
}

function cancelLogout() {
  closeDialog(false);
}

function performLogout() {
  closeDialog(true);
}

function openConfirmDialog(options) {
  return new Promise((resolve) => {
    dialog.value = {
      open: true,
      mode: 'confirm',
      eyebrow: options.eyebrow || '确认操作',
      title: options.title,
      message: options.message || '',
      icon: options.icon || iconLock,
      fields: [],
      values: {},
      confirmText: options.confirmText || '确认',
      cancelText: options.cancelText || '取消',
      danger: Boolean(options.danger),
      onSubmit: null,
      resolver: resolve,
    };
  });
}

function openFormDialog(options) {
  return new Promise((resolve) => {
    const values = {};
    for (const field of options.fields || []) {
      values[field.name] = field.value ?? '';
    }
    dialog.value = {
      open: true,
      mode: 'form',
      eyebrow: options.eyebrow || '编辑',
      title: options.title,
      message: options.message || '',
      icon: options.icon || iconPrivacy,
      fields: options.fields || [],
      values,
      confirmText: options.confirmText || '保存',
      cancelText: options.cancelText || '取消',
      danger: Boolean(options.danger),
      onSubmit: options.onSubmit || null,
      resolver: resolve,
    };
  });
}

async function submitDialog() {
  if (dialog.value.onSubmit) {
    await dialog.value.onSubmit({ ...dialog.value.values });
    closeDialog({ ...dialog.value.values });
    return;
  }
  if (dialog.value.mode === 'form') {
    for (const field of dialog.value.fields) {
      if (field.required && !String(dialog.value.values[field.name] || '').trim()) {
        showToast(`请填写${field.label}`);
        return;
      }
    }
    closeDialog({ ...dialog.value.values });
    return;
  }
  closeDialog(true);
}

function closeDialog(result) {
  const resolver = dialog.value.resolver;
  dialog.value.open = false;
  dialog.value.resolver = null;
  dialog.value.onSubmit = null;
  if (resolver) {
    resolver(result);
  }
}

async function copyText(text) {
  if (navigator.clipboard?.writeText) {
    await navigator.clipboard.writeText(text);
    return true;
  }
  return false;
}

function logout() {
  token.value = '';
  currentUser.value = null;
  activeSpaceId.value = '';
  activeSpace.value = null;
  spaces.value = [];
  events.value = [];
  questions.value = [];
  messages.value = [];
  notes.value = [];
  notices.value = [];
  symptoms.value = [];
  members.value = [];
  currentRole.value = '';
  localStorage.removeItem('care-today-token');
  localStorage.removeItem('care-today-user');
  localStorage.removeItem('care-today-space-id');
  localStorage.removeItem('care-today-role');
  showToast('已退出登录');
}

async function loadSpaces() {
  await withLoading(async () => {
    spaces.value = await api.listSpaces();
    const selected = spaces.value.find((space) => space.id === activeSpaceId.value) || spaces.value[0];
    if (selected) {
      await selectSpace(selected.id);
    }
  });
}

async function createSpace() {
  await withLoading(async () => {
    const space = await api.createSpace({
      name: spaceForm.value.name.trim(),
      patientNickname: spaceForm.value.patientNickname.trim() || currentUser.value.nickname,
      description: spaceForm.value.description.trim() || undefined,
    });
    showToast('陪伴空间已创建');
    await selectSpace(space.id);
  });
}

async function selectSpace(spaceId) {
  activeSpaceId.value = spaceId;
  localStorage.setItem('care-today-space-id', spaceId);
  const detail = await api.getSpace(spaceId);
  activeSpace.value = detail.space;
  members.value = (detail.members || []).map(mapMember);
  currentRole.value = detail.currentRole || '';
  localStorage.setItem('care-today-role', currentRole.value);
  await Promise.all([loadEvents(), loadBodyRecords(), loadQuestions(), loadMessages(), loadNotes(), loadNotices(), loadSymptoms()]);
}

async function loadEvents() {
  events.value = (await api.listEvents(activeSpaceId.value)).map(mapEvent);
}

const fallbackScores = { 疼痛: 3, 乏力: 6, 睡眠: 5, 心情: 4, 食欲: 5 };

function latestValue(field) {
  for (const record of bodyRecordItems.value) {
    const raw = record[field];
    if (raw !== null && raw !== undefined && raw !== '') return raw;
  }
  return null;
}

async function loadBodyRecords() {
  bodyRecordItems.value = await api.listBodyRecords(activeSpaceId.value);
  bodyRecords.value = Object.entries(scoreFieldByLabel).map(([label, field]) => ({
    label,
    value: latestValue(field) ?? fallbackScores[label],
  }));
  const latestNote = bodyRecordItems.value.find((record) => record.note);
  statusNote.value = latestNote?.note || '';
}

async function loadQuestions() {
  questions.value = (await api.listDoctorQuestions(activeSpaceId.value)).map(mapQuestion);
}

async function loadMessages() {
  messages.value = (await api.listMessages(activeSpaceId.value)).map(mapMessage);
}

async function loadNotes() {
  notes.value = (await api.listNotes(activeSpaceId.value)).map(mapNote);
}

async function loadNotices() {
  notices.value = (await api.listNotices(activeSpaceId.value)).map(mapNotice);
}

async function loadSymptoms() {
  symptoms.value = (await api.listSymptoms(activeSpaceId.value)).map(mapSymptom);
}

function openBodyForm() {
  bodyFormOpen.value = true;
}

const todayDateKey = () => new Date().toISOString().slice(0, 10);
const nowLocalInput = () => {
  const d = new Date();
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().slice(0, 16);
};

function toLocalInputDateTime(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
  return date.toISOString().slice(0, 16);
}

async function saveStatus() {
  await withLoading(async () => {
    const result = await api.createBodyRecord(activeSpaceId.value, bodyRecordPayload.value);
    statusNote.value = result.record.note || '';
    statusDraft.value = '';
    bodyFormOpen.value = false;
    await loadBodyRecords();
    showToast('今天的身体状态已记录');
  });
}

async function openTempDialog() {
  const values = await openFormDialog({
    eyebrow: '体温',
    title: '记一次体温',
    message: '体温常一天测多次，可以选具体时间。',
    icon: iconBody,
    fields: [
      { name: 'temperature', label: '体温（℃）', value: '', required: true, type: 'number', placeholder: '例如 36.8' },
      { name: 'measuredAt', label: '测量时间', value: nowLocalInput(), type: 'datetime-local' },
      { name: 'note', label: '备注（可不填）', value: '', placeholder: '例如：服药后测的' },
    ],
    confirmText: '记下来',
  });
  if (!values) return;
  const temperature = Number(values.temperature);
  if (!values.temperature || Number.isNaN(temperature)) {
    showToast('填一个有效的体温');
    return;
  }
  const when = values.measuredAt ? new Date(values.measuredAt) : new Date();
  await withLoading(async () => {
    await api.createBodyRecord(activeSpaceId.value, {
      temperature,
      note: values.note?.trim() || undefined,
      recordDate: when.toISOString().slice(0, 10),
      measuredAt: when.toISOString(),
    });
    await loadBodyRecords();
    showToast(`已记录体温 ${temperature}℃`);
  });
}

async function openWeightDialog() {
  const values = await openFormDialog({
    eyebrow: '体重',
    title: '记一次体重',
    message: '默认记到今天，也可以补记到别的日期。',
    icon: iconBody,
    fields: [
      { name: 'weight', label: '体重（kg）', value: '', required: true, type: 'number', placeholder: '例如 55.5' },
      { name: 'recordDate', label: '日期', value: todayDateKey(), type: 'date' },
      { name: 'note', label: '备注（可不填）', value: '', placeholder: '例如：早晨空腹' },
    ],
    confirmText: '记下来',
  });
  if (!values) return;
  const weight = Number(values.weight);
  if (!values.weight || Number.isNaN(weight)) {
    showToast('填一个有效的体重');
    return;
  }
  await withLoading(async () => {
    await api.createBodyRecord(activeSpaceId.value, {
      weight,
      note: values.note?.trim() || undefined,
      recordDate: values.recordDate || todayDateKey(),
    });
    await loadBodyRecords();
    showToast(`已记录体重 ${weight} kg`);
  });
}

async function editBodyMeasure(record, kind) {
  if (!record) return;
  const temperatureMode = kind === 'temperature';
  const values = await openFormDialog({
    eyebrow: temperatureMode ? '体温' : '体重',
    title: temperatureMode ? '修改体温' : '修改体重',
    icon: iconBody,
    fields: temperatureMode
      ? [
          { name: 'temperature', label: '体温（℃）', value: record.temperature ?? '', required: true, type: 'number' },
          { name: 'measuredAt', label: '测量时间', value: toLocalInputDateTime(bodyTimeOf(record)), type: 'datetime-local' },
          { name: 'note', label: '备注', value: record.note || '' },
        ]
      : [
          { name: 'weight', label: '体重（kg）', value: record.weight ?? '', required: true, type: 'number' },
          { name: 'recordDate', label: '日期', value: record.recordDate || todayDateKey(), type: 'date' },
          { name: 'note', label: '备注', value: record.note || '' },
        ],
    confirmText: '保存修改',
  });
  if (!values) return;
  const amount = Number(temperatureMode ? values.temperature : values.weight);
  if (Number.isNaN(amount)) {
    showToast(temperatureMode ? '填一个有效的体温' : '填一个有效的体重');
    return;
  }
  await withLoading(async () => {
    if (temperatureMode) {
      const measuredAt = values.measuredAt ? new Date(values.measuredAt) : new Date(bodyTimeOf(record));
      if (Number.isNaN(measuredAt.getTime())) {
        showToast('请选择有效的测量时间');
        return;
      }
      await api.updateBodyRecord(activeSpaceId.value, record.id, {
        temperature: amount,
        measuredAt: measuredAt.toISOString(),
        recordDate: toDateKey(measuredAt),
        note: values.note?.trim() || '',
      });
    } else {
      await api.updateBodyRecord(activeSpaceId.value, record.id, {
        weight: amount,
        recordDate: values.recordDate || record.recordDate || todayDateKey(),
        note: values.note?.trim() || '',
      });
    }
    await loadBodyRecords();
    showToast(temperatureMode ? '体温已更新' : '体重已更新');
  });
}



function openSymptomForm() {
  const now = new Date();
  now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
  symptomDraft.value = { tag: '', customTag: '', happenedAt: now.toISOString().slice(0, 16), note: '' };
  symptomFormOpen.value = true;
}

async function addSymptom() {
  const tag = (symptomDraft.value.tag === '__custom__' ? symptomDraft.value.customTag : symptomDraft.value.tag).trim();
  if (!tag) {
    showToast('先选一个症状标签，或自己写一个');
    return;
  }
  if (!symptomDraft.value.happenedAt) {
    showToast('选一下发生的时间');
    return;
  }
  await withLoading(async () => {
    await api.createSymptom(activeSpaceId.value, {
      tag,
      happenedAt: new Date(symptomDraft.value.happenedAt).toISOString(),
      note: symptomDraft.value.note.trim() || undefined,
    });
    symptomFormOpen.value = false;
    await loadSymptoms();
    showToast(`已记下：${tag}`);
  });
}

async function editSymptom(symptom) {
  const values = await openFormDialog({
    eyebrow: '症状记录',
    title: `编辑「${symptom.tag}」`,
    icon: iconBody,
    fields: [
      { name: 'tag', label: '症状', value: symptom.tag, required: true },
      { name: 'note', label: '补充说明', value: symptom.note || '', type: 'textarea' },
    ],
  });
  if (!values) return;
  await withLoading(async () => {
    await api.updateSymptom(activeSpaceId.value, symptom.id, {
      tag: values.tag.trim(),
      note: values.note ?? symptom.note ?? '',
    });
    await loadSymptoms();
    showToast('症状记录已更新');
  });
}

async function deleteSymptom(symptom) {
  const confirmed = await openConfirmDialog({
    eyebrow: '删除症状记录',
    title: `删除「${symptom.tag}」这条记录？`,
    message: symptom.timeLabel,
    icon: iconBody,
    confirmText: '删除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteSymptom(activeSpaceId.value, symptom.id);
    await loadSymptoms();
    showToast('症状记录已删除');
  });
}

async function addQuestion() {
  if (!questionDraft.value.trim()) {
    showToast('先写下想问医生的问题');
    return;
  }
  await withLoading(async () => {
    await api.createDoctorQuestion(activeSpaceId.value, { question: questionDraft.value.trim(), important: false });
    questionDraft.value = '';
    await loadQuestions();
    showToast('已加入问医生清单');
  });
}

async function openEventDialog() {
  const values = await openFormDialog({
    eyebrow: '加日程',
    title: '添加一条日程',
    message: '复诊、检查、取报告、用药提醒都可以记在这里。',
    icon: iconCalendar,
    fields: [
      { name: 'title', label: '日程标题', value: '', required: true, placeholder: '例如：门诊复查' },
      { name: 'scheduledAt', label: '时间', value: '', required: true, type: 'datetime-local' },
      { name: 'location', label: '地点', value: '' },
      { name: 'note', label: '备注', value: '', type: 'textarea', placeholder: '例如：带上报告和问题清单' },
      { name: 'needsCompanion', label: '需要陪同', value: false, type: 'checkbox' },
    ],
    confirmText: '添加日程',
  });
  if (!values) return;
  await withLoading(async () => {
    await api.createEvent(activeSpaceId.value, {
      title: values.title.trim(),
      scheduledAt: new Date(values.scheduledAt).toISOString(),
      location: values.location?.trim() || undefined,
      note: values.note?.trim() || undefined,
      needsCompanion: Boolean(values.needsCompanion),
    });
    await loadEvents();
    showToast('日程已添加');
  });
}

async function editEvent(event) {
  const values = await openFormDialog({
    eyebrow: '日程安排',
    title: '编辑日程',
    icon: iconCalendar,
    fields: [
      { name: 'title', label: '日程标题', value: event.title, required: true },
      { name: 'scheduledAt', label: '时间', value: toLocalInputDateTime(event.scheduledAt), required: true, type: 'datetime-local' },
      { name: 'location', label: '地点', value: event.location || '' },
      { name: 'note', label: '备注', value: event.note || '', type: 'textarea' },
      { name: 'needsCompanion', label: '需要陪同', value: Boolean(event.needsCompanion), type: 'checkbox' },
    ],
  });
  if (!values) return;
  const scheduledAt = new Date(values.scheduledAt);
  if (Number.isNaN(scheduledAt.getTime())) {
    showToast('请选择有效的日程时间');
    return;
  }
  await withLoading(async () => {
    await api.updateEvent(activeSpaceId.value, event.id, {
      title: values.title.trim(),
      scheduledAt: scheduledAt.toISOString(),
      location: values.location?.trim() || '',
      note: values.note?.trim() || '',
      needsCompanion: Boolean(values.needsCompanion),
    });
    await loadEvents();
    showToast('日程已更新');
  });
}

async function deleteEvent(event) {
  const confirmed = await openConfirmDialog({
    eyebrow: '删除日程',
    title: `删除日程“${event.title}”？`,
    message: '删除后时间线和日历中不会再显示这条安排。',
    icon: iconCalendar,
    confirmText: '删除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteEvent(activeSpaceId.value, event.id);
    await loadEvents();
    showToast('日程已删除');
  });
}

async function toggleImportant(question) {
  await withLoading(async () => {
    await api.updateDoctorQuestion(activeSpaceId.value, question.id, { important: !question.important });
    await loadQuestions();
  });
}

async function editQuestion(question) {
  const values = await openFormDialog({
    eyebrow: '问医生',
    title: '编辑问题',
    icon: iconDoctor,
    fields: [
      { name: 'text', label: '问题', value: question.text, required: true, type: 'textarea' },
      { name: 'answer', label: '医生答复', value: question.answer || '', type: 'textarea' },
    ],
  });
  if (!values) return;
  await withLoading(async () => {
    await api.updateDoctorQuestion(activeSpaceId.value, question.id, {
      question: values.text.trim(),
      doctorAnswer: values.answer ?? question.answer ?? '',
    });
    await loadQuestions();
    showToast('问题已更新');
  });
}

async function deleteQuestion(question) {
  const confirmed = await openConfirmDialog({
    eyebrow: '删除问题',
    title: '删除这个问题？',
    message: question.text,
    icon: iconDoctor,
    confirmText: '删除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteDoctorQuestion(activeSpaceId.value, question.id);
    await loadQuestions();
    showToast('问题已删除');
  });
}

async function toggleQuestionAsked(question) {
  await withLoading(async () => {
    await api.updateDoctorQuestion(activeSpaceId.value, question.id, { asked: !question.done });
    await loadQuestions();
  });
}

const composerActions = [
  { id: 'message', label: '说说此刻', desc: '发布给家人看', icon: iconChat, patientOnly: true, bodyRelated: false },
  { id: 'event', label: '加日程', desc: '复诊、检查、提醒', icon: iconCalendar, bodyRelated: false },
  { id: 'bodyRecord', label: '记身体状态', desc: '疼痛、睡眠等评分', icon: iconBody, bodyRelated: true },
  { id: 'temperature', label: '记体温', desc: '测量时间和数值', icon: iconBody, bodyRelated: true },
  { id: 'weight', label: '记体重', desc: '日期和数值', icon: iconBody, bodyRelated: true },
  { id: 'symptom', label: '记症状', desc: '症状和发生时间', icon: iconBody, bodyRelated: true },
  { id: 'notice', label: '记注意事项', desc: '有效期内置顶', icon: iconWarning, bodyRelated: false },
  { id: 'question', label: '问医生的问题', desc: '复诊前确认', icon: iconDoctor, bodyRelated: false },
  { id: 'note', label: '存一条资料', desc: '报告、用药、医嘱', icon: iconFolder, bodyRelated: false },
];

const composerScope = {
  moments: ['message'],
  body: ['bodyRecord', 'temperature', 'weight', 'symptom'],
  notices: ['notice'],
};
const visibleComposerActions = computed(() =>
  composerActions.filter((action) => {
    if (action.patientOnly && !isPatient.value) return false;
    const scope = composerScope[view.value];
    if (scope) return scope.includes(action.id);
    return true;
  })
);

async function runComposerAction(action) {
  composerOpen.value = false;
  if (action.id === 'message') {
    const values = await openFormDialog({
      eyebrow: '说说此刻',
      title: '现在想说点什么？',
      message: '会发布到「分享」，家人朋友都能看到。',
      icon: iconMessage,
      fields: [{ name: 'text', label: '内容', value: '', required: true, type: 'textarea', placeholder: '此刻的想法、状态或想说的话' }],
      confirmText: '发布',
    });
    if (!values) return;
    messageDraft.value = values.text;
    await addMessage();
    go('moments');
    return;
  }
  if (action.id === 'event') {
    await openEventDialog();
    return;
  }
  if (action.id === 'bodyRecord') {
    openBodyForm();
    return;
  }
  if (action.id === 'temperature') {
    await openTempDialog();
    return;
  }
  if (action.id === 'weight') {
    await openWeightDialog();
    return;
  }
  if (action.id === 'symptom') {
    openSymptomForm();
    return;
  }
  if (action.id === 'notice') {
    await openNoticeDialog();
    return;
  }
  if (action.id === 'question') {
    const values = await openFormDialog({
      eyebrow: '问医生',
      title: '添加一个想问医生的问题',
      icon: iconDoctor,
      fields: [{ name: 'text', label: '问题', value: '', required: true, type: 'textarea' }],
      confirmText: '加入清单',
    });
    if (!values) return;
    questionDraft.value = values.text;
    await addQuestion();
    return;
  }
  if (action.id === 'note') {
    const values = await openFormDialog({
      eyebrow: '资料',
      title: '存一条复诊资料',
      icon: iconFolder,
      fields: [
        { name: 'title', label: '资料名称', value: '', required: true, placeholder: '报告名称、用药记录或医嘱备注' },
        { name: 'content', label: '内容', value: '', type: 'textarea' },
      ],
      confirmText: '保存',
    });
    if (!values) return;
    await withLoading(async () => {
      await api.createNote(activeSpaceId.value, {
        title: values.title.trim(),
        type: '文本资料',
        content: values.content?.trim() || '',
        visibility: 'PATIENT_ADMIN',
      });
      await loadNotes();
      showToast('资料已保存');
    });
  }
}



async function addMessage() {
  if (!messageDraft.value.trim()) {
    showToast('先写点什么');
    return;
  }
  await withLoading(async () => {
    await api.createMessage(activeSpaceId.value, { text: messageDraft.value.trim() });
    messageDraft.value = '';
    await loadMessages();
    showToast('动态已发布');
  });
}

async function editMessage(message) {
  const values = await openFormDialog({
    eyebrow: '动态',
    title: '编辑动态',
    icon: iconMessage,
    fields: [{ name: 'text', label: '内容', value: message.text, required: true, type: 'textarea' }],
  });
  if (!values) return;
  await withLoading(async () => {
    await api.updateMessage(activeSpaceId.value, message.id, { text: values.text.trim() });
    await loadMessages();
    showToast('动态已更新');
  });
}

async function deleteMessage(message) {
  const confirmed = await openConfirmDialog({
    eyebrow: '删除动态',
    title: '删除这条动态？',
    message: message.text,
    icon: iconMessage,
    confirmText: '删除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteMessage(activeSpaceId.value, message.id);
    await loadMessages();
    showToast('动态已删除');
  });
}

async function addNote() {
  if (!noteDraft.value.trim()) {
    showToast('先写一个资料名称');
    return;
  }
  await withLoading(async () => {
    await api.createNote(activeSpaceId.value, {
      title: noteDraft.value.trim(),
      type: '文本资料',
      content: '',
      visibility: 'PATIENT_ADMIN',
    });
    noteDraft.value = '';
    await loadNotes();
    showToast('资料记录已创建');
  });
}

async function editNote(note) {
  const values = await openFormDialog({
    eyebrow: '资料夹',
    title: '编辑资料',
    icon: iconFolder,
    fields: [
      { name: 'title', label: '资料标题', value: note.title, required: true },
      { name: 'content', label: '资料内容', value: note.content || '', type: 'textarea' },
    ],
  });
  if (!values) return;
  await withLoading(async () => {
    await api.updateNote(activeSpaceId.value, note.id, {
      title: values.title.trim(),
      content: values.content ?? note.content ?? '',
    });
    await loadNotes();
    showToast('资料已更新');
  });
}

async function deleteNote(note) {
  const confirmed = await openConfirmDialog({
    eyebrow: '删除资料',
    title: `删除资料“${note.title}”？`,
    message: '删除后资料夹里不会再显示这条记录。',
    icon: iconFolder,
    confirmText: '删除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteNote(activeSpaceId.value, note.id);
    await loadNotes();
    showToast('资料已删除');
  });
}

async function openNoticeDialog() {
  const values = await openFormDialog({
    eyebrow: '注意事项',
    title: '记一条注意事项',
    message: '医生叮嘱的禁忌和要小心的事。生效期间每天在「今天」页置顶提醒。',
    icon: iconWarning,
    fields: [
      { name: 'content', label: '要注意的事', value: '', required: true, placeholder: '例如：化疗期间避免生食' },
      { name: 'detail', label: '补充说明', value: '', type: 'textarea' },
      { name: 'startsOn', label: '开始日期（可不填）', value: '', type: 'date' },
      { name: 'endsOn', label: '结束日期（可不填，留空=长期）', value: '', type: 'date' },
      { name: 'important', label: '标为重要', value: false, type: 'checkbox' },
    ],
    confirmText: '记下来',
  });
  if (!values) return;
  await withLoading(async () => {
    await api.createNotice(activeSpaceId.value, {
      content: values.content.trim(),
      detail: values.detail?.trim() || undefined,
      important: Boolean(values.important),
      startsOn: values.startsOn || undefined,
      endsOn: values.endsOn || undefined,
    });
    await loadNotices();
    showToast('注意事项已记下，生效期间每天提醒');
  });
}

async function editNotice(notice) {
  const values = await openFormDialog({
    eyebrow: '注意事项',
    title: '编辑注意事项',
    icon: iconWarning,
    fields: [
      { name: 'content', label: '内容', value: notice.content, required: true, type: 'textarea' },
      { name: 'detail', label: '补充说明', value: notice.detail || '', type: 'textarea' },
    ],
  });
  if (!values) return;
  await withLoading(async () => {
    await api.updateNotice(activeSpaceId.value, notice.id, {
      content: values.content.trim(),
      detail: values.detail ?? notice.detail ?? '',
    });
    await loadNotices();
    showToast('注意事项已更新');
  });
}

async function toggleNoticeImportant(notice) {
  await withLoading(async () => {
    await api.updateNotice(activeSpaceId.value, notice.id, { important: !notice.important });
    await loadNotices();
  });
}

async function archiveNotice(notice) {
  await withLoading(async () => {
    await api.updateNotice(activeSpaceId.value, notice.id, { status: notice.archived ? 'ACTIVE' : 'ARCHIVED' });
    await loadNotices();
    showToast(notice.archived ? '注意事项已恢复' : '注意事项已归档');
  });
}

async function deleteNotice(notice) {
  const confirmed = await openConfirmDialog({
    eyebrow: '删除注意事项',
    title: '删除这条注意事项？',
    message: notice.content,
    icon: iconWarning,
    confirmText: '删除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteNotice(activeSpaceId.value, notice.id);
    await loadNotices();
    showToast('注意事项已删除');
  });
}

async function inviteMember() {
  await withLoading(async () => {
    const invite = await api.createMemberInvite(activeSpaceId.value, {
      nickname: invitePhone.value.trim() || '家人朋友',
      role: 'FRIEND',
    });
    invitePhone.value = '';
    const url = `${window.location.origin}${window.location.pathname}?invite=${invite.token || invite.id}`;
    const copied = await copyText(url);
    await openFormDialog({
      eyebrow: '邀请链接已生成',
      title: '把这条链接发给家人朋友',
      message: copied
        ? '链接已自动复制，直接粘贴到微信发给对方即可。对方打开登录后会自动加入，7 天内有效。'
        : '长按下面的链接复制后，发到微信给对方。对方打开登录后会自动加入，7 天内有效。',
      icon: iconLock,
      fields: [{ name: 'url', label: '邀请链接', value: url, type: 'textarea', readonly: true }],
      confirmText: copied ? '好的' : '再复制一次',
      onSubmit: async (values) => {
        await copyText(values.url);
        showToast('邀请链接已复制');
      },
    });
  });
}

async function acceptMember(member) {
  await withLoading(async () => {
    await api.acceptMember(activeSpaceId.value, member.id);
    const detail = await api.getSpace(activeSpaceId.value);
    members.value = (detail.members || []).map(mapMember);
    showToast('成员已确认加入');
  });
}

async function acceptPendingInvite() {
  const invite = localStorage.getItem('care-today-invite');
  if (!invite || !isAuthed.value) return;
  if (invite.includes(':')) {
    const [spaceId, memberId] = invite.split(':');
    if (spaceId && memberId) {
      await withLoading(async () => {
        await api.acceptMember(spaceId, memberId);
        localStorage.removeItem('care-today-invite');
        window.history.replaceState({}, document.title, window.location.pathname);
        await loadSpaces();
        showToast('已加入陪伴空间');
      });
      return;
    }
    localStorage.removeItem('care-today-invite');
    return;
  }
  await withLoading(async () => {
    await api.acceptMemberInvite(invite, { nickname: currentUser.value?.nickname });
    localStorage.removeItem('care-today-invite');
    window.history.replaceState({}, document.title, window.location.pathname);
    await loadSpaces();
    showToast('已加入陪伴空间');
  });
}

async function copyInviteLink(member) {
  await showInviteLink(member);
}

async function showInviteLink(invite) {
  const url = `${window.location.origin}${window.location.pathname}?invite=${invite.token || invite.id}`;
  const nickname = invite.nickname || invite.name || '家人朋友';
  await openFormDialog({
    eyebrow: '邀请链接',
    title: `邀请“${nickname}”加入`,
    message: '点击“复制链接”后发给家人朋友。对方打开后登录或注册，就会加入这个陪伴空间。',
    icon: iconLock,
    fields: [{ name: 'url', label: '邀请链接', value: url, type: 'textarea', readonly: true }],
    confirmText: '复制链接',
    onSubmit: async (values) => {
      const copied = await copyText(values.url);
      showToast(copied ? '邀请链接已复制' : '当前浏览器不支持自动复制，请手动复制链接');
    },
  });
}

async function removeMember(member) {
  const confirmed = await openConfirmDialog({
    eyebrow: '移除成员',
    title: `移除成员“${member.name}”？`,
    message: '移除后该成员将不能继续访问这个陪伴空间。',
    icon: iconLock,
    confirmText: '移除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.removeMember(activeSpaceId.value, member.id);
    const detail = await api.getSpace(activeSpaceId.value);
    members.value = (detail.members || []).map(mapMember);
    showToast('成员已移除');
  });
}

async function leaveSpace() {
  const confirmed = await openConfirmDialog({
    eyebrow: '退出空间',
    title: '退出当前陪伴空间？',
    message: '退出后你将无法访问这里的数据，除非管理员重新邀请你。',
    icon: iconLock,
    confirmText: '退出空间',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.leaveSpace(activeSpaceId.value);
    activeSpaceId.value = '';
    activeSpace.value = null;
    localStorage.removeItem('care-today-space-id');
    await loadSpaces();
    showToast('已退出空间');
  });
}

async function deleteAccount() {
  const confirmed = await openConfirmDialog({
    eyebrow: '删除账号',
    title: '删除账号会退出所有空间',
    message: '删除后当前账号将不能继续登录，必要审计信息会按规则保留。',
    icon: iconWarning,
    confirmText: '删除账号',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteAccount();
    logout();
    showToast('账号已删除');
  });
}

function mapEvent(event) {
  const date = new Date(event.scheduledAt);
  return {
    ...event,
    dateKey: toDateKey(date),
    time: date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
    date: date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' }),
    day: date.getDate(),
    place: event.location || '待补充地点',
    tag: event.needsCompanion ? '需要陪同' : '站内提醒',
  };
}

function toDateKey(date) {
  if (!(date instanceof Date) || Number.isNaN(date.getTime())) {
    return '';
  }
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function mapQuestion(question) {
  return {
    id: question.id,
    text: question.question,
    done: question.asked,
    important: question.important,
    answer: question.doctorAnswer,
    createdAt: question.createdAt,
  };
}

function mapMessage(message) {
  return {
    id: message.id,
    text: message.text,
    author: message.author,
    time: new Date(message.createdAt).toLocaleString('zh-CN'),
    createdAt: message.createdAt,
  };
}

function mapNote(note) {
  return {
    id: note.id,
    title: note.title,
    type: note.type,
    content: note.content,
    desc: new Date(note.createdAt).toLocaleString('zh-CN'),
    visibility: note.visibility === 'PATIENT_ADMIN' ? '患者和管理员可见' : '空间成员可见',
    createdAt: note.createdAt,
  };
}

function mapSymptom(symptom) {
  const happened = new Date(symptom.happenedAt);
  return {
    id: symptom.id,
    tag: symptom.tag,
    note: symptom.note || '',
    happenedAt: symptom.happenedAt,
    dateKey: toDateKey(happened),
    timeLabel: happened.toLocaleString('zh-CN', { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' }),
    clock: happened.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
    createdAt: symptom.createdAt,
  };
}

function mapNotice(notice) {
  return {
    id: notice.id,
    content: notice.content,
    detail: notice.detail || '',
    important: notice.important,
    startsOn: notice.startsOn || '',
    endsOn: notice.endsOn || '',
    archived: notice.status === 'ARCHIVED',
    createdAt: notice.createdAt,
  };
}

function formatTimelineDate(value) {
  if (!value) return '待记录';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '待记录';
  const sameYear = date.getFullYear() === new Date().getFullYear();
  return date.toLocaleDateString('zh-CN', sameYear ? { month: 'short', day: 'numeric' } : { year: 'numeric', month: 'short', day: 'numeric' });
}

function formatTimelineTime(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' });
}

function formatFullDateTime(value) {
  if (!value) return '待记录';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '待记录';
  return date.toLocaleString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

function formatChartTime(value, includeTime = false) {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  const options = includeTime
    ? { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' }
    : { month: 'numeric', day: 'numeric' };
  return date.toLocaleString('zh-CN', options);
}

function formatChartValue(value, metric) {
  if (metric === '体温') return Number(value).toFixed(1);
  if (metric === '体重') return Number(value).toFixed(1).replace(/\.0$/, '');
  return String(Math.round(Number(value)));
}

function formatTickValue(value) {
  return Number.isInteger(value) ? String(value) : Number(value).toFixed(1).replace(/\.0$/, '');
}

function buildNumericTicks(min, max, count) {
  if (count <= 1 || max <= min) return [min, max];
  const step = (max - min) / (count - 1);
  return Array.from({ length: count }, (_, index) => Number((min + step * index).toFixed(1)));
}

function mapMember(member) {
  const roleMap = {
    PATIENT_ADMIN: '患者/管理员',
    FAMILY: '家属',
    FRIEND: '朋友',
    READONLY: '只读成员',
  };
  const statusMap = {
    ACTIVE: '已加入',
    PENDING: '待确认',
    REMOVED: '已移除',
  };
  return {
    id: member.id,
    name: member.nickname,
    role: roleMap[member.role] || member.role,
    access: member.role === 'PATIENT_ADMIN' ? '完整管理权限' : '按空间授权访问',
    status: statusMap[member.status] || member.status,
  };
}
</script>

<template>
  <div class="app-shell">
    <aside class="sidebar">
      <button class="brand" type="button" @click="go('today')">
        <span class="brand-mark">
          <img :src="iconToday" alt="" aria-hidden="true" />
        </span>
        <span>
          <strong>CareToday</strong>
          <small>今天</small>
        </span>
      </button>

      <nav class="nav" aria-label="页面导航">
        <button
          v-for="item in navItems"
          :key="item.id"
          class="nav-item"
          :class="{ active: item.id === view }"
          type="button"
          @click="go(item.id)"
        >
          <img class="icon" :src="item.icon" alt="" aria-hidden="true" />
          <span>{{ item.label }}</span>
        </button>
      </nav>

      <div class="side-note">
        <img class="icon" :src="iconPrivacy" alt="" aria-hidden="true" />
        <span>{{ disclaimer }}</span>
      </div>
    </aside>

    <main>
      <section class="topbar">
        <div>
          <h1>{{ activeNav?.label || '今天' }}</h1>
        </div>
        <div class="top-actions">
          <div class="privacy-pill">
            <img class="icon" :src="iconPrivacy" alt="" aria-hidden="true" />
            仅自己和被授权成员可见
          </div>
          <button v-if="isAuthed && hasSpace" class="small-btn" type="button" @click="membersOpen = true">成员 · 邀请家人</button>
          <button v-if="isAuthed" class="small-btn sage" type="button" @click="confirmLogout">{{ currentUser.nickname }} · 退出</button>
        </div>
      </section>

      <section v-if="!isAuthed" class="single-stack">
        <article class="card auth-card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconLock" alt="" aria-hidden="true" />
              <h2>{{ authMode === 'login' ? '登录陪伴空间' : '注册账号' }}</h2>
            </div>
            <span class="tag">后端保存</span>
          </header>
          <div class="card-body">
            <div class="auth-grid">
              <input v-model="authForm.email" type="email" placeholder="邮箱，例如 927990956@qq.com" />
              <input v-model="authForm.phone" type="text" placeholder="手机号，可选" />
              <input v-if="authMode === 'register'" v-model="authForm.nickname" type="text" placeholder="昵称" />
              <input v-model="authForm.password" type="password" placeholder="密码" />
            </div>
            <div class="form-row">
              <button class="small-btn sage" type="button" :disabled="loading" @click="submitAuth">
                {{ authMode === 'login' ? '登录' : '注册并登录' }}
              </button>
              <button class="small-btn" type="button" @click="authMode = authMode === 'login' ? 'register' : 'login'">
                {{ authMode === 'login' ? '去注册' : '已有账号' }}
              </button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="!hasSpace" class="single-stack">
        <article class="card auth-card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconPrivacy" alt="" aria-hidden="true" />
              <h2>创建陪伴空间</h2>
            </div>
            <span class="tag">第一位成员将成为管理员</span>
          </header>
          <div class="card-body">
            <div class="auth-grid">
              <input v-model="spaceForm.name" type="text" placeholder="空间名称" />
              <input v-model="spaceForm.patientNickname" type="text" placeholder="患者昵称" />
              <input v-model="spaceForm.description" type="text" placeholder="诊疗阶段备注，可选" />
            </div>
            <label class="consent-row">
              <input v-model="privacyAccepted" type="checkbox" />
              <span>我了解这里会保存日程、身体记录、问题、分享和资料，用于就诊整理和家庭协作。</span>
            </label>
            <div class="form-row">
              <button class="small-btn sage" type="button" :disabled="!privacyAccepted || loading" @click="createSpace">创建空间</button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'today'" class="page-grid">
        <div class="main-stack">
          <article v-if="activeNotices.length" class="card pinned-notices">
            <header class="card-header">
              <div class="card-title">
                <span class="title-icon amber"><img :src="iconWarning" alt="" aria-hidden="true" /></span>
                <h2>要注意</h2>
              </div>
              <span class="tag">有效期内置顶</span>
            </header>
            <div class="card-body pinned-list">
              <button v-for="notice in activeNotices" :key="notice.id" class="pinned-notice" :class="{ important: notice.important }" type="button" @click="openManage('notice', notice)">
                <strong>{{ notice.content }}</strong>
                <span v-if="notice.detail">{{ notice.detail }}</span>
                <small>{{ noticeRangeLabel(notice) }}</small>
              </button>
            </div>
          </article>

          <article class="card">
            <header class="card-header">
              <div class="card-title">
                <img class="icon" :src="iconCalendar" alt="" aria-hidden="true" />
                <h2>今天要做的事</h2>
              </div>
              <span class="tag">下次复诊：{{ nextVisitLabel }}</span>
            </header>
            <div class="card-body today-grid">
              <div class="schedule">
                <p v-if="!todayItems.length" class="empty-note">今天没有日程。</p>
                <div v-for="item in todayItems" :key="item.id" class="schedule-row">
                  <strong class="time">{{ item.time }}</strong>
                  <div>
                    <strong>{{ item.title }}</strong>
                    <span>{{ item.desc }}</span>
                  </div>
                  <span class="tag">{{ item.tag }}</span>
                </div>
              </div>
              <div class="countdown">
                <span>距离下次复诊</span>
                <strong>{{ nextVisitCountdown === null ? '—' : nextVisitCountdown }}</strong>
                <small>{{ nextVisitCountdown === null ? '还没有安排日程。' : nextVisitCountdown === 0 ? '今天，把资料和问题带上。' : '提前整理资料和问题。' }}</small>
                <button class="small-btn" type="button" @click="questionsOpen = true">问题清单</button>
                <button class="small-btn" type="button" @click="folderOpen = true">复诊资料</button>
              </div>
            </div>
          </article>

        </div>

        <aside class="side-stack">
          <article class="card urgent">
            <header class="card-header">
              <div class="card-title">
                <img class="icon" :src="iconWarning" alt="" aria-hidden="true" />
                <h2>及时联系医生</h2>
              </div>
            </header>
            <div class="card-body">
              <ul class="compact-list">
                <li>持续发热、寒战或感染迹象。</li>
                <li>严重疼痛、呼吸困难、胸闷或晕厥。</li>
                <li>过敏、伤口异常或用药后不适加重。</li>
              </ul>
            </div>
          </article>

        </aside>
      </section>

      <section v-else-if="view === 'timeline'" class="single-stack timeline-page">
        <article class="card timeline-card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconTimeline" alt="" aria-hidden="true" />
              <h2>陪伴时间线</h2>
            </div>
            <span class="tag">{{ timelineItems.length ? `共 ${timelineItems.length} 条` : '暂无动态' }}</span>
          </header>
          <div class="card-body">
            <p v-if="!timelineItems.length" class="empty-note">还没有记录。点右下角「+」添加第一条。</p>
            <div v-else class="timeline-list">
              <div v-if="timelineFutureItems.length" class="timeline-section-head upcoming">
                <span>接下来</span>
                <em>{{ timelineFutureItems.length }} 项即将发生</em>
              </div>
              <button
                v-for="item in timelineFutureItems"
                :key="item.id"
                class="timeline-item"
                :class="`accent-${item.accent}`"
                type="button"
                @click="openTimelineDetail(item)"
              >
                <span class="timeline-date">{{ item.dateLabel }}<small>{{ item.timeLabel }}</small></span>
                <span class="timeline-pin">
                  <img :src="item.icon" alt="" aria-hidden="true" />
                </span>
                <span class="timeline-content">
                  <span class="timeline-topline">
                    <strong>{{ item.title }}</strong>
                    <em>{{ item.type }}</em>
                  </span>
                  <span>{{ item.meta }}</span>
                  <small>{{ item.detail }}</small>
                </span>
              </button>

              <div id="timeline-today-divider" class="timeline-divider" role="separator">
                <span>今天 · {{ todayLabel }}</span>
              </div>

              <p v-if="!timelinePastItems.length" class="empty-note">今天和之前还没有记录。</p>
              <button
                v-for="item in timelinePastItems"
                :key="item.id"
                class="timeline-item"
                :class="`accent-${item.accent}`"
                type="button"
                @click="openTimelineDetail(item)"
              >
                <span class="timeline-date">{{ item.dateLabel }}<small>{{ item.timeLabel }}</small></span>
                <span class="timeline-pin">
                  <img :src="item.icon" alt="" aria-hidden="true" />
                </span>
                <span class="timeline-content">
                  <span class="timeline-topline">
                    <strong>{{ item.title }}</strong>
                    <em>{{ item.type }}</em>
                  </span>
                  <span>{{ item.meta }}</span>
                  <small>{{ item.detail }}</small>
                </span>
              </button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'moments'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconChat" alt="" aria-hidden="true" />
              <h2>分享</h2>
            </div>
            <span class="tag">{{ isPatient ? '患者发布' : '仅患者可发布' }}</span>
          </header>
          <div class="card-body">
            <p v-if="!messages.length" class="empty-note">{{ isPatient ? '还没有分享。点右下角「+」发布近况。' : 'TA 还没有发过分享。' }}</p>
            <div v-else class="message-list moments-feed">
              <component :is="isPatient ? 'button' : 'div'" v-for="message in messages" :key="message.id" class="message" :class="{ tappable: isPatient }" type="button" @click="isPatient && openManage('message', message)">
                <p>{{ message.text }}</p>
                <span>{{ message.author }} · {{ message.time }}</span>
              </component>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'body'" class="single-stack">
        <div class="body-summary">
          <button
            v-for="tile in bodySummary"
            :key="tile.label"
            class="summary-tile"
            :class="[`accent-${tile.accent}`, { editable: tile.record }]"
            type="button"
            :aria-disabled="!tile.record"
            @click="tile.record && editBodyMeasure(tile.record, tile.kind)"
          >
            <span class="summary-label">{{ tile.label }}</span>
            <strong class="summary-value">{{ tile.value }}<em>{{ tile.unit }}</em></strong>
            <small>{{ tile.sub }}</small>
          </button>
        </div>

        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <span class="title-icon sage"><img :src="iconBody" alt="" aria-hidden="true" /></span>
              <h2>变化趋势</h2>
            </div>
            <div class="segmented">
              <button :class="{ active: trendDays === 7 }" type="button" @click="trendDays = 7">7 天</button>
              <button :class="{ active: trendDays === 30 }" type="button" @click="trendDays = 30">30 天</button>
            </div>
          </header>
          <div class="card-body">
            <div class="trend-metrics">
              <button
                v-for="metric in trendMetrics"
                :key="metric"
                class="trend-chip"
                :class="{ active: trendMetric === metric }"
                type="button"
                @click="trendMetric = metric"
              >
                {{ metric }}
              </button>
            </div>
            <p v-if="!trendChart.dots.length" class="empty-note">最近{{ trendDays }}天还没有{{ trendMetric }}记录。</p>
            <div v-else class="trend-chart">
              <svg :viewBox="`0 0 ${trendChart.width} ${trendChart.height}`" :style="{ minWidth: `${trendChart.width}px` }" preserveAspectRatio="xMidYMid meet" role="img" :aria-label="`${trendMetric}最近${trendDays}天趋势`">
                <defs>
                  <linearGradient id="trend-fill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="rgba(120,146,124,0.3)" />
                    <stop offset="100%" stop-color="rgba(120,146,124,0)" />
                  </linearGradient>
                </defs>
                <g class="trend-y-grid">
                  <template v-for="tick in trendChart.yTicks" :key="tick.key">
                    <line :x1="trendChart.padLeft" :y1="tick.y" :x2="trendChart.chartRight" :y2="tick.y" class="trend-grid" />
                    <text :x="trendChart.padLeft - 8" :y="tick.y + 4" text-anchor="end" class="trend-tick-label">{{ tick.label }}</text>
                  </template>
                </g>
                <g class="trend-x-grid">
                  <template v-for="tick in trendChart.xTicks" :key="tick.key">
                    <line :x1="tick.x" :y1="tick.y1" :x2="tick.x" :y2="tick.y2" class="trend-grid vertical" />
                    <text :x="tick.x" :y="trendChart.height - 18" text-anchor="middle" class="trend-tick-label trend-x-label">{{ tick.label }}</text>
                  </template>
                </g>
                <line :x1="trendChart.padLeft" :y1="trendChart.baseY" :x2="trendChart.chartRight" :y2="trendChart.baseY" class="trend-axis" />
                <line :x1="trendChart.padLeft" :y1="trendChart.padTop" :x2="trendChart.padLeft" :y2="trendChart.baseY" class="trend-axis" />
                <polygon v-if="trendChart.area" :points="trendChart.area" class="trend-area" />
                <polyline v-if="trendChart.dots.length > 1" :points="trendChart.line" class="trend-line" />
                <g v-for="dot in trendChart.dots" :key="dot.key" class="trend-point">
                  <circle :cx="dot.x" :cy="dot.y" r="3.2" class="trend-dot" />
                  <text :x="dot.x" :y="dot.y - 7" text-anchor="middle" class="trend-value-label">{{ dot.valueLabel }}</text>
                </g>
              </svg>
              <div class="trend-legend">
                <span>{{ trendChart.firstLabel }}</span>
                <span>{{ trendMetric }}（{{ trendChart.rangeLabel }}{{ trendChart.unit }}）· {{ trendChart.countLabel }}</span>
                <span>{{ trendChart.lastLabel }}</span>
              </div>
            </div>
          </div>
        </article>

        <article v-if="todayTempReadings.length" class="card">
          <header class="card-header">
            <div class="card-title">
              <span class="title-icon rose"><img :src="iconBody" alt="" aria-hidden="true" /></span>
              <h2>今天的体温</h2>
            </div>
            <span class="tag">{{ todayTempReadings.length }} 次</span>
          </header>
          <div class="card-body">
            <div class="temp-readings">
              <button v-for="reading in todayTempReadings" :key="reading.id" class="temp-reading" type="button" @click="editBodyMeasure(reading.raw, 'temperature')">
                <strong>{{ reading.temp }}<em>℃</em></strong>
                <span>{{ reading.time }}</span>
                <small v-if="reading.note">{{ reading.note }}</small>
              </button>
            </div>
          </div>
        </article>

        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <span class="title-icon amber"><img :src="iconBody" alt="" aria-hidden="true" /></span>
              <h2>症状记录</h2>
            </div>
            <span class="tag">可编辑</span>
          </header>
          <div class="card-body">
            <div v-if="symptomFilterOptions.length > 1" class="symptom-filter" aria-label="症状筛选">
              <button
                v-for="option in symptomFilterOptions"
                :key="option"
                class="symptom-filter-chip"
                :class="{ active: symptomFilter === option }"
                type="button"
                @click="symptomFilter = option"
              >
                {{ option }}
              </button>
            </div>
            <p v-if="!filteredTodaySymptoms.length && !filteredRecentSymptoms.length" class="empty-note">没有匹配的症状记录。</p>
            <template v-if="filteredTodaySymptoms.length">
              <h3 class="symptom-subhead">今天</h3>
              <div class="symptom-list">
                <button v-for="symptom in filteredTodaySymptoms" :key="symptom.id" class="symptom-row" type="button" @click="openManage('symptom', symptom)">
                  <strong class="time">{{ symptom.clock }}</strong>
                  <div>
                    <strong>{{ symptom.tag }}</strong>
                    <span v-if="symptom.note">{{ symptom.note }}</span>
                  </div>
                  <span class="chevron">›</span>
                </button>
              </div>
            </template>
            <template v-if="filteredRecentSymptoms.length">
              <h3 class="symptom-subhead">最近 7 天</h3>
              <div class="symptom-list">
                <button v-for="symptom in filteredRecentSymptoms" :key="symptom.id" class="symptom-row past" type="button" @click="openManage('symptom', symptom)">
                  <strong class="time">{{ symptom.timeLabel }}</strong>
                  <div>
                    <strong>{{ symptom.tag }}</strong>
                    <span v-if="symptom.note">{{ symptom.note }}</span>
                  </div>
                  <span class="chevron">›</span>
                </button>
              </div>
            </template>
          </div>
        </article>

        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <span class="title-icon sage"><img :src="iconBody" alt="" aria-hidden="true" /></span>
              <h2>评分记录</h2>
            </div>
            <span class="tag">最近 {{ scoreRecordRows.length }} 条</span>
          </header>
          <div class="card-body">
            <p v-if="!scoreRecordRows.length" class="empty-note">还没有评分记录。</p>
            <div v-else class="score-record-list">
              <div v-for="row in scoreRecordRows" :key="row.id" class="score-record-row">
                <time>{{ row.date }}<small>{{ row.time }}</small></time>
                <div class="score-record-main">
                  <span v-for="score in row.scores" :key="score.label" class="score-pill">
                    {{ score.label }} <strong>{{ score.value }}</strong>
                  </span>
                  <p v-if="row.note">{{ row.note }}</p>
                </div>
              </div>
            </div>
          </div>
        </article>

        <article class="card urgent">
          <div class="card-body boundary">{{ disclaimer }}</div>
        </article>
      </section>

      <section v-else-if="view === 'notices'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconWarning" alt="" aria-hidden="true" />
              <h2>注意事项</h2>
            </div>
            <span class="tag">生效中置顶</span>
          </header>
          <div class="card-body">
            <p class="section-hint">点一条可编辑、归档或删除。</p>
            <p v-if="!activeNotices.length && !archivedNotices.length" class="empty-note">还没有注意事项。</p>
            <div class="notice-list">
              <button v-for="notice in notices.filter((item) => !item.archived)" :key="notice.id" class="notice-row" :class="{ important: notice.important }" type="button" @click="openManage('notice', notice)">
                <span class="title-icon amber sm"><img :src="iconWarning" alt="" aria-hidden="true" /></span>
                <div>
                  <strong>{{ notice.content }}</strong>
                  <span>{{ noticeRangeLabel(notice) }}<template v-if="notice.detail"> · {{ notice.detail }}</template></span>
                </div>
                <span class="chevron">›</span>
              </button>
            </div>
            <div v-if="archivedNotices.length" class="notice-archived">
              <p class="section-hint">已归档（不再显示在「今天」）</p>
              <button v-for="notice in archivedNotices" :key="notice.id" class="notice-row archived" type="button" @click="openManage('notice', notice)">
                <span class="title-icon sm"><img :src="iconWarning" alt="" aria-hidden="true" /></span>
                <div>
                  <strong>{{ notice.content }}</strong>
                  <span>{{ noticeRangeLabel(notice) }}</span>
                </div>
                <span class="chevron">›</span>
              </button>
            </div>
          </div>
        </article>
        <article class="card urgent">
          <div class="card-body boundary">{{ disclaimer }}</div>
        </article>
      </section>

      <div class="mobile-nav" aria-label="移动端导航">
        <button v-for="item in navItems" :key="item.id" :class="{ active: item.id === view }" type="button" @click="go(item.id)">
          <img class="icon" :src="item.icon" alt="" aria-hidden="true" />
          <span>{{ item.label }}</span>
        </button>
      </div>

      <button v-if="isAuthed && hasSpace" class="fab" type="button" aria-label="记录点什么" @click="composerOpen = true">＋</button>
    </main>

    <div v-if="toastText" class="toast" role="status" aria-live="polite">{{ toastText }}</div>
    <div v-if="detailItem" class="modal-backdrop" role="presentation" @click.self="closeDetail">
      <section class="confirm-dialog detail-dialog" role="dialog" aria-modal="true" aria-labelledby="detail-dialog-title">
        <div class="confirm-icon" :class="`accent-${detailItem.accent}`">
          <img :src="detailItem.icon" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">{{ detailItem.type }} · {{ detailItem.dateLabel }}</p>
          <h2 id="detail-dialog-title">{{ detailItem.title }}</h2>
          <dl v-if="!detailEditing" class="detail-fields">
            <div v-for="field in detailItem.fields" :key="field.label">
              <dt>{{ field.label }}</dt>
              <dd>{{ field.value }}</dd>
            </div>
          </dl>
          <div v-else class="dialog-fields detail-edit-fields">
            <label v-for="field in detailEditFields" :key="field.name" class="dialog-field" :class="{ checkbox: field.type === 'checkbox' }">
              <span>{{ field.label }}</span>
              <textarea
                v-if="field.type === 'textarea'"
                v-model="detailEditValues[field.name]"
                :placeholder="field.placeholder || ''"
                :rows="field.rows || 2"
              ></textarea>
              <input
                v-else-if="field.type === 'checkbox'"
                v-model="detailEditValues[field.name]"
                type="checkbox"
              />
              <input
                v-else
                v-model="detailEditValues[field.name]"
                :placeholder="field.placeholder || ''"
                :type="field.type || 'text'"
              />
            </label>
          </div>
        </div>
        <div v-if="!detailEditing" class="confirm-actions">
          <button class="small-btn" type="button" @click="closeDetail">知道了</button>
          <button v-if="detailEditable" class="small-btn sage" type="button" @click="beginDetailEdit">{{ detailItem.kind === 'event' ? '修改日程' : '修改' }}</button>
        </div>
        <div v-else class="confirm-actions">
          <button class="small-btn" type="button" @click="cancelDetailEdit">取消</button>
          <button class="small-btn sage" type="button" :disabled="loading" @click="saveDetailEdit">保存</button>
        </div>
      </section>
    </div>

    <div v-if="bodyFormOpen" class="modal-backdrop" role="presentation" @click.self="bodyFormOpen = false">
      <section class="confirm-dialog panel-dialog" role="dialog" aria-modal="true" aria-labelledby="bodyform-title">
        <div class="confirm-icon accent-sage">
          <img :src="iconBody" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">每天一条</p>
          <h2 id="bodyform-title">今天身体怎么样？</h2>
          <p class="section-hint">体温和体重在「+」里有单独的入口，这里只记评分和感受。</p>
          <div class="status-grid large dialog-status-grid">
            <div v-for="record in bodyRecords" :key="record.label" class="status-item">
              <div class="status-label">
                <span>{{ record.label }}</span>
                <strong>{{ record.value }}/10</strong>
              </div>
              <input v-model.number="record.value" type="range" min="0" max="10" />
            </div>
          </div>
          <div class="form-row">
            <input v-model="statusDraft" type="text" placeholder="补一句感受，例如：下午有点恶心，晚饭吃得少（可不填）" />
          </div>
        </div>
        <div class="confirm-actions">
          <button class="small-btn" type="button" @click="bodyFormOpen = false">取消</button>
          <button class="small-btn sage" type="button" :disabled="loading" @click="saveStatus">保存今天的状态</button>
        </div>
      </section>
    </div>

    <div v-if="symptomFormOpen" class="modal-backdrop" role="presentation" @click.self="symptomFormOpen = false">
      <section class="confirm-dialog panel-dialog" role="dialog" aria-modal="true" aria-labelledby="symptomform-title">
        <div class="confirm-icon accent-amber">
          <img :src="iconBody" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">什么时间发生了什么</p>
          <h2 id="symptomform-title">记一次症状</h2>
          <div class="symptom-tags">
            <button
              v-for="preset in symptomPresets"
              :key="preset"
              class="trend-chip"
              :class="{ active: symptomDraft.tag === preset }"
              type="button"
              @click="symptomDraft.tag = preset"
            >
              {{ preset }}
            </button>
            <button
              class="trend-chip"
              :class="{ active: symptomDraft.tag === '__custom__' }"
              type="button"
              @click="symptomDraft.tag = '__custom__'"
            >
              自定义…
            </button>
          </div>
          <div v-if="symptomDraft.tag === '__custom__'" class="form-row">
            <input v-model="symptomDraft.customTag" type="text" placeholder="自己写一个，例如：头晕" />
          </div>
          <div class="dialog-fields">
            <label class="dialog-field">
              <span>发生时间</span>
              <input v-model="symptomDraft.happenedAt" type="datetime-local" />
            </label>
            <label class="dialog-field">
              <span>补充说明（可不填）</span>
              <input v-model="symptomDraft.note" type="text" placeholder="例如：38.2 度，吃了退烧药" />
            </label>
          </div>
        </div>
        <div class="confirm-actions">
          <button class="small-btn" type="button" @click="symptomFormOpen = false">取消</button>
          <button class="small-btn sage" type="button" :disabled="loading" @click="addSymptom">记下来</button>
        </div>
      </section>
    </div>

    <div v-if="manageItem" class="modal-backdrop" role="presentation" @click.self="closeManage">
      <section class="confirm-dialog manage-dialog" role="dialog" aria-modal="true" aria-labelledby="manage-title">
        <div class="confirm-icon">
          <img :src="manageItem.icon" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">{{ manageItem.eyebrow }}</p>
          <h2 id="manage-title">{{ manageItem.title }}</h2>
          <dl class="detail-fields">
            <div v-for="line in manageItem.lines" :key="line.label">
              <dt>{{ line.label }}</dt>
              <dd>{{ line.value }}</dd>
            </div>
          </dl>
        </div>
        <div class="manage-actions">
          <button
            v-for="action in manageItem.actions"
            :key="action.label"
            class="small-btn"
            :class="{ danger: action.danger, sage: !action.danger }"
            type="button"
            @click="runManageAction(action)"
          >
            {{ action.label }}
          </button>
          <button class="small-btn" type="button" @click="closeManage">关闭</button>
        </div>
      </section>
    </div>

    <div v-if="composerOpen" class="modal-backdrop" role="presentation" @click.self="composerOpen = false">
      <section class="confirm-dialog composer-sheet" role="dialog" aria-modal="true" aria-labelledby="composer-title">
        <div class="confirm-icon">
          <img :src="iconToday" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">记录点什么</p>
          <h2 id="composer-title">现在想记下哪件事？</h2>
          <div class="composer-actions">
            <button v-for="action in visibleComposerActions" :key="action.id" class="need-button" type="button" @click="runComposerAction(action)">
              <span class="icon-wrap"><img :src="action.icon" alt="" aria-hidden="true" /></span>
              <span><strong>{{ action.label }}</strong><small>{{ action.desc }}</small></span>
            </button>
          </div>
        </div>
        <div class="confirm-actions">
          <button class="small-btn" type="button" @click="composerOpen = false">取消</button>
        </div>
      </section>
    </div>

    <div v-if="questionsOpen" class="modal-backdrop" role="presentation" @click.self="questionsOpen = false">
      <section class="confirm-dialog panel-dialog" role="dialog" aria-modal="true" aria-labelledby="questions-title">
        <div class="confirm-icon accent-blue">
          <img :src="iconDoctor" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">复诊前勾选</p>
          <h2 id="questions-title">问医生清单</h2>
          <p v-if="!questions.length">还没有问题。把担心的事先记下来，复诊时不怕忘。</p>
          <div class="checklist panel-list">
            <label v-for="question in questions" :key="question.id" class="check-row">
              <input :checked="question.done" type="checkbox" @change="toggleQuestionAsked(question)" />
              <span>
                <strong>{{ question.text }}</strong>
                <small v-if="question.answer">医生答复：{{ question.answer }}</small>
              </span>
              <button class="mark-btn" :class="{ active: question.important }" type="button" @click.prevent="toggleImportant(question)">重要</button>
              <button class="mark-btn" type="button" @click.prevent="editQuestion(question)">编辑</button>
              <button class="mark-btn danger" type="button" @click.prevent="deleteQuestion(question)">删除</button>
            </label>
          </div>
          <div class="form-row">
            <input v-model="questionDraft" type="text" placeholder="添加一个想问医生的问题" />
            <button class="small-btn" type="button" @click="addQuestion">添加</button>
          </div>
        </div>
        <div class="confirm-actions">
          <button class="small-btn sage" type="button" @click="questionsOpen = false">关闭</button>
        </div>
      </section>
    </div>

    <div v-if="folderOpen" class="modal-backdrop" role="presentation" @click.self="folderOpen = false">
      <section class="confirm-dialog panel-dialog" role="dialog" aria-modal="true" aria-labelledby="folder-title">
        <div class="confirm-icon accent-sage">
          <img :src="iconFolder" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">文本资料</p>
          <h2 id="folder-title">复诊资料夹</h2>
          <p v-if="!notes.length">还没有资料。报告名称、用药记录和医嘱备注都可以存在这里。</p>
          <div class="file-list panel-list">
            <div v-for="note in notes" :key="note.id" class="file-row">
              <span class="file-icon"><img :src="iconFolder" alt="" aria-hidden="true" /></span>
              <div>
                <strong>{{ note.title }}</strong>
                <span>{{ note.type }} · {{ note.desc }} · {{ note.visibility }}</span>
              </div>
              <div class="row-actions">
                <button class="small-btn sage" type="button" @click="editNote(note)">编辑</button>
                <button class="small-btn danger" type="button" @click="deleteNote(note)">删除</button>
              </div>
            </div>
          </div>
          <div class="form-row">
            <input v-model="noteDraft" type="text" placeholder="新增报告名称、用药记录或医嘱备注" />
            <button class="small-btn" type="button" @click="addNote">新增</button>
          </div>
        </div>
        <div class="confirm-actions">
          <button class="small-btn sage" type="button" @click="folderOpen = false">关闭</button>
        </div>
      </section>
    </div>

    <div v-if="membersOpen" class="modal-backdrop" role="presentation" @click.self="membersOpen = false">
      <section class="confirm-dialog panel-dialog" role="dialog" aria-modal="true" aria-labelledby="members-title">
        <div class="confirm-icon">
          <img :src="iconLock" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">默认最小可见</p>
          <h2 id="members-title">成员与权限</h2>
          <p>生成邀请链接，对方打开登录后自动加入。</p>
          <button class="invite-cta" type="button" :disabled="loading" @click="inviteMember">
            <img :src="iconChat" alt="" aria-hidden="true" />
            <span>生成邀请链接并复制</span>
          </button>
          <div v-if="members.length" class="member-list panel-list">
            <div v-for="member in members" :key="member.id" class="member-row">
              <div>
                <strong>{{ member.name }}</strong>
                <span>{{ member.role }} · {{ member.status }}</span>
              </div>
              <button v-if="member.role !== '患者/管理员'" class="small-btn danger" type="button" @click="removeMember(member)">移除</button>
            </div>
          </div>
          <div class="form-row">
            <button class="small-btn danger" type="button" @click="leaveSpace">退出空间</button>
            <button class="small-btn danger" type="button" @click="deleteAccount">删除账号</button>
          </div>
          <p class="privacy-footnote">成员退出后不再能访问空间数据。敏感资料默认仅患者和管理员可见。</p>
        </div>
        <div class="confirm-actions">
          <button class="small-btn sage" type="button" @click="membersOpen = false">关闭</button>
        </div>
      </section>
    </div>
    <div v-if="dialog.open" class="modal-backdrop" role="presentation" @click.self="closeDialog(false)">
      <section class="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="app-dialog-title">
        <div class="confirm-icon">
          <img :src="dialog.icon" alt="" aria-hidden="true" />
        </div>
        <div>
          <p class="eyebrow">{{ dialog.eyebrow }}</p>
          <h2 id="app-dialog-title">{{ dialog.title }}</h2>
          <p v-if="dialog.message">{{ dialog.message }}</p>
          <div v-if="dialog.mode === 'form'" class="dialog-fields">
            <label v-for="field in dialog.fields" :key="field.name" class="dialog-field">
              <span>{{ field.label }}</span>
              <textarea
                v-if="field.type === 'textarea'"
                v-model="dialog.values[field.name]"
                :readonly="field.readonly"
                :placeholder="field.placeholder || ''"
                :rows="field.rows || 4"
              ></textarea>
              <input
                v-else-if="field.type === 'checkbox'"
                v-model="dialog.values[field.name]"
                type="checkbox"
              />
              <input
                v-else
                v-model="dialog.values[field.name]"
                :readonly="field.readonly"
                :placeholder="field.placeholder || ''"
                :type="field.type || 'text'"
              />
            </label>
          </div>
        </div>
        <div class="confirm-actions">
          <button class="small-btn" type="button" @click="closeDialog(false)">{{ dialog.cancelText }}</button>
          <button class="small-btn" :class="{ danger: dialog.danger, sage: !dialog.danger }" type="button" @click="submitDialog">
            {{ dialog.confirmText }}
          </button>
        </div>
      </section>
    </div>
  </div>
</template>
