<script setup lang="ts">
import { onLaunch } from '@dcloudio/uni-app';
import { checkForUpdates } from './utils/update';

onLaunch(() => checkForUpdates());
</script>

<style lang="scss">
@import './uni.scss';
</style>
