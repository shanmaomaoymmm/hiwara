<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { showShortToast } from '../core/toast'
import { useKeyboardOffset } from '../composables/useKeyboardOffset'

const { t } = useI18n()

const props = defineProps<{
  contentId: string
  postComment: (contentId: string, body: string, parentId?: string) => Promise<any>
  replyTo?: { id: string; userName: string } | null
}>()

const emit = defineEmits<{
  posted: [comment: any]
  cancelReply: []
  openSyntax: []
}>()

const commentContent = ref('')
const isFocused = ref(false)
const showExpanded = ref(false)
const sending = ref(false)

// 软键盘弹出时仅抬升评论输入组件（配合原生 adjustNothing），页面其余内容保持不动
const { keyboardOffset } = useKeyboardOffset()

async function handleSend() {
  if (!commentContent.value.trim() || sending.value) return
  sending.value = true
  try {
    const res = await props.postComment(props.contentId, commentContent.value, props.replyTo?.id || undefined)
    if (res.ok) {
      emit('posted', res.data)
      commentContent.value = ''
      showExpanded.value = false
      showShortToast(t('comment.publishSuccess'))
    } else {
      showShortToast(t('comment.publishFailed'))
    }
  } catch (error) {
    console.error('发送评论失败:', error)
    showShortToast(t('comment.publishFailed'))
  } finally {
    sending.value = false
  }
}

function handleFocus() {
  isFocused.value = true
  showExpanded.value = true
}

function handleBlur() {
  isFocused.value = false
}

function handleOverlayClick() {
  showExpanded.value = false
  emit('cancelReply')
}

function handleCancelReply() {
  emit('cancelReply')
}

function handleSyntaxClick() {
  emit('openSyntax')
}
</script>

<template>
  <!-- 半透明遮罩 -->
  <Transition name="overlay">
    <div v-if="showExpanded" class="overlay" @click="handleOverlayClick"></div>
  </Transition>

  <div class="comment-input-area" :class="{ expanded: showExpanded }"
    :style="keyboardOffset ? { transform: `translateY(-${keyboardOffset}px)` } : undefined">
    <div v-if="replyTo" class="reply-hint">
      <span>{{ t('comment.replyTo', { name: replyTo.userName }) }}</span>
      <font-awesome-icon class="cancel-reply-btn" icon="fa-solid fa-xmark" @click="handleCancelReply" />
    </div>
    <div>
      <v-textarea v-model="commentContent" :label="t('comment.inputPlaceholder')" :rows="showExpanded ? 6 : 1" density="compact" hide-details
        variant="outlined" no-resize color="#00796B" @focus="handleFocus" @blur="handleBlur"></v-textarea>
    </div>
    <div v-show="showExpanded" class="btns">
      <font-awesome-icon class="btn syntax-btn" icon="fa-solid fa-circle-question" @click="handleSyntaxClick" />
      <v-btn color="#00796B" class="btn send-btn" :loading="sending" :disabled="sending" @click="handleSend">{{ t('comment.send') }}</v-btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.overlay {
  position: absolute;
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

.comment-input-area {
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

  .reply-hint {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 4px 0 8px 0;
    font-size: 0.85rem;
    color: var(--color-primary);

    .cancel-reply-btn {
      cursor: pointer;
      font-size: 1.1rem;
      color: var(--color-text-muted-light);

      &:hover {
        color: var(--color-text-secondary);
      }
    }
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

    .send-btn {
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
