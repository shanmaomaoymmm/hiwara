<script lang="ts" setup>
import topView from "./home/top.vue";
import bottomView from "./home/bottom.vue";
import subscribe from "./home/subscribe.vue";
import { ref } from "vue";
const tab = ref<
  'video' | 'image' | 'subscribe' | 'forum' | 'my'
>('subscribe');
</script>
<template>
  <div class="home">
    <topView class="top"></topView>
    <div class="main">
      <subscribe v-if="tab == 'subscribe'"></subscribe>
    </div>
    <bottomView @change-tab="tab = $event" class="bottom"></bottomView>
  </div>
</template>
<style lang="scss" scoped>
.home {
  // background-color: chartreuse;
  height: 100%;
  display: flex;
  flex-direction: column;

  .main {
    flex: 1;
    overflow: hidden;
  }
}
</style>