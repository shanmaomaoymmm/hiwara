<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import topBarView from '../component/search/topBar.vue';
import emptyView from '../component/search/empty.vue';
import resultView from '../component/search/result.vue';
import { useAutoStatusBar } from '../composables/useAutoStatusBar'
import { setupStore } from '../core/store'

defineOptions({
  name: 'Search'
})

const route = useRoute();
const router = useRouter();
const setup = setupStore();
const searching = ref<'empty' | 'result'>('empty');
const searchKeyword = ref('');
// 搜索方式：keyword = 关键词搜索（/search），tag = 标签搜索（/videos?tags=、/images?tags=）
const searchType = ref<'keyword' | 'tag'>('keyword');

// 自动状态栏文字颜色自适应（根据 --color-primary-90 亮度判断）
useAutoStatusBar({ cssVar: '--color-primary-90' })

// 从路由 query 初始化（播放页/插画页点击标签跳转时会带上 type=tag&keyword=xxx）
function initFromQuery() {
  const keyword = typeof route.query.keyword === 'string' ? route.query.keyword : '';
  const type = route.query.type === 'tag' ? 'tag' : 'keyword';
  if (keyword) {
    searchKeyword.value = keyword;
    searchType.value = type;
    searching.value = 'result';
  }
}

// 路由 query 变化时同步状态（例如从播放页/插画页点击标签跳转过来）
watch(() => route.query, () => {
  initFromQuery();
});

// 处理返回操作（左上角按钮）
function handleBack() {
  console.log('handleBack 被调用，当前状态:', searching.value);
  
  if (searching.value === 'result') {
    // 在 result 状态时，回到 empty 状态
    console.log('从 result 切换回 empty');
    searching.value = 'empty';
    searchKeyword.value = '';
  } else {
    // 在 empty 状态时，真正返回上一页
    console.log('执行 router.back()');
    router.back();
  }
}

// 处理搜索事件
function handleSearch(keyword: string) {
  console.log('接收到搜索关键词:', keyword);
  searchKeyword.value = keyword;
  // 在搜索页面手动搜索时，根据设置决定搜索方式（0 = 关键词搜索，1 = 标签搜索）
  searchType.value = setup.searchMode === 1 ? 'tag' : 'keyword';
  searching.value = 'result';
}

// 处理来自 App.vue 的安卓返回键事件
const handleSearchBackPressed = () => {
  console.log('搜索页面收到 search-back-pressed 事件，当前状态:', searching.value);
  
  if (searching.value === 'result') {
    // 在 result 状态时，回到 empty 状态
    console.log('从 result 切换回 empty');
    searching.value = 'empty';
    searchKeyword.value = '';
  } else {
    // 在 empty 状态时，真正返回上一页
    console.log('执行 router.back()');
    router.back();
  }
};


onMounted(() => {
  // 首次进入时根据路由 query 初始化（如从标签点击跳转过来）
  initFromQuery();
  // 监听来自 App.vue 的返回键事件
  window.addEventListener('search-back-pressed', handleSearchBackPressed);
  console.log('已注册 search-back-pressed 事件监听');
})

onBeforeUnmount(() => {
  // 移除事件监听器
  window.removeEventListener('search-back-pressed', handleSearchBackPressed);
  console.log('已移除 search-back-pressed 事件监听');
})
</script>
<template>
  <div id="searchView">
    <topBarView class="topBar" :keyword="searchKeyword" @back="handleBack" @search="handleSearch" />
    <emptyView v-if="searching === 'empty'" @search="handleSearch" />
    <resultView v-else :keyword="searchKeyword" :searchType="searchType" />
  </div>
</template>
<style lang="scss" scoped>
#searchView {
  display: flex;
  flex-direction: column;
  background-color: var(--color-bg-card);
  height: 100vh;
}

.topBar {
  position: fixed;
  top: 0;
  z-index: 500;
}
</style>