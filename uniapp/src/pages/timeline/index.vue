<script setup lang="ts">
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { useSession } from '../../state/session';
import { formatDate, showError } from '../../utils/format';

const session = useSession();
onShow(() => session.boot().catch(showError));

const items = computed(() => [
  ...session.data.events.map((x) => ({ id: `e-${x.id}`, type: '日程', title: x.title, meta: x.location || '日程安排', at: x.scheduledAt })),
  ...session.data.messages.map((x) => ({ id: `m-${x.id}`, type: '分享', title: x.text, meta: x.author, at: x.createdAt })),
  ...session.data.symptoms.map((x) => ({ id: `s-${x.id}`, type: '症状', title: x.tag, meta: x.note || '身体记录', at: x.happenedAt })),
  ...session.data.notices.map((x) => ({ id: `n-${x.id}`, type: '注意', title: x.content, meta: x.detail || '注意事项', at: x.createdAt })),
  ...session.data.questions.map((x) => ({ id: `q-${x.id}`, type: '问医生', title: x.question, meta: x.asked ? '已询问' : '待询问', at: x.createdAt })),
  ...session.data.notes.map((x) => ({ id: `f-${x.id}`, type: '资料', title: x.title, meta: x.type, at: x.createdAt })),
].filter((x) => x.at).sort((a, b) => +new Date(b.at) - +new Date(a.at)));
</script>

<template><view class="page"><PageHero eyebrow="TIMELINE" title="时间线" subtitle="未来的安排和走过的日子，都在这里慢慢连起来。" />
  <view class="card"><view class="card-title"><text>全部记录</text><text class="tag">{{ items.length }} 条</text></view>
    <view v-if="!items.length" class="empty">还没有记录。点右下角「＋」添加第一条。</view>
    <view v-for="item in items" :key="item.id" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ item.title }}</text><text class="row-meta">{{ item.type }} · {{ formatDate(item.at) }} · {{ item.meta }}</text></view></view>
  </view><ComposeFab /></view></template>
