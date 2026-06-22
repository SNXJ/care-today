'use strict';

const API = '/api';
const $ = (id) => document.getElementById(id);
let token = localStorage.getItem('care-admin-token') || '';

function setMsg(el, text, ok) {
  el.textContent = text;
  el.className = 'msg ' + (ok ? 'ok' : 'err');
}

function fmtSize(bytes) {
  if (!bytes) return '';
  const mb = bytes / 1048576;
  return mb.toFixed(1) + ' MB';
}

function fmtDate(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? iso : d.toLocaleString('zh-CN');
}

function showLoggedIn(loggedIn) {
  $('loginCard').classList.toggle('hidden', loggedIn);
  $('uploadCard').classList.toggle('hidden', !loggedIn);
  $('listCard').classList.toggle('hidden', !loggedIn);
  $('who').textContent = loggedIn ? '已登录' : '';
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
    showLoggedIn(true);
    loadVersions();
  } catch (e) {
    setMsg($('loginMsg'), e.message, false);
  } finally {
    $('loginBtn').disabled = false;
  }
}

function logout() {
  token = '';
  localStorage.removeItem('care-admin-token');
  showLoggedIn(false);
}

async function loadVersions() {
  try {
    const res = await fetch(API + '/app/versions', {
      headers: { Authorization: 'Bearer ' + token },
    });
    if (res.status === 401) return logout();
    if (res.status === 403) {
      $('versions').innerHTML =
        '<p class="msg err">当前账号不在管理员白名单（ADMIN_ACCOUNTS）内，无法发布。</p>';
      return;
    }
    const list = await res.json();
    if (!Array.isArray(list) || !list.length) {
      $('versions').innerHTML = '<p class="sub">还没有发布过版本。</p>';
      return;
    }
    $('versions').innerHTML = '';
    for (const v of list) {
      const row = document.createElement('div');
      row.className = 'ver';
      const info = document.createElement('div');
      info.className = 'grow';
      info.innerHTML =
        '<strong>' + v.versionName + ' (code ' + v.versionCode + ') ' +
        (v.forceUpdate ? '<span class="badge">强制</span>' : '') + '</strong>' +
        '<small>' + fmtSize(v.fileSize) + ' · ' + fmtDate(v.publishedAt) + '</small>' +
        (v.notes ? '<small><br>' + escapeHtml(v.notes) + '</small>' : '');
      const del = document.createElement('button');
      del.className = 'danger';
      del.textContent = '删除';
      del.addEventListener('click', () => removeVersion(v.id));
      row.appendChild(info);
      row.appendChild(del);
      $('versions').appendChild(row);
    }
  } catch (e) {
    $('versions').innerHTML = '<p class="msg err">' + e.message + '</p>';
  }
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"]/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
}

async function removeVersion(id) {
  if (!confirm('确认删除这个版本？APK 文件也会一起删除。')) return;
  const res = await fetch(API + '/app/versions/' + id, {
    method: 'DELETE',
    headers: { Authorization: 'Bearer ' + token },
  });
  if (res.ok || res.status === 204) loadVersions();
  else setMsg($('uploadMsg'), '删除失败', false);
}

function upload() {
  const file = $('file').files[0];
  const versionName = $('versionName').value.trim();
  const versionCode = $('versionCode').value.trim();
  if (!file) return setMsg($('uploadMsg'), '请选择 APK 文件', false);
  if (!versionName || !versionCode) {
    return setMsg($('uploadMsg'), '请填写 versionName 和 versionCode', false);
  }
  const form = new FormData();
  form.append('file', file);
  form.append('versionName', versionName);
  form.append('versionCode', versionCode);
  form.append('notes', $('notes').value);
  form.append('forceUpdate', $('forceUpdate').checked ? 'true' : 'false');

  const xhr = new XMLHttpRequest();
  xhr.open('POST', API + '/app/versions');
  xhr.setRequestHeader('Authorization', 'Bearer ' + token);
  const prog = $('prog');
  const bar = prog.querySelector('span');
  prog.classList.remove('hidden');
  $('uploadBtn').disabled = true;
  xhr.upload.onprogress = (e) => {
    if (e.lengthComputable) bar.style.width = (e.loaded / e.total * 100) + '%';
  };
  xhr.onload = () => {
    $('uploadBtn').disabled = false;
    prog.classList.add('hidden');
    bar.style.width = '0';
    if (xhr.status === 201) {
      setMsg($('uploadMsg'), '发布成功！客户端将在下次检查时收到更新。', true);
      $('versionName').value = '';
      $('versionCode').value = '';
      $('notes').value = '';
      $('file').value = '';
      $('forceUpdate').checked = false;
      loadVersions();
    } else if (xhr.status === 401) {
      logout();
    } else {
      let reason = '上传失败（' + xhr.status + '）';
      try { reason = JSON.parse(xhr.responseText).message || reason; } catch (_) {}
      setMsg($('uploadMsg'), reason, false);
    }
  };
  xhr.onerror = () => {
    $('uploadBtn').disabled = false;
    prog.classList.add('hidden');
    setMsg($('uploadMsg'), '网络错误，上传失败', false);
  };
  xhr.send(form);
}

function showPicked(f) {
  $('filename').textContent = f
    ? `${f.name}（${(f.size / 1048576).toFixed(1)} MB）`
    : '点此选择 APK 文件';
}

$('loginBtn').addEventListener('click', login);
$('logoutBtn').addEventListener('click', logout);
$('uploadBtn').addEventListener('click', upload);
$('password').addEventListener('keydown', (e) => { if (e.key === 'Enter') login(); });
$('file').addEventListener('change', function () { showPicked(this.files[0]); });

// 拖拽支持（桌面浏览器）
const zone = $('filezone');
['dragover', 'dragenter'].forEach((ev) =>
  zone.addEventListener(ev, (e) => { e.preventDefault(); zone.classList.add('drag'); }));
['dragleave', 'drop'].forEach((ev) =>
  zone.addEventListener(ev, (e) => { e.preventDefault(); zone.classList.remove('drag'); }));
zone.addEventListener('drop', (e) => {
  const f = e.dataTransfer.files[0];
  if (f) { $('file').files = e.dataTransfer.files; showPicked(f); }
});

if (token) {
  showLoggedIn(true);
  loadVersions();
}
