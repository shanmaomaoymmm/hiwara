<script setup lang="ts">
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import ForumSyntaxGuide from '../ForumSyntaxGuide.vue';
import { replyForumPost } from '../../core/api';
import { showShortToast } from '../../core/toast';
import { useKeyboardOffset } from '../../composables/useKeyboardOffset';

const { t } = useI18n();

const props = defineProps<{
  threadId: string
}>()

const replyContent = ref('');
const isFocused = ref(false);
const showExpanded = ref(false);
const showSyntaxDrawer = ref(false);
const sending = ref(false);

// 软键盘弹出时仅抬升回复输入组件（配合原生 adjustNothing），页面其余内容保持不动
const { keyboardOffset } = useKeyboardOffset();

const emit = defineEmits<{
  posted: [reply: any]
}>()

async function handleSend() {
  if (!replyContent.value.trim() || sending.value) return;
  sending.value = true;
  try {
    const res = await replyForumPost(props.threadId, replyContent.value);
    replyContent.value = '';
    showExpanded.value = false;
    showShortToast('回复成功');
    emit('posted', res?.data);
  } catch (error) {
    showShortToast('回复失败');
  } finally {
    sending.value = false;
  }
}

function handleFocus() {
  isFocused.value = true;
  showExpanded.value = true;
}

function handleBlur() {
  isFocused.value = false;
}

function handleOverlayClick() {
  showExpanded.value = false;
}

function handleSyntaxClick() {
  showSyntaxDrawer.value = true;
}

function handleDrawerClose() {
  showSyntaxDrawer.value = false;
}
</script>

<template>
  <!-- 半透明遮罩 -->
  <Transition name="overlay">
    <div v-if="showExpanded" class="overlay" @click="handleOverlayClick"></div>
  </Transition>

  <!-- 语法说明抽屉遮罩 -->
  <Transition name="overlay">
    <div v-if="showSyntaxDrawer" class="drawer-overlay" @click="handleDrawerClose"></div>
  </Transition>

  <!-- 语法说明抽屉 -->
  <Transition name="drawer">
    <ForumSyntaxGuide v-if="showSyntaxDrawer" @close="handleDrawerClose" />
  </Transition>

  <div class="reply" :class="{ expanded: showExpanded }"
    :style="keyboardOffset ? { transform: `translateY(-${keyboardOffset}px)` } : undefined">
    <div>
      <v-textarea v-model="replyContent" label="评论" :rows="showExpanded ? 6 : 1" density="compact" hide-details
        variant="outlined" no-resize color="#00796B" @focus="handleFocus" @blur="handleBlur"></v-textarea>
    </div>
    <div v-show="showExpanded" class="btns">
      <font-awesome-icon class="btn syntax-btn" icon="fa-solid fa-circle-question" @click="handleSyntaxClick" />
      <v-btn color="#00796B" class="btn reply-btn" :loading="sending" :disabled="sending" @click="handleSend">发送</v-btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: var(--color-bg-overlay-light);
  z-index: 999;
}

.overlay-enter-active {
  transition: opacity 0.25s ease;
}

.overlay-leave-active {
  transition: opacity 0.2s ease;
}

.overlay-enter-from,
.overlay-leave-to {
  opacity: 0;
}

// 抽屉遮罩
.drawer-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: var(--color-bg-overlay);
  z-index: 1999;
}

// 抽屉过渡
.drawer-enter-active {
  transition: transform 0.3s ease;
}

.drawer-leave-active {
  transition: transform 0.25s ease;
}

.drawer-enter-from,
.drawer-leave-to {
  transform: translateY(100%);
}

.reply {
  position: relative;
  z-index: 1000;
  background-color: var(--color-bg-card);
  box-shadow: var(--shadow-bottom-bar);
  padding: 12px 12px calc(12px + env(safe-area-inset-bottom, 0)) 12px;
  /* 跟随软键盘弹出/收起平滑过渡，仅作用于输入组件自身 */
  transition: transform 0.2s ease;

  &.expanded {
    padding-top: 24px;
  }

  .btns {
    margin-top: 10px;

    .btn {
      color: var(--color-text-muted-light);
      cursor: pointer;
      user-select: none;
    }

    .syntax-btn {
      &:hover {
        color: var(--color-primary);
      }
    }

    .reply-btn {
      float: right;
    }
  }
}

:deep(.v-textarea) {
  .v-field {
    background-color: var(--color-bg-section);
    border-radius: 8px;

    .v-label {
      color: var(--color-text-placeholder) !important;
    }

    input, textarea {
      color: var(--color-text-primary) !important;
    }
  }
}
</style>
