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
  '本工具仅用于生活陪伴、就诊整理和家庭协作，不提供医疗诊断、治疗建议或用药判断。涉及治疗方案、用药调整和症状处理，请以主治医生或医院意见为准。';

const navItems = [
  { id: 'today', label: '今天', icon: iconToday },
  { id: 'timeline', label: '时间线', icon: iconTimeline },
  { id: 'moments', label: '朋友圈', icon: iconChat },
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
const noticeDraft = ref({
  content: '',
  detail: '',
  important: false,
  startsOn: '',
  endsOn: '',
});
const detailItem = ref(null);
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
  { label: '体温', value: 37 },
]);

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
const upcomingEvents = computed(() =>
  events.value.slice().sort((a, b) => new Date(a.scheduledAt) - new Date(b.scheduledAt))
);
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
    ...bodyRecordItems.value.map((record) => ({
      id: `body-${record.id}`,
      kind: 'body',
      type: '身体',
      title: '记录了一次身体状态',
      meta: `疼痛 ${record.painScore}/10 · 乏力 ${record.fatigueScore}/10 · 体温 ${record.temperature}℃`,
      detail: record.note || '没有补充备注',
      at: record.createdAt || record.recordDate,
      icon: iconBody,
      view: 'body',
      accent: 'sage',
      fields: [
        { label: '记录时间', value: formatFullDateTime(record.createdAt || record.recordDate) },
        {
          label: '评分',
          value: `疼痛 ${record.painScore}/10 · 乏力 ${record.fatigueScore}/10 · 睡眠 ${record.sleepScore}/10 · 心情 ${record.moodScore}/10 · 食欲 ${record.appetiteScore}/10`,
        },
        { label: '体温', value: `${record.temperature}℃` },
        { label: '备注', value: record.note || '没有补充备注' },
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
      type: '动态',
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
  temperature: Number(bodyRecords.value.find((item) => item.label === '体温')?.value || 37),
  note: statusDraft.value.trim(),
  recordDate: new Date().toISOString().slice(0, 10),
}));

const trendMetrics = ['疼痛', '乏力', '睡眠', '心情', '食欲', '体温'];
const trendMetricFields = {
  疼痛: 'painScore',
  乏力: 'fatigueScore',
  睡眠: 'sleepScore',
  心情: 'moodScore',
  食欲: 'appetiteScore',
  体温: 'temperature',
};
const trendPoints = computed(() => {
  const byDay = new Map();
  for (const record of bodyRecordItems.value) {
    const key = record.recordDate || toDateKey(new Date(record.createdAt));
    if (!byDay.has(key)) {
      byDay.set(key, record);
    }
  }
  const field = trendMetricFields[trendMetric.value];
  const today = new Date();
  const points = [];
  for (let offset = trendDays.value - 1; offset >= 0; offset -= 1) {
    const date = new Date(today);
    date.setDate(today.getDate() - offset);
    const key = toDateKey(date);
    const record = byDay.get(key);
    const value = record ? Number(record[field]) : null;
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
  const width = 320;
  const height = 120;
  const padX = 12;
  const padY = 14;
  const isTemp = trendMetric.value === '体温';
  const min = isTemp ? 34 : 0;
  const max = isTemp ? 42 : 10;
  const points = trendPoints.value;
  const step = points.length > 1 ? (width - padX * 2) / (points.length - 1) : 0;
  const dots = points
    .filter((point) => point.value !== null)
    .map((point) => ({
      ...point,
      x: padX + point.index * step,
      y: height - padY - ((point.value - min) / (max - min)) * (height - padY * 2),
    }));
  return {
    width,
    height,
    min,
    max,
    dots,
    line: dots.map((dot) => `${dot.x.toFixed(1)},${dot.y.toFixed(1)}`).join(' '),
    firstLabel: points[0]?.label || '',
    lastLabel: points[points.length - 1]?.label || '',
  };
});

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
  document.getElementById('timeline-today-divider')?.scrollIntoView({ block: 'center', behavior: 'smooth' });
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
}

function openNoticeDetail(notice) {
  detailItem.value = noticeTimelineItem(notice);
}

function closeDetail() {
  detailItem.value = null;
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
  await Promise.all([loadEvents(), loadBodyRecords(), loadQuestions(), loadMessages(), loadNotes(), loadNotices()]);
}

async function loadEvents() {
  events.value = (await api.listEvents(activeSpaceId.value)).map(mapEvent);
}

async function loadBodyRecords() {
  const records = await api.listBodyRecords(activeSpaceId.value);
  bodyRecordItems.value = records;
  const latest = records[0];
  if (latest) {
    bodyRecords.value = [
      { label: '疼痛', value: latest.painScore },
      { label: '乏力', value: latest.fatigueScore },
      { label: '睡眠', value: latest.sleepScore },
      { label: '心情', value: latest.moodScore },
      { label: '食欲', value: latest.appetiteScore },
      { label: '体温', value: latest.temperature },
    ];
    statusNote.value = latest.note || '';
  } else {
    bodyRecords.value = [
      { label: '疼痛', value: 3 },
      { label: '乏力', value: 6 },
      { label: '睡眠', value: 5 },
      { label: '心情', value: 4 },
      { label: '食欲', value: 5 },
      { label: '体温', value: 37 },
    ];
    statusNote.value = '';
  }
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

async function saveStatus() {
  if (!statusDraft.value.trim()) {
    showToast('先写一点今天的感受');
    return;
  }
  await withLoading(async () => {
    const result = await api.createBodyRecord(activeSpaceId.value, bodyRecordPayload.value);
    statusNote.value = result.record.note || '';
    statusDraft.value = '';
    await loadBodyRecords();
    showToast('今天的身体状态已记录');
  });
}

async function editLatestBodyRecord() {
  const latest = bodyRecordItems.value[0];
  if (!latest) {
    showToast('还没有身体记录');
    return;
  }
  const values = await openFormDialog({
    eyebrow: '身体记录',
    title: '编辑最近身体记录',
    icon: iconBody,
    fields: [{ name: 'note', label: '备注', value: latest.note || '', type: 'textarea' }],
  });
  if (!values) return;
  await withLoading(async () => {
    await api.updateBodyRecord(activeSpaceId.value, latest.id, { note: values.note });
    await loadBodyRecords();
    showToast('身体记录已更新');
  });
}

async function deleteLatestBodyRecord() {
  const latest = bodyRecordItems.value[0];
  if (!latest) return;
  const confirmed = await openConfirmDialog({
    eyebrow: '删除记录',
    title: '删除最近一条身体记录？',
    message: '删除后默认列表里不会再显示这条记录。',
    icon: iconBody,
    confirmText: '删除',
    danger: true,
  });
  if (!confirmed) return;
  await withLoading(async () => {
    await api.deleteBodyRecord(activeSpaceId.value, latest.id);
    statusNote.value = '';
    await loadBodyRecords();
    showToast('身体记录已删除');
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
      { name: 'location', label: '地点', value: event.location || '' },
      { name: 'note', label: '备注', value: event.note || '', type: 'textarea' },
    ],
  });
  if (!values) return;
  await withLoading(async () => {
    await api.updateEvent(activeSpaceId.value, event.id, {
      title: values.title.trim(),
      location: values.location?.trim() || '',
      note: values.note?.trim() || '',
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
  { id: 'message', label: '说说此刻', desc: '发到朋友圈，家人朋友都能看到', icon: iconChat, patientOnly: true },
  { id: 'event', label: '加日程', desc: '复诊、检查、用药提醒', icon: iconCalendar },
  { id: 'body', label: '记身体', desc: '疼痛、乏力、睡眠、心情', icon: iconBody },
  { id: 'notice', label: '记注意事项', desc: '医嘱和生活禁忌', icon: iconWarning },
  { id: 'question', label: '问医生的问题', desc: '复诊前先记下来', icon: iconDoctor },
  { id: 'note', label: '存一条资料', desc: '报告名称、用药、医嘱备注', icon: iconFolder },
];

const visibleComposerActions = computed(() =>
  composerActions.filter((action) => !action.patientOnly || isPatient.value)
);

async function runComposerAction(action) {
  composerOpen.value = false;
  if (action.id === 'message') {
    const values = await openFormDialog({
      eyebrow: '说说此刻',
      title: '现在想说点什么？',
      message: '会发布到朋友圈，家人朋友都能看到。',
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
  if (action.id === 'body') {
    go('body');
    return;
  }
  if (action.id === 'notice') {
    go('notices');
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

function editFromDetail() {
  const item = detailItem.value;
  if (!item?.kind || !item.raw) return;
  detailItem.value = null;
  if (item.kind === 'event') editEvent(item.raw);
  else if (item.kind === 'message') editMessage(item.raw);
  else if (item.kind === 'note') editNote(item.raw);
  else if (item.kind === 'notice') editNotice(item.raw);
  else if (item.kind === 'question') editQuestion(item.raw);
}

function deleteFromDetail() {
  const item = detailItem.value;
  if (!item?.kind || !item.raw) return;
  detailItem.value = null;
  if (item.kind === 'event') deleteEvent(item.raw);
  else if (item.kind === 'message') deleteMessage(item.raw);
  else if (item.kind === 'note') deleteNote(item.raw);
  else if (item.kind === 'notice') deleteNotice(item.raw);
  else if (item.kind === 'question') deleteQuestion(item.raw);
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

async function addNotice() {
  if (!noticeDraft.value.content.trim()) {
    showToast('先写下要注意的事');
    return;
  }
  await withLoading(async () => {
    await api.createNotice(activeSpaceId.value, {
      content: noticeDraft.value.content.trim(),
      detail: noticeDraft.value.detail.trim() || undefined,
      important: noticeDraft.value.important,
      startsOn: noticeDraft.value.startsOn || undefined,
      endsOn: noticeDraft.value.endsOn || undefined,
    });
    noticeDraft.value = { content: '', detail: '', important: false, startsOn: '', endsOn: '' };
    await loadNotices();
    showToast('注意事项已记录');
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
  if (!invitePhone.value.trim()) {
    showToast('先填写手机号或备注名');
    return;
  }
  await withLoading(async () => {
    const invite = await api.createMemberInvite(activeSpaceId.value, { nickname: invitePhone.value.trim(), role: 'FRIEND' });
    invitePhone.value = '';
    await showInviteLink(invite);
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
          <p class="eyebrow">{{ activeNav?.label || '今天' }}</p>
          <h1>{{ activeSpace?.name || '今天' }}</h1>
          <p class="lead">不用一个人记住所有事情。这里帮你整理复诊、身体感受、想问医生的问题，以及家人朋友可以接住的具体小事。</p>
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
            <span class="tag">数据写入后端数据库</span>
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
              <span>我已了解这里会收集日程、身体记录、问题清单、任务、留言和资料文本，用于就诊整理和家庭协作。</span>
            </label>
            <div class="form-row">
              <button class="small-btn sage" type="button" :disabled="!privacyAccepted || loading" @click="createSpace">创建空间</button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'today'" class="page-grid">
        <div class="main-stack">
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
                <button v-for="notice in activeNotices" :key="notice.id" class="notice-strip" :class="{ important: notice.important }" type="button" @click="openNoticeDetail(notice)">
                  <img :src="iconWarning" alt="" aria-hidden="true" />
                  <span>注意：{{ notice.content }}</span>
                </button>
                <p v-if="!todayItems.length" class="empty-note">今天没有要做的事，好好休息。用右下角「+」加的日程到了当天会出现在这里。</p>
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
                <small>{{ nextVisitCountdown === null ? '还没有安排日程，点右下角「+」添加复诊或检查。' : nextVisitCountdown === 0 ? '就是今天，把资料和问题清单带上。' : '把资料和问题提前整理好，不用临时回忆。' }}</small>
                <button class="small-btn" type="button" @click="questionsOpen = true">问题清单</button>
                <button class="small-btn" type="button" @click="folderOpen = true">复诊资料</button>
              </div>
            </div>
          </article>

          <article class="card">
            <header class="card-header">
              <div class="card-title">
                <img class="icon" :src="iconBody" alt="" aria-hidden="true" />
                <h2>今天身体怎么样</h2>
              </div>
              <span class="tag">家人可在时间线看到</span>
            </header>
            <div class="card-body">
              <p class="section-hint">记录疼痛、乏力、睡眠和心情，并补一句今天的感受。保存后会进入“身体”和“时间线”，方便复诊前回看。</p>
              <div class="status-grid">
                <div v-for="record in bodyRecords.slice(0, 4)" :key="record.label" class="status-item">
                  <div class="status-label">
                    <span>{{ record.label }}</span>
                    <strong>{{ record.value }}/10</strong>
                  </div>
                  <div class="range-line"><span :style="{ width: `${record.value * 10}%` }"></span></div>
                </div>
              </div>
              <div class="form-row">
                <input v-model="statusDraft" type="text" placeholder="写一句今天的感受，例如：下午有点恶心，晚饭吃得少" />
                <button class="small-btn sage" type="button" @click="saveStatus">记录今天状态</button>
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
                <li>持续发热、寒战或明显感染迹象。</li>
                <li>严重疼痛、呼吸困难、胸闷或晕厥。</li>
                <li>伤口红肿渗液、明显过敏或用药后不适加重。</li>
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
            <div class="timeline-summary">
              <div>
                <span class="calendar-kicker">过去和未来都在这里</span>
                <strong>{{ activeSpace?.patientNickname || currentUser.nickname }} 的照护动态</strong>
                <p>日程、身体记录、问题清单、注意事项、朋友圈动态和资料都会汇总到这条时间线上。往上看接下来的计划，往下看已经发生的事，点击任何一条可以查看详情。</p>
              </div>
              <div class="timeline-jump">
                <button class="small-btn sage" type="button" @click="openEventDialog">加日程</button>
                <button class="small-btn" type="button" @click="go('body')">记身体</button>
                <button class="small-btn" type="button" @click="go('notices')">记注意</button>
              </div>
            </div>

            <p v-if="!timelineItems.length" class="empty-note">还没有动态。先添加一条日程、身体记录、问题或朋友圈动态，时间线会自动汇总。</p>
            <div v-else class="timeline-list">
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
              <h2>朋友圈</h2>
            </div>
            <span class="tag">{{ isPatient ? '想到什么就记下来' : '只有患者本人可以发布' }}</span>
          </header>
          <div class="card-body">
            <div v-if="isPatient" class="moments-composer">
              <textarea v-model="messageDraft" rows="3" placeholder="此刻想说点什么？想法、状态、想让家人知道的事…"></textarea>
              <div class="form-row">
                <button class="small-btn sage" type="button" :disabled="loading" @click="addMessage">发布</button>
              </div>
            </div>
            <p v-if="!messages.length" class="empty-note">{{ isPatient ? '还没有动态。写下此刻的想法和状态，家人朋友都能看到。' : '还没有动态。' }}</p>
            <div v-else class="message-list moments-feed">
              <div v-for="message in messages" :key="message.id" class="message">
                <p>{{ message.text }}</p>
                <span>{{ message.author }} · {{ message.time }}</span>
                <div v-if="isPatient" class="row-actions">
                  <button class="small-btn" type="button" @click="editMessage(message)">编辑</button>
                  <button class="small-btn danger" type="button" @click="deleteMessage(message)">删除</button>
                </div>
              </div>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'body'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconBody" alt="" aria-hidden="true" />
              <h2>身体记录</h2>
            </div>
            <span class="tag">每天一条，复诊前回顾</span>
          </header>
          <div class="card-body">
            <div class="status-grid large">
              <div v-for="record in bodyRecords" :key="record.label" class="status-item">
                <div class="status-label">
                  <span>{{ record.label }}</span>
                  <strong>{{ record.value }}{{ record.label === '体温' ? '℃' : '/10' }}</strong>
                </div>
                <input v-if="record.label !== '体温'" v-model.number="record.value" type="range" min="0" max="10" />
                <input v-else v-model.number="record.value" type="number" min="34" max="42" step="0.1" />
              </div>
            </div>
            <div class="form-row">
              <input v-model="statusDraft" type="text" placeholder="写一句今天的身体感受" />
              <button class="small-btn sage" type="button" @click="saveStatus">记录今天状态</button>
              <button class="small-btn" type="button" @click="editLatestBodyRecord">编辑最近</button>
              <button class="small-btn danger" type="button" @click="deleteLatestBodyRecord">删除最近</button>
            </div>
            <p v-if="statusNote" class="saved-note">最近记录：{{ statusNote }}</p>
          </div>
        </article>

        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconBody" alt="" aria-hidden="true" />
              <h2>身体变化趋势</h2>
            </div>
            <div class="trend-period">
              <button class="small-btn" :class="{ sage: trendDays === 7 }" type="button" @click="trendDays = 7">近 7 天</button>
              <button class="small-btn" :class="{ sage: trendDays === 30 }" type="button" @click="trendDays = 30">近 30 天</button>
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
            <p v-if="trendChart.dots.length < 2" class="empty-note">记录还不够多。连续记录两天以上，这里会画出{{ trendMetric }}的变化曲线。</p>
            <div v-else class="trend-chart">
              <svg :viewBox="`0 0 ${trendChart.width} ${trendChart.height}`" preserveAspectRatio="none" role="img" :aria-label="`${trendMetric}最近${trendDays}天趋势`">
                <line :x1="12" :y1="trendChart.height - 14" :x2="trendChart.width - 12" :y2="trendChart.height - 14" class="trend-axis" />
                <polyline :points="trendChart.line" class="trend-line" />
                <circle v-for="dot in trendChart.dots" :key="dot.key" :cx="dot.x" :cy="dot.y" r="3" class="trend-dot" />
              </svg>
              <div class="trend-legend">
                <span>{{ trendChart.firstLabel }}</span>
                <span>{{ trendMetric }}（{{ trendChart.min }}–{{ trendChart.max }}{{ trendMetric === '体温' ? '℃' : '分' }}）· 共 {{ trendChart.dots.length }} 天有记录</span>
                <span>{{ trendChart.lastLabel }}</span>
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
            <span class="tag">生效中的会显示在“今天”</span>
          </header>
          <div class="card-body">
            <p class="section-hint">把医生的叮嘱和生活禁忌记在这里，例如“化疗期间避免生食”“术后两周不要提重物”。生效中的注意事项会置顶显示在“今天”页面，添加动态会进入时间线。</p>
            <p v-if="!activeNotices.length && !archivedNotices.length" class="empty-note">还没有注意事项。下方添加后全家都能看到。</p>
            <div class="notice-list">
              <div v-for="notice in notices.filter((item) => !item.archived)" :key="notice.id" class="notice-row" :class="{ important: notice.important }">
                <img :src="iconWarning" alt="" aria-hidden="true" />
                <div>
                  <strong>{{ notice.content }}</strong>
                  <span>{{ noticeRangeLabel(notice) }}<template v-if="notice.detail"> · {{ notice.detail }}</template></span>
                </div>
                <div class="row-actions">
                  <button class="mark-btn" :class="{ active: notice.important }" type="button" @click="toggleNoticeImportant(notice)">重要</button>
                  <button class="small-btn" type="button" @click="editNotice(notice)">编辑</button>
                  <button class="small-btn" type="button" @click="archiveNotice(notice)">归档</button>
                  <button class="small-btn danger" type="button" @click="deleteNotice(notice)">删除</button>
                </div>
              </div>
            </div>
            <div v-if="archivedNotices.length" class="notice-archived">
              <p class="section-hint">已归档（不再显示在“今天”）</p>
              <div v-for="notice in archivedNotices" :key="notice.id" class="notice-row archived">
                <img :src="iconWarning" alt="" aria-hidden="true" />
                <div>
                  <strong>{{ notice.content }}</strong>
                  <span>{{ noticeRangeLabel(notice) }}</span>
                </div>
                <div class="row-actions">
                  <button class="small-btn" type="button" @click="archiveNotice(notice)">恢复</button>
                  <button class="small-btn danger" type="button" @click="deleteNotice(notice)">删除</button>
                </div>
              </div>
            </div>
            <div class="event-form">
              <input v-model="noticeDraft.content" type="text" placeholder="要注意的事，例如：化疗期间避免生食" />
              <input v-model="noticeDraft.detail" type="text" placeholder="补充说明，可选" />
              <label class="inline-check">
                <span>开始</span>
                <input v-model="noticeDraft.startsOn" type="date" />
              </label>
              <label class="inline-check">
                <span>结束</span>
                <input v-model="noticeDraft.endsOn" type="date" />
              </label>
              <label class="inline-check">
                <input v-model="noticeDraft.important" type="checkbox" />
                <span>重要</span>
              </label>
              <button class="small-btn sage" type="button" @click="addNotice">添加注意事项</button>
            </div>
            <p class="section-hint">开始和结束日期都可以不填，表示长期有效。</p>
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
          <dl class="detail-fields">
            <div v-for="field in detailItem.fields" :key="field.label">
              <dt>{{ field.label }}</dt>
              <dd>{{ field.value }}</dd>
            </div>
          </dl>
        </div>
        <div class="confirm-actions">
          <template v-if="detailItem.kind && detailItem.raw">
            <button class="small-btn" type="button" @click="editFromDetail">编辑</button>
            <button class="small-btn danger" type="button" @click="deleteFromDetail">删除</button>
          </template>
          <button class="small-btn sage" type="button" @click="closeDetail">知道了</button>
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
          <p>输入对方昵称或备注后生成邀请链接发给对方，对方登录或注册后会出现在成员列表里。链接 7 天内有效。</p>
          <div class="member-list panel-list">
            <div v-for="member in members" :key="member.id" class="member-row">
              <div>
                <strong>{{ member.name }}</strong>
                <span>{{ member.role }} · {{ member.access }}</span>
              </div>
              <div class="row-actions">
                <span class="tag">{{ member.status }}</span>
                <button class="small-btn danger" type="button" @click="removeMember(member)">移除</button>
              </div>
            </div>
          </div>
          <div class="form-row">
            <input v-model="invitePhone" type="text" placeholder="输入手机号、昵称或邀请备注" />
            <button class="small-btn" type="button" @click="inviteMember">生成邀请链接</button>
          </div>
          <div class="form-row">
            <button class="small-btn danger" type="button" @click="leaveSpace">退出空间</button>
            <button class="small-btn danger" type="button" @click="deleteAccount">删除账号</button>
          </div>
          <p class="privacy-footnote">这里会记录昵称、成员关系、日程、身体记录、问题清单、动态和资料文本，用于就诊整理和家庭协作。敏感资料默认仅患者和管理员可见，成员退出后不再能访问空间数据。</p>
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
                rows="4"
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
