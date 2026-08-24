<script setup lang="ts">
import { ref, onMounted, nextTick, watch, onUnmounted, onActivated, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import {
  Like as iconLike,
  ShareOne as iconShareOne,
  DownloadFour as iconDownloadFour,
  CopyLink as iconCopyLink,
} from '@icon-park/vue-next';
import defaultAvatarImg from '../../static/img/avatar-default.jpg';
import avatarPlaceholderImg from '../../static/img/avatar-placeholder.png';
import avatarErrorImg from '../../static/img/avatar-error.png';
import { ai } from '../../core/store';
import {
  getImageIwara,
  likeVideo,
  unlikeVideo,
  followUser,
  unfollowUser,
} from '../../core/api';
import recommend from './recommend.vue';
import { showShortToast } from '../../core/toast';
import { upsertDownloadCache, updateDownloadProgress } from '../../core/database'
import { buildAria2Filename, getVideoFileSQ } from '../../core/api'
import { listen } from '@tauri-apps/api/event'
import { invoke } from '@tauri-apps/api/core'
import { setupStore } from '../../core/store'
import { useRouter } from 'vue-router';

const aiStore = ai();
const { t } = useI18n();

const router = useRouter();

// 格式化时间（支持多语言）
const formatDate = (dateString: string) => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  return `${year}/${month}/${day} ${hours}:${minutes}`;
};

interface Props {
  title: string, // 标题
  synopsis: string, // 描述
  playNum: number, // 播放数
  likeNum: number, // 点赞数
  createdAt: string,  // 创建时间 (原始字符串)
  isLike: boolean,  // 是否已点赞
  tags: string[], // 标签
  authorname: string, // 作者昵称
  username: string, // 用户名
  avatar: string, // 作者头像
  fansNum: number, // 粉丝数
  videoNum: number, // 视频数
  isFollow: boolean,  // 是否已关注
  isMyFans?: boolean,  // 是否是粉丝（互粉状态）
  vid: string, // 视频ID
  uid: string, // 用户ID
  download: string, // 下载链接
  slug: string, // 视频slug
  poster?: string, // 视频封面URL
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'like', isLiked: boolean): void;
  (e: 'follow', isFollowed: boolean): void;
}>();

// 复制下载链接到剪贴板
async function copyDownloadLink() {
  if (!props.download) {
    showShortToast(t('common.fetchDownloadFailed'));
    return;
  }
  try {
    await navigator.clipboard.writeText(props.download);
    showShortToast(t('common.downloadLinkCopied'));
  } catch (err) {
    console.error('复制失败:', err);
    showShortToast(t('common.fetchDownloadFailed'));
  }
}

// 使用系统原生分享（Android）或 Web Share API 分享下载链接
async function shareDownloadLink() {
  if (!props.download) {
    showShortToast(t('common.fetchDownloadFailed'));
    return;
  }

  let shareUrl: string;
  if (props.slug === '')
    shareUrl = `https://iwara.tv/video/${props.vid}`;
  else
    shareUrl = `https://iwara.tv/video/${props.vid}/${props.slug}`;

  const shareText = `${props.title} - ${props.authorname} - ${shareUrl}`;

  // 1. Android: 尝试使用 Tauri 原生分享（Intent.ACTION_SEND）
  try {
    const { invoke } = await import('@tauri-apps/api/core');
    const result = await invoke('plugin:device|share', {
      payload: {
        title: props.title || '',
        text: shareText,
        url: shareUrl,
      }
    }) as { success: boolean };
    if (result.success) {
      // 原生分享成功，系统已提供分享面板反馈，无需额外 toast
      return;
    }
  } catch {
    // 原生分享不可用（桌面端或非 Tauri 环境），静默回退
  }

  // 2. 回退: 使用 Web Share API
  if (!navigator.share) {
    showShortToast(t('common.shareNotSupported'));
    return;
  }
  try {
    await navigator.share({
      title: props.title || t('player.shareTitle'),
      text: shareText,
    });
    // Web Share API 分享成功，系统已提供分享面板反馈，无需额外 toast
  } catch (err) {
    // 用户取消分享不显示错误提示
    if ((err as Error).name !== 'AbortError') {
      console.error('分享失败:', err);
      showShortToast(t('common.shareFailed'));
    }
  }
}

const expand = ref(false);  // 是否展开
const titleRef = ref<HTMLElement | null>(null); // 标题元素
const titleCollapseHeightRef = ref<HTMLElement | null>(null); // 标题折叠高度元素
const titleExpandHeightRef = ref<HTMLElement | null>(null); // 标题展开高度元素
const synopsisHeightRef = ref<HTMLElement | null>(null); // 描述高度元素

// 高度缓存对象
const heights = ref({
  titleCollapse: 0,
  titleExpand: 0,
  synopsis: 0
});

// 当前滚动条位置
let scrollTop = 0;
const infoViewRef = ref<HTMLElement>();
const infoViewContentRef = ref<HTMLElement>(); // 内层内容容器
let contentResizeObserver: ResizeObserver | null = null; // ResizeObserver 实例
const isFollowing = ref(false); // 关注操作进行中状态
const isLiking = ref(false); // 点赞操作进行中状态

// 关注按钮状态合并计算
const followBtn = computed(() => {
  if (props.isFollow && props.isMyFans) return { text: t('player.followMutual'), variant: 'outlined' as const, icon: 'fa-solid fa-bars' };
  if (props.isFollow) return { text: t('player.followed'), variant: 'outlined' as const, icon: 'fa-solid fa-bars' };
  if (props.isMyFans) return { text: t('player.followBack'), variant: 'flat' as const, icon: 'fa-solid fa-plus' };
  return { text: t('player.follow'), variant: 'flat' as const, icon: 'fa-solid fa-plus' };
});

// 处理窗口大小改变
function handleResize() {
  calculateHeights();
}

function calculateHeights() {
  heights.value.titleCollapse = titleCollapseHeightRef.value?.offsetHeight || 0;
  heights.value.titleExpand = titleExpandHeightRef.value?.offsetHeight || 0;
  heights.value.synopsis = synopsisHeightRef.value?.offsetHeight || 0;
}
// 保存滚动条位置
function handleSroll(e: Event): void {
  scrollTop = (e.target as HTMLElement).scrollTop;
}
onActivated(() => {
  // 恢复滚动条位置
  if (infoViewRef.value && typeof infoViewRef.value.scrollTo === 'function')
    infoViewRef.value.scrollTo({ top: scrollTop });
})

onMounted(() => {
  calculateHeights();
  if (titleRef.value) {
    titleRef.value.style.height = heights.value.titleCollapse + 'px';
    titleRef.value.style.whiteSpace = 'nowrap';
  }

  // 监听窗口大小改变事件
  window.addEventListener('resize', handleResize);

  // 监听内层内容容器高度变化（推荐视频等异步加载导致），重新计算
  if (infoViewContentRef.value) {
    contentResizeObserver = new ResizeObserver(() => {
      calculateHeights();
    });
    contentResizeObserver.observe(infoViewContentRef.value);
  }
})
onUnmounted(() => {
  // 移除窗口大小改变监听器
  window.removeEventListener('resize', handleResize);
  // 断开 ResizeObserver
  if (contentResizeObserver) {
    contentResizeObserver.disconnect();
    contentResizeObserver = null;
  }
})
// 简化 watch 逻辑，使用 nextTick 确保 DOM 更新后设置样式
watch(expand, async (val) => {
  if (!titleRef.value) return;

  if (val) {
    // === 展开逻辑 ===
    titleRef.value.style.whiteSpace = 'normal';
    titleRef.value.style.height = heights.value.titleExpand + 'px';
  } else {
    // === 折叠逻辑 ===
    const el = titleRef.value;
    el.style.height = heights.value.titleCollapse + 'px';

    // 等待一帧让浏览器应用 height 变化，然后设置 whiteSpace
    await nextTick();
    setTimeout(() => {
      if (!expand.value) {
        el.style.whiteSpace = 'nowrap';
      }
    }, 300); // 与 transition 时间匹配
  }
}, { immediate: true });

// 头像 URL（响应式）
const avatarUrl = ref<string>('');

// 加载头像
async function loadAvatar() {
  if (!props.avatar || props.avatar.trim() === '') {
    // avatar 为空，使用默认头像
    avatarUrl.value = defaultAvatarImg;
  } else {
    try {
      // avatar 不为空，通过 API 获取
      avatarUrl.value = await getImageIwara(props.avatar, aiStore.value);
    } catch (error) {
      console.error('Failed to load avatar:', error);
      // 加载失败时使用默认头像
      avatarUrl.value = avatarErrorImg;
    }
  }
}

// 监听 avatar prop 变化，立即执行
watch(() => props.avatar, () => {
  loadAvatar();
}, { immediate: true });

// 关注
function clickFollow() {
  // 如果正在执行关注操作，直接返回
  if (isFollowing.value) return;
  console.log(props.uid);
  isFollowing.value = true;
  if (props.isFollow) {
    emit('follow', false);
    unfollowUser(props.uid).then((res) => {
      if (res.ok && res.status === 204) {
        console.log('取消关注成功');
        showShortToast(t('common.unfollowed'));
      } else {
        console.log('取消关注失败');
        showShortToast(t('common.unfollowFailed'));
        emit('follow', true);
      }
    }).catch((error) => {
      console.error('取消关注请求失败:', error);
      showShortToast(t('common.unfollowFailed'));
      emit('follow', true);
    }).finally(() => {
      isFollowing.value = false;
    })
  } else {
    emit('follow', true);
    followUser(props.uid).then((res) => {
      if (res.ok && res.status === 201) {
        console.log('关注成功');
        showShortToast(t('common.followed'));
      } else {
        console.log('关注失败');
        showShortToast(t('common.followFailed'));
        emit('follow', false);
      }
    }).catch((error) => {
      console.error('关注请求失败:', error);
      showShortToast(t('common.followFailed'));
      emit('follow', false);
    }).finally(() => {
      isFollowing.value = false;
    })
  }
}
// 点赞
function clickLike() {
  // 如果正在执行点赞操作，直接返回
  if (isLiking.value) return;
  isLiking.value = true;
  if (props.isLike) {
    emit('like', false);
    unlikeVideo(props.vid, aiStore.value).then((res) => {
      if (res.ok && res.status === 204) {
        console.log('取消点赞成功');
        showShortToast(t('common.unliked'));
      } else {
        console.log('取消点赞失败');
        showShortToast(t('common.unlikeFailed'));
        emit('like', true);
      }
    }).catch((error) => {
      console.error('取消点赞请求失败:', error);
      showShortToast(t('common.unlikeFailed'));
      emit('like', true);
    }).finally(() => {
      isLiking.value = false;
    })
  } else {
    emit('like', true);
    likeVideo(props.vid, aiStore.value).then((res) => {
      if (res.ok && res.status === 201) {
        console.log('点赞成功');
        showShortToast(t('common.liked'));
      } else {
        console.log('点赞失败');
        showShortToast(t('common.likeFailed'));
        emit('like', false);
      }
    }).catch((error) => {
      console.error('点赞请求失败:', error);
      showShortToast(t('common.likeFailed'));
      emit('like', false);
    }).finally(() => {
      isLiking.value = false;
    });
  }
}
function toZone() {
  router.push({
    path: `/zone/${props.username}`,
  });
}
// 点击标签跳转到搜索页（标签搜索）
function searchByTag(tag: string) {
  router.push({
    path: '/search',
    query: { type: 'tag', keyword: tag },
  });
}
// 下载缓存（只负责发起下载，管理在离线缓存页）
const isDownloading = ref(false)

async function downloadVideo() {
  if (isDownloading.value) return
  if (!props.download) {
    showShortToast(t('common.fetchDownloadFailed'))
    return
  }

  // 检查是否已在下载队列中或等待队列中
  try {
    const [inDownloading, inQueue] = await Promise.all([
      invoke<boolean>('is_downloading', { downloadId: props.vid }),
      invoke<boolean>('is_in_queue', { downloadId: props.vid }),
    ])
    if (inDownloading || inQueue) {
      showShortToast(t('player.alreadyCaching'))
      return
    }
  } catch { /* 忽略检查错误 */ }

  isDownloading.value = true

  const filename = buildAria2Filename(props.title, props.vid, props.username, '.mp4')
  const setup = setupStore()
  const saveDir = setup.videoSavePath
  let filePath: string
  if (saveDir) {
    filePath = `${saveDir}/${filename}`
  } else {
    filePath = filename
  }

  try {
    // 写入数据库（离线缓存页根据此记录展示状态）
    await upsertDownloadCache(
      props.vid,
      props.title,
      props.authorname,
      props.poster || '',
      0,
      props.playNum,
      props.likeNum,
      false,
      aiStore.value,
      props.download
    )

    showShortToast(t('player.cacheQueued'))

    // 发起 Rust 下载，传入 download_id 实现并发隔离，不等待完成
    invoke('download_video', {
      url: props.download,
      filePath: filePath,
      downloadId: props.vid,
      maxConcurrent: setupStore().maxConcurrentDownloads,
    }).catch((e) => {
      console.error('发起下载失败:', e)
      updateDownloadProgress(props.vid, 0, 'failed')
    })
  } catch (error) {
    const errMsg = String(error)
    if (errMsg.includes('已取消')) {
      showShortToast(t('player.cacheCancelled'))
    } else {
      console.error('缓存失败:', error)
      await updateDownloadProgress(props.vid, 0, 'failed')
      showShortToast(t('player.cacheFailed'))
    }
  } finally {
    isDownloading.value = false
  }
}

// 暗色模式响应式检测
const isDarkMode = ref(detectDarkMode());
let darkModeMediaQuery: MediaQueryList | null = null;
let darkModeChangeHandler: ((e: MediaQueryListEvent) => void) | null = null;

function updateDarkMode() {
  isDarkMode.value = detectDarkMode();
}

onMounted(() => {
  // 监听系统暗色模式变化
  darkModeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  darkModeChangeHandler = (e: MediaQueryListEvent) => {
    updateDarkMode();
  };
  darkModeMediaQuery.addEventListener('change', darkModeChangeHandler);

  // 监听 .dark-theme class 变化（通过 MutationObserver）
  const observer = new MutationObserver(() => {
    updateDarkMode();
  });
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });

  // 存储 observer 以便卸载时断开
  (window as any).__darkModeObserver = observer;
});

onUnmounted(() => {
  if (darkModeMediaQuery && darkModeChangeHandler) {
    darkModeMediaQuery.removeEventListener('change', darkModeChangeHandler);
  }
  // 断开 MutationObserver
  const observer = (window as any).__darkModeObserver;
  if (observer) {
    observer.disconnect();
    (window as any).__darkModeObserver = null;
  }
});

// 暗色模式下图标第一个 fill 值
const iconFirstFill = computed(() => isDarkMode.value ? '#bdbdbd' : '#424242');
const iconLikeOutlineFill = computed(() => isDarkMode.value ? '#bdbdbd' : '#212121');
</script>

<script lang="ts">
/**
 * 暗色模式检测函数
 * 判断依据：.dark-theme class 或系统 prefers-color-scheme: dark
 */
function detectDarkMode(): boolean {
  if (typeof document === 'undefined') return false;
  return document.documentElement.classList.contains('dark-theme') ||
    window.matchMedia('(prefers-color-scheme: dark)').matches;
}
</script>

<template>
  <div class="infoView" @scroll="handleSroll" ref="infoViewRef">
    <div ref="infoViewContentRef">
      <div class="author">
        <div class="avatar" @click="toZone">
          <!-- <img :src="avatarUrl" alt=""> -->
          <v-img :src="avatarUrl" cover>
            <template v-slot:placeholder>
              <v-img height="100%" :src="avatarPlaceholderImg" cover></v-img>
            </template>
          </v-img>
        </div>
        <div class="userinfo">
          <div class="authorname">
            <span @click="toZone">{{ authorname }}</span>
          </div>
          <!-- <div class="userdata">{{ fansNum }}粉丝 {{ videoNum }}视频</div> -->
        </div>
        <div class="follow">
          <v-btn size="small" :variant="followBtn.variant" color="#00796B" @click="clickFollow" :loading="isFollowing">
            <font-awesome-icon :icon="followBtn.icon" />
            {{ followBtn.text }}
          </v-btn>
        </div>
      </div>
      <div class="more" :class="{ expanded: expand }">
        <font-awesome-icon icon="fa-solid fa-angle-down" />
      </div>
      <div class="title" ref="titleRef" @click="expand = !expand">
        {{ title }}
      </div>
      <div class="infomsg">
        <font-awesome-icon icon="fa-regular fa-circle-play" /> {{ playNum }}
        &nbsp;
        <font-awesome-icon icon="fa-regular fa-clock" /> {{ formatDate(createdAt) }}
      </div>
      <div class="synopsis" :style="{ height: expand ? `${heights.synopsis}px` : 0 }">
        <div class="text">
          {{ synopsis }}
        </div>
        <div class="tags">
          <v-chip class="tag" v-for="tag in tags" size="small" @click="searchByTag(tag)">{{ tag }}</v-chip>
        </div>
      </div>
      <div class="calculateHeight">
        <div class="titleCollapseHeight" ref="titleCollapseHeightRef">
          {{ title }}
        </div>
        <div class="titleExpandHeight" ref="titleExpandHeightRef">
          {{ title }}
        </div>
        <div class="synopsisHeight" ref="synopsisHeightRef">
          <div class="text">
            {{ synopsis }}
          </div>
          <div class="tags">
            <v-chip class="tag" v-for="tag in tags" size="small">{{ tag }}</v-chip>
          </div>
        </div>
      </div>
      <div class="operation">
        <div @click="clickLike">
          <iconLike v-if="isLike" theme="filled" size="22" fill="#FF3D00" />
          <iconLike v-else theme="outline" size="22" :fill="iconLikeOutlineFill" />
          <br>
          <span v-if="isLike">{{ t('player.liked') }}</span>
          <span v-else>{{ t('player.like') }}</span>
        </div>
        <div @click="shareDownloadLink">
          <iconShareOne theme="two-tone" size="22" :fill="[iconFirstFill, '#00796B']" /><br>{{ t('player.share') }}
        </div>
        <div @click="downloadVideo">
          <iconDownloadFour theme="two-tone" size="22" :fill="[iconFirstFill, '#00796B']" /><br>{{ t('player.cache') }}
        </div>
        <div @click="copyDownloadLink">
          <iconCopyLink theme="multi-color" size="22" :fill="[iconFirstFill, '#00796B', '#FFF', '#00796B']" /><br>{{
            t('player.downloadLink') }}
        </div>
      </div>
      <recommend :vid="vid" :uid="uid" :isAI="aiStore.value" />
    </div>
  </div>
</template>
<style lang="scss" scoped>
.infoView {
  height: 100%;
  overflow-y: auto;

  >div {
    padding-bottom: env(safe-area-inset-bottom, 0);
  }
}

.author {
  display: flex;

  .avatar {
    padding: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    user-select: none;

    .v-img {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      box-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
    }
  }

  .userinfo {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;

    .authorname {
      font-size: 0.9rem;
      cursor: pointer;
      user-select: none;
      color: var(--color-text-primary);
    }

    .userdata {
      font-size: 0.7rem;
      color: var(--color-text-muted);
    }
  }

  .follow {
    display: flex;
    flex-direction: column;
    justify-content: center;
    padding: 0 10px;
  }
}

.more {
  position: relative;
  height: 0;
  top: 4px;
  left: -8px;
  text-align: right;
  font-size: 0.7rem;
  color: var(--color-text-muted);

  // 旋转过渡动画
  :deep(svg) {
    transition: transform 0.3s ease-in-out;
  }

  // 展开状态 - 箭头旋转180度向上
  &.expanded {
    :deep(svg) {
      transform: rotate(180deg);
    }
  }
}

@mixin title-base {
  margin: 5px 0;
  padding: 0 15px 0 10px;
  text-overflow: ellipsis;
  overflow: hidden;
  font-size: 1.1rem;
  transition: height 0.3s ease-in-out;
  cursor: pointer;
  color: var(--color-text-primary);
}

.title {
  @include title-base;
}

.infomsg {
  padding: 0 10px;
  font-size: 0.8rem;
  color: var(--color-text-muted);
  cursor: pointer;
}

@mixin synopsis-base {
  padding: 0 10px;
  color: var(--color-text-muted);
  font-size: 0.8rem;
  overflow: hidden;
  transition: height 0.3s ease-in-out;

  .text {
    padding: 4px 0 2px 0;
  }

  .tags {
    padding: 2px 0 4px 0;

    .tag {
      margin: 2px 2px 2px 0;
      color: var(--color-text-primary);
      user-select: none;
      cursor: pointer;
    }
  }
}

.synopsis {
  @include synopsis-base;
}

.calculateHeight {
  overflow: hidden;
  height: 0;

  .titleCollapseHeight {
    @include title-base;
    white-space: nowrap;
  }

  .titleExpandHeight {
    @include title-base;
  }

  .synopsisHeight {
    @include synopsis-base;
  }
}

.operation {
  padding: 10px 0;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  justify-items: center;
  /* 水平居中 */
  align-items: center;
  /* 垂直居中 */

  div {
    text-align: center;
    color: var(--color-text-muted);
    font-size: 0.8rem;
    width: 55px;
    cursor: pointer;
    user-select: none;
  }
}

// 桌面端（>=720px）：info 内的推荐由 view-side 接管，此处隐藏
@media (min-width: 720px) {
  :deep(.recommend) {
    display: none;
  }
}
</style>