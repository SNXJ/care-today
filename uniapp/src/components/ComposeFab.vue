<script setup lang="ts">
defineProps<{ type?: string }>();
function open(type?: string) { uni.navigateTo({ url: `/pages/compose/index${type ? `?type=${type}` : ''}` }); }
</script>
<template><button class="fab" @click="open(type)">＋</button></template>
