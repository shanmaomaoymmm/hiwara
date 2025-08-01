<script lang="ts" setup>
import gridList from './gridList.vue';
import { ref } from 'vue'
const tab = ref(0)
</script>
<template>
  <div class="container">
    <div>
      <v-layout>
        <v-tabs v-model="tab" align-tabs="center" color="#00796B" base-color="#616161" grow>
          <v-tab :value="0">视频</v-tab>
          <v-tab :value="1">图片</v-tab>
        </v-tabs>
      </v-layout>
    </div>
    <div class="content">
      <v-layout>
        <v-tabs-window v-model="tab">
          <v-tabs-window-item :value="0">
            <gridList type="video"></gridList>
          </v-tabs-window-item>
          <v-tabs-window-item :value="1">
            <gridList type="image"></gridList>
          </v-tabs-window-item>
        </v-tabs-window>
      </v-layout>
    </div>
  </div>
</template>
<style lang="scss" scoped>
.container {
  height: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;

  >:last-child {
    flex: 1;
    overflow: hidden;

    .v-layout,
    .v-window,
    .v-window__container,
    .v-window-item {
      height: 100%;
      width: 100%;
    }

    .v-window-item {
      overflow: auto;
    }
  }
}

.content {
  background-color: #fafafa;
}
</style>
