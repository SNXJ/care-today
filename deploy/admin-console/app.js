'use strict';

const API = '/api';
const $ = (id) => document.getElementById(id);
let token = localStorage.getItem('care-admin-token') || '';

function setMsg(el, text, ok) {
  el.textContent = text;
  el.className = 'msg ' + (ok ? 'ok' : 'err');
}

function fmtSize(bytes) {
  if (!bytes) return '0';
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / 1048576).toFixed(1) + ' MB';
}

function fmtDate(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? iso : d.toLocaleString('zh-CN');
}

function fmtDay(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? iso : d.toLocaleDateString('zh-CN');
}

function escapeHtml(s) {
  return String(s ?? '').replace(/[&<>"]/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

async function adminFetch(path) {
  const res = await fetch(API + path, { headers: { Authorization: 'Bearer ' + token } });
  if (res.status === 401) { logout(); throw new Error('登录已过期，请重新登录'); }
  if (res.status === 403) throw new Error('当前账号不在管理员白名单（ADMIN_ACCOUNTS）内');
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.reason || data.message || '请求失败（' + res.status + '）');
  }
  return res.json();
}

// ———————————————— 登录 ————————————————

function showLoggedIn(loggedIn) {
  $('loginCard').classList.toggle('hidden', loggedIn);
  $('tabs').classList.toggle('hidden', !loggedIn);
  $('who').textContent = loggedIn ? '已登录' : '';
  if (loggedIn) {
    switchTab(currentTab);
  } else {
    for (const name of TABS) $('tab-' + name).classList.add('hidden');
  }
}

async function login() {
  const account = $('account').value.trim();
  const password = $('password').value;
  if (!account || !password) {
    setMsg($('loginMsg'), '请输入账号和密码', false);
    return;
  }
  const isEmail = account.includes('@');
  $('loginBtn').disabled = true;
  try {
    const res = await fetch(API + '/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: isEmail ? account : null,
        phone: isEmail ? null : account,
        password,
      }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.reason || data.message || '登录失败');
    token = data.token;
    localStorage.setItem('care-admin-token', token);
    setMsg($('loginMsg'), '', true);
    loadedTabs.clear();
    showLoggedIn(true);
  } catch (e) {
    setMsg($('loginMsg'), e.message, false);
  } finally {
    $('loginBtn').disabled = false;
  }
}

function logout() {
  token = '';
  localStorage.removeItem('care-admin-token');
  loadedTabs.clear();
  showLoggedIn(false);
}

// ———————————————— 标签页 ————————————————

const TABS = ['overview', 'users', 'spaces', 'photos'];
let currentTab = 'overview';
const loadedTabs = new Set();

function switchTab(name) {
  currentTab = name;
  for (const t of TABS) $('tab-' + t).classList.toggle('hidden', t !== name);
  document.querySelectorAll('#tabs button[data-tab]').forEach((b) =>
    b.classList.toggle('active', b.dataset.tab === name));
  if (!loadedTabs.has(name)) {
    loadedTabs.add(name);
    if (name === 'overview') loadOverview();
    if (name === 'users') loadUsers();
    if (name === 'spaces') loadSpaces();
    if (name === 'photos') loadPhotos();
  }
}

// ———————————————— 总览 ————————————————

const STAT_LABELS = [
  ['users', '注册用户'], ['spaces', '陪伴空间'], ['members', '空间成员'],
  ['events', '日程'], ['messages', '分享'], ['notes', '资料'],
  ['bodyRecords', '身体记录'], ['symptoms', '症状'], ['medications', '用药'],
  ['questions', '问医生'], ['notices', '注意事项'], ['files', '图片'],
];

async function loadOverview() {
  try {
    const data = await adminFetch('/admin/overview');
    const t = data.totals || {};
    $('statGrid').innerHTML = STAT_LABELS.map(([key, label], i) => {
      const cls = i % 3 === 1 ? 'sage' : i % 3 === 2 ? 'amber' : '';
      let extra = '';
      if (key === 'files' && t.fileBytes) extra = '（' + fmtSize(t.fileBytes) + '）';
      return '<div class="stat ' + cls + '"><b>' + (t[key] ?? 0) + '</b><span>'
        + label + extra + '</span></div>';
    }).join('');

    // 近 14 天：绿色柱=新增记录，黄色柱=新增用户
    const days = [];
    const now = new Date();
    for (let i = 13; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const dd = String(d.getDate()).padStart(2, '0');
      days.push(d.getFullYear() + '-' + m + '-' + dd);
    }
    const recMap = {}, userMap = {};
    for (const r of data.recordDaily || []) recMap[String(r.day).slice(0, 10)] = Number(r.n);
    for (const r of data.userDaily || []) userMap[String(r.day).slice(0, 10)] = Number(r.n);
    const max = Math.max(1, ...days.map((d) => recMap[d] || 0), ...days.map((d) => userMap[d] || 0));
    $('chart').innerHTML = days.map((d) => {
      const rec = recMap[d] || 0, usr = userMap[d] || 0;
      const label = d.slice(5).replace('-', '/');
      return '<div class="bar"><b>' + (rec || '') + '</b>'
        + '<i style="height:' + Math.round(rec / max * 78) + '%"></i>'
        + (usr ? '<i style="height:' + Math.round(usr / max * 78) + '%;background:var(--amber)"></i>' : '')
        + '<small>' + label + '</small></div>';
    }).join('');
    setMsg($('overviewMsg'), '', true);
  } catch (e) {
    setMsg($('overviewMsg'), e.message, false);
  }
}

// ———————————————— 用户 ————————————————

async function loadUsers() {
  try {
    const list = await adminFetch('/admin/users');
    const rows = list.map((u) =>
      '<tr><td>' + escapeHtml(u.nickname) + '</td>'
      + '<td>' + escapeHtml(u.email || '') + '</td>'
      + '<td>' + escapeHtml(u.phone || '') + '</td>'
      + '<td class="num">' + (u.spaceCount ?? 0) + '</td>'
      + '<td>' + fmtDate(u.createdAt) + '</td></tr>').join('');
    $('userTable').innerHTML =
      '<tr><th>昵称</th><th>邮箱</th><th>手机号</th><th class="num">空间数</th><th>注册时间</th></tr>' + rows;
    setMsg($('usersMsg'), '共 ' + list.length + ' 位用户', true);
  } catch (e) {
    setMsg($('usersMsg'), e.message, false);
  }
}

// ———————————————— 空间 ————————————————

async function loadSpaces() {
  try {
    const list = await adminFetch('/admin/spaces');
    const rows = list.map((s) =>
      '<tr class="clickable" data-id="' + s.id + '"><td>' + escapeHtml(s.name) + '</td>'
      + '<td>' + escapeHtml(s.patientNickname || '') + '</td>'
      + '<td class="num">' + s.memberCount + '</td>'
      + '<td class="num">' + s.events + '</td>'
      + '<td class="num">' + s.messages + '</td>'
      + '<td class="num">' + s.notes + '</td>'
      + '<td class="num">' + s.bodyRecords + '</td>'
      + '<td class="num">' + s.symptoms + '</td>'
      + '<td class="num">' + s.medications + '</td>'
      + '<td class="num">' + s.questions + '</td>'
      + '<td class="num">' + s.notices + '</td>'
      + '<td class="num">' + s.files + '</td>'
      + '<td>' + fmtDay(s.createdAt) + '</td></tr>').join('');
    $('spaceTable').innerHTML =
      '<tr><th>空间</th><th>患者</th><th class="num">成员</th><th class="num">日程</th>'
      + '<th class="num">分享</th><th class="num">资料</th><th class="num">身体</th>'
      + '<th class="num">症状</th><th class="num">用药</th><th class="num">问医生</th>'
      + '<th class="num">注意</th><th class="num">图片</th><th>创建</th></tr>' + rows;
    $('spaceTable').querySelectorAll('tr.clickable').forEach((tr) =>
      tr.addEventListener('click', () => openSpaceDetail(tr.dataset.id)));
    setMsg($('spacesMsg'), '共 ' + list.length + ' 个空间', true);
  } catch (e) {
    setMsg($('spacesMsg'), e.message, false);
  }
}

function photoThumbs(photosJson) {
  let ids = [];
  try { ids = JSON.parse(photosJson || '[]'); } catch (_) { ids = []; }
  if (!Array.isArray(ids) || !ids.length) return '';
  return '<span class="inline-photos">' + ids.map((id) =>
    '<img class="thumb" loading="lazy" data-lightbox src="' + API + '/files/' + encodeURIComponent(id) + '" />').join('') + '</span>';
}

function section(title, items, render) {
  if (!items || !items.length) return '';
  return '<h3>' + title + '（' + items.length + '）</h3>'
    + items.map((x) => '<p class="item">' + render(x) + '</p>').join('');
}

async function openSpaceDetail(id) {
  $('spaceListCard').classList.add('hidden');
  $('spaceDetailCard').classList.remove('hidden');
  $('spaceDetail').innerHTML = '加载中…';
  try {
    const d = await adminFetch('/admin/spaces/' + id);
    const s = d.space || {};
    let html = '<h2 style="margin:0 0 2px">' + escapeHtml(s.name)
      + ' <span style="font-size:13px;color:var(--muted)">患者：' + escapeHtml(s.patientNickname || '—')
      + ' · 创建于 ' + fmtDay(s.createdAt) + '</span></h2>';
    if (s.description) html += '<p style="margin:0;color:var(--muted);font-size:13px">' + escapeHtml(s.description) + '</p>';

    html += section('成员', d.members, (m) =>
      '<b>' + escapeHtml(m.nickname) + '</b>（' + escapeHtml(m.role) + ' · ' + escapeHtml(m.status) + '）'
      + '<small>' + escapeHtml(m.email || m.phone || '') + (m.joinedAt ? ' · 加入于 ' + fmtDate(m.joinedAt) : '') + '</small>');
    html += section('分享', d.messages, (m) =>
      escapeHtml(m.text) + photoThumbs(m.photos)
      + '<small>' + escapeHtml(m.author || '家人') + ' · ' + fmtDate(m.createdAt) + '</small>');
    html += section('复诊资料', d.notes, (n) =>
      '<b>' + escapeHtml(n.title) + '</b>' + (n.content ? ' — ' + escapeHtml(n.content) : '') + photoThumbs(n.photos)
      + '<small>' + escapeHtml(n.type || '') + ' · ' + fmtDate(n.createdAt) + '</small>');
    html += section('日程', d.events, (e) =>
      '<b>' + escapeHtml(e.title) + '</b>'
      + '<small>' + fmtDate(e.scheduledAt) + (e.location ? ' · ' + escapeHtml(e.location) : '')
      + (e.needsCompanion ? ' · 需要陪同' : '') + (e.note ? ' · ' + escapeHtml(e.note) : '') + '</small>');
    html += section('身体记录', d.bodyRecords, (b) => {
      const parts = [];
      if (b.temperature != null) parts.push('体温 ' + b.temperature + '℃');
      if (b.weight != null) parts.push('体重 ' + b.weight + 'kg');
      if (b.painScore != null) parts.push('疼痛' + b.painScore + ' 乏力' + b.fatigueScore
        + ' 睡眠' + b.sleepScore + ' 心情' + b.moodScore + ' 食欲' + b.appetiteScore);
      return (parts.join(' · ') || '—')
        + '<small>' + (b.recordDate || '') + (b.note ? ' · ' + escapeHtml(b.note) : '') + '</small>';
    });
    html += section('症状', d.symptoms, (x) =>
      '<b>' + escapeHtml(x.tag) + '</b>'
      + '<small>' + fmtDate(x.happenedAt) + (x.note ? ' · ' + escapeHtml(x.note) : '') + '</small>');
    html += section('用药', d.medications, (m) =>
      '<b>' + escapeHtml(m.name) + '</b>' + (m.dosage ? '（' + escapeHtml(m.dosage) + '）' : '')
      + '<small>' + fmtDate(m.takenAt) + (m.note ? ' · ' + escapeHtml(m.note) : '') + '</small>');
    html += section('问医生', d.questions, (q) =>
      escapeHtml(q.question) + (q.important ? ' <span class="badge">重点</span>' : '')
      + '<small>' + (q.asked ? '已问过' : '待确认')
      + (q.doctorAnswer ? ' · 答复：' + escapeHtml(q.doctorAnswer) : '') + '</small>');
    html += section('注意事项', d.notices, (n) =>
      escapeHtml(n.content) + (n.important ? ' <span class="badge">重要</span>' : '')
      + '<small>' + escapeHtml(n.status) + (n.startsOn ? ' · ' + n.startsOn : '') + (n.endsOn ? ' ~ ' + n.endsOn : '')
      + (n.detail ? ' · ' + escapeHtml(n.detail) : '') + '</small>');
    $('spaceDetail').innerHTML = html;
  } catch (e) {
    $('spaceDetail').innerHTML = '<p class="msg err">' + escapeHtml(e.message) + '</p>';
  }
}

// ———————————————— 图片 ————————————————

async function loadPhotos() {
  try {
    const list = await adminFetch('/admin/files');
    const totalBytes = list.reduce((sum, f) => sum + (f.sizeBytes || 0), 0);
    $('photoCount').textContent = '共 ' + list.length + ' 张 · ' + fmtSize(totalBytes);
    $('photoGrid').innerHTML = list.map((f) => {
      const meta = escapeHtml((f.spaceName || '') + (f.uploader ? ' · ' + f.uploader : ''));
      const metaFull = escapeHtml(fmtDate(f.createdAt) + ' · ' + fmtSize(f.sizeBytes));
      return '<div class="photo-cell">'
        + '<img loading="lazy" data-lightbox data-meta="' + meta + ' · ' + metaFull + '" src="'
        + API + '/files/' + encodeURIComponent(f.id) + '" />'
        + '<small>' + meta + '<br>' + fmtDay(f.createdAt) + ' · ' + fmtSize(f.sizeBytes) + '</small></div>';
    }).join('') || '<p class="sub">还没有图片。</p>';
    setMsg($('photosMsg'), '', true);
  } catch (e) {
    setMsg($('photosMsg'), e.message, false);
  }
}

// 大图查看：事件代理，点任何带 data-lightbox 的图片放大
document.addEventListener('click', (e) => {
  const img = e.target.closest('img[data-lightbox]');
  if (!img) return;
  $('lightboxImg').src = img.src;
  $('lightboxMeta').textContent = img.dataset.meta || '';
  $('lightbox').classList.remove('hidden');
});

// ———————————————— 事件绑定 ————————————————

$('loginBtn').addEventListener('click', login);
$('logoutBtn').addEventListener('click', logout);
$('password').addEventListener('keydown', (e) => { if (e.key === 'Enter') login(); });
document.querySelectorAll('#tabs button[data-tab]').forEach((b) =>
  b.addEventListener('click', () => switchTab(b.dataset.tab)));
$('backToSpaces').addEventListener('click', () => {
  $('spaceDetailCard').classList.add('hidden');
  $('spaceListCard').classList.remove('hidden');
});
$('lightbox').addEventListener('click', () => $('lightbox').classList.add('hidden'));

if (token) {
  showLoggedIn(true);
}
