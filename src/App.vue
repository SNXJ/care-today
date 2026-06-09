<script setup>
import { computed, onMounted, ref } from 'vue';
import { createApi } from './api';

import iconToday from './assets/icons/nav-today.svg';
import iconCalendar from './assets/icons/nav-calendar.svg';
import iconDoctor from './assets/icons/nav-doctor.svg';
import iconBody from './assets/icons/nav-body.svg';
import iconHelp from './assets/icons/nav-help.svg';
import iconMessage from './assets/icons/nav-message.svg';
import iconFolder from './assets/icons/nav-folder.svg';
import iconHospital from './assets/icons/action-hospital.svg';
import iconTask from './assets/icons/action-task.svg';
import iconChat from './assets/icons/action-chat.svg';
import iconPrivacy from './assets/icons/status-privacy.svg';
import iconWarning from './assets/icons/status-warning.svg';
import iconLock from './assets/icons/status-lock.svg';

const disclaimer =
  '本工具仅用于生活陪伴、就诊整理和家庭协作，不提供医疗诊断、治疗建议或用药判断。涉及治疗方案、用药调整和症状处理，请以主治医生或医院意见为准。';

const navItems = [
  { id: 'today', label: '今天', icon: iconToday },
  { id: 'calendar', label: '日历', icon: iconCalendar },
  { id: 'body', label: '身体', icon: iconBody },
  { id: 'doctor', label: '问医生', icon: iconDoctor },
  { id: 'help', label: '帮忙墙', icon: iconHelp },
  { id: 'messages', label: '留言', icon: iconMessage },
  { id: 'folder', label: '资料夹', icon: iconFolder },
  { id: 'members', label: '成员', icon: iconLock },
];

const quickNeeds = [
  { label: '陪我去医院', desc: '把时间、地点和资料先放好', icon: iconHospital },
  { label: '帮我处理一件事', desc: '买药、做饭、接送都可以认领', icon: iconTask },
  { label: '只是陪我聊聊', desc: '不讲道理，也不急着解决', icon: iconChat },
];

const view = ref('today');
const toastText = ref('');
const loading = ref(false);
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
  name: '陪你一起过今天',
  patientNickname: '',
  description: '',
});
const statusNote = ref('');
const statusDraft = ref('');
const messageDraft = ref('');
const questionDraft = ref('');
const taskDraft = ref('');
const noteDraft = ref('');
const invitePhone = ref('');
const eventDraft = ref({
  title: '',
  scheduledAt: '',
  location: '',
  note: '',
  needsCompanion: false,
});
const privacyAccepted = ref(false);
const api = createApi(() => token.value);

const spaces = ref([]);
const activeSpace = ref(null);
const events = ref([]);

const bodyRecords = ref([
  { label: '疼痛', value: 3 },
  { label: '乏力', value: 6 },
  { label: '睡眠', value: 5 },
  { label: '心情', value: 4 },
  { label: '食欲', value: 5 },
  { label: '体温', value: 37 },
]);

const questions = ref([]);
const helpTasks = ref([]);
const messages = ref([]);
const notes = ref([]);
const members = ref([]);

const activeNav = computed(() => navItems.find((item) => item.id === view.value));
const isAuthed = computed(() => Boolean(token.value && currentUser.value));
const hasSpace = computed(() => Boolean(activeSpaceId.value));
const nextVisitLabel = computed(() => events.value[0]?.date || '待添加');
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

onMounted(() => {
  if (isAuthed.value) {
    loadSpaces();
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
  window.scrollTo({ top: 0, behavior: 'smooth' });
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
    const payload = {
      email: authForm.value.email.trim() || undefined,
      phone: authForm.value.phone.trim() || undefined,
      password: authForm.value.password,
      ...(authMode.value === 'register' ? { nickname: authForm.value.nickname.trim() } : {}),
    };
    const result = authMode.value === 'register' ? await api.register(payload) : await api.login(payload);
    token.value = result.token;
    currentUser.value = result.user;
    localStorage.setItem('care-today-token', result.token);
    localStorage.setItem('care-today-user', JSON.stringify(result.user));
    spaceForm.value.patientNickname = result.user.nickname;
    showToast(authMode.value === 'register' ? '注册成功' : '登录成功');
    await loadSpaces();
  });
}

function logout() {
  token.value = '';
  currentUser.value = null;
  activeSpaceId.value = '';
  activeSpace.value = null;
  spaces.value = [];
  events.value = [];
  questions.value = [];
  helpTasks.value = [];
  messages.value = [];
  notes.value = [];
  members.value = [];
  localStorage.removeItem('care-today-token');
  localStorage.removeItem('care-today-user');
  localStorage.removeItem('care-today-space-id');
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
  await Promise.all([loadEvents(), loadBodyRecords(), loadQuestions(), loadHelpTasks(), loadMessages(), loadNotes()]);
}

async function loadEvents() {
  events.value = (await api.listEvents(activeSpaceId.value)).map(mapEvent);
}

async function loadBodyRecords() {
  const records = await api.listBodyRecords(activeSpaceId.value);
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
  }
}

async function loadQuestions() {
  questions.value = (await api.listDoctorQuestions(activeSpaceId.value)).map(mapQuestion);
}

async function loadHelpTasks() {
  helpTasks.value = (await api.listHelpTasks(activeSpaceId.value)).map(mapTask);
}

async function loadMessages() {
  messages.value = (await api.listMessages(activeSpaceId.value)).map(mapMessage);
}

async function loadNotes() {
  notes.value = (await api.listNotes(activeSpaceId.value)).map(mapNote);
}

function saveNeed(label) {
  showToast(`已记录：${label}`);
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
    showToast('身体记录已保存到数据库');
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

async function addEvent() {
  if (!eventDraft.value.title.trim() || !eventDraft.value.scheduledAt) {
    showToast('先填写日程标题和时间');
    return;
  }
  await withLoading(async () => {
    await api.createEvent(activeSpaceId.value, {
      title: eventDraft.value.title.trim(),
      scheduledAt: new Date(eventDraft.value.scheduledAt).toISOString(),
      location: eventDraft.value.location.trim() || undefined,
      note: eventDraft.value.note.trim() || undefined,
      needsCompanion: eventDraft.value.needsCompanion,
    });
    eventDraft.value = { title: '', scheduledAt: '', location: '', note: '', needsCompanion: false };
    await loadEvents();
    showToast('日程已添加');
  });
}

async function toggleImportant(question) {
  await withLoading(async () => {
    await api.updateDoctorQuestion(activeSpaceId.value, question.id, { important: !question.important });
    await loadQuestions();
  });
}

async function claimTask(task) {
  await withLoading(async () => {
    await api.claimHelpTask(activeSpaceId.value, task.id);
    await loadHelpTasks();
    showToast('已认领这件事');
  });
}

async function addTask() {
  if (!taskDraft.value.trim()) {
    showToast('先写一件可以被认领的小事');
    return;
  }
  await withLoading(async () => {
    await api.createHelpTask(activeSpaceId.value, {
      title: taskDraft.value.trim(),
      type: '其他',
      description: '创建后可补充时间和说明。',
    });
    taskDraft.value = '';
    await loadHelpTasks();
    showToast('已添加到帮忙墙');
  });
}

async function addMessage() {
  if (!messageDraft.value.trim()) {
    showToast('先写一句留言');
    return;
  }
  await withLoading(async () => {
    await api.createMessage(activeSpaceId.value, { text: messageDraft.value.trim() });
    messageDraft.value = '';
    await loadMessages();
    showToast('留言已添加');
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

async function inviteMember() {
  if (!invitePhone.value.trim()) {
    showToast('先填写手机号或备注名');
    return;
  }
  await withLoading(async () => {
    await api.inviteMember(activeSpaceId.value, { nickname: invitePhone.value.trim(), role: 'FRIEND' });
    invitePhone.value = '';
    const detail = await api.getSpace(activeSpaceId.value);
    members.value = (detail.members || []).map(mapMember);
    showToast('邀请已创建，等待确认');
  });
}

function mapEvent(event) {
  const date = new Date(event.scheduledAt);
  return {
    ...event,
    time: date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }),
    date: date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' }),
    place: event.location || '待补充地点',
    tag: event.needsCompanion ? '需要陪同' : '站内提醒',
  };
}

function mapQuestion(question) {
  return {
    id: question.id,
    text: question.question,
    done: question.asked,
    important: question.important,
    answer: question.doctorAnswer,
  };
}

function mapTask(task) {
  const statusMap = { PENDING: '待认领', CLAIMED: '已认领', DONE: '已完成', CANCELLED: '已取消' };
  return {
    id: task.id,
    title: task.title,
    type: task.type,
    time: task.scheduledAt ? new Date(task.scheduledAt).toLocaleString('zh-CN') : '待约定',
    desc: task.description || '暂无说明',
    status: statusMap[task.status] || task.status,
    claimedBy: task.claimedBy || '',
  };
}

function mapMessage(message) {
  return {
    text: message.text,
    author: message.author,
    time: new Date(message.createdAt).toLocaleString('zh-CN'),
  };
}

function mapNote(note) {
  return {
    title: note.title,
    type: note.type,
    desc: new Date(note.createdAt).toLocaleString('zh-CN'),
    visibility: note.visibility === 'PATIENT_ADMIN' ? '患者和管理员可见' : '空间成员可见',
  };
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
          <small>陪你一起过今天</small>
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
          <h1>{{ activeSpace?.name || '陪你一起过今天' }}</h1>
          <p class="lead">不用一个人记住所有事情。这里帮你整理复诊、身体感受、想问医生的问题，以及家人朋友可以接住的具体小事。</p>
        </div>
        <div class="top-actions">
          <div class="privacy-pill">
            <img class="icon" :src="iconPrivacy" alt="" aria-hidden="true" />
            仅自己和被授权成员可见
          </div>
          <button v-if="isAuthed" class="small-btn sage" type="button" @click="logout">{{ currentUser.nickname }} · 退出</button>
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
          <section class="quick-actions" aria-label="今天最需要什么">
            <button v-for="need in quickNeeds" :key="need.label" class="need-button" type="button" @click="saveNeed(need.label)">
              <span class="icon-wrap"><img :src="need.icon" alt="" aria-hidden="true" /></span>
              <span><strong>{{ need.label }}</strong><small>{{ need.desc }}</small></span>
            </button>
          </section>

          <article class="card">
            <header class="card-header">
              <div class="card-title">
                <img class="icon" :src="iconCalendar" alt="" aria-hidden="true" />
                <h2>今日安排</h2>
              </div>
              <span class="tag">下次复诊：{{ nextVisitLabel }}</span>
            </header>
            <div class="card-body today-grid">
              <div class="schedule">
                <p v-if="!events.length" class="empty-note">还没有日程。到“日历”页添加复诊、检查或用药提醒。</p>
                <div v-for="event in events.slice(0, 3)" :key="event.title" class="schedule-row">
                  <strong class="time">{{ event.time }}</strong>
                  <div>
                    <strong>{{ event.title }}</strong>
                    <span>{{ event.note }}</span>
                  </div>
                  <span class="tag">{{ event.tag }}</span>
                </div>
              </div>
              <div class="countdown">
                <span>距离下次复诊</span>
                <strong>9</strong>
                  <small>把资料和问题提前整理好，不用临时回忆。</small>
                <button class="small-btn" type="button" @click="go('folder')">整理复诊资料</button>
              </div>
            </div>
          </article>

          <article class="card">
            <header class="card-header">
              <div class="card-title">
                <img class="icon" :src="iconBody" alt="" aria-hidden="true" />
                <h2>身体状态快捷记录</h2>
              </div>
              <span class="tag">保存到数据库</span>
            </header>
            <div class="card-body">
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
                <input v-model="statusDraft" type="text" placeholder="补充今天的感受，例如：下午有点恶心，晚饭吃得少" />
                <button class="small-btn sage" type="button" @click="saveStatus">保存记录</button>
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

          <article class="card">
            <header class="card-header">
              <div class="card-title">
                <img class="icon" :src="iconHelp" alt="" aria-hidden="true" />
                <h2>待认领帮忙任务</h2>
              </div>
            </header>
            <div class="card-body mini-list">
              <p v-if="!helpTasks.filter((item) => item.status === '待认领').length" class="empty-note">暂无待认领任务。</p>
              <div v-for="task in helpTasks.filter((item) => item.status === '待认领').slice(0, 3)" :key="task.title" class="mini-row">
                <div>
                  <strong>{{ task.title }}</strong>
                  <span>{{ task.time }}</span>
                </div>
                <button class="claim-btn" type="button" @click="claimTask(task)">认领</button>
              </div>
            </div>
          </article>

          <article class="card">
            <header class="card-header">
              <div class="card-title">
                <img class="icon" :src="iconMessage" alt="" aria-hidden="true" />
                <h2>温柔留言</h2>
              </div>
            </header>
            <div class="card-body message-list">
              <p v-if="!messages.length" class="empty-note">还没有留言。</p>
              <div v-for="message in messages.slice(0, 2)" :key="message.text" class="message">
                <p>{{ message.text }}</p>
                <span>{{ message.author }} · {{ message.time }}</span>
              </div>
            </div>
          </article>
        </aside>
      </section>

      <section v-else-if="view === 'calendar'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconCalendar" alt="" aria-hidden="true" />
              <h2>日历与安排</h2>
            </div>
            <span class="tag">站内提醒</span>
          </header>
          <div class="card-body schedule full">
            <p v-if="!events.length" class="empty-note">还没有日程。下方添加后会写入后端数据库。</p>
            <div v-for="event in events" :key="event.title" class="schedule-row">
              <strong class="time">{{ event.date }}<br />{{ event.time }}</strong>
              <div>
                <strong>{{ event.title }}</strong>
                <span>{{ event.place }} · {{ event.note }}</span>
              </div>
              <span class="tag">{{ event.tag }}</span>
            </div>
            <div class="event-form">
              <input v-model="eventDraft.title" type="text" placeholder="日程标题，例如：门诊复查" />
              <input v-model="eventDraft.scheduledAt" type="datetime-local" />
              <input v-model="eventDraft.location" type="text" placeholder="地点" />
              <input v-model="eventDraft.note" type="text" placeholder="备注，例如：带上报告和问题清单" />
              <label class="inline-check">
                <input v-model="eventDraft.needsCompanion" type="checkbox" />
                <span>需要陪同</span>
              </label>
              <button class="small-btn sage" type="button" @click="addEvent">添加日程</button>
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
            <span class="tag">最近 7 天用于复诊回顾</span>
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
              <input v-model="statusDraft" type="text" placeholder="补充今天的身体感受" />
              <button class="small-btn sage" type="button" @click="saveStatus">保存记录</button>
            </div>
            <p v-if="statusNote" class="saved-note">最近记录：{{ statusNote }}</p>
          </div>
        </article>
        <article class="card urgent">
          <div class="card-body boundary">{{ disclaimer }}</div>
        </article>
      </section>

      <section v-else-if="view === 'doctor'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconDoctor" alt="" aria-hidden="true" />
              <h2>问医生清单</h2>
            </div>
            <span class="tag">复诊前勾选</span>
          </header>
          <div class="card-body checklist">
            <label v-for="question in questions" :key="question.text" class="check-row">
              <input v-model="question.done" type="checkbox" />
              <span>
                <strong>{{ question.text }}</strong>
                <small v-if="question.answer">医生答复：{{ question.answer }}</small>
              </span>
              <button class="mark-btn" :class="{ active: question.important }" type="button" @click.prevent="toggleImportant(question)">
                重要
              </button>
            </label>
            <div class="form-row">
              <input v-model="questionDraft" type="text" placeholder="添加一个复诊时想问医生的问题" />
              <button class="small-btn" type="button" @click="addQuestion">添加</button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'help'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconHelp" alt="" aria-hidden="true" />
              <h2>朋友帮忙墙</h2>
            </div>
            <span class="tag">家庭协作</span>
          </header>
          <div class="card-body">
            <div class="help-grid">
              <div v-for="task in helpTasks" :key="task.title" class="help-card">
                <header>
                  <div>
                    <strong>{{ task.title }}</strong>
                    <span>{{ task.type }} · {{ task.time }}</span>
                  </div>
                  <span class="tag">{{ task.status }}</span>
                </header>
                <p>{{ task.desc }}</p>
                <footer>
                  <span>{{ task.claimedBy ? `认领人：${task.claimedBy}` : '还没人认领' }}</span>
                  <button v-if="task.status === '待认领'" class="claim-btn" type="button" @click="claimTask(task)">认领</button>
                </footer>
              </div>
            </div>
            <div class="form-row">
              <input v-model="taskDraft" type="text" placeholder="添加一件家人朋友可以帮忙的小事" />
              <button class="small-btn" type="button" @click="addTask">添加任务</button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'messages'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconMessage" alt="" aria-hidden="true" />
              <h2>温柔留言</h2>
            </div>
          </header>
          <div class="card-body">
            <div class="message-list">
              <div v-for="message in messages" :key="message.text" class="message">
                <p>{{ message.text }}</p>
                <span>{{ message.author }} · {{ message.time }}</span>
              </div>
            </div>
            <div class="form-row">
              <input v-model="messageDraft" type="text" placeholder="写一句不催促、不讲道理的陪伴话" />
              <button class="small-btn" type="button" @click="addMessage">添加</button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'folder'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconFolder" alt="" aria-hidden="true" />
              <h2>复诊资料夹</h2>
            </div>
            <span class="tag">第一版仅文本记录</span>
          </header>
          <div class="card-body file-list">
            <div v-for="note in notes" :key="note.title" class="file-row">
              <span class="file-icon"><img :src="iconFolder" alt="" aria-hidden="true" /></span>
              <div>
                <strong>{{ note.title }}</strong>
                <span>{{ note.type }} · {{ note.desc }} · {{ note.visibility }}</span>
              </div>
              <button class="small-btn sage" type="button">查看</button>
            </div>
            <div class="form-row">
              <input v-model="noteDraft" type="text" placeholder="新增报告名称、用药记录或医嘱备注" />
              <button class="small-btn" type="button" @click="addNote">新增</button>
            </div>
          </div>
        </article>
      </section>

      <section v-else-if="view === 'members'" class="single-stack">
        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconLock" alt="" aria-hidden="true" />
              <h2>成员与权限</h2>
            </div>
            <span class="tag">默认最小可见</span>
          </header>
          <div class="card-body">
            <div class="member-list">
              <div v-for="member in members" :key="member.name" class="member-row">
                <div>
                  <strong>{{ member.name }}</strong>
                  <span>{{ member.role }} · {{ member.access }}</span>
                </div>
                <span class="tag">{{ member.status }}</span>
              </div>
            </div>
            <div class="form-row">
              <input v-model="invitePhone" type="text" placeholder="输入手机号、昵称或邀请备注" />
              <button class="small-btn" type="button" @click="inviteMember">邀请成员</button>
            </div>
          </div>
        </article>

        <article class="card">
          <header class="card-header">
            <div class="card-title">
              <img class="icon" :src="iconPrivacy" alt="" aria-hidden="true" />
              <h2>隐私说明</h2>
            </div>
          </header>
          <div class="card-body privacy-copy">
            <p>创建陪伴空间时会记录昵称、成员关系、日程、身体记录、问题清单、任务、留言和资料文本。这些信息用于就诊整理和家庭协作。</p>
            <p>新成员加入后需要管理员授权；敏感资料默认仅患者和管理员可见。成员退出后，不再能访问空间数据。</p>
            <label class="consent-row">
              <input v-model="privacyAccepted" type="checkbox" />
              <span>我已了解这些信息的用途、可见范围和退出方式。</span>
            </label>
          </div>
        </article>
      </section>

      <div class="mobile-nav" aria-label="移动端导航">
        <button v-for="item in navItems.slice(0, 6)" :key="item.id" :class="{ active: item.id === view }" type="button" @click="go(item.id)">
          <img class="icon" :src="item.icon" alt="" aria-hidden="true" />
          <span>{{ item.label }}</span>
        </button>
      </div>
    </main>

    <div v-if="toastText" class="toast" role="status" aria-live="polite">{{ toastText }}</div>
  </div>
</template>
