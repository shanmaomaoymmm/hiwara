<script setup lang="ts">
import {
  Moon as iconMoon,
  Theme as iconTheme,
  VideoTwo as iconVideoTwo,
  Pic as iconPic,
  MusicList as iconMusicList,
  Download as iconDownload,
  Remind as iconRemind,
  People as iconPeople,
  Mail as iconMail,
  SettingConfig as iconSetting,
  Star as iconStar,
  Financing as iconFinancing,
  Help as iconHelp,
  ShareOne as iconShareOne
} from '@icon-park/vue-next';
import { useRouter } from 'vue-router'
import { ref, onMounted, onActivated, inject, watch, type Ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { ai } from '../../core/store';
import {
  getImageIwara,
  getMyselfInfo,
  getUserFollowers,
  getUserFans
} from '../../core/api'
import { getVideoHistoryList } from '../../core/database'
import { showShortToast } from '../../core/toast';
import HistoryItem from './HistoryItem.vue';
const aiStore = ai();
import defaultAvatarImg from '../../static/img/avatar-default.jpg';
import avatarPlaceholderImg from '../../static/img/avatar-placeholder.png';
import avatarErrorImg from '../../static/img/avatar-error.png';

const { t } = useI18n();
const router = useRouter()

const nickname = ref<string>('');
const username = ref<string>('');
const avatar = ref<string>('');
const avatarUrl = ref<string>(''); // 经过 getImageIwara 处理后的可显示 URL
const followNum = ref<number>(0);
const fansNum = ref<number>(0);
const historyList = ref<any[]>([]);
const historyContainer = ref<HTMLElement | null>(null);
const contentRef = ref<HTMLElement | null>(null);
let contentScrollTop = 0;

// 注入父组件提供的isTab响应式引用
const isTab = inject<Ref<string>>('isTab');

function routerGoTo(path: string, query?: any) {
  if (query) {
    router.push({
      path: path,
      query: query
    });
  } else {
    router.push(path);
  }
}
// 获取用户个人信息
// 移除立即调用,改为在生命周期钩子中调用
// getUserInfo();
// getHistoryList();

onMounted(() => {
  getUserInfo();
  getHistoryList();
});

onActivated(() => {
  // 当组件被激活(从缓存中恢复)时重新获取历史记录
  getHistoryList();
  // 恢复滚动条位置
  if (contentRef.value) {
    contentRef.value.scrollTop = contentScrollTop;
  }
});

// 监听isTab变化,当切换到my时重新获取数据
if (isTab) {
  watch(isTab, (newVal) => {
    if (newVal === 'my') {
      console.log('切换到my选项卡,重新获取历史记录');
      getHistoryList();
    }
  });
}

async function getUserInfo() {
  try {
    const userInfoRes = await getMyselfInfo();
    if (!userInfoRes.ok)
      throw new Error(userInfoRes.message);
    nickname.value = userInfoRes.data.user.name;
    username.value = userInfoRes.data.user.username;
    avatar.value = userInfoRes.data.user.avatar;
    const uid = userInfoRes.data.user.id;
    await Promise.allSettled([
      getFollowersNum(uid),
      getFansNum(uid),
      loadAvatar()
    ])
  } catch (err) {
    console.error(err);
    showShortToast(t('home.toast.getUserInfoFailed'));
  }
  async function getFollowersNum(uid: string) {
    try {
      const res = await getUserFollowers(uid);
      if (!res.ok)
        throw new Error(res.message);
      followNum.value = res.data.count;
    } catch (err) {
      console.error(err);
    }
  }
  async function getFansNum(uid: string) {
    try {
      const res = await getUserFans(uid);
      if (!res.ok)
        throw new Error(res.message);
      fansNum.value = res.data.count;
    } catch (err) {
      console.error(err);
    }
  }
}

// 加载头像
async function loadAvatar() {
  if (!avatar.value || avatar.value.trim() === '') {
    // avatar 为空，使用默认头像
    avatarUrl.value = defaultAvatarImg;
  } else {
    try {
      // avatar 不为空，通过 API 获取
      avatarUrl.value = await getImageIwara(avatar.value, aiStore.value);
    } catch (error) {
      console.error('Failed to load avatar:', error);
      // 加载失败时使用错误头像
      avatarUrl.value = avatarErrorImg;
    }
  }
}

async function getHistoryList() {
  try {
    const res = await getVideoHistoryList(0, 16);
    console.log('获取历史记录:', res);
    historyList.value = res;
  } catch (err) {
    console.error(err);
    showShortToast(t('home.toast.getHistoryFailed'));
  }
}

// 处理鼠标滚轮横向滚动
function handleWheelScroll(event: WheelEvent) {
  if (historyContainer.value) {
    event.preventDefault();
    historyContainer.value.scrollLeft += event.deltaY;
  }
}

// 处理内容区域滚动，保存滚动位置
function handleContentScroll(e: Event) {
  contentScrollTop = (e.target as HTMLElement).scrollTop;
}

// 未实现功能
function handleUnimplemented() {
  showShortToast(t('home.my.notImplemented'));
}
</script>
<template>
  <div class="container">
    <div class="top">
      <div class="topBtns">
        <span class="btn">
          <iconTheme theme="outline" size="22" fill="#ffffff" />
        </span>
        <span class="btn">
          <iconMoon theme="outline" size="22" fill="#ffffff" />
        </span>
      </div>
      <div class="user" @click="routerGoTo(`/zone`)">
        <div class="avatar">
          <v-img class="img" cover :src="avatarUrl">
            <template v-slot:placeholder>
              <v-img height="100%" :src="avatarPlaceholderImg" cover></v-img>
            </template>
          </v-img>
        </div>
        <div class="info">
          <div class="nickname">{{ nickname }}</div>
          <div class="username">@{{ username }}</div>
        </div>
        <div class="right">
          <div class="btn">
            {{ t('home.my.space') }}
            <font-awesome-icon icon="fa-solid fa-angle-right" />
          </div>
        </div>
      </div>
      <div class="friendsNum">
        <div class="fill">
          <div class="btn" @click="routerGoTo('/friends', { type: 'follow' })">
            <div class="num">{{ followNum }}</div>
            <div class="label">{{ t('home.my.followers') }}</div>
          </div>
        </div>
        <div class="fill last">
          <div class="btn" @click="routerGoTo('/friends', { type: 'fans' })">
            <div class="num">{{ fansNum }}</div>
            <div class="label">{{ t('home.my.fans') }}</div>
          </div>
        </div>
      </div>
    </div>
    <div class="content" ref="contentRef" @scroll="handleContentScroll">
      <div class="card">
        <div class="label">
          <div class="left" @click="routerGoTo('/history')">{{ t('home.my.history') }}</div>
          <div class="right" @click="routerGoTo('/history')">{{ t('home.my.viewAllHistory') }}</div>
        </div>
        <div class="history" ref="historyContainer" @wheel="handleWheelScroll">
          <template v-if="historyList.length > 0">
            <HistoryItem v-for="item in historyList" :key="item.id" :item="item" />
            <div class="all-btn" @click="routerGoTo('/history')">{{ t('home.my.viewAllHistory') }}</div>
          </template>
          <template v-else>
            <div class="empty-text">{{ t('home.my.noHistory') }}</div>
          </template>
        </div>
      </div>
      <div class="card">
        <div class="usserFunction">
          <div class="btn" @click="routerGoTo('/favorites', { type: 'video' })">
            <div class="icon">
              <iconVideoTwo theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.videoFavorites') }}</div>
          </div>
          <div class="btn" @click="routerGoTo('/favorites', { type: 'image' })">
            <div class="icon">
              <iconPic theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.imageFavorites') }}</div>
          </div>
          <div class="btn" @click="handleUnimplemented">
            <div class="icon">
              <iconMusicList theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.playlist') }}</div>
          </div>
          <div class="btn" @click="routerGoTo('/offline-cache')">
            <div class="icon">
              <iconDownload theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.offlineCache') }}</div>
          </div>
          <div class="btn"
            @click="routerGoTo('/webview', { url: 'https://www.iwara.tv/notifications', title: t('home.my.notifications') })">
            <div class="icon">
              <iconRemind theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.notifications') }}</div>
          </div>
          <div class="btn" @click="routerGoTo('/friends', { type: 'friend' })">
            <div class="icon">
              <iconPeople theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.friends') }}</div>
          </div>
          <div class="btn"
            @click="routerGoTo('/webview', { url: 'https://www.iwara.tv/messages', title: t('home.my.messages') })">
            <div class="icon">
              <iconMail theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.messages') }}</div>
          </div>
          <div class="btn" @click="routerGoTo('/setup')">
            <div class="icon">
              <iconSetting theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.settings') }}</div>
          </div>
        </div>
      </div>
      <div class="card">
        <div class="label">
          <div class="left">{{ t('home.my.iwaraServices') }}</div>
        </div>
        <div class="usserFunction">
          <div class="btn"
            @click="routerGoTo('/webview', { url: 'https://www.iwara.tv/account/premium', title: t('home.my.premium') })">
            <div class="icon" style="color: #ff62cd;">
              <iconStar theme="outline" size="22" fill="#ff62cd" />
            </div>
            <div class="text">{{ t('home.my.premium') }}</div>
          </div>
          <div class="btn"
            @click="routerGoTo('/webview', { url: 'https://www.iwara.tv/dashboard', title: t('home.my.wura') })">
            <div class="icon" style="color: #dda82b;">
              <iconFinancing theme="outline" size="22" fill="#dda82b" />
            </div>
            <div class="text">{{ t('home.my.wura') }}</div>
          </div>
          <div class="btn"
            @click="routerGoTo('/webview', { url: 'https://www.iwara.tv/page/faq', title: t('home.my.faq') })">
            <div class="icon">
              <iconHelp theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.faq') }}</div>
          </div>
          <div class="btn"
            @click="routerGoTo('/webview', { url: 'https://www.iwara.tv/page/links', title: t('home.my.links') })">
            <div class="icon">
              <iconShareOne theme="outline" size="22" />
            </div>
            <div class="text">{{ t('home.my.links') }}</div>
          </div>
        </div>
      </div>
      <div class="about">
        <span class="logo">Hiwara</span>
        <br>
        {{ t('home.my.aboutText') }}
        <br>
        ©2023-2026 Hiwara Team
      </div>
    </div>
  </div>
</template>
<style lang="scss" scoped>
@use '@/assets/mixins' as *;
.container {
  flex: 1;
  position: relative;
  padding: calc(215px + env(safe-area-inset-top, 0)) 0 env(safe-area-inset-bottom, 0) 0;
}

.top {
  padding-top: env(safe-area-inset-top, 0);
  background-color: var(--color-primary-90);
  backdrop-filter: blur(10px);
  color: var(--color-text-on-primary);
  position: absolute;
  width: 100%;
  top: 0;
  box-shadow: var(--shadow-tab-bar);
  z-index: 400;

  .topBtns {
    text-align: right;
    padding-bottom: 10px;

    .btn {
      height: 40px;
      width: 40px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
    }
  }

  .user {
    padding: 0 14px;
    display: flex;
    height: 90px;

    .avatar {
      display: flex;
      align-items: center;
      cursor: pointer;
      user-select: none;

      .img {
        width: 64px;
        height: 64px;
        border-radius: 50%;
        border: var(--color-white) 2px solid;
      }
    }

    .info {
      flex: 1;
      padding: 0 14px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      justify-content: center;

      .nickname {
        font-size: 1.1rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        font-weight: 500;
        cursor: pointer;
        user-select: none;
      }

      .username {
        font-size: 0.9rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        cursor: pointer;
        user-select: none;
      }
    }

    .right {
      display: flex;
      align-items: center;

      .btn {
        display: flex;
        align-items: center;
        height: 48px;
        font-size: 0.9rem;
        cursor: pointer;
        user-select: none;
      }
    }
  }

  .friendsNum {
    display: flex;
    padding: 10px;

    .fill {
      flex: 1;
      text-align: center;
      border-right: 1px solid var(--color-white-80);
      height: 55px;
      display: flex;
      align-items: center;
      justify-content: center;

      .btn {
        cursor: pointer;
        user-select: none;
        display: inline-block;
        padding: 4px 16px;

        .num {
          font-size: 1.1rem;
        }

        .label {
          font-size: 0.8rem;
        }
      }

    }

    .fill.last {
      border-right: none;
    }
  }
}

.content {
  z-index: 1;
  overflow-y: auto;
  height: 100%;
  padding-bottom: calc(60px + env(safe-area-inset-bottom));

  &::-webkit-scrollbar-track {
    margin: 4px 0 calc(60px + env(safe-area-inset-bottom, 0) + 4px) 0;
  }

  .card {
    margin: 10px;
    box-shadow: var(--shadow-card-item);
    border-radius: 4px;
    overflow: hidden;
    padding: 6px 0;
    background-color: var(--color-bg-card);

    .label {
      display: flex;
      justify-content: space-between;
      align-items: center;

      .left {
        padding: 4px 12px;
        color: var(--color-text-primary);
        cursor: pointer;
        user-select: none;
        font-weight: 500;
        font-size: 0.9rem;
      }

      .right {
        padding: 4px 12px;
        color: var(--color-text-muted-light);
        cursor: pointer;
        user-select: none;
        font-size: 0.8rem;
      }
    }

    .history {
      overflow-x: auto;
      margin: 8px 12px 10px 12px;
      display: flex;
      flex-wrap: nowrap;
      align-items: center;

      .empty-text {
        font-size: 0.9rem;
        color: var(--color-text-muted-light);
        padding: 20px 0;
        text-align: center;
        flex: 1;
      }

      .all-btn {
        font-size: 0.9rem;
        color: var(--color-text-muted);
        width: 80px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        min-width: fit-content;
        cursor: pointer;
        user-select: none;
      }
    }

    .usserFunction {
      display: grid;
      grid-template-columns: repeat(4, 1fr);

      gap: 10px;

      @include up(md) {
        grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));

        .btn {
          max-width: 140px;
        }
      }

      .btn {
        text-align: center;
        color: var(--color-text-secondary-alt);
        padding: 10px 0;
        user-select: none;
        cursor: pointer;

        .icon {
          font-size: 1.2rem;
        }

        .text {
          font-size: 0.8rem;
          line-height: 1rem;
        }
      }
    }
  }

  .about {
    width: 100%;
    color: var(--color-text-muted-light);
    font-size: 0.7rem;
    text-align: center;
    padding: 0 10px 10px 10px;

    @font-face {
      font-family: 'riwenlogo';
      /* 优先使用相对路径（Android assets目录） */
      src: url('/fonts/riwenlogo.ttf') format('truetype');
      font-weight: normal;
      font-style: normal;
    }

    .logo {
      font-family: 'riwenlogo';
      font-size: 0.8rem;
    }
  }
}
</style>