<script setup lang="ts">
import { computed } from 'vue';
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { useSession } from '../../state/session';
import { formatDate, showError } from '../../utils/format';
const session = useSession();
onShow(() => session.boot().catch(showError));
function latest(field: string) { return session.data.body.find((x) => x[field] !== null && x[field] !== undefined)?.[field] ?? '—'; }
const recentSymptoms = computed(() => session.data.symptoms.slice(0, 10));
</script>
<template><view class="page"><PageHero eyebrow="BODY NOTES" title="身体" subtitle="只记录变化，不替你下结论。复诊时，把更清楚的信息交给医生。" />
  <view class="metric-grid" style="margin-bottom:24rpx"><view class="metric"><text class="label">最新体温</text><text class="metric-value">{{ latest('temperature') }}<text style="font-size:24rpx"> ℃</text></text></view><view class="metric"><text class="label">最新体重</text><text class="metric-value">{{ latest('weight') }}<text style="font-size:24rpx"> kg</text></text></view><view class="metric"><text class="label">最新疼痛</text><text class="metric-value">{{ latest('painScore') }}<text style="font-size:24rpx"> / 10</text></text></view><view class="metric"><text class="label">最新乏力</text><text class="metric-value">{{ latest('fatigueScore') }}<text style="font-size:24rpx"> / 10</text></text></view></view>
  <view class="card"><view class="card-title"><text>最近症状</text><text class="tag">{{ recentSymptoms.length }} 条</text></view><view v-if="!recentSymptoms.length" class="empty">还没有症状记录。</view><view v-for="item in recentSymptoms" :key="item.id" class="row"><view class="dot" /><view class="row-main"><text class="row-title">{{ item.tag }}</text><text class="row-meta">{{ formatDate(item.happenedAt) }} · {{ item.note || '没有补充说明' }}</text></view></view></view>
  <view class="card boundary">身体记录不能替代医生判断。如症状明显加重，请及时联系医生或医院。</view><ComposeFab type="body" /></view></template>
