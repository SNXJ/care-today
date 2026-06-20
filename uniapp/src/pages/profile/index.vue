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
async function invite() {
  try {
    const result = await api.createInvite(session.data.space.id, { nickname: nickname.value.trim() || '家人朋友', role: 'FRIEND' });
    const url = `https://your-domain.example/?invite=${result.token}`;
    uni.setClipboardData({ data: url, success: () => uni.showToast({ title: '邀请链接已复制' }) });
  } catch (error) { showError(error); }
}
function logout() { uni.showModal({ title: '退出登录', content: '确定退出当前账号吗？', success: (r) => { if (r.confirm) session.logout(); } }); }
</script>
<template><view class="page" style="padding-top:32rpx">
  <view class="card"><view class="card-title"><text>{{ session.data.space?.name || '陪伴空间' }}</text><text class="tag">{{ roleName[session.data.currentRole] || '成员' }}</text></view><text class="subtitle">{{ session.data.space?.description || '让家人一起分担今天需要记住的事。' }}</text></view>
  <view class="card"><view class="card-title"><text>空间成员</text><text class="tag">{{ session.data.members.length }} 人</text></view><view v-for="member in session.data.members" :key="member.id" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ member.nickname }}</text><text class="row-meta">{{ roleName[member.role] || member.role }} · {{ member.status === 'ACTIVE' ? '已加入' : '待加入' }}</text></view></view></view>
  <view v-if="session.isPatient.value" class="card"><view class="card-title"><text>邀请家人朋友</text><text class="tag">链接 7 天有效</text></view><view class="field"><text class="label">对方昵称</text><input v-model="nickname" class="input" /></view><button class="primary" @click="invite">生成并复制邀请链接</button></view>
  <view class="card boundary"><text style="display:block;font-weight:700;color:#312b27;margin-bottom:10rpx">隐私与医疗边界</text>所有健康相关数据只用于当前陪伴空间协作。应用不提供医疗诊断、治疗建议或用药判断；涉及治疗与症状处理，请以医生意见为准。</view>
  <button class="secondary" style="width:100%" @click="logout">退出登录</button>
</view></template>
