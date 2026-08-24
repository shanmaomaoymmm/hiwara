<script setup lang="ts">
import { ref, computed, onActivated, onDeactivated } from 'vue';
import { ai } from '../../core/store';
import { getFavoritesVideoList } from '../../core/api';
import { showShortToast } from '../../core/toast';
import MediaItem from '../MediaItem.vue';
import loadingHuawu from '../loadingHuawu.vue';
import errorHuawu from '../errorHuawu.vue';

const aiStore = ai();
// 定义列表项接口
interface ListItem {
  id: string;
  title: string;
  img: string;
  author: string;
  createTime: string;
  longNum: number;
  isR18: boolean;
  ai: boolean; // 是否为AI站（依据 API 返回的 siteId 判定）
  dateText: string;
  timestamp?: number;
}

const videoFavorites = ref<ListItem[]>([]);
const videoPage = ref(0);
const pageSize = 32;
const videoIsLoading = ref(false);
const videoHasFinished = ref(false);

// 加载更多失败标记
const videoLoadMoreFailed = ref(false);

// 聚合状态：'failed' | 'empty' | 'loading' | 'success'
type ListState = 'failed' | 'empty' | 'loading' | 'success';
const videoState = ref<ListState>('loading');

// 加载更多视频数据
const loadMoreVideoData = async ({ done }: any = { done: () => { } }) => {
  if (videoIsLoading.value || videoHasFinished.value) {
    return;
  }

  videoIsLoading.value = true;

  try {
    const res = await getFavoritesVideoList(videoPage.value, aiStore.value);

    if (!res.ok) {
      throw new Error(`状态码：${res.status}, 错误信息：${res.statusText}`);
    }

    if (res.data.results && res.data.results.length > 0) {
      // 如果是第一页且之前是 loading 状态，更新为 success
      if (videoPage.value === 0 && videoState.value === 'loading') {
        videoState.value = 'success';
      }

      const newItems = res.data.results.map((item: any) => {
        return {
          id: item.video.id,
          title: item.video.title,
          img: item.video.file ? `https://i.iwara.tv/image/thumbnail/${item.video.file.id}/thumbnail-${String(item.video.thumbnail).padStart(2, '0')}.jpg` : 'file-loss',
          author: item.video.user?.name || item.video.user?.username || 'Unknown',
          time: item.video.createdAt,
          viewNum: item.video.numViews || 0,
          likeNum: item.video.numLikes || 0,
          longNum: item.video.file?.duration ?? 0,
          isR18: item.video.rating === 'ecchi' || item.video.rating === 'r18',
          ai: item.video.siteId === 'iwara_ai', // 是否为AI站（依据 API 返回的 siteId 判定）
          dateText: item.createdAt.split('T')[0], // 使用 createdAt 作为收藏日期
          timestamp: new Date(item.createdAt).getTime() // 保留完整时间戳用于显示时间
        };
      });

      // 追加数据
      videoFavorites.value = [...videoFavorites.value, ...newItems];
      videoPage.value++;

      done('ok');
    } else {
      videoHasFinished.value = true;

      // 如果还没开始加载（第一页）且没有数据，更新为 empty
      if (videoPage.value === 0 && videoState.value === 'loading') {
        videoState.value = 'empty';
      }

      done('empty');
    }
  } catch (error) {
    console.error('加载视频收藏失败:', error);
    showShortToast('加载视频收藏失败');

    // 如果是第一页加载失败，更新为 failed
    if (videoPage.value === 0 && videoState.value === 'loading') {
      videoState.value = 'failed';
    } else {
      // 翻页加载失败，设置失败标记
      videoLoadMoreFailed.value = true;
    }
    done('error');
  } finally {
    videoIsLoading.value = false;
  }
};

// 内部加载函数（用于初始化和刷新，不需要 done 回调）
const loadVideoDataInternal = async () => {
  await loadMoreVideoData();
};

// 刷新数据
const refreshData = () => {
  // 清空视频列表数据
  videoFavorites.value = [];
  videoPage.value = 0;
  videoHasFinished.value = false;
  videoLoadMoreFailed.value = false;
  videoState.value = 'loading';

  // 重新加载第一页
  loadVideoDataInternal();
};

// 点击错误图片刷新数据
const handleErrorClick = () => {
  refreshData();
};

// 按日期分组数据（使用 computed 缓存结果，避免每次渲染都重新计算）
const groupedVideoFavorites = computed(() => {
  const grouped: Record<string, ListItem[]> = {};

  // 创建副本进行排序，避免修改原数组
  const sortedItems = [...videoFavorites.value].sort((a, b) =>
    new Date(b.dateText).getTime() - new Date(a.dateText).getTime()
  );

  // 按日期分组
  sortedItems.forEach(item => {
    if (!grouped[item.dateText]) {
      grouped[item.dateText] = [];
    }
    grouped[item.dateText].push(item);
  });

  return grouped;
});

// 初始加载第一页数据
loadMoreVideoData();

const videoListView = ref();
let videoScrollTop = 0;

// 处理滚动事件
function handleVideoScroll(event: Event): void {
  const target = event.target as HTMLElement;
  if (target) {
    videoScrollTop = target.scrollTop;
  }
}

// 页面激活时恢复滚动位置
onActivated(() => {
  if (videoListView.value && videoListView.value.$el) {
    videoListView.value.$el.scrollTop = videoScrollTop;
  }
});

// 页面停用时保存滚动位置（已在handleVideoScroll中实时保存）
onDeactivated(() => {
  // 滚动位置已在滚动事件中实时保存，这里可以执行其他清理操作
});

// 暴露刷新方法供父组件调用
defineExpose({
  refreshData
});
</script>

<template>
  <!-- 加载状态 -->
  <div v-if="videoState === 'loading'" class="loading">
    <loadingHuawu>数据加载中</loadingHuawu>
  </div>

  <!-- 加载失败状态 -->
  <div v-else-if="videoState === 'failed'" class="loading" @click="handleErrorClick">
    <errorHuawu>视频收藏加载失败了喵~</errorHuawu>
  </div>

  <!-- 空数据状态 -->
  <div v-else-if="videoState === 'empty'" class="loading" @click="handleErrorClick">
    <errorHuawu>暂无视频收藏</errorHuawu>
  </div>

  <!-- 成功加载状态 -->
  <v-infinite-scroll v-else ref="videoListView" color="#00796B" @load="loadMoreVideoData" :disabled="videoHasFinished"
    @scroll="handleVideoScroll" class="list-view">
    <div v-for="(groupItems, date) in groupedVideoFavorites" :key="date" class="date-group">
      <div class="date-header">{{ date === new Date().toISOString().split('T')[0] ? '今天' : date }}</div>
      <v-list lines="two" class="pa-0">
        <MediaItem v-for="(item, index) in groupItems" :key="index" :item="item" type="video" />
      </v-list>
    </div>
    <!-- 加载失败提示 -->
    <template v-slot:error="{ props }">
      <div class="load-more-failed">
        <span>加载失败，</span>
        <span class="retry-btn" v-bind="props">点击重试</span>
      </div>
    </template>
    <!-- 已到底部提示 -->
    <template v-slot:empty>
      <div class="listEnd">
        已经到底了喵~
      </div>
    </template>
  </v-infinite-scroll>
</template>

<style lang="scss" scoped>
.list-view {
  $top: calc(env(safe-area-inset-top, 0) + 60px + 40px);
  $bottom: calc(env(safe-area-inset-bottom, 0));
  height: 100vh;
  padding-top: $top;
  padding-bottom: $bottom;
  overflow: auto;

  &::-webkit-scrollbar-track {
    margin: calc($top + 4px) 0 calc($bottom + 4px) 0;
  }

  .date-group {
    .date-header {
      padding: 12px 16px 8px;
      background-color: var(--color-bg-section-alt);
      font-size: 0.8rem;
      color: var(--color-text-placeholder);
      font-weight: 500;
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
  color: var(--color-text-muted-light);
  padding: 4px 0;
}

.load-more-failed {
  text-align: center;
  padding: 10px 0;
  color: var(--color-text-muted-light);
  font-size: 0.9rem;

  .retry-btn {
    color: var(--color-retry-btn);
    cursor: pointer;

    &:hover {
      opacity: 0.8;
      text-decoration: underline;
    }
  }
}
</style>