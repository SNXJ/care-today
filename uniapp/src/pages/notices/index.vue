<script setup lang="ts">
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import { api } from '../../api/client';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { refreshCurrentSpace, useSession } from '../../state/session';
import { dateKey, showError } from '../../utils/format';
const session = useSession();
onShow(() => session.boot().catch(showError));
const today = dateKey();
const notices = computed(() => session.data.notices.filter((x) => x.status !== 'ARCHIVED' && (!x.startsOn || x.startsOn <= today) && (!x.endsOn || x.endsOn >= today)));
const futureNotices = computed(() => session.data.notices.filter((x) => x.status !== 'ARCHIVED' && x.startsOn && x.startsOn > today));
const archivedNotices = computed(() => session.data.notices.filter((x) => x.status === 'ARCHIVED'));

function rangeLabel(item: any) {
  if (item.startsOn && item.endsOn) return `${item.startsOn} 至 ${item.endsOn}`;
  if (item.startsOn) return `${item.startsOn} 起生效`;
  if (item.endsOn) return `${item.endsOn} 前有效`;
  return '长期有效';
}

function askText(title: string, placeholder: string, value: string) {
  return new Promise<string | null>((resolve) => {
    uni.showModal({
      title,
      editable: true,
      placeholderText: placeholder,
      content: value,
      success: (result) => resolve(result.confirm ? String(result.content || '').trim() : null),
      fail: () => resolve(null),
    });
  });
}

async function updateNotice(item: any, data: any, toastTitle?: string) {
  try {
    if (!session.data.space?.id) return;
    await api.updateNotice(session.data.space.id, item.id, data);
    await refreshCurrentSpace();
    if (toastTitle) uni.showToast({ title: toastTitle });
  } catch (error) { showError(error); }
}

async function editNotice(item: any) {
  const content = await askText('编辑注意事项', '填写注意事项内容', item.content);
  if (content === null) return;
  if (!content) {
    uni.showToast({ title: '内容不能为空', icon: 'none' });
    return;
  }
  const detail = await askText('补充说明', '可留空', item.detail || '');
  if (detail === null) return;
  await updateNotice(item, { content, detail }, '已更新');
}

async function toggleImportant(item: any) {
  await updateNotice(item, { important: !item.important }, item.important ? '已取消重要' : '已标为重要');
}

async function toggleArchive(item: any) {
  const nextStatus = item.status === 'ARCHIVED' ? 'ACTIVE' : 'ARCHIVED';
  await updateNotice(item, { status: nextStatus }, nextStatus === 'ARCHIVED' ? '已归档' : '已恢复');
}

async function deleteNotice(item: any) {
  uni.showModal({
    title: '删除注意事项？',
    content: item.content,
    confirmText: '删除',
    confirmColor: '#b85f55',
    success: async (result) => {
      if (!result.confirm || !session.data.space?.id) return;
      try {
        await api.deleteNotice(session.data.space.id, item.id);
        await refreshCurrentSpace();
        uni.showToast({ title: '已删除' });
      } catch (error) { showError(error); }
    },
  });
}

function openActions(item: any) {
  const archived = item.status === 'ARCHIVED';
  const itemList = [
    '编辑内容',
    item.important ? '取消重要' : '标为重要',
    archived ? '恢复显示' : '归档',
    '删除',
  ];
  uni.showActionSheet({
    itemList,
    success: ({ tapIndex }) => {
      if (tapIndex === 0) editNotice(item);
      if (tapIndex === 1) toggleImportant(item);
      if (tapIndex === 2) toggleArchive(item);
      if (tapIndex === 3) deleteNotice(item);
    },
  });
}
</script>
<template><view class="page"><PageHero eyebrow="PLEASE NOTICE" title="注意" subtitle="把医生叮嘱和需要小心的事，放在每天都看得见的位置。" :profile="session.isAuthed.value" />
  <view v-if="!session.hasSpace.value" class="card empty">登录并创建陪伴空间后，这里会显示注意事项。</view>
  <template v-else>
    <view class="card"><view class="card-title"><text>生效中的提醒</text><text class="tag">{{ notices.length }} 条</text></view><view v-if="!notices.length" class="empty">目前没有生效中的注意事项。</view><view v-for="item in notices" :key="item.id" class="row notice-row" @click="openActions(item)"><view class="dot" /><view class="row-main"><text class="row-title">{{ item.important ? '重要 · ' : '' }}{{ item.content }}</text><text class="row-meta">{{ rangeLabel(item) }}<template v-if="item.detail"> · {{ item.detail }}</template></text></view><text class="arrow">›</text></view></view>
    <view v-if="futureNotices.length" class="card"><view class="card-title"><text>未开始</text><text class="tag">{{ futureNotices.length }} 条</text></view><view v-for="item in futureNotices" :key="item.id" class="row notice-row" @click="openActions(item)"><view class="dot" /><view class="row-main"><text class="row-title">{{ item.important ? '重要 · ' : '' }}{{ item.content }}</text><text class="row-meta">{{ rangeLabel(item) }}<template v-if="item.detail"> · {{ item.detail }}</template></text></view><text class="arrow">›</text></view></view>
    <view v-if="archivedNotices.length" class="card"><view class="card-title"><text>已归档</text><text class="tag">{{ archivedNotices.length }} 条</text></view><view v-for="item in archivedNotices" :key="item.id" class="row notice-row muted-row" @click="openActions(item)"><view class="dot" /><view class="row-main"><text class="row-title">{{ item.content }}</text><text class="row-meta">{{ rangeLabel(item) }}</text></view><text class="arrow">›</text></view></view>
    <view class="card boundary">注意事项只用于记录已有医嘱和生活提醒，不用于自动判断用药或治疗方案。</view>
    <ComposeFab type="notice" />
  </template>
</view></template>

<style scoped lang="scss">
.notice-row { align-items: center; }
.muted-row { opacity: .72; }
</style>
