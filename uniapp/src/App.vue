<script setup lang="ts">
import { onLaunch } from '@dcloudio/uni-app';
import { checkMiniProgramUpdate } from './utils/update';

onLaunch(() => checkMiniProgramUpdate());
</script>

<style lang="scss">
@import './uni.scss';
</style>
