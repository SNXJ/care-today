<script setup lang="ts">
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { useSession } from '../../state/session';
import { showError } from '../../utils/format';
const session = useSession();
onShow(() => session.boot().catch(showError));
const notices = computed(() => session.data.notices.filter((x) => x.status !== 'ARCHIVED'));
</script>
<template><view class="page"><PageHero eyebrow="PLEASE NOTICE" title="注意" subtitle="把医生叮嘱和需要小心的事，放在每天都看得见的位置。" />
  <view class="card"><view class="card-title"><text>生效中的提醒</text><text class="tag">{{ notices.length }} 条</text></view><view v-if="!notices.length" class="empty">目前没有注意事项。</view><view v-for="item in notices" :key="item.id" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ item.important ? '重要 · ' : '' }}{{ item.content }}</text><text class="row-meta">{{ item.detail || '没有补充说明' }}<template v-if="item.startsOn || item.endsOn"> · {{ item.startsOn || '现在' }} 至 {{ item.endsOn || '长期' }}</template></text></view></view></view>
  <view class="card boundary">注意事项只用于记录已有医嘱和生活提醒，不用于自动判断用药或治疗方案。</view><ComposeFab type="notice" /></view></template>
