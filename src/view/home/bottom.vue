<script lang="ts" setup>
import {
  Video as iconVideo,
  Pic as iconPic,
  Rss as iconRss,
  Comments as iconComments,
  User as iconUser
} from '@icon-park/vue-next';
import { ref, watch } from 'vue';
const tab = ref<
  'video' | 'image' | 'subscribe' | 'forum' | 'my'
>('subscribe');
const emit = defineEmits(['changeTab'])
watch(tab, (val) => {
  console.log(val);
  emit('changeTab', val)
})
</script>
<template>
  <div class="bottom">
    <v-layout>
      <v-bottom-navigation v-model="tab" color="#00796B" mode="shift" :mandatory="true" grow>
        <v-btn value="video">
          <v-icon class="btn-icon">
            <iconVideo theme="outline" size="24" :fill="tab == 'video' ? '#00796B' : '#424242'" />
          </v-icon>
          <span>视频</span>
        </v-btn>
        <v-btn value="image">
          <v-icon class="btn-icon">
            <iconPic theme="outline" size="24" :fill="tab == 'image' ? '#00796B' : '#424242'" />
          </v-icon>
          <span>图片</span>
        </v-btn>
        <v-btn value="subscribe">
          <v-icon class="btn-icon">
            <iconRss theme="outline" size="24" :fill="tab == 'subscribe' ? '#00796B' : '#424242'" />
          </v-icon>
          <span>订阅</span>
        </v-btn>
        <v-btn value="forum">
          <v-icon class="btn-icon">
            <iconComments theme="outline" size="24" :fill="tab == 'forum' ? '#00796B' : '#424242'" />
          </v-icon>
          <span>论坛</span>
        </v-btn>
        <v-btn value="my">
          <v-icon class="btn-icon">
            <iconUser theme="outline" size="24" :fill="tab == 'my' ? '#00796B' : '#424242'" />
          </v-icon>
          <span>我的</span>
        </v-btn>
      </v-bottom-navigation>
    </v-layout>
  </div>
</template>
<style lang="scss" scoped>
.bottom {
  height: 4rem;

  .v-layout,
  .v-bottom-navigation {
    height: inherit !important;
  }
}

.btn-icon {
  padding: 0.8rem 0;
}
</style>
