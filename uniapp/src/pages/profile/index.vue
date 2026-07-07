<script setup lang="ts">
import { ref } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { api } from '../../api/client';
import { useSession } from '../../state/session';
import { showError } from '../../utils/format';
const session = useSession();
const nickname = ref('家人朋友');
onShow(() => session.boot().catch(showError));
const roleName: Record<string,string> = { PATIENT_ADMIN: '患者/管理员', FAMILY: '家属', FRIEND: '朋友', READONLY: '只读成员' };
function requireSpaceId() {
  const id = session.data.space?.id;
  if (!id) uni.showToast({ title: '请先进入陪伴空间', icon: 'none' });
  return id;
}
async function invite() {
  try {
    const spaceId = requireSpaceId();
    if (!spaceId) return;
    const result = await api.createInvite(spaceId, { nickname: nickname.value.trim() || '家人朋友', role: 'FRIEND' });
    const siteOrigin = import.meta.env.VITE_SITE_ORIGIN || 'https://your-domain.example';
    const url = `${siteOrigin}/?invite=${result.token}`;
    uni.setClipboardData({ data: url, success: () => uni.showToast({ title: '邀请链接已复制' }) });
  } catch (error) { showError(error); }
}
function removeMember(member: any) {
  const spaceId = requireSpaceId();
  if (!spaceId) return;
  uni.showModal({
    title: '移除成员',
    content: `确定移除“${member.nickname}”吗？移除后对方不能继续访问这个空间。`,
    confirmText: '移除',
    confirmColor: '#b85f55',
    success: async (result) => {
      if (!result.confirm) return;
      try {
        await api.removeMember(spaceId, member.id);
        await session.selectSpace(spaceId);
        uni.showToast({ title: '已移除' });
      } catch (error) { showError(error); }
    },
  });
}
function openMemberActions(member: any) {
  if (!session.isPatient.value) return;
  uni.showActionSheet({
    itemList: ['移除成员'],
    success: ({ tapIndex }) => { if (tapIndex === 0) removeMember(member); },
  });
}
function leaveSpace() {
  const spaceId = requireSpaceId();
  if (!spaceId) return;
  uni.showModal({
    title: '退出空间',
    content: '退出后你将无法继续访问这个陪伴空间，除非管理员重新邀请。',
    confirmText: '退出',
    confirmColor: '#b85f55',
    success: async (result) => {
      if (!result.confirm) return;
      try {
        await api.leaveSpace(spaceId);
        uni.removeStorageSync('care-today-space-id');
        await session.boot(true);
        uni.showToast({ title: '已退出空间' });
        uni.reLaunch({ url: '/pages/index/index' });
      } catch (error) { showError(error); }
    },
  });
}
function deleteAccount() {
  uni.showModal({
    title: '删除账号',
    content: '删除后当前账号将不能继续登录，并会退出所有陪伴空间。必要审计信息会按规则保留。',
    confirmText: '删除账号',
    confirmColor: '#b85f55',
    success: async (result) => {
      if (!result.confirm) return;
      try {
        await api.deleteAccount();
        session.logout();
        uni.showToast({ title: '账号已删除' });
      } catch (error) { showError(error); }
    },
  });
}
function logout() { uni.showModal({ title: '退出登录', content: '确定退出当前账号吗？', success: (r) => { if (r.confirm) session.logout(); } }); }
function openLegal(path: 'user-agreement' | 'privacy-policy') { uni.navigateTo({ url: `/pages/legal/${path}` }); }
</script>
<template><view class="page" style="padding-top:32rpx">
  <view class="card"><view class="card-title"><text>{{ session.data.space?.name || '陪伴空间' }}</text><text class="tag">{{ roleName[session.data.currentRole] || '成员' }}</text></view><text class="subtitle">{{ session.data.space?.description || '让家人一起分担今天需要记住的事。' }}</text></view>
  <view class="card"><view class="card-title"><text>空间成员</text><text class="tag">{{ session.data.members.length }} 人</text></view><view v-for="member in session.data.members" :key="member.id" class="row member-row" @click="openMemberActions(member)"><view class="dot" /><view class="row-main"><text class="row-title">{{ member.nickname }}</text><text class="row-meta">{{ roleName[member.role] || member.role }} · {{ member.status === 'ACTIVE' ? '已加入' : '待加入' }}</text></view><text v-if="session.isPatient.value" class="arrow">›</text></view></view>
  <view v-if="session.isPatient.value" class="card"><view class="card-title"><text>邀请家人朋友</text><text class="tag">链接 7 天有效</text></view><view class="field"><text class="label">对方昵称</text><input v-model="nickname" class="input" /></view><button class="primary" @click="invite()">生成并复制邀请链接</button></view>
  <view class="card boundary"><text style="display:block;font-weight:700;color:#312b27;margin-bottom:10rpx">隐私与医疗边界</text>所有健康相关数据只用于当前陪伴空间协作。应用不提供医疗诊断、治疗建议或用药判断；涉及治疗与症状处理，请以医生意见为准。</view>
  <view class="card"><view class="card-title"><text>协议与隐私</text><text class="tag">上架必读</text></view><button class="action" @click="openLegal('user-agreement')"><view><text class="row-title">用户协议</text><text class="row-meta">账号、空间协作和使用边界</text></view><text class="arrow">›</text></button><button class="action" @click="openLegal('privacy-policy')"><view><text class="row-title">隐私政策</text><text class="row-meta">健康数据、成员可见性与账号注销</text></view><text class="arrow">›</text></button></view>
  <view class="card"><view class="card-title"><text>账号与数据</text><text class="tag">权限管理</text></view><button class="action" @click="leaveSpace()"><view><text class="row-title">退出当前空间</text><text class="row-meta">退出后不能继续查看这个空间的数据</text></view><text class="arrow">›</text></button><button class="action danger-action" @click="deleteAccount()"><view><text class="row-title">删除账号</text><text class="row-meta">删除登录账号并退出所有空间</text></view><text class="arrow">›</text></button></view>
  <button class="secondary" style="width:100%" @click="logout()">退出登录</button>
</view></template>

<style scoped lang="scss">
.member-row { align-items: center; }
.danger-action .row-title, .danger-action .arrow { color: #b85f55; }
</style>
