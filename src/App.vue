<script setup>
import { computed, ref } from 'vue';

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
const statusNote = ref(localStorage.getItem('care-today-status') || '');
const statusDraft = ref('');
const messageDraft = ref('');
const questionDraft = ref('');
const taskDraft = ref('');
const noteDraft = ref('');
const invitePhone = ref('');
const privacyAccepted = ref(false);

const events = ref([
  {
    time: '09:20',
    title: '门诊复查',
    place: '乳腺外科门诊 3 诊室',
    note: '带上病理报告、用药单、最近症状记录',
    tag: '需要陪同',
    date: '6 月 18 日',
  },
  {
    time: '14:00',
    title: '整理想问医生的问题',
    place: '家中',
    note: '把担心的事写下来，复诊时逐条确认',
    tag: '15 分钟',
    date: '今天',
  },
  {
    time: '20:30',
    title: '记录今天身体感受',
    place: '睡前',
    note: '疼痛、乏力、睡眠、心情简单打分',
    tag: '站内提醒',
    date: '今天',
  },
]);

const bodyRecords = ref([
  { label: '疼痛', value: 3 },
  { label: '乏力', value: 6 },
  { label: '睡眠', value: 5 },
  { label: '心情', value: 4 },
  { label: '食欲', value: 5 },
  { label: '体温', value: 37 },
]);

const questions = ref([
  { text: '我的分期、分型和这次治疗目标分别是什么？', done: false, important: true, answer: '' },
  { text: '现在的药物或治疗常见副作用有哪些，哪些情况需要马上联系医院？', done: false, important: true, answer: '' },
  { text: '饮食、运动、工作、睡眠有没有需要特别注意的限制？', done: false, important: false, answer: '' },
  { text: '下次检查需要提前准备什么，报告多久可以拿到？', done: true, important: false, answer: '提前预约抽血，报告当天可在院内系统查看。' },
]);

const helpTasks = ref([
  { title: '陪诊', type: '陪诊', time: '6 月 18 日 09:20', desc: '帮忙一起带资料、记录医生答复。', status: '待认领', claimedBy: '' },
  { title: '做饭', type: '做饭', time: '今天晚饭', desc: '清淡一点，少油。', status: '已认领', claimedBy: '妈妈' },
  { title: '接送', type: '接送', time: '周五下午', desc: '从医院回家。', status: '待认领', claimedBy: '' },
  { title: '整理报告', type: '整理报告', time: '复诊前一天', desc: '按日期把报告名称和备注整理好。', status: '已完成', claimedBy: '姐姐' },
]);

const messages = ref([
  { text: '今天不用把所有事都做好，先吃一点、睡一会儿，我们都在。', author: '家人', time: '10:24' },
  { text: '明天我可以陪你去医院，资料我晚上帮你一起整理。', author: '朋友', time: '昨天' },
]);

const notes = ref([
  { title: '病理报告', type: '报告名称记录', desc: '上次更新：6 月 6 日', visibility: '患者和管理员可见' },
  { title: '当前用药', type: '用药记录', desc: '剂量、时间、注意事项', visibility: '患者和管理员可见' },
  { title: '医嘱备注', type: '医嘱文本', desc: '复诊后补充医生答复', visibility: '空间成员可见' },
]);

const members = ref([
  { name: '小洁', role: '患者/管理员', access: '完整管理权限', status: '已加入' },
  { name: '姐姐', role: '家属', access: '可查看多数信息、创建任务、留言', status: '已加入' },
  { name: '朋友 A', role: '朋友', access: '可认领任务、留言', status: '已授权' },
  { name: '同事 B', role: '只读成员', access: '只能查看被授权内容', status: '待确认' },
]);

const activeNav = computed(() => navItems.find((item) => item.id === view.value));

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

function saveNeed(label) {
  showToast(`已记录：${label}`);
}

function saveStatus() {
  if (!statusDraft.value.trim()) {
    showToast('先写一点今天的感受');
    return;
  }
  statusNote.value = statusDraft.value.trim();
  localStorage.setItem('care-today-status', statusNote.value);
  statusDraft.value = '';
  showToast('身体记录已本地保存');
}

function addQuestion() {
  if (!questionDraft.value.trim()) {
    showToast('先写下想问医生的问题');
    return;
  }
  questions.value.unshift({ text: questionDraft.value.trim(), done: false, important: false, answer: '' });
  questionDraft.value = '';
  showToast('已加入问医生清单');
}

function claimTask(task) {
  task.status = '已认领';
  task.claimedBy = '我';
  showToast('已认领这件事');
}

function addTask() {
  if (!taskDraft.value.trim()) {
    showToast('先写一件可以被认领的小事');
    return;
  }
  helpTasks.value.unshift({
    title: taskDraft.value.trim(),
    type: '其他',
    time: '待约定',
    desc: '创建后可补充时间和说明。',
    status: '待认领',
    claimedBy: '',
  });
  taskDraft.value = '';
  showToast('已添加到帮忙墙');
}

function addMessage() {
  if (!messageDraft.value.trim()) {
    showToast('先写一句留言');
    return;
  }
  messages.value.unshift({ text: messageDraft.value.trim(), author: '我', time: '刚刚' });
  messageDraft.value = '';
  showToast('留言已添加');
}

function addNote() {
  if (!noteDraft.value.trim()) {
    showToast('先写一个资料名称');
    return;
  }
  notes.value.unshift({
    title: noteDraft.value.trim(),
    type: '文本资料',
    desc: '刚刚创建',
    visibility: '患者和管理员可见',
  });
  noteDraft.value = '';
  showToast('资料记录已创建');
}

function inviteMember() {
  if (!invitePhone.value.trim()) {
    showToast('先填写手机号或备注名');
    return;
  }
  members.value.push({
    name: invitePhone.value.trim(),
    role: '朋友',
    access: '加入后需管理员授权',
    status: '待确认',
  });
  invitePhone.value = '';
  showToast('邀请已创建，等待确认');
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
          <h1>陪你一起过今天</h1>
          <p class="lead">不用一个人记住所有事情。这里帮你整理复诊、身体感受、想问医生的问题，以及家人朋友可以接住的具体小事。</p>
        </div>
        <div class="privacy-pill">
          <img class="icon" :src="iconPrivacy" alt="" aria-hidden="true" />
          仅自己和被授权成员可见
        </div>
      </section>

      <section v-if="view === 'today'" class="page-grid">
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
              <span class="tag">下次复诊：6 月 18 日</span>
            </header>
            <div class="card-body today-grid">
              <div class="schedule">
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
                <small>天后带齐资料和问题，不用临时回忆。</small>
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
              <span class="tag">本地草稿</span>
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
            <div v-for="event in events" :key="event.title" class="schedule-row">
              <strong class="time">{{ event.date }}<br />{{ event.time }}</strong>
              <div>
                <strong>{{ event.title }}</strong>
                <span>{{ event.place }} · {{ event.note }}</span>
              </div>
              <span class="tag">{{ event.tag }}</span>
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
              <button class="mark-btn" :class="{ active: question.important }" type="button" @click.prevent="question.important = !question.important">
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
