<script setup lang="ts">
import notImg from '../static/img/not-img.jpg';
import lossImg from '../static/img/loss.png';
import iwaraSVG from '../assets/svg/iwara.svg'
import { computed, type PropType, ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { ai } from '../core/store';
import { getImageIwara } from '../core/api';
import { formatCardDate } from '../utils/dateFormat';

const aiStore = ai();
const router = useRouter();
const { t, locale } = useI18n()

// 定义卡片数据接口
interface CardData {
  id?: string;
  title?: string;
  img?: string;
  author?: string;
  time?: string;
  viewNum?: number;
  likeNum?: number;
  longNum?: number;
  isR18?: boolean;
}

const props = defineProps({
  type: { type: String, default: 'video' },
  data: { type: Object as PropType<CardData>, required: true },
  isAI: { type: Boolean, default: undefined }, // 由父组件传入时覆盖 store 值
});

// 检测 CJK 语言（使用 10^4 进制大数单位）
const isCJK = computed(() => {
  const loc = locale.value
  return loc === 'zh-Hans' || loc === 'zh-Hant' || loc === 'ja' || loc === 'ko'
})

// 根据语言构建数字单位数组（CJK: 10^4 进制; 其他: 10^3 进制）
const numberUnits = computed(() => {
  const cjkThresholds = [1, 1e4, 1e8, 1e12, 1e16, 1e20, 1e24, 1e28, 1e32, 1e36, 1e40, 1e44, 1e48]
  const westernThresholds = [1, 1e3, 1e6, 1e9, 1e12, 1e15, 1e18, 1e21, 1e24, 1e27, 1e30, 1e33, 1e36]
  const thresholds = isCJK.value ? cjkThresholds : westernThresholds

  return thresholds.map((value, index) => ({
    value,
    name: index === 0 ? '' : t(`card.numberUnit${index}`)
  }))
})

// 最大支持的数值
const maxSupportedValue = computed(() => {
  const lastUnit = numberUnits.value[numberUnits.value.length - 1]
  return (isCJK.value ? 10000 : 1000) * lastUnit.value
})

// 直接显示阈值（小于该值不进行单位转换）
const directThreshold = computed(() => isCJK.value ? 10000 : 1000)

// 数字格式化函数 - 支持多语言大数单位
const formatNumber = (num: number): string => {
  if (isNaN(num)) return '0'

  const units = numberUnits.value
  const maxVal = maxSupportedValue.value
  const threshold = directThreshold.value

  // 小于阈值直接显示
  if (num < threshold) {
    return num.toString()
  }

  // 超过最大支持范围显示∞
  if (num > maxVal) {
    return '∞'
  }

  // 从最大的单位开始查找合适的单位
  for (let i = units.length - 1; i >= 0; i--) {
    const unit = units[i]
    if (num >= unit.value) {
      const result = num / unit.value
      // 优化小数显示：如果是整数或者小数部分为0，则不显示小数点
      if (result === Math.floor(result)) {
        return Math.floor(result) + unit.name
      } else {
        // 保留一位小数，但如果小数部分为0则显示整数
        const rounded = Math.round(result * 10) / 10
        if (rounded === Math.floor(rounded)) {
          return Math.floor(rounded) + unit.name
        } else {
          return rounded.toFixed(1) + unit.name
        }
      }
    }
  }

  // 默认返回原数字（理论上不会到达这里）
  return num.toString()
}

// 时间格式化函数 - 将秒数转换为 hh:mm:ss 或 mm:ss 格式
const formatTime = (seconds: number): string => {
  // 如果不能解析为有效数字，返回默认值
  if (isNaN(seconds) || seconds < 0) {
    return '00:00';
  }

  // 计算时、分、秒
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  // 根据是否存在小时来确定格式
  if (hours > 0) {
    // 显示为 hh:mm:ss 格式
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  } else {
    // 显示为 mm:ss 格式
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
};

// 卡片日期显示（今天 hh:mm；今年 日期+hh:mm；跨年 仅日期，中日韩按各自语言习惯）
// 统一由 utils/dateFormat 处理

// 计算属性用于格式化显示的数字
const formattedViewNum = computed(() => formatNumber(props.data.viewNum ?? 0));
const formattedLikeNum = computed(() => formatNumber(props.data.likeNum ?? 0));
// 根据type决定是否格式化longNum：视频类型显示为时间格式，图像类型使用大数格式
const formattedLongNum = computed(() => {
  if (props.type === 'video') {
    // 视频类型，格式化为时间格式
    return formatTime(props.data.longNum ?? 0);
  } else {
    // 图像类型，使用数字格式化
    return formatNumber(props.data.longNum ?? 0);
  }
});

// 格式化后的时间显示
const formattedTime = computed(() => formatCardDate(props.data.time, locale.value));

// 处理图片源，初始状态如果有图片链接则显示空字符串，等待 API 加载
const displayImg = ref(props.data.img && props.data.img !== 'file-loss'
  ? '' // 初始为空，等待 API 加载完成
  : (props.data.img === 'file-loss' ? lossImg : notImg));

onMounted(async () => {
  if (props.data.img && props.data.img !== 'file-loss') {
    // 使用 API 获取图片，避免直接从网页获取导致的 403 错误
    try {
      displayImg.value = await getImageIwara(props.data.img, aiStore.value);
    } catch (error) {
      // console.error('Failed to load image via API:', error);
      // 如果 API 失败，尝试回退到直接 URL（可选，或者保持占位图/错误图）
      // 这里为了用户体验，如果 API 失败，可以选择不更新 displayImg 保持占位图，或者显示错误图
      // 根据原有逻辑 fallback to direct url，但通常直接 url 会 403，所以建议显示 notImg 或保持 placeholder
      displayImg.value = notImg;
    }
  }
});

async function clickCard() {
  // return
  if (!props.data.id) {
    console.error('缺少id');
    return;
  }
  const resolvedIsAI = props.isAI !== undefined ? props.isAI : aiStore.value;
  const queryIsAI = resolvedIsAI ? 'true' : 'false';
  if (props.type === 'video') {
    router.push({ path: `/player/${props.data.id}/${Math.random().toString(36).substring(2, 8)}`, query: { isAI: queryIsAI } });
  } else if (props.type === 'image') {
    router.push({ path: `/image/${props.data.id}`, query: { isAI: queryIsAI } });
  }
}
</script>

<template>
  <div class="card-button" v-ripple @click="clickCard">
    <!-- 修改 src 绑定逻辑，确保初始显示正确，并添加 transition 实现淡入效果 -->
    <v-img :src="displayImg" cover class="card-image" transition="fade-transition">
      <div class="info1">
        <div></div>
        <div class="isR18">
          <span v-if="props.data.isR18">
            R-18
          </span>
        </div>
        <div class="viewNum">
          <span v-if="props.type === 'video'">
            <font-awesome-icon icon="fa-regular fa-circle-play" />{{ formattedViewNum }}
          </span>
          <span v-else-if="props.type === 'image'">
            <font-awesome-icon icon="fa-regular fa-eye" />{{ formattedViewNum }}
          </span>
          &nbsp;
          <span>
            <font-awesome-icon icon="fa-regular fa-heart" />{{ formattedLikeNum }}
          </span>
        </div>
        <div class="longNum">
          <span v-if="!(props.type === 'image' && props.data.longNum as number <= 1)">
            {{ formattedLongNum }}
          </span>
        </div>
      </div>
      <template v-slot:placeholder>
        <div class="placeholder">
          <img :src="iwaraSVG" class="img" />
        </div>
      </template>
      <template v-slot:error>
        <img height="100%" :src="notImg" cover />
      </template>
    </v-img>
    <div class="title">
      <div>{{ props.data.title }}</div>
    </div>
    <div class="info2">
      <div class="content">
        <div class="author">
          <font-awesome-icon icon="fa-regular fa-user" />{{ props.data.author }}
        </div>
        <div class="time">
          {{ formattedTime }}
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.card-button {
  position: relative;
  height: 180px;
  width: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  background-color: var(--color-bg-card);
  box-shadow: var(--shadow-card);
  border-radius: 4px;
  cursor: pointer;
  user-select: none;
}

.card-image {
  // aspect-ratio: 16 / 10;
  flex: 1;
  cursor: pointer;
  user-select: none;
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
    width: 60px;
  }
}

.info1 {
  width: 100%;
  height: 100%;
  display: grid;
  grid-template-columns: repeat(2, 1fr);


  .isR18 {
    display: flex;
    justify-content: flex-end;
    align-items: start;
    padding: 6px;

    span {
      display: inline-block;
      background: var(--color-badge);
      text-shadow: var(--shadow-badge-text);
      font-size: 0.6rem;
      font-weight: 500;
      padding: 1px 4px;
      color: var(--color-text-on-dark);
      font-family: sans-serif;
    }
  }

  .viewNum {
    display: flex;
    justify-content: flex-start;
    align-items: end;
    padding: 6px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;

    span {
      display: inline-block;
      font-size: 0.7rem;
      color: var(--color-text-on-image);
      text-shadow: var(--shadow-image-text);

      svg {
        filter: var(--shadow-icon);
      }
    }
  }

  .longNum {
    display: flex;
    justify-content: flex-end;
    align-items: end;
    padding: 6px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;

    span {
      display: inline-block;
      font-size: 0.7rem;
      color: var(--color-text-on-image);
      text-shadow: var(--shadow-image-text);
    }
  }
}

.title {
  font-size: 1rem;
  height: 2rem;
  overflow: hidden;

  padding: 0 10px;
  display: flex;
  align-items: center;
  justify-self: start;
  color: var(--color-text-primary);

  div {
    text-overflow: ellipsis;
    white-space: nowrap;
    overflow: hidden;
  }
}

.info2 {
  padding: 0 10px;
  font-size: 0.8rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-self: start;

  .content {
    width: 100%;
    display: grid;
    grid-template-columns: repeat(2, 50%);

    div {
      color: var(--color-text-muted);
      font-size: 0.8rem;
      text-overflow: ellipsis;
      white-space: nowrap;
      overflow: hidden;
    }

    div:nth-child(2) {
      text-align: right;
    }
  }
}
</style>