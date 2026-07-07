<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { useSession } from '../../state/session';
import { dateKey, formatDate, formatTime, showError } from '../../utils/format';

const session = useSession();
const mode = ref<'login' | 'register'>('login');
const submitting = ref(false);
const agreementAccepted = ref(false);
const privacyAccepted = ref(false);
const auth = reactive({ account: '', nickname: '', password: '' });
const spaceForm = reactive({ name: '陪你一起过今天', patientNickname: '', description: '' });

const todayEvents = computed(() => session.data.events.filter((item) => dateKey(item.scheduledAt) === dateKey()));
const activeNotices = computed(() => session.data.notices.filter((item) => item.status !== 'ARCHIVED' && (!item.startsOn || item.startsOn <= dateKey()) && (!item.endsOn || item.endsOn >= dateKey())));
const nextEvent = computed(() => session.data.events.filter((item) => new Date(item.scheduledAt) > new Date()).sort((a, b) => +new Date(a.scheduledAt) - +new Date(b.scheduledAt))[0]);
const todayMedications = computed(() => session.data.medications
  .filter((m: any) => dateKey(m.takenAt) === dateKey())
  .sort((a: any, b: any) => +new Date(a.takenAt) - +new Date(b.takenAt)));

function goCompose(type: string) {
  uni.navigateTo({ url: `/pages/compose/index?type=${type}` });
}

onShow(async () => {
  try { await session.boot(); } catch (error) { showError(error); }
});

async function submitAuth() {
  console.log('[login] 点击触发 submitAuth', { account: auth.account, passwordLen: auth.password.length, mode: mode.value });
  const account = auth.account.trim();
  if (!account || !auth.password) {
    console.log('[login] 拦截：账号或密码为空');
    uni.showToast({ title: '请填写账号和密码', icon: 'none' });
    return;
  }
  if (mode.value === 'register' && !agreementAccepted.value) {
    console.log('[login] 拦截：注册未勾选协议');
    uni.showToast({ title: '请先阅读并同意协议', icon: 'none' });
    return;
  }
  const isEmail = account.includes('@');
  console.log('[login] 准备发请求', { isEmail });
  submitting.value = true;
  try {
    if (mode.value === 'login') {
      await session.authenticate('login', { email: isEmail ? account : undefined, phone: isEmail ? undefined : account, password: auth.password });
    } else {
      await session.authenticate('register', {
        email: isEmail ? account : undefined,
        phone: isEmail ? undefined : account,
        nickname: auth.nickname.trim() || (isEmail ? account.split('@')[0] : account),
        password: auth.password,
      });
    }
    console.log('[login] 请求成功');
    uni.showToast({ title: mode.value === 'login' ? '欢迎回来' : '注册成功' });
  } catch (error) { console.error('[login] 请求失败', error); showError(error); } finally { submitting.value = false; }
}

async function submitSpace() {
  if (!privacyAccepted.value) {
    uni.showToast({ title: '请先阅读并同意隐私政策', icon: 'none' });
    return;
  }
  submitting.value = true;
  try {
    await session.createSpace({ ...spaceForm, patientNickname: spaceForm.patientNickname.trim() || session.data.user?.nickname });
    uni.showToast({ title: '空间已创建' });
  } catch (error) { showError(error); } finally { submitting.value = false; }
}

function openLegal(path: 'user-agreement' | 'privacy-policy') {
  uni.navigateTo({ url: `/pages/legal/${path}` });
}
</script>

<template>
  <view class="page">
    <PageHero eyebrow="CARE TODAY" title="陪你一起过今天" subtitle="把今天需要记住的事，放在一个温柔而清楚的地方。" :profile="session.isAuthed.value" />

    <view v-if="!session.data.ready || session.data.loading" class="card empty">正在打开陪伴空间…</view>

    <view v-else-if="!session.isAuthed.value" class="card">
      <view class="card-title"><text>{{ mode === 'login' ? '登录陪伴空间' : '创建一个账号' }}</text><text class="tag">隐私保护</text></view>
      <view v-if="mode === 'register'" class="field"><text class="label">昵称</text><input v-model="auth.nickname" class="input" placeholder="家人看到的名字" /></view>
      <view class="field"><text class="label">手机号或邮箱</text><input v-model="auth.account" class="input" placeholder="请输入手机号或邮箱" /></view>
      <view class="field"><text class="label">密码</text><input v-model="auth.password" class="input" password :placeholder="mode === 'login' ? '请输入密码' : '至少 8 位'" /></view>
      <view v-if="mode === 'register'" class="check agreement">
        <checkbox :checked="agreementAccepted" color="#b85f55" @click.stop="agreementAccepted = !agreementAccepted" />
        <text>我已阅读并同意</text>
        <text class="link" @click.stop="openLegal('user-agreement')">《用户协议》</text>
        <text>和</text>
        <text class="link" @click.stop="openLegal('privacy-policy')">《隐私政策》</text>
      </view>
      <view class="form-actions">
        <button class="primary" :loading="submitting" @click="submitAuth()">{{ mode === 'login' ? '登录' : '注册并登录' }}</button>
        <button class="secondary" @click="mode = mode === 'login' ? 'register' : 'login'">{{ mode === 'login' ? '第一次来，去注册' : '已有账号，去登录' }}</button>
      </view>
    </view>

    <view v-else-if="!session.hasSpace.value" class="card">
      <view class="card-title"><text>建立陪伴空间</text><text class="tag">第一步</text></view>
      <view class="field"><text class="label">空间名称</text><input v-model="spaceForm.name" class="input" /></view>
      <view class="field"><text class="label">患者昵称</text><input v-model="spaceForm.patientNickname" class="input" :placeholder="session.data.user?.nickname || '怎么称呼你'" /></view>
      <view class="field"><text class="label">阶段备注</text><textarea v-model="spaceForm.description" class="textarea" placeholder="可选，不必填写具体病情" /></view>
      <view class="check agreement">
        <checkbox :checked="privacyAccepted" color="#b85f55" @click.stop="privacyAccepted = !privacyAccepted" />
        <text>我同意按照</text>
        <text class="link" @click.stop="openLegal('privacy-policy')">《隐私政策》</text>
        <text>处理陪伴空间数据</text>
      </view>
      <button class="primary" :class="{ disabled: !privacyAccepted }" :loading="submitting" :disabled="!privacyAccepted" @click="submitSpace()">创建空间</button>
    </view>

    <template v-else>
      <view v-if="activeNotices.length" class="card">
        <view class="card-title"><text>今天请留意</text><text class="tag">{{ activeNotices.length }} 条</text></view>
        <view v-for="notice in activeNotices" :key="notice.id" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ notice.content }}</text><text class="row-meta">{{ notice.detail || '生效中的注意事项' }}</text></view></view>
      </view>

      <view class="card">
        <view class="card-title"><text>今天要做的事</text><text class="tag">{{ todayEvents.length }} 项</text></view>
        <view v-if="!todayEvents.length" class="empty">今天没有排好的日程。给自己留一点从容，也很好。</view>
        <view v-for="event in todayEvents" :key="event.id" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ event.title }}</text><text class="row-meta">{{ formatDate(event.scheduledAt) }} · {{ event.location || '地点待补充' }}{{ event.needsCompanion ? ' · 需要陪同' : '' }}</text></view></view>
      </view>

      <view class="card">
        <view class="card-title"><text>下一件重要的事</text><text class="tag">提前准备</text></view>
        <view v-if="nextEvent" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ nextEvent.title }}</text><text class="row-meta">{{ formatDate(nextEvent.scheduledAt) }} · {{ nextEvent.location || '地点待补充' }}</text></view></view>
        <view v-else class="empty">还没有未来日程，可以点右下角「＋」记下来。</view>
      </view>

      <view class="card">
        <view class="card-title"><text>今天的用药</text><text class="tag">{{ todayMedications.length ? `已记 ${todayMedications.length} 次` : '还没记录' }}</text></view>
        <view v-if="!todayMedications.length" class="empty">今天还没有用药记录。吃过药就记一笔，别漏了也别重复吃。</view>
        <view v-for="m in todayMedications" :key="m.id" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ m.name }}<text v-if="m.dosage">（{{ m.dosage }}）</text></text><text class="row-meta">{{ formatTime(m.takenAt) }}{{ m.note ? ' · ' + m.note : '' }}</text></view></view>
        <button class="secondary inline-btn" @click="goCompose('medication')">记一次服药</button>
      </view>

      <view class="card">
        <view class="card-title"><text>及时联系医生</text></view>
        <view class="bullet-list">
          <view class="bullet">持续发热、寒战或感染迹象。</view>
          <view class="bullet">严重疼痛、呼吸困难、胸闷或晕厥。</view>
          <view class="bullet">过敏、伤口异常或用药后不适加重。</view>
        </view>
      </view>

      <view class="card boundary">这里用于生活陪伴和就诊整理，不提供诊断、治疗建议或用药判断。如有明显不适或紧急情况，请及时联系医生、医院或当地急救服务。</view>
      <ComposeFab />
    </template>
  </view>
</template>
