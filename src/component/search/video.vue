<script setup lang="ts">
import { onActivated, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import cardButton from '../cardButton.vue';
import { ai } from '../../core/store';
import { search, searchVideoByTag } from '../../core/api/video';
import loadingHuawu from '../loadingHuawu.vue';
import errorHuawu from '../errorHuawu.vue';
import { showShortToast } from '../../core/toast';
import type { VInfiniteScroll } from 'vuetify/components'

const aiStore = ai();
const { t } = useI18n();

const props = defineProps<{
  keyword: string;
  // 搜索方式：keyword = 关键词搜索（/search），tag = 标签搜索（/videos?tags=）
  searchType?: 'keyword' | 'tag';
}>();

interface VideoItem {
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

const videoResult = ref<VideoItem[]>([]);
const videoPage = ref(0);
const videoLoadMoreFailed = ref(false);
const videoIsLoading = ref(false);
const videoHasFinished = ref(false);

type ListState = 'failed' | 'empty' | 'loading' | 'success';
const videoState = ref<ListState>('loading');

const listView = ref<InstanceType<typeof VInfiniteScroll>>();
let scrollTop = 0;

// 加载更多视频数据
const loadMoreVideoData = async ({ done }: any = { done: () => { } }) => {
  if (videoIsLoading.value || videoHasFinished.value) return;
  videoIsLoading.value = true;

  try {
    // 根据搜索方式选择接口：标签搜索使用 /videos?tags=，否则使用 /search
    const res = props.searchType === 'tag'
      ? await searchVideoByTag(props.keyword, videoPage.value, aiStore.value)
      : await search(props.keyword, videoPage.value, 'videos', aiStore.value);
    console.log('视频搜索 API 返回值:', res);
    if (!res.ok) throw new Error(`状态码：${res.status}, 错误信息：${res.statusText}`);

    if (res.data.results && res.data.results.length > 0) {
      if (videoPage.value === 0 && videoState.value === 'loading') videoState.value = 'success';

      const newVideos = res.data.results.map((item: any) => ({
        id: item.id,
        title: item.title,
        img: item.file ? `https://i.iwara.tv/image/thumbnail/${item.file.id}/thumbnail-${String(item.thumbnail).padStart(2, '0')}.jpg` : 'file-loss',
        author: item.user?.name || item.user?.username || 'Unknown',
        time: item.createdAt,
        viewNum: item.numViews || 0,
        likeNum: item.numLikes || 0,
        longNum: item.file?.duration ?? 0,
        isR18: item.rating === 'ecchi' || item.rating === 'r18'
      }));

      videoResult.value = [...videoResult.value, ...newVideos];
      videoPage.value++;
      videoLoadMoreFailed.value = false;
      done('ok');
    } else {
      videoHasFinished.value = true;
      if (videoPage.value === 0 && videoState.value === 'loading') videoState.value = 'empty';
      done('empty');
    }
  } catch (error) {
    console.error('加载视频搜索结果失败:', error);
    showShortToast(t('search.loadingVideoFailed'));
    if (videoPage.value === 0 && videoState.value === 'loading') {
      videoState.value = 'failed';
    } else {
      videoLoadMoreFailed.value = true;
    }
    done('error');
  } finally {
    videoIsLoading.value = false;
  }
};

// 执行搜索（当 keyword 变化时）
const startSearch = () => {
  if (props.keyword && videoState.value === 'loading') {
    console.log('视频组件开始搜索:', props.keyword);
    videoResult.value = [];
    videoPage.value = 0;
    videoHasFinished.value = false;
    videoLoadMoreFailed.value = false;
    loadMoreVideoData();
  }
};

// 监听 keyword 变化，重新搜索
watch(() => props.keyword, (newKeyword) => {
  if (newKeyword && videoState.value !== 'loading') {
    console.log('视频组件关键词变化，重新搜索:', newKeyword);
    videoResult.value = [];
    videoPage.value = 1;
    videoHasFinished.value = false;
    videoLoadMoreFailed.value = false;
    videoState.value = 'loading';
    loadMoreVideoData();
  }
});

// 监听搜索方式变化（关键词搜索 / 标签搜索），重新搜索
watch(() => props.searchType, () => {
  if (props.keyword && videoState.value !== 'loading') {
    console.log('视频组件搜索方式变化，重新搜索:', props.searchType, props.keyword);
    videoResult.value = [];
    videoPage.value = 0;
    videoHasFinished.value = false;
    videoLoadMoreFailed.value = false;
    videoState.value = 'loading';
    loadMoreVideoData();
  }
});

defineExpose({
  startSearch
});

// 点击错误图片刷新数据
const handleErrorClick = () => {
  videoResult.value = [];
  videoPage.value = 1;
  videoHasFinished.value = false;
  videoLoadMoreFailed.value = false;
  videoState.value = 'loading';
  loadMoreVideoData();
};

// 滚动监听
function handleScroll(e: Event): void {
  scrollTop = (e.target as HTMLElement).scrollTop;
}
// 回到此页面时恢复滚动位置
onActivated(() => {
  if (listView.value)
    listView.value.$el.scrollTop = scrollTop;
});
</script>

<template>
  <div v-if="videoState === 'loading'" class="loading">
    <loadingHuawu>数据加载中</loadingHuawu>
  </div>
  <div v-else-if="videoState === 'failed'" class="loading" @click="handleErrorClick">
    <errorHuawu>视频列表加载失败了喵~</errorHuawu>
  </div>
  <div v-else-if="videoState === 'empty'" class="loading" @click="handleErrorClick">
    <errorHuawu>暂无视频内容</errorHuawu>
  </div>
  <v-infinite-scroll v-else color="#00796B" @load="loadMoreVideoData" :disabled="videoHasFinished" class="list-view"
    ref="listView" @scroll="handleScroll">
    <div class="grid">
      <template v-for="item in videoResult" :key="item.id">
        <cardButton type="video" :data="{
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
      </template>
    </div>
    <template v-slot:error="{ props }">
      <div class="load-more-failed">
        <span>加载失败，</span>
        <span class="retry-btn" v-bind=props>点击重试</span>
      </div>
    </template>
    <template v-slot:empty>
      <div class="listEnd">已经到底了喵~</div>
    </template>
  </v-infinite-scroll>
</template>

<style lang="scss" scoped>
.list-view {
  $top: calc(env(safe-area-inset-top, 0) + 60px + 36px);
  $bottom: calc(env(safe-area-inset-bottom, 0));
  height: calc(100vh - $top - 10px - $bottom);
  padding-top: calc($top + 10px);
  padding-bottom: $bottom;
  overflow: auto;

  &::-webkit-scrollbar-track {
    margin: calc($top + 4px) 0 calc($bottom + 4px) 0;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 10px;
    padding: 0 10px 0 10px;

    >* {
      content-visibility: auto;
      contain-intrinsic-size: 0 180px;
    }
  }
}

.loading {
  height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.listEnd {
  color: #757575;
  padding: 4px 0;
}

.load-more-failed {
  text-align: center;
  padding: 10px 0;
  color: #757575;
  font-size: 0.9rem;

  .retry-btn {
    color: #00796B;
    cursor: pointer;

    &:hover {
      opacity: 0.8;
      text-decoration: underline;
    }
  }
}
</style>
