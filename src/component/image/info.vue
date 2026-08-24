<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, nextTick, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import {
  Like as iconLike,
  ShareOne as iconShareOne,
  DownloadFour as iconDownloadFour,
  Comments as iconComments
} from '@icon-park/vue-next';
import defaultAvatarImg from '../../static/img/avatar-default.jpg';
import avatarPlaceholderImg from '../../static/img/avatar-placeholder.png';
import avatarErrorImg from '../../static/img/avatar-error.png';
import { invoke } from '@tauri-apps/api/core';
import { ai, setupStore } from '../../core/store';
import {
  likeImage,
  unlikeImage,
  followUser,
  unfollowUser,
  getImageIwara,
  sanitizeFilename,
} from '../../core/api';
import { upsertDownloadCache, updateDownloadProgress } from '../../core/database';
import { showShortToast } from '../../core/toast';

const aiStore = ai();
const { t } = useI18n();
const router = useRouter();

// 内容容器（用于 ResizeObserver 动态高度重算）
const infoContentRef = ref<HTMLElement>();
let contentResizeObserver: ResizeObserver | null = null;
// 交叉观察器：组件从隐藏变为可见时重算高度
let intersectionObserver: IntersectionObserver | null = null;

// 插画信息展开状态（内部状态）
const infoExpand = ref(false);
const titleRef = ref<HTMLElement | null>(null);
const tagsContainerRef = ref<HTMLElement | null>(null);
const titleCollapseHeightRef = ref<HTMLElement | null>(null);
const titleExpandHeightRef = ref<HTMLElement | null>(null);
const synopsisHeightRef = ref<HTMLElement | null>(null);
const tagsCollapseHeightRef = ref<HTMLElement | null>(null);
const tagsExpandHeightRef = ref<HTMLElement | null>(null);

// 高度缓存对象
const heights = ref({
  titleCollapse: 0,
  titleExpand: 0,
  synopsis: 0,
  tagsCollapse: 0,
  tagsExpand: 0,
});

// 接收父组件传递的插画信息数据
interface ImageFile {
  id: string;
  name: string;
  width: number;
  height: number;
}
interface ImageInfoProps {
  title: string;
  viewCount: number;
  createdAt: string;
  pid: string;
  slug: string;
  resolution: string;
  synopsis: string;
  tags: string[];
  authorname: string;
  username: string;
  uid: string;
  fansNum: number;
  imageNum: number;
  avatar: string;
  isFollow: boolean;
  isMyFans?: boolean;  // 是否是粉丝（互粉状态）
  isLike: boolean;
  images: ImageFile[];  // 插画图片文件数组（用于下载）
  isAI?: boolean;  // 站点标记（AI 站 / 普通站）
}

const props = defineProps<ImageInfoProps>();

// 定义 emits
const emit = defineEmits<{
  (e: 'commentTrigger'): void;
  (e: 'like', isLiked: boolean): void;
  (e: 'follow', isFollowed: boolean): void;
}>();

// 标签容器高度（computed 缓存）
const tagsContainerHeight = computed(() => {
  if (!heights.value.tagsCollapse || !heights.value.tagsExpand) return 'auto';
  if (infoExpand.value) {
    return `${heights.value.tagsExpand}px`;
  } else {
    const linesNum = heights.value.tagsExpand / heights.value.tagsCollapse;
    if (linesNum < 3) {
      return `${heights.value.tagsCollapse * linesNum}px`;
    } else {
      return `${heights.value.tagsCollapse * 3}px`;
    }
  }
});

// 处理窗口大小改变
function handleResize() {
  calculateHeights();
}

onMounted(() => {
  calculateHeights();
  // 下一帧重算一次，确保首次渲染完成后的尺寸正确
  requestAnimationFrame(() => calculateHeights());

  if (titleRef.value) {
    titleRef.value.style.height = heights.value.titleCollapse + 'px';
    titleRef.value.style.whiteSpace = 'nowrap';
  }

  // 监听窗口大小改变事件
  window.addEventListener('resize', handleResize);

  // 监听内容容器高度变化（推荐内容等异步加载导致），重新计算
  if (infoContentRef.value) {
    contentResizeObserver = new ResizeObserver(() => {
      calculateHeights();
    });
    contentResizeObserver.observe(infoContentRef.value);
  }

  // 交叉观察器：组件从隐藏变为可见时重算高度
  // 不受祖先 CSS display 层级限制（解决 view-side 在 portrait 下 display:none 的问题）
  if (infoContentRef.value) {
    intersectionObserver = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting) {
          requestAnimationFrame(() => calculateHeights());
        }
      },
      { threshold: 0 }
    );
    intersectionObserver.observe(infoContentRef.value);
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
  // 断开 IntersectionObserver
  if (intersectionObserver) {
    intersectionObserver.disconnect();
    intersectionObserver = null;
  }
})

// 简化 watch 逻辑，使用 nextTick 确保 DOM 更新后设置样式
watch(infoExpand, async (val) => {
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
      if (!infoExpand.value) {
        el.style.whiteSpace = 'nowrap';
      }
    }, 300); // 与 transition 时间匹配
  }
}, { immediate: true });

function calculateHeights() {
  heights.value.titleCollapse = titleCollapseHeightRef.value?.offsetHeight || 0;
  heights.value.titleExpand = titleExpandHeightRef.value?.offsetHeight || 0;
  heights.value.synopsis = synopsisHeightRef.value?.offsetHeight || 0;
  heights.value.tagsCollapse = tagsCollapseHeightRef.value?.offsetHeight || 0;
  heights.value.tagsExpand = tagsExpandHeightRef.value?.offsetHeight || 0;
}

// 操作状态
const isFollowing = ref(false); // 关注操作进行中状态
const isLiking = ref(false); // 点赞操作进行中状态

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

// 使用 Web Share API 分享插画
async function shareImage() {
  if (!props.pid) {
    showShortToast(t('common.fetchDownloadFailed'));
    return;
  }
  // 检查浏览器是否支持 Web Share API
  if (!navigator.share) {
    showShortToast(t('common.shareNotSupported'));
    return;
  }
  try {
    let shareUrl: string;
    if (props.slug === '')
      shareUrl = `https://iwara.tv/image/${props.pid}`;
    else
      shareUrl = `https://iwara.tv/image/${props.pid}/${props.slug}`;
    await navigator.share({
      title: props.title || t('imageView.shareTitle'),
      text: t('imageView.shareText', { title: props.title }),
      url: shareUrl,
    });
    showShortToast(t('common.shareSuccess'));
  } catch (err) {
    // 用户取消分享不显示错误提示
    if ((err as Error).name !== 'AbortError') {
      console.error('分享失败:', err);
      showShortToast(t('common.shareFailed'));
    }
  }
}

// 下载缓存（只负责发起下载，管理在离线缓存页）——参考 player/info.vue
const isDownloading = ref(false)

// 获取图片文件扩展名
const getImageExtension = (name: string): string => {
  const idx = name.lastIndexOf('.')
  return idx !== -1 ? name.substring(idx) : '.jpg'
}

// 下载插画全部图片到本地（离线缓存）
async function downloadImages() {
  if (isDownloading.value) return
  if (!props.images || props.images.length === 0) {
    showShortToast(t('common.fetchDownloadFailed'))
    return
  }

  isDownloading.value = true
  const setup = setupStore()
  const saveDir = setup.imageSavePath
  const aiFlag = props.isAI ?? aiStore.value
  const maxConcurrent = setup.maxConcurrentDownloads || 2

  try {
    let startedCount = 0
    for (let i = 0; i < props.images.length; i++) {
      const file = props.images[i]
      const downloadId = `${props.pid}_${i}`

      // 检查是否已在下载队列中或等待队列中
      try {
        const [inDownloading, inQueue] = await Promise.all([
          invoke<boolean>('is_downloading', { downloadId }),
          invoke<boolean>('is_in_queue', { downloadId }),
        ])
        if (inDownloading || inQueue) continue
      } catch { /* 忽略检查错误 */ }

      // 构建图片下载直链与文件名
      const url = `https://i.iwara.tv/image/large/${file.id}/${file.name}`
      const filename = sanitizeFilename(
        `${props.title}[${props.pid}]_${String(i + 1).padStart(2, '0')}${getImageExtension(file.name)}`
      )
      const filePath = saveDir ? `${saveDir}/${filename}` : filename

      try {
        // 写入数据库（离线缓存页根据此记录展示状态）
        await upsertDownloadCache(
          downloadId,
          `${props.title} (${i + 1}/${props.images.length})`,
          props.authorname,
          url,
          props.images.length,
          0,
          0,
          false,
          aiFlag,
          url
        )
        startedCount++

        // 发起 Rust 下载，传入 download_id 实现并发隔离，不等待完成
        invoke('download_video', {
          url,
          filePath,
          downloadId,
          maxConcurrent,
        }).catch((e) => {
          console.error('发起图片下载失败:', e)
          updateDownloadProgress(downloadId, 0, 'failed')
        })
      } catch (error) {
        const errMsg = String(error)
        if (errMsg.includes('已取消')) {
          showShortToast(t('player.cacheCancelled'))
        } else {
          console.error('图片缓存失败:', error)
          await updateDownloadProgress(downloadId, 0, 'failed')
        }
      }
    }
    if (startedCount > 0) {
      showShortToast(t('player.cacheQueued'))
    } else {
      showShortToast(t('imageView.alreadyCaching'))
    }
  } finally {
    isDownloading.value = false
  }
}

// 关注按钮点击处理
function clickFollow() {
  // 如果正在执行关注操作，直接返回
  if (isFollowing.value) return;

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

// 点赞按钮点击处理
function clickLike() {
  // 如果正在执行点赞操作，直接返回
  if (isLiking.value) return;

  isLiking.value = true;
  if (props.isLike) {
    emit('like', false);
    unlikeImage(props.pid, aiStore.value).then((res) => {
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
    likeImage(props.pid, aiStore.value).then((res) => {
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
  (window as any).__darkModeObserverImage = observer;
});

onUnmounted(() => {
  if (darkModeMediaQuery && darkModeChangeHandler) {
    darkModeMediaQuery.removeEventListener('change', darkModeChangeHandler);
  }
  // 断开 MutationObserver
  const observer = (window as any).__darkModeObserverImage;
  if (observer) {
    observer.disconnect();
    (window as any).__darkModeObserverImage = null;
  }
});

// 暗色模式下图标第一个 fill 值
const iconFirstFill = computed(() => isDarkMode.value ? '#bdbdbd' : '#424242');
const iconLikeOutlineFill = computed(() => isDarkMode.value ? '#bdbdbd' : '#212121');
const iconCommentsFill = computed(() => isDarkMode.value ? '#bdbdbd' : '#484848');
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
  <!-- 第二部分：插画信息区域 -->
  <div ref="infoContentRef">
    <div class="more" :class="{ expanded: infoExpand }" @click="infoExpand = !infoExpand">
      <font-awesome-icon icon="fa-solid fa-angle-down" />
    </div>
    <div class="title" ref="titleRef" @click="infoExpand = !infoExpand">
      {{ title }}
    </div>
    <div class="infomsg">
      <font-awesome-icon icon="fa-regular fa-eye" /> {{ viewCount }}
      &nbsp;
      <font-awesome-icon icon="fa-regular fa-clock" /> {{ formatDate(createdAt) }}
      <br>
      <span>{{ t('imageView.imageId', { id: pid }) }}</span>
      &nbsp;
      <span v-if="resolution !== ''">{{ t('imageView.resolution', { res: resolution }) }}</span>
    </div>
    <div class="author">
      <div class="avatar" @click="toZone">
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
        <div class="userdata" v-if="false">{{ fansNum }}粉丝 {{ imageNum }}插画</div>
      </div>
      <div class="follow">
        <span v-if="!isFollow && !isMyFans">
          <v-btn size="small" variant="flat" color="#00796B" @click="clickFollow" :loading="isFollowing">
            <font-awesome-icon icon="fa-solid fa-plus" />
            {{ t('imageView.follow') }}
          </v-btn>
        </span>
        <span v-else-if="isFollow && !isMyFans">
          <v-btn size="small" variant="outlined" color="#00796B" @click="clickFollow" :loading="isFollowing">
            <font-awesome-icon icon="fa-solid fa-bars" />
            {{ t('imageView.followed') }}
          </v-btn>
        </span>
        <span v-else-if="isFollow && isMyFans">
          <v-btn size="small" variant="outlined" color="#00796B" @click="clickFollow" :loading="isFollowing">
            <font-awesome-icon icon="fa-solid fa-bars" />
            {{ t('imageView.followMutual') }}
          </v-btn>
        </span>
        <span v-else-if="!isFollow && isMyFans">
          <v-btn size="small" variant="flat" color="#00796B" @click="clickFollow" :loading="isFollowing">
            <font-awesome-icon icon="fa-solid fa-plus" />
            {{ t('imageView.followBack') }}
          </v-btn>
        </span>
      </div>
    </div>
    <div class="synopsis" :style="{ height: infoExpand ? `${heights.synopsis}px` : 0 }">
      <div class="text">
        {{ synopsis }}
      </div>
    </div>
    <div class="operation">
      <div @click="clickLike">
        <iconLike v-if="isLike" theme="filled" size="22" fill="#FF3D00" />
        <iconLike v-else theme="outline" size="22" :fill="iconLikeOutlineFill" />
        <br>
        <span v-if="isLike">{{ t('imageView.liked') }}</span>
        <span v-else>{{ t('imageView.like') }}</span>
      </div>
      <div @click="shareImage">
        <iconShareOne theme="two-tone" size="22" :fill="[iconFirstFill, '#00796B']" /><br>{{ t('imageView.share') }}
      </div>
      <div @click="downloadImages">
        <iconDownloadFour theme="two-tone" size="22" :fill="[iconFirstFill, '#00796B']" /><br>{{ t('imageView.download') }}
      </div>
      <div @click="emit('commentTrigger')">
        <iconComments theme="multi-color" size="22" :fill="[iconCommentsFill, '#00796B', '#FFFFFF', '#00796B']" /><br>{{ t('imageView.comment') }}
      </div>
    </div>
    <div class="tags" ref="tagsContainerRef" :style="{ height: tagsContainerHeight }">
      <v-chip class="tag" v-for="tag in tags" :key="tag" size="small" @click="searchByTag(tag)">{{ tag }}</v-chip>
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
      </div>
      <div class="tagsCollapseHeight" ref="tagsCollapseHeightRef">
        <v-chip class="tag" size="small">{{ tags[0] }}</v-chip>
      </div>
      <div class="tagsExpandHeight" ref="tagsExpandHeightRef">
        <v-chip class="tag" v-for="tag in tags" :key="tag" size="small">{{ tag }}</v-chip>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
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

  // 展开状态 - 箭头旋转 180 度向上
  &.expanded {
    :deep(svg) {
      transform: rotate(180deg);
    }
  }
}

.title {
  margin: 5px 0;
  padding: 10px 15px 0 10px;
  text-overflow: ellipsis;
  overflow: hidden;
  font-size: 1.1rem;
  transition: height 0.3s ease-in-out;
  cursor: pointer;
  color: var(--color-text-primary);
}

.infomsg {
  padding: 0 10px;
  font-size: 0.8rem;
  color: var(--color-text-muted);
  cursor: pointer;
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

.synopsis {
  padding: 0 10px;
  color: var(--color-text-muted);
  font-size: 0.8rem;
  overflow: hidden;
  transition: height 0.3s ease-in-out;

  .text {
    padding: 4px 0 2px 0;
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

.tags {
  overflow: hidden;
  transition: height 0.3s ease-in-out;
  margin: 10px;

  .tag {
    margin: 2px 2px 2px 0;
    color: var(--color-text-primary);
    user-select: none;
    cursor: pointer;
  }
}

.calculateHeight {
  overflow: hidden;
  height: 0;

  .titleCollapseHeight {
    @extend .title;
    white-space: nowrap;
  }

  .titleExpandHeight {
    @extend .title;
    white-space: normal;
  }

  .synopsisHeight {
    @extend .synopsis;
    height: auto !important;
  }

  .tagsCollapseHeight,
  .tagsExpandHeight {
    overflow: hidden;
    margin: 10px;

    .tag {
      margin: 2px 2px 2px 0;
    }
  }
}
</style>