<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, computed, nextTick } from 'vue';
import { Swiper, SwiperSlide } from 'swiper/vue';
import { Navigation } from 'swiper/modules';
import type { Swiper as SwiperType } from 'swiper';
import { ai } from '../../core/store';
import { getImageIwara } from '../../core/api';
import placeholderImg from '../../static/img/placeholder.png'
import notImg from '../../static/img/not-img.jpg'

// 导入 Swiper 样式
const aiStore = ai();
import 'swiper/swiper-bundle.css';

interface ImageFile {
  id: string;
  name: string;
  width: number;
  height: number;
}

const props = defineProps<{
  images: ImageFile[];
}>();

const emit = defineEmits(['close']);

// 处理后的图片URL数组
const processedImages = ref<string[]>([]);
// 加载状态
const loading = ref(false);
// 当前页码
const currentIndex = ref(1);
// Swiper 模块
const modules = [Navigation];
// Swiper navigation 配置（使用 any 类型绕过 swiper 12.x 的 PropType 类型推导缺陷）
const swiperNavigation: any = { enabled: true };
// Swiper 实例
let swiperInstance: SwiperType | null = null;

// ---------- 图片手势缩放相关 ----------
const MAX_SCALE = 5;
// 双击放大到 2 倍
const DOUBLE_TAP_SCALE = 2;

interface ZoomState {
  scale: number;
  x: number;
  y: number;
}

// 每张图片的缩放状态（非响应式，直接操作 DOM transform）
const zoomStates = new Map<number, ZoomState>();
// slide 元素引用
let slideEls: (HTMLElement | null)[] = [];
// 事件监听清理函数列表
const touchCleanups: (() => void)[] = [];
// 按钮显示状态
const showButtons = ref(false);
// 按钮元素引用
let prevButton: HTMLElement | null = null;
let nextButton: HTMLElement | null = null;
// 全屏状态
const isFullscreen = ref(false);

// 判断是否为服务器URL（需要特殊处理）
const isServerUrl = (url: string): boolean => {
  return url.startsWith('http://') || url.startsWith('https://');
};

// 处理单个图片文件对象
const processImageFile = async (file: ImageFile): Promise<string> => {
  try {
    const url = `https://i.iwara.tv/image/large/${file.id}/${file.name}`;
    return await getImageIwara(url, aiStore.value);
  } catch (error) {
    console.error('Failed to load image:', file, error);
    return notImg;
  }
};

// 处理所有图片
const loadImages = async () => {
  if (!props.images || props.images.length === 0) {
    processedImages.value = [];
    return;
  }

  loading.value = true;
  try {
    const results = await Promise.all(props.images.map(processImageFile));
    processedImages.value = results;
  } catch (error) {
    console.error('Failed to load images:', error);
    processedImages.value = [];
  } finally {
    loading.value = false;
  }
};

// 监听images变化，重新加载
watch(() => props.images, () => {
  loadImages();
}, { immediate: true });

// 图片加载完成后重新初始化手势（slide 数量可能变化）
watch(processedImages, () => {
  if (processedImages.value.length > 0) {
    nextTick(() => initGestures());
  }
});

// ---------- 图片双指捏合缩放 / 拖动 / 双击 手势 ----------
const getZoomState = (index: number): ZoomState => {
  let state = zoomStates.get(index);
  if (!state) {
    state = { scale: 1, x: 0, y: 0 };
    zoomStates.set(index, state);
  }
  return state;
};

// 获取 slide 内实际渲染的 <img> 元素（Vuetify v-img 的内层图片）
const getImageEl = (slideEl: HTMLElement): HTMLImageElement | null => {
  return slideEl.querySelector('.fullscreen-image img') as HTMLImageElement | null;
};

// 将缩放/平移状态应用到外层容器 .zoom-wrapper 的 transform
// （外层容器 overflow: visible，避免 v-img 内部 overflow: hidden 裁切放大后的图片）
const applyTransform = (slideEl: HTMLElement, state: ZoomState) => {
  const wrapper = slideEl.querySelector('.zoom-wrapper') as HTMLElement | null;
  if (wrapper) {
    wrapper.style.transform = `translate(${state.x}px, ${state.y}px) scale(${state.scale})`;
    wrapper.style.willChange = 'transform';
  }
};

const clampNum = (v: number, min: number, max: number): number => {
  return Math.min(max, Math.max(min, v));
};

// 限制平移范围，防止图片被拖出视口
const clampTranslate = (slideEl: HTMLElement, index: number, state: ZoomState) => {
  const img = getImageEl(slideEl);
  if (!img) return;
  const container = slideEl.getBoundingClientRect();
  const cw = container.width;
  const ch = container.height;
  const nw = img.naturalWidth || cw;
  const nh = img.naturalHeight || ch;
  const baseScale = Math.min(cw / nw, ch / nh);
  const w = nw * baseScale * state.scale;
  const h = nh * baseScale * state.scale;
  const maxX = Math.max(0, (w - cw) / 2);
  const maxY = Math.max(0, (h - ch) / 2);
  state.x = clampNum(state.x, -maxX, maxX);
  state.y = clampNum(state.y, -maxY, maxY);
};

// 控制 Swiper 是否响应触摸滑动（缩放时禁用，避免手势冲突）
const setSwiperTouchMove = (allowed: boolean) => {
  if (swiperInstance) {
    swiperInstance.allowTouchMove = allowed;
  }
};

// 重置指定图片的缩放状态
const resetZoomState = (index: number) => {
  const state = zoomStates.get(index);
  if (!state) return;
  state.scale = 1;
  state.x = 0;
  state.y = 0;
  const el = slideEls[index];
  if (el) applyTransform(el, state);
};

// 销毁所有手势事件监听
const destroyGestures = () => {
  touchCleanups.forEach((cleanup) => cleanup());
  touchCleanups.length = 0;
  slideEls = [];
};

// 为每个 slide 初始化手势（双指捏合缩放 / 单指拖动 / 双击 / 滚轮缩放）
const initGestures = () => {
  destroyGestures();
  if (!swiperInstance) return;
  const swiperEl = swiperInstance.el;
  slideEls = Array.from(swiperEl.querySelectorAll<HTMLElement>('.slide-content'));

  slideEls.forEach((el, index) => {
    if (!el) return;
    const state = getZoomState(index);

    // 单次手势临时数据
    let mode: 'none' | 'pan' | 'pinch' = 'none';
    let startDist = 0;
    let startScale = 1;
    let startX = 0;
    let startY = 0;
    let startTouchX = 0;
    let startTouchY = 0;
    let baseX = 0;
    let baseY = 0;
    let isMouseDown = false;
    let mouseStartX = 0;
    let mouseStartY = 0;
    let mouseStartStateX = 0;
    let mouseStartStateY = 0;
    // 双击检测临时数据（兼容桌面与移动端，不依赖原生 dblclick）
    let lastTapTime = 0;
    let lastTapX = 0;
    let lastTapY = 0;

    // 双指捏合开始 / 单指拖动开始
    const onTouchStart = (e: TouchEvent) => {
      // 触摸开始立即停止双击过渡，保证捏合/拖动实时响应
      clearWrapperTransition();
      const touches = Array.from(e.touches);
      if (touches.length >= 2) {
        mode = 'pinch';
        const [a, b] = touches;
        startDist = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY) || 1;
        startScale = state.scale;
        startX = state.x;
        startY = state.y;
        const wrapper = el.querySelector('.zoom-wrapper') as HTMLElement | null;
        const rect = wrapper ? wrapper.getBoundingClientRect() : el.getBoundingClientRect();
        baseX = rect.left + rect.width / 2 - state.x;
        baseY = rect.top + rect.height / 2 - state.y;
        // 双指手势期间禁用 Swiper 滑动，避免冲突
        setSwiperTouchMove(false);
        e.preventDefault();
      } else if (touches.length === 1 && state.scale > 1) {
        // 单指且已放大：进入拖动模式
        mode = 'pan';
        startX = state.x;
        startY = state.y;
        startTouchX = touches[0].clientX;
        startTouchY = touches[0].clientY;
        setSwiperTouchMove(false);
      } else {
        mode = 'none';
      }
    };

    // 双指捏合移动（任意方向均可缩放）/ 单指拖动平移
    const onTouchMove = (e: TouchEvent) => {
      const touches = Array.from(e.touches);
      if (mode === 'pinch' && touches.length >= 2) {
        const [a, b] = touches;
        const curDist = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY) || 1;
        const cx = (a.clientX + b.clientX) / 2;
        const cy = (a.clientY + b.clientY) / 2;
        const newScale = clampNum(startScale * (curDist / startDist), 1, MAX_SCALE);
        const ratio = newScale / state.scale;
        // 以手指中心为锚点缩放（含平移补偿）
        const offX = cx - (baseX + state.x);
        const offY = cy - (baseY + state.y);
        state.x += offX - offX * ratio;
        state.y += offY - offY * ratio;
        state.scale = newScale;
        clampTranslate(el, index, state);
        applyTransform(el, state);
        setSwiperTouchMove(false);
        e.preventDefault();
      } else if (mode === 'pan' && touches.length === 1) {
        const t = touches[0];
        state.x = startX + (t.clientX - startTouchX);
        state.y = startY + (t.clientY - startTouchY);
        clampTranslate(el, index, state);
        applyTransform(el, state);
        e.preventDefault();
      }
    };

    // 触摸结束：全部抬起时回弹/恢复滑动；抬起一指则切换为拖动
    const onTouchEnd = (e: TouchEvent) => {
      const remaining = Array.from(e.touches);
      if (remaining.length === 0) {
        mode = 'none';
        if (state.scale <= 1) {
          state.scale = 1;
          state.x = 0;
          state.y = 0;
        } else {
          clampTranslate(el, index, state);
        }
        applyTransform(el, state);
        setSwiperTouchMove(true);
      } else if (remaining.length === 1 && mode === 'pinch') {
        mode = 'pan';
        startX = state.x;
        startY = state.y;
        startTouchX = remaining[0].clientX;
        startTouchY = remaining[0].clientY;
      }
    };

    // 鼠标拖动平移（桌面端，放大后生效）
    const onMouseDown = (e: MouseEvent) => {
      clearWrapperTransition();
      if (e.button !== 0) return;
      if (state.scale <= 1) return; // 未放大时交给 Swiper 滑动
      isMouseDown = true;
      mouseStartX = e.clientX;
      mouseStartY = e.clientY;
      mouseStartStateX = state.x;
      mouseStartStateY = state.y;
      setSwiperTouchMove(false);
      e.preventDefault();
    };

    const onMouseMove = (e: MouseEvent) => {
      if (!isMouseDown) return;
      state.x = mouseStartStateX + (e.clientX - mouseStartX);
      state.y = mouseStartStateY + (e.clientY - mouseStartY);
      clampTranslate(el, index, state);
      applyTransform(el, state);
    };

    const onMouseUp = () => {
      if (!isMouseDown) return;
      isMouseDown = false;
      setSwiperTouchMove(true);
    };

    const onMouseLeave = () => {
      if (isMouseDown) {
        isMouseDown = false;
        setSwiperTouchMove(true);
      }
    };

    // 清除外层容器的 transform 过渡（捏合/拖动/滚轮需实时响应，不能带过渡）
    const clearWrapperTransition = () => {
      const wrapper = el.querySelector('.zoom-wrapper') as HTMLElement | null;
      if (wrapper) wrapper.style.transition = '';
    };

    // 双击缩放：低于 2 倍时放大到 2 倍；2 倍及以上时恢复原大小
    // 通过短暂的 transform 过渡让缩放平滑不突兀
    const applyDoubleTapZoom = () => {
      const wrapper = el.querySelector('.zoom-wrapper') as HTMLElement | null;
      if (wrapper) {
        wrapper.style.transition = 'transform 0.3s cubic-bezier(0.22, 1, 0.36, 1)';
      }
      if (state.scale >= DOUBLE_TAP_SCALE) {
        state.scale = 1;
        state.x = 0;
        state.y = 0;
        setSwiperTouchMove(true);
      } else {
        state.scale = DOUBLE_TAP_SCALE;
        state.x = 0;
        state.y = 0;
        setSwiperTouchMove(false);
      }
      applyTransform(el, state);
      // 动画结束后移除过渡，避免影响后续实时手势
      if (wrapper) {
        const clear = () => { wrapper.style.transition = ''; };
        wrapper.addEventListener('transitionend', clear, { once: true });
        window.setTimeout(clear, 350); // 兜底：动画被中断时也能清除残留过渡
      }
    };

    // 通过 click 事件计时 + 坐标距离检测双击
    const onClick = (e: MouseEvent) => {
      const now = Date.now();
      if (
        now - lastTapTime < 300 &&
        Math.abs(e.clientX - lastTapX) < 30 &&
        Math.abs(e.clientY - lastTapY) < 30
      ) {
        // 两次快速点击视为双击
        lastTapTime = 0;
        applyDoubleTapZoom();
      } else {
        lastTapTime = now;
        lastTapX = e.clientX;
        lastTapY = e.clientY;
      }
    };

    // 滚轮缩放（桌面端，以鼠标位置为锚点）
    const onWheel = (e: WheelEvent) => {
      clearWrapperTransition();
      const factor = e.deltaY < 0 ? 1.15 : 1 / 1.15;
      const newScale = clampNum(state.scale * factor, 1, MAX_SCALE);
      if (newScale === state.scale) return;
      const ratio = newScale / state.scale;
      const wrapper = el.querySelector('.zoom-wrapper') as HTMLElement | null;
      const rect = wrapper ? wrapper.getBoundingClientRect() : el.getBoundingClientRect();
      const bx = rect.left + rect.width / 2 - state.x;
      const by = rect.top + rect.height / 2 - state.y;
      const offX = e.clientX - (bx + state.x);
      const offY = e.clientY - (by + state.y);
      state.x += offX - offX * ratio;
      state.y += offY - offY * ratio;
      state.scale = newScale;
      clampTranslate(el, index, state);
      applyTransform(el, state);
      if (newScale > 1) setSwiperTouchMove(false);
      else setSwiperTouchMove(true);
      e.preventDefault();
    };

    el.addEventListener('touchstart', onTouchStart, { passive: false });
    el.addEventListener('touchmove', onTouchMove, { passive: false });
    el.addEventListener('touchend', onTouchEnd);
    el.addEventListener('touchcancel', onTouchEnd);
    el.addEventListener('mousedown', onMouseDown);
    el.addEventListener('mousemove', onMouseMove);
    el.addEventListener('mouseup', onMouseUp);
    el.addEventListener('mouseleave', onMouseLeave);
    el.addEventListener('click', onClick);
    el.addEventListener('wheel', onWheel, { passive: false });

    touchCleanups.push(() => {
      el.removeEventListener('touchstart', onTouchStart);
      el.removeEventListener('touchmove', onTouchMove);
      el.removeEventListener('touchend', onTouchEnd);
      el.removeEventListener('touchcancel', onTouchEnd);
      el.removeEventListener('mousedown', onMouseDown);
      el.removeEventListener('mousemove', onMouseMove);
      el.removeEventListener('mouseup', onMouseUp);
      el.removeEventListener('mouseleave', onMouseLeave);
      el.removeEventListener('click', onClick);
      el.removeEventListener('wheel', onWheel);
    });
  });
};

// Swiper 初始化回调
const onSwiper = (swiper: SwiperType) => {
  swiperInstance = swiper;
  currentIndex.value = 1;

  // 初始化每张图片的捏合缩放手势
  initGestures();

  // 获取按钮元素并添加事件监听
  setTimeout(() => {
    const container = swiper.el;
    prevButton = container.querySelector('.swiper-button-prev');
    nextButton = container.querySelector('.swiper-button-next');

    if (prevButton && nextButton) {
      // 为两个按钮添加鼠标事件监听
      const handleMouseEnter = () => {
        showButtons.value = true;
      };

      const handleMouseLeave = () => {
        showButtons.value = false;
      };

      prevButton.addEventListener('mouseenter', handleMouseEnter);
      prevButton.addEventListener('mouseleave', handleMouseLeave);
      nextButton.addEventListener('mouseenter', handleMouseEnter);
      nextButton.addEventListener('mouseleave', handleMouseLeave);
    }
  }, 100);
};

// Swiper 滑动回调
const onSlideChange = (swiper: SwiperType) => {
  currentIndex.value = swiper.activeIndex + 1;
  // 切换页面时重置其它图片的缩放状态
  const activeIndex = swiper.activeIndex;
  slideEls.forEach((_, i) => {
    if (i !== activeIndex) resetZoomState(i);
  });
  // 恢复 Swiper 滑动
  setSwiperTouchMove(true);
};

// 判断是否显示左按钮（不在第一张时显示）
const showPrevButton = computed(() => {
  return currentIndex.value > 1;
});

// 判断是否显示右按钮（不在最后一张时显示）
const showNextButton = computed(() => {
  return currentIndex.value < processedImages.value.length;
});

// 组件卸载时清理
onUnmounted(() => {
  if (prevButton && nextButton) {
    // 清理事件监听器（如果需要的话）
  }
});

// 组件挂载时加载图片
onMounted(() => {
  // 初始加载已在watch中处理
});

// 更改当前页码
const changeSwiper = (num: number) => {
  // 边界检查
  if (!swiperInstance || num < 0 || num >= processedImages.value.length) {
    console.warn('Invalid slide index or swiper not ready:', num);
    return;
  }

  // 先执行滑动操作，再更新索引（确保同步）
  swiperInstance.slideTo(num, 0); // 0ms 过渡时间，立即切换

  // 在下一帧更新索引，确保与 Swiper 内部状态同步
  requestAnimationFrame(() => {
    currentIndex.value = num + 1;
  });
};

// 进入全屏
const enterFullscreen = async () => {
  try {
    // 推入历史记录，用于捕获返回键
    history.pushState({ fullscreen: true }, '');
    isFullscreen.value = true;
  } catch (err) {
    console.error('进入全屏失败:', err);
  }
};

// 退出全屏
const exitFullscreen = async () => {
  try {
    // 如果处于全屏状态，则退出
    if (isFullscreen.value) {
      isFullscreen.value = false;
    }
  } catch (err) {
    console.error('退出全屏失败:', err);
  }
};

// 监听手机返回键 (popstate)
const handlePopState = () => {
  // 如果用户按了返回键，且当前处于全屏，则退出全屏
  if (isFullscreen.value) {
    exitFullscreen();
    emit('close');
  }
};

// 关闭全屏
const handleClose = async () => {
  await exitFullscreen();
  emit('close');
};

defineExpose({
  changeSwiper,
  enterFullscreen
});

// 组件挂载时加载图片
onMounted(() => {
  // 初始加载已在watch中处理
  // 监听 popstate 事件
  window.addEventListener('popstate', handlePopState);
});

onUnmounted(() => {
  if (prevButton && nextButton) {
    // 清理事件监听器（如果需要的话）
  }
  // 销毁所有手势实例
  destroyGestures();
  // 移除 popstate 监听
  window.removeEventListener('popstate', handlePopState);
  // 确保退出全屏状态
  if (isFullscreen.value) {
    exitFullscreen();
  }
});
</script>

<template>
  <div class="full-screen">
    <!-- 顶部导航栏 -->
    <div class="top">
      <span class="btn" @click="handleClose">
        <font-awesome-icon icon="fa-solid fa-angle-left" />
      </span>
    </div>

    <!-- 底部页码指示器 -->
    <div class="bottom-indicator" v-if="processedImages.length > 1">
      <span class="page-number">{{ currentIndex }} / {{ processedImages.length }}</span>
    </div>

    <!-- 加载中状态 -->
    <div v-if="loading" class="loading-container">
      <v-progress-circular indeterminate color="white" size="50"></v-progress-circular>
    </div>

    <!-- Swiper 轮播 -->
    <Swiper v-else-if="processedImages.length > 0" :modules="modules" :navigation="swiperNavigation" :slides-per-view="1"
      :space-between="0" class="swiper-container" @swiper="onSwiper" @slide-change="onSlideChange">
      <SwiperSlide v-for="(img, index) in processedImages" :key="index">
        <div class="slide-content">
          <div class="zoom-wrapper">
            <v-img :src="img" contain max-height="100vh" max-width="100vw" class="fullscreen-image">
              <template v-slot:placeholder>
                <v-img cover :src="placeholderImg" class="placeholder"></v-img>
              </template>
            </v-img>
          </div>
        </div>
      </SwiperSlide>
    </Swiper>

    <!-- 无图片提示 -->
    <div v-else class="no-image">
      <v-icon size="64" color="white">mdi-image-off</v-icon>
      <p>暂无图片</p>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.full-screen {
  background-color: #000;
  height: 100vh;
  width: 100vw;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
  user-select: none;
}

.top {
  position: absolute;
  top: 0;
  left: 0;
  z-index: 400;
  height: calc(48px + env(safe-area-inset-top, 0));
  padding-top: env(safe-area-inset-top, 0);
  color: #fff;
  filter: drop-shadow(1px 1px 1px rgba(0, 0, 0, 0.5));
  width: 100%;

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

.bottom-indicator {
  position: absolute;
  bottom: 0;
  left: 0;
  z-index: 400;
  height: calc(48px + env(safe-area-inset-bottom, 0));
  padding-bottom: env(safe-area-inset-bottom, 0);
  color: #fff;
  filter: drop-shadow(1px 1px 1px rgba(0, 0, 0, 0.5));
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;

  .page-number {
    font-size: 1rem;
    font-weight: 500;
    user-select: none;
  }
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
}

.swiper-container {
  width: 100%;
  height: 100%;

  :deep(.swiper-slide) {
    display: flex;
    justify-content: center;
    align-items: center;
  }

  :deep(.swiper-button-prev) {
    color: white;
    filter: drop-shadow(1px 1px 2px rgba(0, 0, 0, 0.8));
    opacity: v-bind('(showButtons && showPrevButton) ? 1 : 0');
    transition: opacity 0.3s ease;
    pointer-events: auto;

    &::after {
      font-size: 24px;
      font-weight: bold;
    }
  }

  :deep(.swiper-button-next) {
    color: white;
    filter: drop-shadow(1px 1px 2px rgba(0, 0, 0, 0.8));
    opacity: v-bind('(showButtons && showNextButton) ? 1 : 0');
    transition: opacity 0.3s ease;
    pointer-events: auto;

    &::after {
      font-size: 24px;
      font-weight: bold;
    }
  }
}

.slide-content {
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  touch-action: none;
  overflow: visible;

  // 外层缩放容器：承载 transform，overflow: visible 避免裁切放大后的图片
  .zoom-wrapper {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    transform-origin: center center;
    overflow: visible;
    touch-action: none;
    cursor: zoom-in;
    will-change: transform;
  }

  .fullscreen-image {
    max-width: 100vw;
    max-height: 100vh;
    object-fit: contain;
    touch-action: none;
  }

  .placeholder {
    opacity: 0.3;
  }
}

.no-image {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  color: white;
  gap: 16px;

  p {
    font-size: 1.2rem;
    margin: 0;
  }
}
</style>