<script setup lang="ts">
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import cardButton from '../cardButton.vue';
import {
  getImageRecommendByUser as api_getImageRecommendByUser,
  getImageRecommendByOther as api_getImageRecommendByOther
} from '../../core/api';
import { showShortToast } from '../../core/toast';

const { t } = useI18n();

const props = defineProps(['pid', 'uid', 'isAI']);

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
const authorOtherVideoList = ref<ListItem[]>([]);
const recommendVideoList = ref<ListItem[]>([]);

getImageRecommendByUser()
getImageRecommendByOther()
async function getImageRecommendByUser() {
  try {
    const res = await api_getImageRecommendByUser(props.pid, props.uid, props.isAI);
    console.log(res);
    if (!res.ok)
      throw new Error(`状态码：${res.status}, 错误信息：${res.statusText}`);
    if (res.data.results && res.data.results.length > 0) {
      const newImages = res.data.results.map((item: any) => {
        return {
          id: item.id,
          title: item.title,
          img: item.thumbnail ? `https://i.iwara.tv/image/thumbnail/${item.thumbnail.id}/${item.thumbnail.id}.jpg` : 'file-loss',
          author: item.user?.name || item.user?.username || 'Unknown',
          time: item.createdAt,
          viewNum: item.numViews || 0,
          likeNum: item.numLikes || 0,
          longNum: item.numImages || 0,
          isR18: item.rating === 'ecchi' || item.rating === 'r18'
        };
      });
      authorOtherVideoList.value = newImages;
    }
  } catch (error) {
    console.error('该用户其他插画推荐获取失败：', error);
    showShortToast(t('common.fetchRecommendFailed'));
    throw error;
  }
}
async function getImageRecommendByOther() {
  try {
    const res = await api_getImageRecommendByOther(props.pid, props.isAI);
    console.log(res);
    if (!res.ok)
      throw new Error(`状态码：${res.status}, 错误信息：${res.statusText}`);
    if (res.data.results && res.data.results.length > 0) {
      const newImages = res.data.results.map((item: any) => {
        return {
          id: item.id,
          title: item.title,
          img: item.thumbnail ? `https://i.iwara.tv/image/thumbnail/${item.thumbnail.id}/${item.thumbnail.id}.jpg` : 'file-loss',
          author: item.user?.name || item.user?.username || 'Unknown',
          time: item.createdAt,
          viewNum: item.numViews || 0,
          likeNum: item.numLikes || 0,
          longNum: item.numImages || 0,
          isR18: item.rating === 'ecchi' || item.rating === 'r18'
        };
      });
      recommendVideoList.value = newImages;
    }
  } catch (error) {
    console.error('更多插画推荐获取失败：', error);
    showShortToast(t('common.fetchRecommendFailed'));
    throw error;
  }
}
</script>

<template>
  <div class="recommend">
    <div v-if="authorOtherVideoList.length > 0">
      <div class="label">
        该作者其他插画
      </div>
      <div class="lists">
        <cardButton v-for="(item, index) in authorOtherVideoList" :key="item.id" type="image" :isAI="props.isAI" :data="{
          id: item.id,
          title: item.title,
          img: item.img,
          author: item.author,
          time: item.time,
          viewNum: item.viewNum,
          likeNum: item.likeNum,
          longNum: item.longNum,
          isR18: item.isR18
        }" />
      </div>
    </div>
    <div v-if="recommendVideoList.length > 0">
      <div class="label">
        更多推荐
      </div>
      <div class="lists">
        <cardButton v-for="(item, index) in recommendVideoList" :key="item.id" type="image" :isAI="props.isAI" :data="{
          id: item.id,
          title: item.title,
          img: item.img,
          author: item.author,
          time: item.time,
          viewNum: item.viewNum,
          likeNum: item.likeNum,
          longNum: item.longNum,
          isR18: item.isR18
        }" />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.recommend {
  padding: 0 10px 10px 10px;

  .label {
    font-size: 0.9rem;
    margin: 10px 0;
    color: var(--color-text-primary);
  }

  .lists {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
    // padding: 10px;
  }
}
</style>