<script setup lang="ts">
import { onActivated, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import cardButton from '../cardButton.vue';
import { ai } from '../../core/store';
import { search } from '../../core/api/video';
import { searchImageByTag } from '../../core/api/image';
import loadingHuawu from '../loadingHuawu.vue';
import errorHuawu from '../errorHuawu.vue';
import { showShortToast } from '../../core/toast';
import type { VInfiniteScroll } from 'vuetify/components'

const aiStore = ai();
const { t } = useI18n();

const props = defineProps<{
  keyword: string;
  // 搜索方式：keyword = 关键词搜索（/search），tag = 标签搜索（/images?tags=）
  searchType?: 'keyword' | 'tag';
}>();

interface ImageItem {
  id: string;
  title: string;
  img: string;
  author: string;
  time: string;
  viewNum: number;
  likeNum: number;
  isR18: boolean;
}

const imageResult = ref<ImageItem[]>([]);
const imagePage = ref(0);
const imageLoadMoreFailed = ref(false);
const imageIsLoading = ref(false);
const imageHasFinished = ref(false);

type ListState = 'failed' | 'empty' | 'loading' | 'success';
const imageState = ref<ListState>('loading');

const listView = ref<InstanceType<typeof VInfiniteScroll>>();
let scrollTop = 0;

// 加载更多插画数据
const loadMoreImageData = async ({ done }: any = { done: () => { } }) => {
  if (imageIsLoading.value || imageHasFinished.value) return;
  imageIsLoading.value = true;

  try {
    // 根据搜索方式选择接口：标签搜索使用 /images?tags=，否则使用 /search
    const res = props.searchType === 'tag'
      ? await searchImageByTag(props.keyword, imagePage.value, aiStore.value)
      : await search(props.keyword, imagePage.value, 'images', aiStore.value);
    console.log('插画搜索 API 返回值:', res);
    if (!res.ok) throw new Error(`状态码：${res.status}, 错误信息：${res.statusText}`);

    if (res.data.results && res.data.results.length > 0) {
      if (imagePage.value === 0 && imageState.value === 'loading') imageState.value = 'success';

      const newImages = res.data.results.map((item: any) => ({
        id: item.id,
        title: item.title,
        img: item.thumbnail ? `https://i.iwara.tv/image/thumbnail/${item.thumbnail.id}/${item.thumbnail.id}.jpg` : 'file-loss',
        author: item.user?.name || item.user?.username || 'Unknown',
        time: item.createdAt,
        viewNum: item.numViews || 0,
        likeNum: item.numLikes || 0,
        isR18: item.rating === 'ecchi' || item.rating === 'r18'
      }));

      imageResult.value = [...imageResult.value, ...newImages];
      imagePage.value++;
      imageLoadMoreFailed.value = false;
      done('ok');
    } else {
      imageHasFinished.value = true;
      if (imagePage.value === 0 && imageState.value === 'loading') imageState.value = 'empty';
      done('empty');
    }
  } catch (error) {
    console.error('加载插画搜索结果失败:', error);
    showShortToast(t('search.loadingImageFailed'));
    if (imagePage.value === 0 && imageState.value === 'loading') {
      imageState.value = 'failed';
    } else {
      imageLoadMoreFailed.value = true;
    }
    done('error');
  } finally {
    imageIsLoading.value = false;
  }
};

// 执行搜索（当 keyword 变化时）
const startSearch = () => {
  if (props.keyword && imageState.value === 'loading') {
    console.log('插画组件开始搜索:', props.keyword);
    imageResult.value = [];
    imagePage.value = 0;
    imageHasFinished.value = false;
    imageLoadMoreFailed.value = false;
    loadMoreImageData();
  }
};

// 监听 keyword 变化，重新搜索
watch(() => props.keyword, (newKeyword) => {
  if (newKeyword && imageState.value !== 'loading') {
    console.log('插画组件关键词变化，重新搜索:', newKeyword);
    imageResult.value = [];
    imagePage.value = 0;
    imageHasFinished.value = false;
    imageLoadMoreFailed.value = false;
    imageState.value = 'loading';
    loadMoreImageData();
  }
});

// 监听搜索方式变化（关键词搜索 / 标签搜索），重新搜索
watch(() => props.searchType, () => {
  if (props.keyword && imageState.value !== 'loading') {
    console.log('插画组件搜索方式变化，重新搜索:', props.searchType, props.keyword);
    imageResult.value = [];
    imagePage.value = 0;
    imageHasFinished.value = false;
    imageLoadMoreFailed.value = false;
    imageState.value = 'loading';
    loadMoreImageData();
  }
});

defineExpose({
  startSearch
});

// 点击错误图片刷新数据
const handleErrorClick = () => {
  imageResult.value = [];
  imagePage.value = 0;
  imageHasFinished.value = false;
  imageLoadMoreFailed.value = false;
  imageState.value = 'loading';
  loadMoreImageData();
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
  <div v-if="imageState === 'loading'" class="loading">
    <loadingHuawu>数据加载中</loadingHuawu>
  </div>
  <div v-else-if="imageState === 'failed'" class="loading" @click="handleErrorClick">
    <errorHuawu>插画列表加载失败了喵~</errorHuawu>
  </div>
  <div v-else-if="imageState === 'empty'" class="loading" @click="handleErrorClick">
    <errorHuawu>暂无插画内容</errorHuawu>
  </div>
  <v-infinite-scroll v-else color="#00796B" @load="loadMoreImageData" :disabled="imageHasFinished" class="list-view"
    ref="listView" @scroll="handleScroll">
    <div class="grid">
      <template v-for="item in imageResult" :key="item.id">
        <cardButton type="image" :data="{
          id: item.id,
          title: item.title,
          img: item.img,
          author: item.author,
          time: item.time,
          viewNum: item.viewNum,
          likeNum: item.likeNum,
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
