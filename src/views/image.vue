<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, onBeforeUnmount, onActivated } from 'vue';
import { useAutoStatusBar } from '../composables/useAutoStatusBar'
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import ImageInfo from '../component/image/info.vue';
import RecommendList from '../component/image/recommend.vue';
import imgPreview from '../component/image/preview.vue';
import previewLandscape from '../component/image/previewLandscape.vue';
import {
  getImageInfo as api_getImageInfo,
} from '../core/api';
import { showShortToast } from '../core/toast';
import { insertImageHistory } from '../core/database';
import loadingHuawu from '../component/loadingHuawu.vue';
import errorHuawu from '../component/errorHuawu.vue';
import fullScreen from '../component/image/fullScreen.vue';
import comment from '../component/image/comment.vue';

const { t } = useI18n();

defineOptions({
  name: 'Image'
})

const router = useRouter();
const route = useRoute();

// 从路由查询参数获取 isAI（由前一个页面传入），不存在时默认为 false
const isAI = ref(route.query.isAI === 'true');

// 插画图片数据
interface ImageFile {
  id: string;
  name: string;
  width: number;
  height: number;
}
const illustrationImages = ref<ImageFile[]>([]);

// 页面状态
const isState = ref<'failed' | 'loading' | 'success'>('loading');
const fullScreenVisible = ref(false);
const commentVisible = ref(false);

// 插画信息数据（全部独立变量）
const pid = ref<string>(route.params.id as string);  // 插画ID
const slug = ref<string>('');  // 插画slug
const title = ref<string>('');  // 插画标题
const viewCount = ref<number>(0); // 插画浏览数
const createdAt = ref<string>('');  // 插画创建时间
const resolution = ref<string>(''); // 插画分辨率
const synopsis = ref<string>(''); // 插画简介
const tags = ref<string[]>([]); // 插画标签数组

// 作者信息
const authorname = ref<string>(''); // 作者名称
const username = ref<string>(''); // 作者用户名
const uid = ref<string>(''); // 作者ID
const avatar = ref<string>(''); // 作者头像URL
const fansNum = ref<number>(0); // 粉丝数
const imageNum = ref<number>(0);  // 插画数量
const isFollow = ref<boolean>(false); // 是否已关注作者
const isMyFans = ref<boolean>(false); // 作者是否关注我（我是否是作者的粉丝，互粉状态）
const isLike = ref<boolean>(false); // 是否已点赞

// 顶部导航栏颜色状态
const isTopGreen = ref(false);
const viewMainRef = ref<HTMLElement | null>(null);
const viewSideRef = ref<HTMLElement | null>(null);
const viewMainOuterRef = ref<HTMLElement | null>(null); // .view-main（横屏时的滚动源）
const topRef = ref<HTMLElement | null>(null); // 顶部导航栏元素

// 自动状态栏文字颜色自适应
// 初始时顶部透明，透出页面背景色；滚动后 .top-green 启用 --color-primary-90
const statusBarBg = computed(() => {
  const varName = isTopGreen.value ? '--color-primary-90' : '--color-bg-page'
  return getComputedStyle(document.documentElement).getPropertyValue(varName).trim()
})
useAutoStatusBar({ color: statusBarBg })

const fullScreenRef = ref();

// 横屏大屏检测（用于 v-if 切换预览组件，避免重复加载图片）
const isLandscape = ref(false);
let landscapeMedia: MediaQueryList | null = null;
const updateLandscape = () => {
  isLandscape.value = landscapeMedia?.matches ?? false;
};
onMounted(() => {
  landscapeMedia = window.matchMedia('(min-width: 720px) and (orientation: landscape)');
  updateLandscape();
  landscapeMedia.addEventListener('change', updateLandscape);
});
onUnmounted(() => {
  landscapeMedia?.removeEventListener('change', updateLandscape);
});

// 返回顶部
function scrollToTop() {
  const container = isLandscape.value ? viewMainOuterRef.value : viewMainRef.value;
  if (container)
    container.scrollTo({ top: 0, behavior: 'smooth' });
}

// 处理安卓返回键事件（来自 App.vue）
const handleImageBackPressed = () => {
  // 1. 如果全屏打开 → 关闭全屏
  if (fullScreenVisible.value) {
    fullScreenVisible.value = false;
    return;
  }
  // 2. 如果评论打开 → 关闭评论
  if (commentVisible.value) {
    commentVisible.value = false;
    return;
  }
  // 3. 无抽屉打开 → 回退到上一页
  router.back();
};

// 返回
function goBack() {
  router.back();
}
// 回到主界面
function goHome() {
  router.replace('/');
}

// 当前滚动条位置（view-main 和 view-side 各自保存）
let viewMainScrollTop = 0;
let viewSideScrollTop = 0;

// 处理 view-main 滚动事件（竖屏滚动源：.image-container；横屏滚动源：.view-main）
function handleMainScroll(e: Event) {
  const target = e.target as HTMLElement;
  viewMainScrollTop = target.scrollTop;

  const container = viewMainRef.value;
  const topElement = topRef.value;
  if (!container || !topElement) return;

  // top 元素的高度（包括 padding 和 safe-area-inset）
  const topHeight = topElement.offsetHeight;

  // 横屏：主区域顶部为全高预览区，滚动超过顶栏高度即切换顶栏颜色
  if (isLandscape.value) {
    isTopGreen.value = target.scrollTop > topHeight;
    return;
  }

  // 竖屏：获取 imgPreview 的位置
  const imgPreview = container.querySelector('.imgPreview') as HTMLElement;
  if (imgPreview) {
    // 计算 imgPreview 底部相对于容器视口的位置
    const imgPreviewBottomInViewport = imgPreview.offsetTop + imgPreview.offsetHeight - target.scrollTop;
    // 当 imgPreview 的底部在视口中的位置 < top 元素的高度时
    isTopGreen.value = imgPreviewBottomInViewport < topHeight;
  }
}

// 处理 view-side 滚动事件
function handleSideScroll(e: Event) {
  viewSideScrollTop = (e.target as HTMLElement).scrollTop;
}

onActivated(() => {
  // 恢复 view-main 滚动条位置（横屏滚 .view-main，竖屏滚 .image-container）
  const mainContainer = isLandscape.value ? viewMainOuterRef.value : viewMainRef.value;
  if (mainContainer && typeof mainContainer.scrollTo === 'function')
    mainContainer.scrollTo({ top: viewMainScrollTop });
  // 恢复 view-side 滚动条位置
  const sideContainer = viewSideRef.value;
  if (sideContainer && typeof sideContainer.scrollTo === 'function')
    sideContainer.scrollTo({ top: viewSideScrollTop });
})

onMounted(() => {
  // 监听来自 App.vue 的安卓返回键事件
  window.addEventListener('image-back-pressed', handleImageBackPressed);
})

onBeforeUnmount(() => {
  // 移除返回键事件监听
  window.removeEventListener('image-back-pressed', handleImageBackPressed);
})

onUnmounted(() => {
  // 清理不再需要，滚动事件绑定在模板中处理
})
// 获取插画信息，若站点归属判定错误（API 返回 301 重定向）则自动切换站点重试一次
const fetchImageInfoWithRetry = async (): Promise<any> => {
  try {
    return await api_getImageInfo(pid.value as string, isAI.value);
  } catch (error: any) {
    // 以错误站点（Referer/X-Site）请求时，api.iwara.tv 会对归属他站的作品返回 301，
    // 切换站点（isAI）后重试即可正常获取
    if (error?.message && String(error.message).includes('301')) {
      isAI.value = !isAI.value;
      router.replace({ query: { ...route.query, isAI: isAI.value ? 'true' : 'false' } });
      return await api_getImageInfo(pid.value as string, isAI.value);
    }
    throw error;
  }
};

// 获取插画信息
getImageInfo();
async function getImageInfo(): Promise<void> {
  try {
    const res = await fetchImageInfoWithRetry();
    console.log(res);
    if (!res.ok)
      throw new Error(`状态码：${res.status}, 错误信息：${res.statusText}`);
    const imageInfo = res.data;
    // 插画信息
    title.value = imageInfo.title;
    slug.value = imageInfo.slug || '';
    viewCount.value = imageInfo.numViews || 0;
    createdAt.value = imageInfo.createdAt;
    synopsis.value = imageInfo.body ? imageInfo.body : '-';
    interface Tag {
      id: string;
      type: string;
      sensitive: boolean;
    }
    tags.value = Array.isArray(imageInfo.tags)
      ? imageInfo.tags.map((tag: Tag) => tag.id)
      : [];
    // 用户信息
    authorname.value = imageInfo.user.name;
    username.value = imageInfo.user.username;
    uid.value = imageInfo.user.id;
    avatar.value = imageInfo.user.avatar
      ? `https://i.iwara.tv/image/avatar/${imageInfo.user.avatar.id}/${imageInfo.user.avatar.name}`
      : ''; // 作者头像
    isFollow.value = imageInfo.user.following || false;
    isMyFans.value = imageInfo.user.followedBy || false;
    isLike.value = imageInfo.liked || false;
    // 插画文件数组
    illustrationImages.value = imageInfo.files.map((file: any) => {
      const id = file.id;
      const name = file.name;
      const width = file.width;
      const height = file.height;
      return { id, name, width, height };
    });
    // 更新页面状态
    isState.value = 'success';

    // 添加插画历史记录
    try {
      // 使用thumbnail作为封面(参照subscribe.vue的实现)
      const coverUrl = imageInfo.thumbnail
        ? `https://i.iwara.tv/image/thumbnail/${imageInfo.thumbnail.id}/${imageInfo.thumbnail.id}.jpg`
        : '';

      // 解析 createdAt 为时间戳
      const createTimeTimestamp = imageInfo.createdAt ? new Date(imageInfo.createdAt).getTime() : 0;

      await insertImageHistory(
        pid.value,
        imageInfo.title,
        imageInfo.user.name,
        coverUrl,
        illustrationImages.value.length, // 插画张数
        createTimeTimestamp, // 作品发布时间
        imageInfo.siteId === 'iwara_ai' // 是否为AI站（依据 API 返回的 siteId 判定）
      );
      console.log('插画历史记录已添加:', pid.value);
    } catch (error) {
      console.error('添加插画历史记录失败:', error);
    }
  } catch (error) {
    console.error(`获取插画信息失败：`, error);
    showShortToast(t('imageView.fetchInfoFailed'));
    isState.value = 'failed';
    throw error;
  }
}
// 监听图片分辨率事件
function handleResolution(res: { width: number; height: number }) {
  resolution.value = `${res.width}x${res.height}`;
}
// 全屏大图
const fullScreenTrigger = async (num: number) => {
  fullScreenVisible.value = true;
  // 等待下一帧确保组件已渲染
  await new Promise(resolve => requestAnimationFrame(resolve));
  fullScreenRef.value.changeSwiper(num);
  // 调用全屏组件的进入全屏方法
  if (fullScreenRef.value.enterFullscreen) {
    fullScreenRef.value.enterFullscreen();
  }
}
// 打开评论
const handleCommentTrigger = () => {
  console.log('打开评论');
  commentVisible.value = true;
}

// 处理点赞事件
const handleLike = (isLiked: boolean) => {
  isLike.value = isLiked;
}

// 处理关注事件
const handleFollow = (isFollowed: boolean) => {
  isFollow.value = isFollowed;
}
</script>
<template>
  <div id="imageView">
    <div class="view-main" ref="viewMainOuterRef" @scroll="handleMainScroll">
      <div class="top" ref="topRef" :class="{ 'top-green': isTopGreen }" @click="scrollToTop">
        <span class="btn" @click="goBack">
          <font-awesome-icon icon="fa-solid fa-angle-left" />
        </span>
        <span class="btn" @click="goHome">
          <font-awesome-icon icon="fa-regular fa-house" />
        </span>
      </div>
      <div v-if="isState === 'loading'" class="state-container">
        <loadingHuawu>{{ t('imageView.loading') }}</loadingHuawu>
      </div>
      <div v-else-if="isState === 'failed'" class="state-container">
        <errorHuawu>{{ t('imageView.failed') }}</errorHuawu>
      </div>
      <div v-else-if="isState === 'success'" class="image-container" ref="viewMainRef" @scroll="handleMainScroll">

        <!-- 横屏预览（大屏横屏时显示，替代普通 imgPreview；v-if 避免重复加载图片） -->
        <div v-show="isLandscape" class="preview-landscape-wrapper">
          <previewLandscape :pid="pid" :images="illustrationImages" @resolution="handleResolution"
            @fullScreen="fullScreenTrigger" />
        </div>

        <!-- 第一部分：图片区域（竖屏/小屏时显示） -->
        <div v-show="!isLandscape" class="preview-normal-wrapper">
          <imgPreview :pid="pid" :images="illustrationImages" @resolution="handleResolution"
            @fullScreen="fullScreenTrigger" />
        </div>

        <!-- 第二部分：插画信息区域（已拆分为子组件） -->
        <div class="view-main-side-content">
          <ImageInfo v-if="isState === 'success'" :title="title" :view-count="viewCount" :created-at="createdAt"
            :pid="pid" :slug="slug" :resolution="resolution" :synopsis="synopsis" :tags="tags" :authorname="authorname"
            :username="username" :uid="uid" :avatar="avatar" :fans-num="fansNum" :image-num="imageNum"
            :is-follow="isFollow" :is-my-fans="isMyFans" :is-like="isLike" :images="illustrationImages" :isAI="isAI"
            @commentTrigger="handleCommentTrigger" @like="handleLike" @follow="handleFollow" />
          <!-- 第三部分：推荐列表（已拆分为子组件） -->
          <RecommendList :pid="pid" :uid="uid" :isAI="isAI" />
        </div>
      </div>
    </div>
    <div class="view-side">
      <div class="image-container" ref="viewSideRef" @scroll="handleSideScroll">
        <!-- 第二部分：插画信息区域（已拆分为子组件） -->
        <ImageInfo v-if="isState === 'success'" :title="title" :view-count="viewCount" :created-at="createdAt"
          :pid="pid" :slug="slug" :resolution="resolution" :synopsis="synopsis" :tags="tags" :authorname="authorname"
          :username="username" :uid="uid" :avatar="avatar" :fans-num="fansNum" :image-num="imageNum"
          :is-follow="isFollow" :is-my-fans="isMyFans" :is-like="isLike" :images="illustrationImages" :isAI="isAI"
          @commentTrigger="handleCommentTrigger" @like="handleLike" @follow="handleFollow" />
        <!-- 第三部分：推荐列表（已拆分为子组件） -->
        <RecommendList :pid="pid" :uid="uid" :isAI="isAI" />
      </div>
    </div>
    <comment class="drawer" :pid="pid" :isAI="isAI"
      :style="{ transform: commentVisible ? 'translateX(0)' : 'translateX(100%)' }" @close="commentVisible = false" />
    <fullScreen class="drawer" :style="{ transform: fullScreenVisible ? 'translateX(0)' : 'translateX(100%)' }"
      ref="fullScreenRef" @close="fullScreenVisible = false" :images="illustrationImages" />
  </div>
</template>
<style lang="scss" scoped>
#imageView {
  background-color: var(--color-bg-page);
  display: flex;
  position: relative;
}

.view-main {
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  flex: 1;
  position: relative;

  >.image-container {
    @include up(md) {
      @media (orientation: landscape) {
        display: flex;
        flex-direction: column;
        overflow: hidden;
      }
    }
  }
}

.view-side {
  flex: 0 0 auto;
  width: clamp(380px, 25vw, 580px);
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow-y: auto;

  @include down(md) {
    display: none;
  }

  @media (orientation: portrait) {
    display: none;
  }
}

.top {
  position: absolute;
  top: 0;
  z-index: 400;
  height: calc(48px + env(safe-area-inset-top, 0));
  padding-top: env(safe-area-inset-top, 0);
  color: var(--color-text-on-image);
  filter: drop-shadow(1px 1px 1px rgba(0, 0, 0, 0.5));
  // background-color: #00796B;
  width: 100%;
  transition: background-color 0.3s ease-in-out;

  .btn {
    display: inline-flex;
    margin: 4px;
    width: 40px;
    height: 40px;
    justify-content: center;
    align-items: center;
    font-size: 1.2rem;
    cursor: pointer;
    user-select: none;
  }
}

.top-green {
  background-color: var(--color-primary-90);
  backdrop-filter: blur(10px);
}

.state-container {
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
}

.preview-normal-wrapper {
  /* v-if 控制渲染，无需额外样式 */
}

.preview-landscape-wrapper {
  height: 100%;
}

.view-main-side-content {
  overflow: hidden;

  @include up(md) {
    @media (orientation: landscape) {
      height: 0;
    }
  }
}

.image-container {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
  background-color: var(--color-bg-card);
  position: relative;
  padding-bottom: env(safe-area-inset-bottom, 0);
}

.drawer {
  position: absolute;
  top: 0;
  right: 0;
  z-index: 600;
  transform: translateX(100%);
  transition: transform 0.3s ease-in-out;
}
</style>
