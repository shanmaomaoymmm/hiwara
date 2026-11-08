<script setup lang="ts">
import { computed, ref, watch, nextTick, onMounted, onUnmounted, defineComponent, h, type Component } from 'vue'
import { useRoute, useRouter } from 'vue-router'
// 官方 API：Android 返回键
import { onBackButtonPress } from '@tauri-apps/api/app'
import type { PluginListener } from '@tauri-apps/api/core'
import { showShortToast } from './core/toast'
import { isTauri } from '@tauri-apps/api/core'
import { moveTaskToBack } from './plugins/appControl'
import { getCachedComponentNames } from './router/index'
import { imageBackStore } from './core/store'

const route = useRoute()
const router = useRouter()
// 插画页抽屉状态（全屏/评论），用于安卓返回键时判断是否需要先让插画页关闭抽屉
const imageBack = imageBackStore()

// 存储需要缓存的组件名称（供 keep-alive :include 使用）
const cachedPages = ref<string[]>([])
// 存储首页组件名称，使其不受 max 限制
const homeComponentName = ref<string>('Home')

// 缓存已生成的包装组件，避免重复创建
const wrappedComponentCache = new Map<string, Component>()

/**
 * 根据原始组件和 cacheKey 生成一个带有唯一 name 的包装组件
 */
function wrapComponent(originalComp: Component, cacheKey: string): Component {
  if (!originalComp) return originalComp

  // 如果已缓存，直接返回
  if (wrappedComponentCache.has(cacheKey)) {
    return wrappedComponentCache.get(cacheKey)!
  }

  // 创建一个新的组件定义，name 设置为 cacheKey
  const wrapped = defineComponent({
    name: cacheKey,
    // 显式设置 inheritAttrs 为 false，防止属性自动继承到根元素
    inheritAttrs: false,
    setup(props, { attrs, slots }) {
      // 直接渲染原始组件，并透传所有属性和插槽
      return () => h(originalComp as any, { ...props, ...attrs }, slots)
    }
  })

  wrappedComponentCache.set(cacheKey, wrapped)
  return wrapped
}

// 计算过渡名称
const transitionName = computed(() => {
  const transition = route.meta?.transition
  // 当过渡名称为空字符串时，不会应用任何过渡效果
  return typeof transition === 'string' ? transition : 'fade'
})

// 更新缓存组件名称列表（同步更新，确保及时响应）
const updateCachedPages = async () => {
  // 等待 DOM 更新完成，保证组件实例已经创建
  await nextTick()
  const allCachedNames = getCachedComponentNames()
  // 分离首页和其他页面，确保首页始终被缓存
  const nonHomePages = allCachedNames.filter(name => name !== homeComponentName.value)
  // 对非首页页面应用 max 限制（保留最近的9个，为首页留出空间）
  const limitedNonHomePages = nonHomePages.slice(-9)
  // 将首页添加到列表中
  cachedPages.value = [homeComponentName.value, ...limitedNonHomePages]
}

// 监听路由变化，立即更新缓存列表
watch(
  () => route.fullPath,
  () => {
    updateCachedPages()
  },
  { immediate: true }
)

router.afterEach(() => {
  updateCachedPages()
})

// =====================
// Toast / Snackbar 状态
// =====================
const snackbar = ref(false)
const snackbarText = ref('')
const snackbarTimeout = ref(2000)
const snackbarColor = ref('#424242')

// 离开插画页时重置抽屉状态，避免残留状态导致后续返回键误判
watch(() => route.name, (name) => {
  if (name !== 'Image') {
    imageBack.setDrawerOpen(false)
  }
})

// 监听自定义事件来显示 snackbar
onMounted(() => {
  window.addEventListener('show-snackbar', ((event: CustomEvent) => {
    snackbarText.value = event.detail.message
    snackbarTimeout.value = event.detail.timeout || 2000
    snackbarColor.value = event.detail.color || '#424242'
    snackbar.value = true
  }) as EventListener)

  // 只在 Tauri 环境中尝试注册返回键监听器
  if (isTauri()) {
    // 使用 setTimeout 延迟注册，确保 Tauri 插件已完全初始化
    // 这可以解决开发环境下的竞态条件问题
    setTimeout(async () => {
      try {
        // 只在 Android 上有效；桌面端不会触发
        // 使用新的事件监听API替代onBackButtonPress
        const listener = await onBackButtonPress(async ({ canGoBack }) => {
          const currentTime = Date.now()

          // 1. 如果当前在首页
          if (route.path === '/') {
            // 发送自定义事件到 Home 组件处理
            window.dispatchEvent(new CustomEvent('home-back-pressed'))
            return
          }

          // 2. 如果当前在播放页且处于全屏状态，通知播放器退出全屏，不放行返回键
          if (route.name === 'Player' && document.fullscreenElement) {
            window.dispatchEvent(new CustomEvent('player-exit-fullscreen'))
            return
          }

          // 2.5 如果当前在搜索页，分发事件给 search.vue 自行处理
          if (route.name === 'Search') {
            window.dispatchEvent(new CustomEvent('search-back-pressed'))
            return
          }

          // 2.6 如果当前在插画页且打开了抽屉（全屏/评论）：通知插画页关闭抽屉，不放行返回键
          // （与播放页全屏处理一致：仅特殊状态交由页面处理，普通返回统一走 router.back()，避免重复返回）
          if (route.name === 'Image' && imageBack.drawerOpen) {
            window.dispatchEvent(new CustomEvent('image-back-pressed'))
            return
          }

          // 3. 不在首页且非全屏：希望"回退到上一页"
          // 优先用 Tauri 提供的 canGoBack 信息
          if (canGoBack) {
            router.back()
            return
          }

          // 3. 极端情况：不在首页，且 WebHistory 已经回退到底
          // 再按返回，就直接退出应用（双击退出逻辑）
          if (
            lastBackPressedTime &&
            currentTime - lastBackPressedTime <= DOUBLE_BACK_PRESS_TIMEOUT
          ) {
            moveTaskToBack()
            return
          } else {
            lastBackPressedTime = currentTime
            showShortToast('再按一次返回键退出应用')
            return
          }
        })

        // 保存监听器引用以便后续清理
        backListener = listener
      } catch (error) {
        // 在非 Android 平台或插件未就绪时，静默失败
        // 这不会影响应用的正常运行
        console.warn('[App] 注册返回按钮监听器失败：', error)
      }
    }, 100) // 延迟 100ms 确保 Tauri 桥接已就绪
  }
})

// =====================
// Android 返回键处理（Tauri v2 官方 API）
// =====================

let backListener: PluginListener | null = null
// 双击返回检测相关变量
let lastBackPressedTime: number | null = null
const DOUBLE_BACK_PRESS_TIMEOUT = 2000 // 2秒内再次按下返回键则退出

onUnmounted(() => {
  // 取消监听，防止内存泄漏
  backListener?.unregister()
})
</script>

<template>
  <!-- 始终渲染 router-view，由路由守卫控制显示哪个页面 -->
  <router-view v-slot="{ Component, route: currentRoute }">
    <transition :name="transitionName" appear>
      <keep-alive :include="cachedPages">
        <component :is="wrapComponent(Component, (currentRoute.meta.cacheKey as string) || 'Anonymous')"
          :key="currentRoute.fullPath" v-if="Component" />
      </keep-alive>
    </transition>
  </router-view>

  <!-- Vuetify Snackbar -->
  <v-snackbar v-model="snackbar" :timeout="snackbarTimeout" :color="snackbarColor" top centered class="snackbar">
    {{ snackbarText }}
  </v-snackbar>
</template>

<style lang="scss" scoped>
// 定义动画时间变量
$transition-duration: 0.25s;

// 基础过渡样式
.fade-enter-active,
.fade-leave-active {
  transition: opacity $transition-duration cubic-bezier(0.4, 0, 0.2, 1);
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

// 前进动画 - 新页面从右侧滑入并覆盖（同时执行）
.stack-enter-active {
  transition: all $transition-duration cubic-bezier(0.4, 0, 0.2, 1);
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 2;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
  border-radius: 12px 0 0 12px;
  will-change: transform, opacity;
}

.stack-enter-from {
  transform: translateX(100%) scale(0.98);
  opacity: 0.9;
}

.stack-enter-to {
  transform: translateX(0) scale(1);
  opacity: 1;
}

// 前进动画 - 旧页面向左移动（同时执行）
.stack-leave-active {
  transition: all $transition-duration cubic-bezier(0.4, 0, 0.2, 1);
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 1;
  will-change: transform, opacity;
}

.stack-leave-from {
  transform: translateX(0);
  opacity: 1;
}

.stack-leave-to {
  transform: translateX(-25%);
  opacity: 0.8;
}

// 后退动画 - 底层页面从左侧进入（同时执行）
.stack-reverse-enter-active {
  transition: all $transition-duration cubic-bezier(0.4, 0, 0.2, 1);
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 1;
  will-change: transform, opacity;
}

.stack-reverse-enter-from {
  transform: translateX(-20%);
  opacity: 0.85;
}

.stack-reverse-enter-to {
  transform: translateX(0);
  opacity: 1;
}

// 后退动画 - 顶层页面向右侧滑出（同时执行）
.stack-reverse-leave-active {
  transition: all $transition-duration cubic-bezier(0.4, 0, 0.2, 1);
  position: absolute;
  width: 100%;
  height: 100%;
  z-index: 2;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
  border-radius: 0 12px 12px 0;
  will-change: transform, opacity;
}

.stack-reverse-leave-from {
  transform: translateX(0) scale(1);
  opacity: 1;
}

.stack-reverse-leave-to {
  transform: translateX(100%) scale(0.98);
  opacity: 0.9;
}

// 传统水平滑动（用于同级页面）
.slide-horizontal-enter-active,
.slide-horizontal-leave-active {
  transition: all $transition-duration cubic-bezier(0.4, 0, 0.2, 1);
  position: absolute;
  width: 100%;
  will-change: transform;
}

.slide-horizontal-enter-from {
  transform: translateX(100%);
}

.slide-horizontal-leave-to {
  transform: translateX(-100%);
}

.snackbar {
  // 向上平移80px
  transform: translateY(calc(-80px - env(safe-area-inset-bottom, 0)));
}
</style>