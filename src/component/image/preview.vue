<script setup lang="ts">
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { ai } from '../../core/store';
import { getImageIwara } from '../../core/api';
import notImg from '../../static/img/not-img.jpg'
import iwaraSVG from '../../assets/svg/iwara.svg'

const aiStore = ai();
const { t } = useI18n();

interface ImageFile {
  id: string;
  name: string;
  width: number;
  height: number;
}
interface ImgPreviewProps {
  pid: string;
  images: ImageFile[]; // 插画图片URL数组
}

const props = defineProps<ImgPreviewProps>();
const emit = defineEmits(['resolution', 'fullScreen']);

// 图片展开状态
const imageExpand = ref(false);
// 处理后的图片URL数组
const processedImages = ref<string[]>([]);
// 加载状态
const loading = ref(false);
// 第一张图片ref
const firstImg = ref<HTMLImageElement>();

// 判断是否为服务器URL（需要特殊处理）
const isServerUrl = (url: string): boolean => {
  return url.startsWith('http://') || url.startsWith('https://');
};

// 处理单个图片文件对象
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

// 组件卸载时清理Blob URL
onMounted(() => {
  // 初始加载已在watch中处理
});

const onImageLoaded = () => {
  const realImgElement = firstImg.value;
  if (realImgElement) {
    const width = realImgElement.naturalWidth;
    const height = realImgElement.naturalHeight;
    // console.log(`Image loaded: ${width}x${height}`);
    emit('resolution', { width, height });
  }
};

// 全屏大图
function fullScreen(num: number = 0) {
  if (processedImages.value.length <= 1)
    emit('fullScreen', num);
  else {
    if (imageExpand.value)
      emit('fullScreen', num);
    else
      imageExpand.value = true;
  }
}
</script>

<template>
  <div class="imgPreview">
    <!-- 主图 -->
    <v-img cover :src="processedImages[0]" @load="onImageLoaded" ref="firstImg" @click="fullScreen(0)"
      :style="{ aspectRatio: `${props.images[0].width}/${props.images[0].height}` }">
      <template v-slot:placeholder>
        <div class="placeholder">
          <img :src="iwaraSVG" class="img" />
        </div>
      </template>
      <template v-slot:error>
        <v-img cover :src="notImg" />
      </template>
    </v-img>
    <!-- 额外的图片（展开时显示） -->
    <div v-if="imageExpand && processedImages.length > 1">
      <v-img v-for="(img, index) in processedImages.slice(1)" :key="index" cover :src="img"
        @click="fullScreen(index + 1)">
        <template v-slot:placeholder>
          <div class="placeholder">
            <img :src="iwaraSVG" class="img" />
          </div>
        </template>
        <template v-slot:error>
          <v-img cover :src="notImg" />
        </template>
      </v-img>
    </div>
    <!-- 展开/收起按钮（只有多张图片时才显示） -->
    <span v-if="processedImages.length > 1" class="expand-btn" @click="imageExpand = !imageExpand">
      {{ imageExpand ? t('imageView.collapse') : t('imageView.expandAll') }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
.imgPreview {
  width: 100%;
  position: relative;

  .expand-btn {
    color: var(--color-text-on-image);
    text-shadow: var(--shadow-image-text);
    display: inline-block;
    position: absolute;
    right: 0;
    bottom: 0;
    padding: 6px 10px;
    font-size: 0.9rem;
    user-select: none;
    cursor: pointer;
  }
}

.placeholder {
  overflow: hidden;
  width: 100%;
  height: 100%;
  background-color: var(--color-bg-placeholder);
  display: flex;
  justify-content: center;
  align-items: center;

  .img {
    width: 120px;
  }
}
</style>