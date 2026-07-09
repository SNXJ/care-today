<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { api, photoUrl } from '../../api/client';
import { refreshCurrentSpace, useSession } from '../../state/session';
import { formatDay, showError } from '../../utils/format';

const session = useSession();
onShow(() => session.boot().catch(showError));

function photosOf(n: any): string[] {
  return Array.isArray(n.photos) ? n.photos : [];
}
function previewPhotos(photos: string[], index: number) {
  uni.previewImage({ urls: photos.map(photoUrl), current: index });
}
function edit(n: any) {
  uni.navigateTo({ url: `/pages/compose/index?edit=note&id=${n.id}` });
}
function confirmDelete(n: any) {
  uni.showModal({
    title: '删除这条资料？', content: n.title, confirmText: '删除', confirmColor: '#b85f55',
    success: async (r) => {
      if (!r.confirm || !session.data.space?.id) return;
      try {
        await api.deleteNote(session.data.space.id, n.id);
        await refreshCurrentSpace();
        uni.showToast({ title: '已删除' });
      } catch (error) { showError(error); }
    },
  });
}
</script>
<template><view class="page"><PageHero eyebrow="FILES" title="复诊资料" subtitle="检查报告、化验单拍照存进来，复诊时直接翻给医生看。" :profile="session.isAuthed.value" />
  <view v-if="!session.hasSpace.value" class="card empty">登录并创建陪伴空间后，这里会汇总全部复诊资料。</view>
  <view v-else class="card">
    <view class="card-title"><text>复诊资料</text><text class="tag">{{ session.data.notes.length ? `共 ${session.data.notes.length} 条` : '拍照或文字存档' }}</text></view>
    <view v-if="!session.data.notes.length" class="empty">还没有资料。点右下角「＋」上传照片或记录第一条。</view>
    <view v-for="n in session.data.notes" :key="n.id" class="note-tile">
      <view class="note-head">
        <view class="note-title">
          <text class="nt-name">{{ n.title }}</text>
          <text class="nt-meta">{{ n.type || '文本资料' }} · {{ formatDay(n.createdAt) }}</text>
        </view>
        <view class="note-actions">
          <text class="small-link" @click="edit(n)">编辑</text>
          <text class="small-link danger" @click="confirmDelete(n)">删除</text>
        </view>
      </view>
      <text v-if="n.content" class="note-content">{{ n.content }}</text>
      <view v-if="photosOf(n).length" class="note-photos">
        <image v-for="(pid, pi) in photosOf(n)" :key="pid" class="note-photo" :src="photoUrl(pid)" mode="aspectFill" @click="previewPhotos(photosOf(n), pi)" />
      </view>
    </view>
  </view>
  <ComposeFab v-if="session.hasSpace.value" type="note" />
</view></template>

<style scoped lang="scss">
.note-tile { margin-bottom: 16rpx; padding: 22rpx; border: 1px solid #eadbca; border-radius: 20rpx; background: #fff7ee; }
.note-tile:last-child { margin-bottom: 0; }
.note-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 16rpx; }
.note-title { flex: 1; min-width: 0; }
.nt-name { display: block; color: #312b27; font-size: 29rpx; font-weight: 700; }
.nt-meta { display: block; margin-top: 6rpx; color: #766b62; font-size: 23rpx; }
.note-actions { display: flex; gap: 18rpx; flex: 0 0 auto; }
.small-link { color: #71836a; font-size: 25rpx; }
.small-link.danger { color: #b85f55; }
.note-content { display: block; margin-top: 10rpx; color: #312b27; font-size: 27rpx; line-height: 1.5; }
.note-photos { display: flex; flex-wrap: wrap; gap: 12rpx; margin-top: 12rpx; }
.note-photo { width: 160rpx; height: 160rpx; border-radius: 14rpx; border: 1px solid #eadbca; }
</style>
