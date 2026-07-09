<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { useSession } from '../../state/session';
import { photoUrl } from '../../api/client';
import { formatFull, showError } from '../../utils/format';
const session = useSession();
onShow(() => session.boot().catch(showError));

function photosOf(m: any): string[] {
  return Array.isArray(m.photos) ? m.photos : [];
}
function previewPhotos(photos: string[], index: number) {
  uni.previewImage({ urls: photos.map(photoUrl), current: index });
}
function edit(m: any) {
  uni.navigateTo({ url: `/pages/compose/index?edit=message&id=${m.id}` });
}
</script>
<template><view class="page"><PageHero eyebrow="SHARING" title="分享" subtitle="不是汇报病情，只是让关心你的人知道：此刻的你，在想什么。" :profile="session.isAuthed.value" />
  <view v-if="!session.hasSpace.value" class="card empty">登录并创建陪伴空间后，患者本人可以在这里分享近况。</view>
  <view v-else class="card">
    <view class="card-title"><text>分享</text><text class="tag">{{ session.isPatient.value ? '管理员可管理' : '成员都能发' }}</text></view>
    <view v-if="!session.data.messages.length" class="empty">还没有分享。点右下角「＋」发布近况。</view>
    <view v-for="m in session.data.messages" :key="m.id" class="moment-tile" @click="session.isPatient.value && edit(m)">
      <text class="moment-text">{{ m.text }}</text>
      <view v-if="photosOf(m).length" class="moment-photos">
        <image v-for="(pid, pi) in photosOf(m)" :key="pid" class="moment-photo" :src="photoUrl(pid)" mode="aspectFill" @click.stop="previewPhotos(photosOf(m), pi)" />
      </view>
      <text class="moment-meta">{{ m.author || '家人' }} · {{ formatFull(m.createdAt) }}</text>
    </view>
  </view>
  <ComposeFab v-if="session.hasSpace.value && session.isPatient.value" type="message" />
</view></template>

<style scoped lang="scss">
.moment-tile { margin-bottom: 16rpx; padding: 22rpx; border: 1px solid #eadbca; border-radius: 20rpx; background: #fff7ee; }
.moment-tile:last-child { margin-bottom: 0; }
.moment-text { display: block; color: #312b27; font-size: 28rpx; line-height: 1.5; }
.moment-meta { display: block; margin-top: 8rpx; color: #766b62; font-size: 22rpx; }
.moment-photos { display: flex; flex-wrap: wrap; gap: 12rpx; margin-top: 12rpx; }
.moment-photo { width: 160rpx; height: 160rpx; border-radius: 14rpx; border: 1px solid #eadbca; }
</style>
