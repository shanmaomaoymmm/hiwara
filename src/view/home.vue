<script lang="ts" setup>
import topView from "./home/top.vue";
import bottomView from "./home/bottom.vue";
</script>
<template>
  <div class="home">
    <topView class="top"></topView>
    <div class="main"> </div>
    <bottomView class="bottom"></bottomView>
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
  }
}
</style>
