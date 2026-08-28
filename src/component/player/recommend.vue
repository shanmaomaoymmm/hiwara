<script setup lang="ts">
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  getVideoRecommendByUser,
  getVideoRecommendByOther,
} from '../../core/api';
import cardButton from '../cardButton.vue';
import test1Img from '../../static/img/test1.jpg';

const emit = defineEmits<{
  (e: 'data-loaded'): void;
}>();

const { t } = useI18n();

interface ListItem {
  id: string;
  title: string;
  img: string;
  author: string;
  time: string;
  viewNum: number;
  likeNum: number;
  longNum: number;
  isR18: boolean;
}

const props = defineProps<{
  vid: string;
  uid: string;
  isAI: boolean;
}>();

const authorOtherVideoList = ref<ListItem[]>([]);
const recommendVideoList = ref<ListItem[]>([]);
const isLoadingAuthorVideos = ref(false);
const isLoadingRecommendVideos = ref(false);

// 加载作者其他视频
async function loadAuthorOtherVideos() {
  if (!props.vid || !props.uid) return;

  isLoadingAuthorVideos.value = true;
  try {
    const response = await getVideoRecommendByUser(props.vid, props.uid, props.isAI);
    if (response.ok && response.data.results) {
      authorOtherVideoList.value = await Promise.all(response.data.results.map(async (item: any) => ({
        id: item.id,
        title: item.title,
        img: item.file ? `https://i.iwara.tv/image/thumbnail/${item.file.id}/thumbnail-${String(item.thumbnail ?? 0).padStart(2, '0')}.jpg` : test1Img,
        author: item.user?.name || item.user?.username || '',
        time: item.createdAt,
        viewNum: item.numViews || 0,
        likeNum: item.numLikes || 0,
        longNum: item.file?.duration || 0,
        isR18: item.rating === 'ecchi' || item.rating === 'r18',
      })));
      console.log(`✅ 推荐: 作者其他视频加载完成, 共 ${authorOtherVideoList.value.length} 条`);
      emit('data-loaded');
    }
  } catch (error) {
    console.error('Failed to load author other videos:', error);
  } finally {
    isLoadingAuthorVideos.value = false;
  }
}

// 加载推荐视频
async function loadRecommendVideos() {
  if (!props.vid) return;

  isLoadingRecommendVideos.value = true;
  try {
    const response = await getVideoRecommendByOther(props.vid, props.isAI);
    if (response.ok && response.data.results) {
      recommendVideoList.value = await Promise.all(response.data.results.map(async (item: any) => ({
        id: item.id,
        title: item.title,
        img: item.file ? `https://i.iwara.tv/image/thumbnail/${item.file.id}/thumbnail-${String(item.thumbnail ?? 0).padStart(2, '0')}.jpg` : test1Img,
        author: item.user?.name || item.user?.username || '',
        time: item.createdAt,
        viewNum: item.numViews || 0,
        likeNum: item.numLikes || 0,
        longNum: item.file?.duration || 0,
        isR18: item.rating === 'ecchi' || item.rating === 'r18',
      })));
      console.log(`✅ 推荐: 推荐视频加载完成, 共 ${recommendVideoList.value.length} 条`);
      emit('data-loaded');
    }
  } catch (error) {
    console.error('Failed to load recommend videos:', error);
  } finally {
    isLoadingRecommendVideos.value = false;
  }
}

// 立即加载数据
loadAuthorOtherVideos();
loadRecommendVideos();

// 监听 uid 变化（异步获取后重新加载作者其他视频）
watch(() => props.uid, (newUid) => {
  if (newUid) {
    loadAuthorOtherVideos();
  }
});
</script>

<template>
  <div class="recommend">
    <div class="label" v-if="!isLoadingAuthorVideos && authorOtherVideoList.length > 0">
      {{ t('player.authorOtherVideos') }}
    </div>
    <div class="lists" v-if="!isLoadingAuthorVideos && authorOtherVideoList.length > 0">
      <cardButton v-for="(item, index) in authorOtherVideoList" :key="item.id" type="video" :isAI="props.isAI" :data="{
        id: item.id,
        title: item.title,
        img: item.img,
        author: item.author,
        time: item.time,
        viewNum: item.viewNum,
        likeNum: item.likeNum,
        longNum: item.longNum,
        isR18: item.isR18
      }" class="card-button" />
    </div>
    <div class="label" v-if="!isLoadingRecommendVideos && recommendVideoList.length > 0">
      {{ t('player.moreRecommend') }}
    </div>
    <div class="lists" v-if="!isLoadingRecommendVideos && recommendVideoList.length > 0">
      <cardButton v-for="(item, index) in recommendVideoList" :key="item.id" type="video" :isAI="props.isAI" :data="{
        id: item.id,
        title: item.title,
        img: item.img,
        author: item.author,
        time: item.time,
        viewNum: item.viewNum,
        likeNum: item.likeNum,
        longNum: item.longNum,
        isR18: item.isR18
      }" class="card-button" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.recommend {
  height: calc(100% - 10px);
  overflow-y: auto;
  padding-top: 10px;

  .label {
    font-size: 0.9rem;
    padding: 0 10px;
    color: var(--color-text-primary);
  }

  .lists {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
    padding: 10px;
  }
}
</style>
