<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, onActivated, watch, provide, onDeactivated } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import videoPlayer from '../component/player/videoPlayer.vue';
import infoView from '../component/player/info.vue';
import commentView from '../component/player/comment.vue';
import recommend from '../component/player/recommend.vue';
import { useAutoStatusBar } from '../composables/useAutoStatusBar';
import { Swiper, SwiperSlide } from 'swiper/vue';
import type { Swiper as SwiperType } from 'swiper';
import 'swiper/swiper-bundle.css';
import {
  getVideoInfo as api_getVideoInfo,
  getVideoFileSQ as api_getVideoFileSQ,
  addAria2Download,
  buildAria2Filename
} from '../core/api';
import { showShortToast } from '../core/toast';
import { setupStore } from '../core/store';
import { insertVideoHistory } from '../core/database';
import loadingHuawu from '../component/loadingHuawu.vue';
import errorHuawu from '../component/errorHuawu.vue';

const { t } = useI18n();

// 设置组件名称，确保与路由name一致
defineOptions({
  name: 'Player'
})

const router = useRouter();
const route = useRoute();

// 从路由查询参数获取 isAI（由前一个页面传入），不存在时默认为 false
const isAI = ref(route.query.isAI === 'true');

const tab = ref('info');  // 当前选中的tab
const tab2 = ref('recommend');  // 当前选中的tab
const id = ref(route.params.id);  // 视频id
// view-side 侧边栏是否已获取到推荐数据（独立于 main 的 videoInfoState）
const sideDataLoaded = ref(false);
const onSideDataLoaded = () => {
  sideDataLoaded.value = true;
};
const title = ref<string>('');   // 视频标题
const synopsis = ref<string>('');  // 视频简介
const poster = ref<string>(''); //视频封面
const playNum = ref<number>(0);  // 播放次数
const likeNum = ref<number>(0);  // 点赞数
const createdAt = ref<string>('');  // 创建时间
const isLike = ref(false);  // 是否已点赞
const tags = ref<string[]>([]);  // 标签
const authorname = ref<string>('');  // 作者名称
const username = ref<string>(''); // 用户名
const avatar = ref<string>('');   // 作者头像
const uid = ref<string>('');  // 作者ID
const fansNum = ref<number>(0);   // 作者粉丝数（无API）
const videoNum = ref<number>(0);  // 作者视频数（无API）
const isFollow = ref(false);  // 是否已关注
const slug = ref<string>('');
const fileExtension = ref('.mp4'); // 视频文件扩展名，用于 aria2 下载

interface VideoFileItem {
  id: string;
  name: string;
  server: string;
  type: string;
  view: string;
  download: string;
}
const videoFile = ref<VideoFileItem[]>([]);
const videoSelect = ref<number>(0);
const showDefinitionDialog = ref(false); // 控制清晰度选择对话框显示

// 聚合状态：'failed' | 'loading' | 'success'
type VideoInfoState = 'failed' | 'loading' | 'success';
const videoInfoState = ref<VideoInfoState>('loading');
// 是否正在切换服务器
const isRefreshingServer = ref(false)

// 当前选中的视频文件信息
const currentServer = computed(() => {
  return videoFile.value[videoSelect.value]?.server || '';
});
const currentDefinition = computed(() => {
  return videoFile.value[videoSelect.value]?.name || '';
});
const currentVideoSrc = computed(() => {
  return videoFile.value[videoSelect.value]?.view || '';
});
const currentDownloadUrl = computed(() => {
  return videoFile.value[videoSelect.value]?.download || '';
});

// --- Swiper 联动逻辑 ---
// 左侧主内容区 Swiper（info / comment）
const swiperInstance = ref<SwiperType | null>(null);

const onSwiper = (swiper: SwiperType) => {
  swiperInstance.value = swiper;
};

watch(tab, (newVal) => {
  if (swiperInstance.value) {
    const targetIndex = newVal === 'info' ? 0 : 1;
    if (swiperInstance.value.activeIndex !== targetIndex) {
      swiperInstance.value.slideTo(targetIndex);
    }
  }
});

const onSlideChange = (swiper: SwiperType) => {
  tab.value = swiper.activeIndex === 0 ? 'info' : 'comment';
};

// 右侧侧边栏 Swiper（recommend / comment）
const swiperInstance2 = ref<SwiperType | null>(null);

const onSwiper2 = (swiper: SwiperType) => {
  swiperInstance2.value = swiper;
};

watch(tab2, (newVal) => {
  if (swiperInstance2.value) {
    const targetIndex = newVal === 'recommend' ? 0 : 1;
    if (swiperInstance2.value.activeIndex !== targetIndex) {
      swiperInstance2.value.slideTo(targetIndex);
    }
  }
});

const onSlideChange2 = (swiper: SwiperType) => {
  tab2.value = swiper.activeIndex === 0 ? 'recommend' : 'comment';
};
// --- End Swiper 联动逻辑 ---

const goBack = () => {
  router.back();
};
provide('goBack', goBack);
const goHome = () => {
  router.replace('/');
};
provide('goHome', goHome);

// 自动状态栏文字颜色自适应（根据 --color-primary-90 亮度判断）
const { forceUpdate: forceStatusBarStyle } = useAutoStatusBar({ cssVar: '--color-primary-90' })

// 全屏进入/退出后：重新应用状态栏样式 + 同步桌面/移动端布局状态
// 1) 避免退出沉浸模式时系统把状态栏图标颜色重置回默认（浅色模式下为黑色）；
// 2) 避免退出全屏后 isDesktop 残留 true，界面停留在平板/PC 布局。
const onFullscreenChange = () => {
  forceStatusBarStyle();
  updateDesktopState();
};

// 获取视频信息
const fetchVideoInfo = async () => {
  videoInfoState.value = 'loading'; // 开始加载
  try {
    // 若站点归属判定错误（API 返回 301 重定向）则自动切换站点重试一次
    let res: any;
    try {
      res = await api_getVideoInfo(id.value as string, isAI.value);
    } catch (error: any) {
      // 以错误站点（Referer/X-Site）请求时，api.iwara.tv 会对归属他站的作品返回 301，
      // 切换站点（isAI）后重试即可正常获取
      if (error?.message && String(error.message).includes('301')) {
        isAI.value = !isAI.value;
        router.replace({ query: { ...route.query, isAI: isAI.value ? 'true' : 'false' } });
        res = await api_getVideoInfo(id.value as string, isAI.value);
      } else {
        throw error;
      }
    }
    // console.log(res);
    if (res.ok) {
      const data = res.data;
      title.value = data.title || '';
      synopsis.value = data.body || '';
      playNum.value = data.numViews || 0;
      likeNum.value = data.numLikes || 0;
      isLike.value = data.liked || false;
      slug.value = data.slug || '';
      // 修改: 直接传递原始时间字符串，由 info 组件格式化
      createdAt.value = data.createdAt || '';
      // 处理标签
      if (data.tags && Array.isArray(data.tags)) {
        tags.value = data.tags.map((tag: any) => tag.id);
      } else {
        tags.value = [];
      }
      // 处理作者信息
      if (data.user) {
        authorname.value = data.user.name || '';
        username.value = data.user.username || '';
        uid.value = data.user.id || '';
        avatar.value = data.user.avatar ? `https://i.iwara.tv/image/avatar/${data.user.avatar.id}/${data.user.avatar.name}` : '';
        isFollow.value = data.user.following || false;
      }
      // 获取视频封面
      if (data.file && data.file.id) {
        // 使用 API 返回的 thumbnail 索引，如果不存在则默认为 0
        const thumbnailIndex = data.thumbnail ?? 0;
        poster.value = `https://i.iwara.tv/image/thumbnail/${data.file.id}/thumbnail-${String(thumbnailIndex).padStart(2, '0')}.jpg`;
      }
      // 获取视频文件
      let extension = '.mp4'; // 默认扩展名
      if (data.file?.name) {
        const lastDotIndex = data.file.name.lastIndexOf('.');
        if (lastDotIndex !== -1) {
          extension = data.file.name.substring(lastDotIndex);
        }
      }
      fileExtension.value = extension;
      const filename = `Iwara - ${data.title} [${data.id}]${extension}`;
      await fetchVideoFile(data.fileUrl, filename);

      // 数据获取成功
      videoInfoState.value = 'success';

      // 添加视频历史记录
      try {
        // 解析 createdAt 为时间戳
        const createTimeTimestamp = data.createdAt ? new Date(data.createdAt).getTime() : 0;

        await insertVideoHistory(
          data.id,
          data.title || '',
          data.user?.name || '',
          poster.value,
          data.file?.duration || 0, // 视频时长（秒）
          createTimeTimestamp, // 作品发布时间
          data.siteId === 'iwara_ai' // 是否为AI站（依据 API 返回的 siteId 判定）
        );
        console.log('视频历史记录已添加:', data.id);
      } catch (error) {
        console.error('添加视频历史记录失败:', error);
      }
    } else {
      console.error(`状态码：${res.status}`, `错误信息：${res.statusText}`);
      showShortToast(t('player.fetchInfoFailed'));
      videoInfoState.value = 'failed';
    }
  } catch (error) {
    console.error(error);
    showShortToast(t('player.fetchInfoFailed'));
    videoInfoState.value = 'failed';
  }
};
fetchVideoInfo();
// 获取视频文件
async function fetchVideoFile(url: string, filename: string) {
  try {
    const res = await api_getVideoFileSQ(url, filename, isAI.value)
    // console.log(res);
    // 补全逻辑：解析并存储视频文件信息
    if (res.ok && res.data && Array.isArray(res.data)) {
      videoFile.value = res.data.map((item: any) => {
        // 从 view URL 中提取 server 名称 (例如: //hime.iwara.tv/... -> hime)
        let server = 'unknown';
        if (item.src && item.src.view) {
          const match = item.src.view.match(/\/\/([^.]+)\./);
          if (match && match[1]) {
            server = match[1];
          }
        }
        return {
          id: item.id,
          name: item.name,
          server: server,
          type: item.type,
          view: `https:${item.src?.view}` || '',
          download: `https:${item.src?.download}` || ''
        };
      });
      // console.log('Processed video files:', videoFile.value);

      // 根据 store 中的 definition 值设置 videoSelect
      const setup = setupStore();
      const targetDefinition = setup.definition;
      // console.log('Target definition:', targetDefinition);
      const selectedIndex = videoFile.value.findIndex(file => file.name === targetDefinition);
      if (selectedIndex !== -1) {
        videoSelect.value = selectedIndex;
      } else {
        // 如果找不到匹配的，默认选择第一个
        videoSelect.value = 0;
      }
      // console.log(videoFile.value[videoSelect.value])
    }
  } catch (error) {
    showShortToast(t('player.fetchFileFailed'));
    console.error('获取视频文件失败：', error);
  }
}
// 重试加载视频信息
const retryFetchVideoInfo = () => {
  fetchVideoInfo();
};

function definitionTextFormat(text: string): string {
  // 如果输入是数字，返回值后面加个P
  if (!isNaN(Number(text))) {
    return `${text}P`;
  }
  // 如果输入是Source，返回原画
  if (text === 'Source') {
    return t('player.original');
  }
  // 其他情况返回原文本
  return text;
}

// 选择清晰度
const selectDefinition = async (index: number) => {
  // 如果选择的清晰度与当前相同,则不执行切换
  if (index === videoSelect.value) {
    showDefinitionDialog.value = false;
    return;
  }

  videoSelect.value = index;
  showDefinitionDialog.value = false;

  // 同步到 store 和数据库
  const setup = setupStore();
  await setup.updateSetting('definition', videoFile.value[index].name);

  showShortToast(t('player.switchedTo', { definition: definitionTextFormat(videoFile.value[index].name) }));
};

// 过滤并排序视频文件列表
const sortedVideoFiles = computed(() => {
  // 先过滤掉 preview
  const filtered = videoFile.value.filter(file => file.name.toLowerCase() !== 'preview');

  // 排序函数
  return filtered.sort((a, b) => {
    // Source(原画)排最后
    if (a.name === 'Source' && b.name !== 'Source') return 1;
    if (a.name !== 'Source' && b.name === 'Source') return -1;

    // 都是数字类型,按数值大小排序
    const aNum = Number(a.name);
    const bNum = Number(b.name);
    if (!isNaN(aNum) && !isNaN(bNum)) {
      return aNum - bNum;
    }

    // 其他情况保持原顺序
    return 0;
  });
});

// 获取排序后文件在原数组中的索引
const getOriginalIndex = (file: VideoFileItem) => {
  return videoFile.value.findIndex(f => f.id === file.id);
};

// 刷新视频文件列表（切换服务器，最多重试 10 次）
const refreshVideoFile = async () => {
  // 切换中防止重复点击
  if (isRefreshingServer.value) return
  const maxRetries = 10
  const originalServer = currentServer.value
  const currentDefName = videoFile.value[videoSelect.value]?.name

  isRefreshingServer.value = true

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const res = await api_getVideoInfo(id.value as string, isAI.value)
      if (!res.ok || !res.data?.fileUrl) continue

      let extension = '.mp4'
      if (res.data.file?.name) {
        const lastDotIndex = res.data.file.name.lastIndexOf('.')
        if (lastDotIndex !== -1) {
          extension = res.data.file.name.substring(lastDotIndex)
        }
      }
      const filename = `Iwara - ${res.data.title} [${res.data.id}]${extension}`

      const fileRes = await api_getVideoFileSQ(res.data.fileUrl, filename, isAI.value)
      if (!fileRes.ok || !fileRes.data || !Array.isArray(fileRes.data)) continue

      // 在返回数据中找当前清晰度对应的文件
      const matchedItem = fileRes.data.find(
        (item: any) => item.name === currentDefName
      )

      if (matchedItem) {
        // 提取新服务器名
        let newServer = 'unknown'
        if (matchedItem.src && matchedItem.src.view) {
          const match = matchedItem.src.view.match(/\/\/([^.]+)\./)
          if (match && match[1]) newServer = match[1]
        }

        if (newServer !== originalServer) {
          // 找到不同服务器 → 更新当前清晰度的 view/download URL 和 server 名
          const newViewUrl = `https:${matchedItem.src.view}`
          const newDownloadUrl = `https:${matchedItem.src.download}`
          videoFile.value = videoFile.value.map((file, index) => {
            if (index === videoSelect.value) {
              return { ...file, view: newViewUrl, download: newDownloadUrl, server: newServer }
            }
            return file
          })
          isRefreshingServer.value = false
          showShortToast(t('player.switchComplete'))
          return
        }

        console.log(`[refreshVideoFile] 服务器相同(${newServer}), 第${attempt + 1}次重试`)
      }
    } catch (error) {
      console.error('刷新服务器列表失败:', error)
    }
  }

  // 10 次重试后服务器仍相同，不更新 URL（无提示）
  isRefreshingServer.value = false
}

onActivated(() => {
  console.log('🔄 Player activated', id.value);
})
onDeactivated(() => {
  console.log('⏸️ Player deactivated', id.value);
})
onUnmounted(() => {
  console.log('❌ Player unmounted', id.value);
})

const likeTrigger = (val: boolean) => {
  isLike.value = val;
  if (val) {
    // 点赞时触发 aria2 下载
    addAria2DownloadTask();
  }
}

/**
 * 向 aria2 发送添加下载任务的请求
 * 从 store 读取 aria2 配置，按 标题[id]username.扩展名 格式命名文件
 * 仅在 aria2 启用且推送失败时提示用户
 */
async function addAria2DownloadTask() {
  const setup = setupStore();
  // 检查 aria2 开关是否开启
  if (!setup.aria2Switch) {
    return;
  }
  // 检查是否有下载链接
  const downloadUrl = currentDownloadUrl.value;
  if (!downloadUrl) {
    console.warn('aria2 下载失败: 未获取到下载链接');
    return;
  }
  // 检查 RPC 地址是否已配置
  if (!setup.aria2Rpc || setup.aria2Rpc.trim() === '') {
    console.warn('aria2 下载失败: 未配置 RPC 地址');
    return;
  }

  // 构建文件名: 标题[id]username.扩展名
  const filename = buildAria2Filename(
    title.value,
    id.value as string,
    username.value,
    fileExtension.value
  );

  console.log('aria2 开始添加下载任务:', {
    rpc: setup.aria2Rpc,
    dir: setup.aria2Download,
    filename: filename,
    url: downloadUrl.substring(0, 50) + '...',
  });

  const result = await addAria2Download(
    setup.aria2Rpc,
    setup.aria2Token || null,
    downloadUrl,
    setup.aria2Download,
    filename
  );

  if (result.ok) {
    console.log('aria2 下载任务添加成功, GID:', result.result);
  } else {
    console.error('aria2 下载任务添加失败:', result.error);
    showShortToast(t('player.aria2Failed'));
  }
}
const followTrigger = (val: boolean) => {
  isFollow.value = val;
}

// 桌面端检测（>=720px），用于条件渲染
const isDesktop = ref(window.innerWidth >= 720);

// 统一同步桌面/移动端布局状态。
// 同时依赖 mql change、resize、orientationchange、fullscreenchange 多个信号，
// 避免 Android WebView 在全屏/横竖屏切换时 matchMedia change 事件漏发，
// 导致退出全屏后 isDesktop 残留 true，界面停留在平板/PC 布局。
const updateDesktopState = () => {
  const desktop = window.innerWidth >= 720;
  isDesktop.value = desktop;
  // 从桌面切回移动端时，重置 tab 防止评论 slide 仍处于选中状态
  if (!desktop && tab.value === 'comment') {
    tab.value = 'info';
  }
};

const mql = window.matchMedia('(min-width: 720px)');
const onMqlChange = () => {
  updateDesktopState();
};

onMounted(() => {
  mql.addEventListener('change', onMqlChange);
  document.addEventListener('fullscreenchange', onFullscreenChange);
  window.addEventListener('resize', updateDesktopState);
  window.addEventListener('orientationchange', updateDesktopState);
});
onUnmounted(() => {
  mql.removeEventListener('change', onMqlChange);
  document.removeEventListener('fullscreenchange', onFullscreenChange);
  window.removeEventListener('resize', updateDesktopState);
  window.removeEventListener('orientationchange', updateDesktopState);
});
</script>
<template>
  <div id="playerView">
    <div class="view-main">
      <div class="topBar"></div>
      <div class="video-player-wrapper">
        <videoPlayer class="video-player" :poster="poster" :src="currentVideoSrc" :title="title" :server="currentServer"
          :video-files="videoFile" :current-definition-index="videoSelect" :is-refreshing-server="isRefreshingServer"
          :is-like="isLike" :vid="id as string" :like-num="likeNum"
          :username="username" :author-name="authorname" :play-num="playNum"
          @refresh-server="refreshVideoFile" @definition-change="selectDefinition" @like="likeTrigger" />
      </div>

      <!-- 加载中 -->
      <div class="status-view" v-if="videoInfoState === 'loading'">
        <loadingHuawu>{{ t('player.loading') }}</loadingHuawu>
      </div>
      <!-- 加载失败 -->
      <div class="status-view" v-else-if="videoInfoState === 'failed'">
        <errorHuawu>{{ t('player.failed') }}</errorHuawu>
      </div>
      <!-- 加载成功：视频信息 + Swiper 内容 -->
      <div class="video-info" v-else>
        <div class="tabs">
          <div class="tabs-bar">
            <v-tabs class="left" v-model="tab" color="#00796B" density="comfortable">
              <v-tab value="info">{{ t('player.infoTab') }}</v-tab>
              <v-tab v-if="!isDesktop" value="comment">{{ t('player.commentTab') }}</v-tab>
            </v-tabs>
            <div class="right" v-if="videoFile.length > 0">
              <span v-ripple @click="refreshVideoFile" :class="{ 'right-btn-disabled': isRefreshingServer }">
                <template v-if="isRefreshingServer">
                  <v-progress-circular :size="16" :width="2" color="inherit" indeterminate />
                </template>
                <template v-else>
                  <font-awesome-icon icon="fa-solid fa-server" />{{ currentServer }}
                </template>
              </span>
              <span v-ripple @click="showDefinitionDialog = true">
                <font-awesome-icon icon="fa-solid fa-film" />{{ definitionTextFormat(currentDefinition) }}
              </span>
            </div>
          </div>
          <v-divider></v-divider>
        </div>
        <div class="tabs-content">
          <swiper class="tabs-window" :slides-per-view="1" :space-between="0" @swiper="onSwiper"
            @slide-change="onSlideChange">
            <swiper-slide>
              <infoView :title="title" :synopsis="synopsis" :playNum="playNum" :likeNum="likeNum" :createdAt="createdAt"
                :isLike="isLike" :tags="tags" :authorname="authorname" :username="username" :avatar="avatar"
                :fansNum="fansNum" :videoNum="videoNum" :isFollow="isFollow" :vid="id as string" :uid="uid"
                :download="currentDownloadUrl" :slug="slug" :poster="poster" @like="likeTrigger" @follow="followTrigger" />
            </swiper-slide>
            <swiper-slide v-if="!isDesktop">
              <commentView :vid="id as string" :isAI="isAI" />
            </swiper-slide>
          </swiper>
        </div>
        <!-- 清晰度选择对话框 -->
        <v-dialog v-model="showDefinitionDialog" max-width="400">
          <v-card>
            <v-card-title class="text-center">
              {{ t('player.selectDefinition') }}
            </v-card-title>
            <v-divider></v-divider>
            <v-list>
              <v-list-item v-for="(file, index) in sortedVideoFiles" :key="file.id"
                @click="selectDefinition(getOriginalIndex(file))" :active="getOriginalIndex(file) === videoSelect">
                <template v-slot:prepend>
                  <v-icon icon="fa-solid fa-film"></v-icon>
                </template>
                <v-list-item-title>{{ definitionTextFormat(file.name) }}</v-list-item-title>
                <template v-slot:append v-if="getOriginalIndex(file) === videoSelect">
                  <v-icon color="primary" icon="fa-solid fa-check"></v-icon>
                </template>
              </v-list-item>
            </v-list>
          </v-card>
        </v-dialog>
      </div>
    </div>
    <div class="view-side">
      <!-- 加载中 -->
      <div class="status-view" v-show="videoInfoState === 'loading' || (videoInfoState === 'success' && !sideDataLoaded)">
        <loadingHuawu>{{ t('player.loading') }}</loadingHuawu>
      </div>
      <!-- 加载失败 -->
      <div class="status-view" v-show="videoInfoState === 'failed'">
        <errorHuawu>{{ t('player.failed') }}</errorHuawu>
      </div>
      <!-- 加载成功 / side 已有数据 -->
      <div class="view-side-content" v-show="sideDataLoaded && videoInfoState === 'success'">
        <div class="tabs">
          <div class="tabs-bar">
            <v-tabs class="left" v-model="tab2" color="#00796B" density="comfortable">
              <v-tab value="recommend">推荐</v-tab>
              <v-tab value="comment">{{ t('player.commentTab') }}</v-tab>
            </v-tabs>
          </div>
          <v-divider></v-divider>
        </div>
        <div class="tabs-content">
          <swiper class="tabs-window" :slides-per-view="1" :space-between="0" @swiper="onSwiper2"
            @slide-change="onSlideChange2">
            <swiper-slide>
              <recommend :vid="id as string" :uid="uid" :isAI="isAI" @data-loaded="onSideDataLoaded" />
            </swiper-slide>
            <swiper-slide>
              <commentView :vid="id as string" :isAI="isAI" />
            </swiper-slide>
          </swiper>
        </div>
      </div>
    </div>
  </div>
</template>
<style lang="scss" scoped>
@use '../assets/mixins' as *;

#playerView {
  background-color: var(--color-bg-page);
  display: flex;
}

.view-main {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.view-side {
  flex: 0 0 auto;
  width: clamp(380px, 25vw, 580px);
  display: flex;
  flex-direction: column;
  overflow: hidden;

  @include down(md) {
    display: none;
  }

  @media (orientation: portrait) {
    display: none;
  }
}

.view-side-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.topBar {
  height: env(safe-area-inset-top, 0);
  width: 100%;
  background-color: #000;
}

.video-player-wrapper {
  position: relative;
  width: 100%;

  @include up(md) {
    @media (orientation: landscape) {
      max-height: 66.67vh;
    }
  }
}

.video-player {
  width: 100%;
  aspect-ratio: 16 / 9;
  display: block;

  @include up(md) {
    @media (orientation: landscape) {
      max-height: 66.67vh;
    }
  }
}

/* 加载/失败 状态容器 */
.status-view {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.video-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.tabs {
  background-color: var(--color-bg-card);
  box-shadow: var(--shadow-tab-bar);

  :deep(.v-tab) {
    min-width: 0 !important;
    color: var(--color-text-muted);

    &.v-tab--selected {
      color: var(--color-primary);
    }
  }

  :deep(.v-divider) {
    border-color: var(--color-border-divider) !important;
  }

  .tabs-bar {
    display: flex;

    .left {
      flex: 1;
      padding: 0 16px;
    }

    .right {
      display: flex;
      padding: 0 14px;
      color: var(--color-text-muted);
      font-size: 0.9rem;

      span {
        display: inline-flex;
        align-items: center;
        user-select: none;
        justify-content: center;
        cursor: pointer;
      }

      .right-btn-disabled {
        pointer-events: none;
        min-width: 60px;
        justify-content: center;
      }

      span:nth-child(1) {
        padding: 0 6px;
      }

      span:nth-child(2) {
        padding: 0 6px;
      }
    }
  }
}

.tabs-content {
  flex: 1;
  overflow: hidden;

  .tabs-window {
    height: 100%;

    :deep(.swiper-wrapper) {
      height: 100%;
    }

    :deep(.swiper-slide) {
      height: 100%;
    }
  }
}
</style>
