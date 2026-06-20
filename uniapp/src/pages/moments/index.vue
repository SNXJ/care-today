<script setup lang="ts">
import { onShow } from '@dcloudio/uni-app';
import PageHero from '../../components/PageHero.vue';
import ComposeFab from '../../components/ComposeFab.vue';
import { useSession } from '../../state/session';
import { formatDate, showError } from '../../utils/format';
const session = useSession();
onShow(() => session.boot().catch(showError));
</script>
<template><view class="page"><PageHero eyebrow="SHARING" title="分享" subtitle="不是汇报病情，只是让关心你的人知道：此刻的你，在想什么。" />
  <view v-if="!session.data.messages.length" class="card empty">这里还很安静。患者本人可以分享第一条近况。</view>
  <view v-for="message in session.data.messages" :key="message.id" class="card"><view class="card-title"><text>{{ message.author }}</text><text class="tag">{{ formatDate(message.createdAt) }}</text></view><text class="row-meta" style="color:#312b27;font-size:29rpx">{{ message.text }}</text></view>
  <ComposeFab v-if="session.isPatient.value" type="message" /></view></template>
