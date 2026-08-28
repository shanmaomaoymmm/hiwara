<script setup lang="ts">
import { ref, watch, computed, onUnmounted } from 'vue';
import { Swiper, SwiperSlide } from 'swiper/vue';
import { Navigation } from 'swiper/modules';
import type { Swiper as SwiperType } from 'swiper';
import { ai } from '../../core/store';
import { getImageIwara } from '../../core/api';
import placeholderImg from '../../static/img/placeholder.png'
import notImg from '../../static/img/not-img.jpg'
import iwaraSVG from '../../assets/svg/iwara.svg'

const aiStore = ai();
import 'swiper/swiper-bundle.css';

interface ImageFile {
  id: string;
  name: string;
  width: number;
  height: number;
}

const props = defineProps<{
  pid: string;
  images: ImageFile[];
}>();

const emit = defineEmits(['resolution', 'fullScreen']);

const processedImages = ref<string[]>([]);
const currentIndex = ref(1);
const modules = [Navigation];
const swiperNavigation: any = { enabled: true };
let swiperInstance: SwiperType | null = null;
const showButtons = ref(false);
let prevButton: HTMLElement | null = null;
let nextButton: HTMLElement | null = null;
// iwaraSVG 浮层控制：首图加载完成后隐藏
const showOverlay = ref(true);

const isServerUrl = (url: string): boolean => {
  return url.startsWith('http://') || url.startsWith('https://');
};

const processImageFile = async (file: ImageFile): Promise<string> => {
  try {
    // 非全屏预览使用 large 尺寸，文件名固定为 {id}.jpg（iwara 会将该变体转为 jpg）
    const url = `https://i.iwara.tv/image/large/${file.id}/${file.id}.jpg`;
    return await getImageIwara(url, aiStore.value);
  } catch (error) {
    console.error('Failed to load image:', file, error);
    return '';
  }
};

const loadImages = async () => {
  if (!props.images || props.images.length === 0) {
    processedImages.value = [];
    return;
  }

  try {
    const results = await Promise.all(props.images.map(processImageFile));
    processedImages.value = results;
  } catch (error) {
    console.error('Failed to load images:', error);
    processedImages.value = [];
  }
};

watch(() => props.images, () => {
  showOverlay.value = true;
  loadImages();
}, { immediate: true });

const onImageLoaded = (e: any) => {
  // 从原生 img 事件获取图片实际分辨率
  const img = e?.target as HTMLImageElement;
  if (img?.naturalWidth) {
    emit('resolution', { width: img.naturalWidth, height: img.naturalHeight });
  }
  requestAnimationFrame(() => {
    showOverlay.value = false;
  });
};

const onSwiper = (swiper: SwiperType) => {
  swiperInstance = swiper;
  currentIndex.value = 1;

  setTimeout(() => {
    const container = swiper.el;
    prevButton = container.querySelector('.swiper-button-prev');
    nextButton = container.querySelector('.swiper-button-next');

    if (prevButton && nextButton) {
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

const onSlideChange = (swiper: SwiperType) => {
  currentIndex.value = swiper.activeIndex + 1;
};

const showPrevButton = computed(() => {
  return currentIndex.value > 1;
});

const showNextButton = computed(() => {
  return currentIndex.value < processedImages.value.length;
});

const handleImageClick = (index: number) => {
  emit('fullScreen', index);
};

const changeSwiper = (num: number) => {
  if (!swiperInstance || num < 0 || num >= processedImages.value.length) {
    console.warn('Invalid slide index or swiper not ready:', num);
    return;
  }

  swiperInstance.slideTo(num, 0);

  requestAnimationFrame(() => {
    currentIndex.value = num + 1;
  });
};

onUnmounted(() => {
  if (prevButton && nextButton) {
  }
});

defineExpose({
  changeSwiper
});
</script>

<template>
  <div class="preview-landscape">
    <Swiper v-if="processedImages.length > 0" :modules="modules" :navigation="swiperNavigation" :slides-per-view="1"
      :space-between="0" class="swiper-container" @swiper="onSwiper" @slide-change="onSlideChange">
      <SwiperSlide v-for="(img, index) in processedImages" :key="index">
        <div class="slide-content" @click="handleImageClick(index)">
          <v-img :src="img" contain class="preview-image" max-height="100vh" max-width="100vw" @load="onImageLoaded">
            <template v-slot:placeholder>
              <v-img cover :src="placeholderImg" class="placeholder-img"></v-img>
            </template>
            <template v-slot:error>
              <v-img cover :src="notImg" />
            </template>
          </v-img>
        </div>
      </SwiperSlide>
    </Swiper>

    <div class="bottom-indicator" v-if="processedImages.length > 1">
      <span class="page-number">{{ currentIndex }} / {{ processedImages.length }}</span>
    </div>

    <!-- iwaraSVG 浮层：叠在 Swiper 上面，首图加载完成后渐隐 -->
    <div class="loading-overlay" :class="{ 'is-hidden': !showOverlay }">
      <img :src="iwaraSVG" class="loading-icon" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.preview-landscape {
  width: 100%;
  height: 100%;
  background-color: #000;
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  user-select: none;
  overflow: hidden;
  isolation: isolate;
}

.loading-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 500;
  background-color: var(--color-bg-placeholder);
  display: flex;
  justify-content: center;
  align-items: center;
  opacity: 1;
  transition: opacity 0.25s ease;
  pointer-events: none;

  .loading-icon {
    width: 120px;
  }
}

.loading-overlay.is-hidden {
  opacity: 0;
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
  cursor: pointer;

  .preview-image {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
  }

  .placeholder-img {
    opacity: 0.3;
    width: 100%;
    height: 100%;
  }
}

.bottom-indicator {
  position: absolute;
  bottom: 12px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 400;
  color: #fff;
  filter: drop-shadow(1px 1px 2px rgba(0, 0, 0, 0.8));
  display: flex;
  justify-content: center;
  align-items: center;

  .page-number {
    font-size: 0.85rem;
    font-weight: 500;
    user-select: none;
    background-color: rgba(0, 0, 0, 0.5);
    padding: 4px 12px;
    border-radius: 12px;
  }
}
</style>
