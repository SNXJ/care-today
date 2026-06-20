<script setup lang="ts">
import { computed, reactive, ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { useSession } from '../../state/session';
import { dateKey, formatDate, showError } from '../../utils/format';

const session = useSession();
const mode = ref<'login' | 'register'>('login');
const submitting = ref(false);
const auth = reactive({ account: '', email: '', phone: '', nickname: '', password: '' });
const spaceForm = reactive({ name: '陪你一起过今天', patientNickname: '', description: '' });

const todayEvents = computed(() => session.data.events.filter((item) => dateKey(item.scheduledAt) === dateKey()));
const activeNotices = computed(() => session.data.notices.filter((item) => item.status !== 'ARCHIVED' && (!item.startsOn || item.startsOn <= dateKey()) && (!item.endsOn || item.endsOn >= dateKey())));
const nextEvent = computed(() => session.data.events.filter((item) => new Date(item.scheduledAt) > new Date()).sort((a, b) => +new Date(a.scheduledAt) - +new Date(b.scheduledAt))[0]);

onShow(async () => {
  try { await session.boot(); } catch (error) { showError(error); }
});

async function submitAuth() {
  submitting.value = true;
  try {
    if (mode.value === 'login') {
      const account = auth.account.trim();
      await session.authenticate('login', { email: account.includes('@') ? account : undefined, phone: account.includes('@') ? undefined : account, password: auth.password });
    } else {
      await session.authenticate('register', { email: auth.email.trim() || undefined, phone: auth.phone.trim() || undefined, nickname: auth.nickname.trim(), password: auth.password });
    }
    uni.showToast({ title: mode.value === 'login' ? '欢迎回来' : '注册成功' });
  } catch (error) { showError(error); } finally { submitting.value = false; }
}

async function submitSpace() {
  submitting.value = true;
  try {
    await session.createSpace({ ...spaceForm, patientNickname: spaceForm.patientNickname.trim() || session.data.user?.nickname });
    uni.showToast({ title: '空间已创建' });
  } catch (error) { showError(error); } finally { submitting.value = false; }
}
</script>

<template>
  <view class="page">
    <PageHero eyebrow="CARE TODAY" title="陪你一起过今天" subtitle="把今天需要记住的事，放在一个温柔而清楚的地方。" :profile="session.isAuthed.value" />

    <view v-if="!session.data.ready || session.data.loading" class="card empty">正在打开陪伴空间…</view>

    <view v-else-if="!session.isAuthed.value" class="card">
      <view class="card-title"><text>{{ mode === 'login' ? '登录陪伴空间' : '创建一个账号' }}</text><text class="tag">隐私保护</text></view>
      <view v-if="mode === 'login'" class="field"><text class="label">手机号或邮箱</text><input v-model="auth.account" class="input" placeholder="请输入登录账号" /></view>
      <template v-else>
        <view class="field"><text class="label">昵称</text><input v-model="auth.nickname" class="input" placeholder="家人看到的名字" /></view>
        <view class="field"><text class="label">邮箱</text><input v-model="auth.email" class="input" placeholder="邮箱或手机号至少填一个" /></view>
        <view class="field"><text class="label">手机号</text><input v-model="auth.phone" class="input" type="number" placeholder="可选" /></view>
      </template>
      <view class="field"><text class="label">密码</text><input v-model="auth.password" class="input" password placeholder="至少 8 位" /></view>
      <view class="form-actions">
        <button class="primary" :loading="submitting" @click="submitAuth">{{ mode === 'login' ? '登录' : '注册并登录' }}</button>
        <button class="secondary" @click="mode = mode === 'login' ? 'register' : 'login'">{{ mode === 'login' ? '第一次来，去注册' : '已有账号，去登录' }}</button>
      </view>
    </view>

    <view v-else-if="!session.hasSpace.value" class="card">
      <view class="card-title"><text>建立陪伴空间</text><text class="tag">第一步</text></view>
      <view class="field"><text class="label">空间名称</text><input v-model="spaceForm.name" class="input" /></view>
      <view class="field"><text class="label">患者昵称</text><input v-model="spaceForm.patientNickname" class="input" :placeholder="session.data.user?.nickname || '怎么称呼你'" /></view>
      <view class="field"><text class="label">阶段备注</text><textarea v-model="spaceForm.description" class="textarea" placeholder="可选，不必填写具体病情" /></view>
      <button class="primary" :loading="submitting" @click="submitSpace">创建空间</button>
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

      <view class="card boundary">这里用于生活陪伴和就诊整理，不提供诊断、治疗建议或用药判断。如有明显不适或紧急情况，请及时联系医生、医院或当地急救服务。</view>
      <ComposeFab />
    </template>
  </view>
</template>
