<script setup lang="ts">
import { ref, onMounted } from 'vue';
defineProps<{ eyebrow: string; title: string; subtitle: string; profile?: boolean }>();

// 顶部安全间距：把头部内容压到小程序胶囊下方，避免与右上角胶囊重叠。
const topPad = ref(54);
onMounted(() => {
  try {
    const sys = uni.getSystemInfoSync();
    let pad = (sys.statusBarHeight || 20) + 46; // 非小程序端兜底（状态栏 + 导航高度）
    const getRect = (uni as any).getMenuButtonBoundingClientRect;
    if (typeof getRect === 'function') {
      const rect = getRect();
      if (rect && rect.bottom) pad = rect.bottom + 8; // 胶囊底部 + 8px 间距
    }
    topPad.value = pad;
  } catch (e) { /* 保留兜底值 */ }
});

function openProfile() { uni.navigateTo({ url: '/pages/profile/index' }); }
</script>

<template>
  <view class="hero" :style="{ paddingTop: topPad + 'px' }">
    <view>
      <text class="eyebrow">{{ eyebrow }}</text>
      <text class="title">{{ title }}</text>
      <text class="subtitle">{{ subtitle }}</text>
    </view>
    <button v-if="profile !== false" class="avatar" @click="openProfile()">我</button>
  </view>
</template>
