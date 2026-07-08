<script setup lang="ts">
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { api } from '../../api/client';
import { refreshCurrentSpace, useSession } from '../../state/session';
import { dateKey, formatDay, formatTime, showError } from '../../utils/format';

const session = useSession();
onShow(() => session.boot().catch(showError));

// 各类型的强调色与线稿图标（对齐 Flutter：日程/分享=玫瑰，问医生=蓝，资料=草绿，注意=琥珀）
const accents: Record<string, { c: string; soft: string; icon: string }> = {
  日程: { c: '#b85f55', soft: 'rgba(184,95,85,0.12)', icon: '/static/timeline/event.svg' },
  分享: { c: '#b85f55', soft: 'rgba(184,95,85,0.12)', icon: '/static/timeline/message.svg' },
  问医生: { c: '#5b7c99', soft: 'rgba(91,124,153,0.14)', icon: '/static/timeline/question.svg' },
  资料: { c: '#71836a', soft: 'rgba(113,131,106,0.14)', icon: '/static/timeline/note.svg' },
  注意: { c: '#c8893f', soft: 'rgba(200,137,63,0.14)', icon: '/static/timeline/notice.svg' },
};

function rangeLabel(n: any) {
  if (n.startsOn && n.endsOn) return `${n.startsOn} 至 ${n.endsOn}`;
  if (n.startsOn) return `${n.startsOn} 起生效`;
  if (n.endsOn) return `${n.endsOn} 前有效`;
  return '长期有效';
}

const items = computed(() => {
  const list: any[] = [];
  for (const e of session.data.events) {
    list.push({ id: `e-${e.id}`, kind: 'event', rawId: e.id, type: '日程', title: e.title, meta: `${formatTime(e.scheduledAt)} · ${e.location || '待补充地点'}`, detail: e.note || (e.needsCompanion ? '需要有人陪同' : '站内提醒'), at: e.scheduledAt });
  }
  for (const q of session.data.questions) {
    list.push({ id: `q-${q.id}`, kind: 'question', rawId: q.id, type: '问医生', title: q.question, meta: q.asked ? '已问过医生' : (q.important ? '重点问题' : '待复诊时确认'), detail: q.doctorAnswer || '还没有记录医生回复', at: q.createdAt });
  }
  for (const m of session.data.messages) {
    list.push({ id: `m-${m.id}`, kind: 'message', rawId: m.id, type: '分享', title: m.text, meta: m.author || '家人', detail: '一条分享动态', at: m.createdAt });
  }
  for (const n of session.data.notes) {
    list.push({ id: `f-${n.id}`, kind: 'note', rawId: n.id, type: '资料', title: n.title, meta: n.type || '文本资料', detail: n.content || '资料文本已保存', at: n.createdAt });
  }
  for (const n of session.data.notices) {
    list.push({ id: `n-${n.id}`, kind: 'notice', rawId: n.id, type: '注意', title: n.content, meta: `${n.important ? '重要 · ' : ''}${rangeLabel(n)}`, detail: n.detail || '添加了一条注意事项', at: n.createdAt });
  }
  return list.filter((x) => x.at)
    .map((x) => ({ ...x, accent: accents[x.type], dateLabel: formatDay(x.at), timeLabel: formatTime(x.at) }))
    .sort((a, b) => +new Date(b.at) - +new Date(a.at));
});

const todayKey = computed(() => dateKey());
const futureItems = computed(() => items.value.filter((x) => dateKey(x.at) > todayKey.value));
const pastItems = computed(() => items.value.filter((x) => dateKey(x.at) <= todayKey.value));
const todayLabel = computed(() => {
  const d = new Date();
  return `${d.getMonth() + 1}月${d.getDate()}日`;
});

const deleteApis: Record<string, (spaceId: string, id: string) => Promise<any>> = {
  event: api.deleteEvent, question: api.deleteQuestion, message: api.deleteMessage, note: api.deleteNote, notice: api.deleteNotice,
};

function openActions(item: any) {
  uni.showActionSheet({
    itemList: ['查看详情', '编辑', '删除'],
    success: ({ tapIndex }) => {
      if (tapIndex === 0) showDetail(item);
      else if (tapIndex === 1) uni.navigateTo({ url: `/pages/compose/index?edit=${item.kind}&id=${item.rawId}` });
      else if (tapIndex === 2) confirmDelete(item);
    },
  });
}

function showDetail(item: any) {
  uni.showModal({ title: `${item.type} · ${item.dateLabel}`, content: `${item.title}\n\n${item.meta}${item.detail ? '\n' + item.detail : ''}`, showCancel: false, confirmText: '好的' });
}

function confirmDelete(item: any) {
  uni.showModal({
    title: '删除这条记录？', content: item.title, confirmText: '删除', confirmColor: '#b85f55',
    success: async (r) => {
      if (!r.confirm || !session.data.space?.id) return;
      try {
        await deleteApis[item.kind](session.data.space.id, item.rawId);
        await refreshCurrentSpace();
        uni.showToast({ title: '已删除' });
      } catch (error) { showError(error); }
    },
  });
}
</script>

<template><view class="page"><PageHero eyebrow="TIMELINE" title="时间线" subtitle="未来的安排和走过的日子，都在这里慢慢连起来。" :profile="session.isAuthed.value" />
  <view v-if="!session.hasSpace.value" class="card empty">登录并创建陪伴空间后，这里会汇总全部记录。</view>
  <view v-else-if="!items.length" class="card empty">还没有记录。点右下角「＋」添加第一条。</view>
  <template v-else>
    <!-- 接下来 -->
    <template v-if="futureItems.length">
      <view class="tl-sechead"><text class="t">接下来</text><text class="s">{{ futureItems.length }} 项即将发生</text></view>
      <view v-for="(item, i) in futureItems" :key="item.id" class="tl-row" @click="openActions(item)">
        <view class="tl-rail">
          <view v-if="i !== 0" class="tl-seg top" />
          <view v-if="i !== futureItems.length - 1" class="tl-seg bottom" />
          <view class="tl-node" :style="{ borderColor: item.accent.c }"><image class="tl-icon" :src="item.accent.icon" mode="aspectFit" /></view>
        </view>
        <view class="tl-card">
          <view class="tl-head"><text class="tl-date" :style="{ color: item.accent.c }">{{ item.dateLabel }}</text><text class="tl-time">{{ item.timeLabel }}</text><text class="tl-type" :style="{ color: item.accent.c, background: item.accent.soft }">{{ item.type }}</text></view>
          <text class="tl-title">{{ item.title }}</text>
          <text class="tl-meta">{{ item.meta }}</text>
          <text v-if="item.detail" class="tl-detail">{{ item.detail }}</text>
        </view>
      </view>
    </template>

    <!-- 今天分隔 -->
    <view class="tl-divider"><view class="line" /><text class="label">今天 · {{ todayLabel }}</text><view class="line" /></view>

    <!-- 过往 -->
    <view v-if="!pastItems.length" class="empty">今天和之前还没有记录。</view>
    <view v-for="(item, i) in pastItems" :key="item.id" class="tl-row" @click="openActions(item)">
      <view class="tl-rail">
        <view v-if="i !== 0" class="tl-seg top" />
        <view v-if="i !== pastItems.length - 1" class="tl-seg bottom" />
        <view class="tl-node" :style="{ borderColor: item.accent.c }"><image class="tl-icon" :src="item.accent.icon" mode="aspectFit" /></view>
      </view>
      <view class="tl-card">
        <view class="tl-head"><text class="tl-date" :style="{ color: item.accent.c }">{{ item.dateLabel }}</text><text class="tl-time">{{ item.timeLabel }}</text><text class="tl-type" :style="{ color: item.accent.c, background: item.accent.soft }">{{ item.type }}</text></view>
        <text class="tl-title">{{ item.title }}</text>
        <text class="tl-meta">{{ item.meta }}</text>
        <text v-if="item.detail" class="tl-detail">{{ item.detail }}</text>
      </view>
    </view>

    <ComposeFab />
  </template>
</view></template>
