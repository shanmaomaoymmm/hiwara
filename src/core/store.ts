import { defineStore } from 'pinia';
import { getSetupData, updateSetupData, checkUserIsLogin, getUserToken, getUserInfo, logout as dbLogout } from './database';

/**
 * 解码 JWT token 的 payload 部分
 * JWT 格式：header.payload.signature，payload 是 base64url 编码
 */
function decodeJwtPayload(token: string): Record<string, any> | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    // base64url -> base64: 替换 URL-safe 字符并补齐 padding
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padding = '='.repeat((4 - base64.length % 4) % 4);
    const decoded = atob(base64 + padding);
    return JSON.parse(decoded);
  } catch (error) {
    console.error('解码 JWT payload 失败:', error);
    return null;
  }
}

/**
 * 检查 JWT token 是否已过期
 * 通过解析 payload 中的 exp（Unix 时间戳，秒）与当前时间比较
 */
function isTokenExpired(token: string): boolean {
  const payload = decodeJwtPayload(token);
  if (!payload || typeof payload.exp !== 'number') {
    // 无法解析出过期时间，视为过期
    return true;
  }
  return Date.now() >= payload.exp * 1000;
}

export const isLogin = defineStore('isLogin', {
  state: () => ({
    value: false, // 登录状态，默认为false
    loginVersion: 0, // 登录版本号，退出/登录时递增，用于通知组件刷新
  }),
  getters: {
    // 如果需要，可以在这里添加getter
  },
  actions: {
    // 设置登录状态的方法
    set(status: boolean) {
      this.value = status;
    },
    // 从数据库初始化登录状态（含 token 过期检查）
    async initFromDatabase() {
      try {
        const isLoggedIn = await checkUserIsLogin();
        if (isLoggedIn) {
          // 进一步检查 token 是否过期
          try {
            const userToken = await getUserToken();
            if (userToken && !isTokenExpired(userToken)) {
              this.set(true);
            } else {
              console.log('Token已过期，设置为未登录状态');
              // 清理数据库中已过期的 token
              await dbLogout();
              this.set(false);
            }
          } catch {
            // getUserToken 失败（如 token 为 null/空），设为未登录
            this.set(false);
          }
        } else {
          this.set(false);
        }
      } catch (error) {
        console.error('Failed to initialize login status:', error);
        this.set(false);
      }
    }
  },
});

export const token = defineStore('token', {
  state: () => ({ value: null as string | null }),
  actions: {
    set(token: string) {
      this.value = token;
    }
  }
})

export const uid = defineStore('uid', {
  state: () => ({ value: null as string | null }),
  actions: {
    set(uid: string) {
      this.value = uid;
    },
    // 从数据库初始化 uid
    async initFromDatabase() {
      try {
        const userInfo = await getUserInfo();
        if (userInfo.uid) {
          this.set(userInfo.uid);
        }
      } catch (error) {
        console.error('Failed to initialize uid:', error);
      }
    }
  }
})

export const uname = defineStore('uname', {
  state: () => ({ value: null as string | null }),
  actions: {
    set(uname: string) {
      this.value = uname;
    },
    // 从数据库初始化 username
    async initFromDatabase() {
      try {
        const userInfo = await getUserInfo();
        if (userInfo.username) {
          this.set(userInfo.username);
        }
      } catch (error) {
        console.error('Failed to initialize uname:', error);
      }
    }
  }
})

export const ai = defineStore('ai', {
  state: () => ({ value: false }),
  actions: {
    set(value: boolean) {
      this.value = value;
    }
  }
})

// 插画页抽屉（全屏/评论）状态：供 App.vue 处理安卓返回键时判断是否需要先关闭抽屉
// （对应播放页使用 document.fullscreenElement 判断全屏状态的逻辑）
export const imageBackStore = defineStore('imageBack', {
  state: () => ({
    drawerOpen: false, // 插画页是否有打开的抽屉
  }),
  actions: {
    setDrawerOpen(open: boolean) {
      this.drawerOpen = open;
    }
  }
})

// 定义设置状态的接口
interface SetupState {
  autoPlay: boolean;
  reconnect: number;
  definition: string;
  searchMode: number;
  language: string;
  videoSavePath: string;
  imageSavePath: string;
  aria2Rpc: string;
  aria2Token: string;
  aria2Download: string;
  aria2Switch: boolean;
  maxConcurrentDownloads: number;
}

// 设置相关的 store
export const setupStore = defineStore('setup', {
  state: (): SetupState => ({
    autoPlay: true,
    reconnect: 1,
    definition: 'Source',
    searchMode: 0,
    language: 'auto',
    videoSavePath: '',
    imageSavePath: '',
    aria2Rpc: '',
    aria2Token: '',
    aria2Download: '~/Downloads/Iwara',
    aria2Switch: false,
    maxConcurrentDownloads: 2,
  }),
  actions: {
    // 从数据库加载设置
    async loadSetupFromDatabase() {
      try {
        const dbData = await getSetupData();
        // 映射数据库字段名到 store 状态属性
        this.autoPlay = Boolean(dbData.auto_play) ?? this.autoPlay;
        this.reconnect = dbData.reconnect ?? this.reconnect;
        this.definition = dbData.definition ?? this.definition;
        this.searchMode = dbData.search_mode ?? this.searchMode;
        this.language = dbData.language ?? this.language;
        this.videoSavePath = dbData.video_save_path ?? this.videoSavePath;
        this.imageSavePath = dbData.image_save_path ?? this.imageSavePath;
        this.aria2Rpc = dbData.aria2_rpc ?? this.aria2Rpc;
        this.aria2Token = dbData.aria2_token ?? this.aria2Token;
        this.aria2Download = dbData.aria2_download ?? this.aria2Download;
        this.aria2Switch = Boolean(dbData.aria2_switch) ?? this.aria2Switch;
        this.maxConcurrentDownloads = dbData.max_concurrent_downloads ?? this.maxConcurrentDownloads;
      } catch (error) {
        console.error('Failed to load setup from database:', error);
      }
    },
    // 更新整个设置对象并同步到数据库
    async updateSetup(setupData: Partial<SetupState>) {
      Object.assign(this.$state, setupData);
      await this.saveToDatabase();
    },
    // 更新单个设置项并同步到数据库
    async updateSetting<K extends keyof SetupState>(key: K, value: SetupState[K]): Promise<void> {
      this.$state[key] = value;
      await this.saveToDatabase();
    },
    // 重置为默认值并同步到数据库
    async resetToDefault() {
      this.$reset();
      await this.saveToDatabase();
    },
    // 将当前状态保存到数据库
    async saveToDatabase() {
      try {
        const dbFormatData = {
          auto_play: this.autoPlay ? 1 : 0,
          reconnect: this.reconnect,
          definition: this.definition,
          search_mode: this.searchMode,
          language: this.language,
          video_save_path: this.videoSavePath,
          image_save_path: this.imageSavePath,
          aria2_rpc: this.aria2Rpc,
          aria2_token: this.aria2Token,
          aria2_download: this.aria2Download,
          aria2_switch: this.aria2Switch ? 1 : 0,
          max_concurrent_downloads: this.maxConcurrentDownloads
        };

        await updateSetupData(dbFormatData);
      } catch (error) {
        console.error('Failed to save setup to database:', error);
      }
    }
  },
})

/**
 * 统一初始化所有 Store
 * 在应用启动时调用一次，从数据库加载所有持久化状态
 */
export async function initializeAllStores(): Promise<void> {
  try {
    // 并行初始化所有 Store
    await Promise.all([
      isLogin().initFromDatabase(),
      setupStore().loadSetupFromDatabase(),
      uid().initFromDatabase(),
      uname().initFromDatabase()
    ]);
  } catch (error) {
    console.error('Failed to initialize stores:', error);
  }
}
