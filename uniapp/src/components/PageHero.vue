<script setup lang="ts">
defineProps<{ eyebrow: string; title: string; subtitle: string; profile?: boolean }>();
function openProfile() { uni.navigateTo({ url: '/pages/profile/index' }); }
</script>

<template>
  <view class="hero">
    <view>
      <text class="eyebrow">{{ eyebrow }}</text>
      <text class="title">{{ title }}</text>
      <text class="subtitle">{{ subtitle }}</text>
    </view>
    <button v-if="profile !== false" class="avatar" @click="openProfile">我</button>
  </view>
</template>
