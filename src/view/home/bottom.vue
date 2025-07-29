<script lang="ts" setup>
</script>
<template>
  <div class="bottom">
    <v-app>
      <v-bottom-navigation :elevation="0" color="#00796B" grow>
        <v-btn value="video">
          <span>视频</span>
        </v-btn>
        <v-btn value="image">
          <span>图片</span>
        </v-btn>
        <v-btn value="subscribe">
          <span>订阅</span>
        </v-btn>
        <v-btn value="forum">
          <span>论坛</span>
        </v-btn>
        <v-btn value="my">
          <span>我的</span>
        </v-btn>
      </v-bottom-navigation>
    </v-app>
  </div>
</template>
<style lang="scss" scoped>
.bottom {
  background-color: aqua;
  height: 4rem;
}
</style>
