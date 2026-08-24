<script setup lang="ts">
import { ref, nextTick, onMounted, onUnmounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { ai } from '../../core/store';
import { getImageComments, getImageCommentReplies, getImageIwara, postImageComment } from '../../core/api';
import errorHuawu from '../errorHuawu.vue';
import loadingHuawu from '../loadingHuawu.vue';
import { showShortToast } from '../../core/toast';

const aiStore = ai();
const { t } = useI18n();
import defaultAvatarImg from '../../static/img/avatar-default.jpg';
import avatarPlaceholderImg from '../../static/img/avatar-placeholder.png';
import avatarErrorImg from '../../static/img/avatar-error.png';
import CommentInput from '../CommentInput.vue';
import ForumSyntaxGuide from '../ForumSyntaxGuide.vue';

interface CommentUser {
  id: string
  name: string
  username: string
  avatar: {
    id: string
    path: string
    name: string
  } | null
}

interface Comment {
  id: string
  approved: boolean
  body: string
  numReplies: number
  parent: string | null
  createdAt: string
  updatedAt: string
  user: CommentUser
  imageId: string
}

const emit = defineEmits(['close']);

// 全屏状态
const isFullscreen = ref(false);

// 接收图片ID prop
const props = defineProps<{
  pid: string
  isAI?: boolean // 是否AI站（由页面基于 siteId 判定），未传时回退到全局开关
}>();

const commentList = ref<Comment[]>([])
const commentListRef = ref<HTMLElement>()

let commentPage = 0
const commentMore = ref(false) // 评论加载到底
let scrollTop = 0

// 加载更多失败标记
const loadMoreFailed = ref(false) // 评论加载失败

// 聚合状态：'failed' | 'empty' | 'loading' | 'success'
type CommentState = 'failed' | 'empty' | 'loading' | 'success'
const commentState = ref<CommentState>('loading')

// 头像 URL 缓存 (userId -> avatarUrl)
const avatarUrlMap = ref<Record<string, string>>({})

// 回复目标
const replyTarget = ref<{ id: string; userName: string } | null>(null)

// 语法说明
const showSyntaxGuide = ref(false)

// 加载单个用户头像
async function loadUserAvatar(user: CommentUser): Promise<string> {
  const userId = user.id

  // 如果已经缓存，直接返回
  if (avatarUrlMap.value[userId]) {
    return avatarUrlMap.value[userId]
  }

  let avatarUrl: string

  try {
    // 没有头像信息，使用默认头像
    if (!user.avatar) {
      avatarUrl = defaultAvatarImg
    } else {
      // 先拼接头像URL
      const avatarImageUrl = `https://i.iwara.tv/image/avatar/${user.avatar.id}/${user.avatar.name}`
      // 通过 API 获取图片数据
      avatarUrl = await getImageIwara(avatarImageUrl, props.isAI ?? aiStore.value)
    }
  } catch (error) {
    console.error('Failed to load avatar:', error)
    avatarUrl = avatarErrorImg
  }

  avatarUrlMap.value[userId] = avatarUrl
  return avatarUrl
}

// 批量加载新评论的头像
async function loadAvatarsForComments(comments: Comment[]) {
  for (const comment of comments) {
    await loadUserAvatar(comment.user)
  }
}

// 评论发布成功回调
function handleCommentPosted(newComment: any) {
  // 加载新评论的头像
  loadUserAvatar(newComment.user)
  // 判断是否为回复
  const parentId = newComment.parent?.id || newComment.parent
  if (parentId && typeof parentId === 'string') {
    // 是回复：插入到对应评论的回复列表中
    if (!repliesMap.value[parentId]) {
      repliesMap.value[parentId] = []
    }
    repliesMap.value[parentId].unshift(newComment)
    // 更新评论的回复数（在评论列表中查找并递增）
    const parentComment = commentList.value.find(c => c.id === parentId)
    if (parentComment) {
      parentComment.numReplies++
    }
    // 自动展开回复
    repliesExpanded.value[parentId] = true
  } else {
    // 是顶层评论：插入到列表顶部
    commentList.value.unshift(newComment)
    // 更新状态
    if (commentState.value === 'empty') {
      commentState.value = 'success'
    }
  }
  replyTarget.value = null
}

function handleReply(comment: Comment) {
  replyTarget.value = {
    id: comment.id,
    userName: comment.user.name || comment.user.username
  }
}

function handleCancelReply() {
  replyTarget.value = null
}

function handleOpenSyntax() {
  showSyntaxGuide.value = true
}

function handleCloseSyntax() {
  showSyntaxGuide.value = false
}

// 初始获取评论列表数据
function initGetComments() {
  if (commentState.value === 'loading') {
    getCommentList().then((res) => {
      if (res.length > 0)
        commentState.value = 'success';
      else
        commentState.value = 'empty';
    }).catch(() => {
      commentState.value = 'failed';
    });
  }
}

// 刷新数据
function refreshData() {
  // 清空评论列表数据
  commentList.value = [];
  commentPage = 0;
  commentMore.value = false;
  loadMoreFailed.value = false;
  commentState.value = 'loading';

  // 获取评论列表数据
  getCommentList().then((res) => {
    if (res.length > 0)
      commentState.value = 'success';
    else
      commentState.value = 'empty';
  }).catch(() => {
    commentState.value = 'failed';
  });
}

// 点击错误图片刷新数据
function handleErrorClick() {
  refreshData();
}

// 下滑列表到底追加数据
async function handleScrollToEnd({ done }: any) {
  getCommentList().then((res) => {
    if (res.length > 0) done('ok');
    else {
      commentMore.value = true;
      done('empty');
    }
  }).catch(() => {
    loadMoreFailed.value = true;
    done('error');
  });
}

// 获取评论列表
async function getCommentList(): Promise<any> {
  if (!props.pid) {
    throw new Error('图片ID不存在');
  }

  try {
    const res = await getImageComments(props.pid, commentPage, props.isAI ?? aiStore.value);
    if (res.ok) {
      if (res.data.results && res.data.results.length > 0) {
        const newComments = res.data.results.map((item: any) => {
          return {
            id: item.id,
            approved: item.approved,
            body: item.body,
            numReplies: item.numReplies,
            parent: item.parent,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            user: item.user,
            imageId: item.imageId
          };
        });
        // 追加数据
        commentList.value = [...commentList.value, ...newComments];
        // 批量加载新评论的头像
        await loadAvatarsForComments(newComments);
        commentPage++;
        // 返回数据
        return newComments;
      } else {
        // 返回空数组
        return [];
      }
    }
    throw new Error(`状态码：${res.status}, 错误信息：${res.statusText}`);
  } catch (error) {
    console.error(`获取评论列表失败:`, error);
    showShortToast(t('common.fetchCommentsFailed'));
    throw error;
  }
}

// 监听图片ID变化
watch(() => props.pid, (newVal) => {
  if (newVal) {
    // 重置分页状态
    commentPage = 0;
    commentMore.value = false;
    commentList.value = [];
    avatarUrlMap.value = {};
    loadMoreFailed.value = false;
    commentState.value = 'loading';
    replyTarget.value = null;
    showSyntaxGuide.value = false;
    // 重新初始化加载
    initGetComments();
  }
}, { immediate: true })

const expandedMap = ref<Record<string, boolean>>({})

// 回复展开相关
const repliesMap = ref<Record<string, Comment[]>>({})
const repliesLoading = ref<Record<string, boolean>>({})
const repliesExpanded = ref<Record<string, boolean>>({})

async function toggleReplies(comment: Comment) {
  const id = comment.id
  if (repliesExpanded.value[id]) {
    repliesExpanded.value[id] = false
    return
  }
  if (repliesMap.value[id] && repliesMap.value[id].length > 0) {
    repliesExpanded.value[id] = true
    return
  }
  repliesLoading.value[id] = true
  try {
    const res = await getImageCommentReplies(props.pid, id, 0, 50, props.isAI ?? aiStore.value)
    if (res.ok && res.data.results) {
      const replies = res.data.results.map((item: any) => ({
        id: item.id,
        approved: item.approved,
        body: item.body,
        numReplies: item.numReplies || 0,
        parent: item.parent,
        createdAt: item.createdAt,
        updatedAt: item.updatedAt,
        user: item.user,
        imageId: item.imageId
      }))
      repliesMap.value[id] = replies
      await loadAvatarsForComments(replies)
      repliesExpanded.value[id] = true
    } else {
      showShortToast(t('common.fetchRepliesFailed'))
    }
  } catch (error) {
    console.error('获取评论回复失败:', error)
    showShortToast(t('common.fetchRepliesFailed'))
  } finally {
    repliesLoading.value[id] = false
  }
}

const needToggle = (content: string) => {
  return content.length > 180
}

const toggleExpand = (id: string) => {
  expandedMap.value[id] = !expandedMap.value[id]
}

// 格式化日期
function formatDate(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diff = now.getTime() - date.getTime()

  const minute = 60 * 1000
  const hour = 60 * minute
  const day = 24 * hour
  const month = 30 * day
  const year = 365 * day

  if (diff < minute) {
    return t('comment.justNow')
  } else if (diff < hour) {
    const mins = Math.floor(diff / minute)
    if (mins <= 1) {
      return t('comment.minuteAgo', { n: mins })
    }
    return t('comment.minutesAgo', { n: mins })
  } else if (diff < day) {
    return t('comment.hoursAgo', { n: Math.floor(diff / hour) })
  } else if (diff < month) {
    return t('comment.daysAgo', { n: Math.floor(diff / day) })
  } else if (diff < year) {
    return t('comment.monthsAgo', { n: Math.floor(diff / month) })
  } else {
    return t('comment.yearsAgo', { n: Math.floor(diff / year) })
  }
}

// 保存滚动条位置
function handleScroll(e: Event): void {
  scrollTop = (e.target as HTMLElement).scrollTop
}

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

// 关闭评论
const handleClose = async () => {
  await exitFullscreen();
  emit('close');
};

defineExpose({
  enterFullscreen
});

// 组件挂载时监听 popstate 事件
onMounted(() => {
  window.addEventListener('popstate', handlePopState);
});

onUnmounted(() => {
  // 移除 popstate 监听
  window.removeEventListener('popstate', handlePopState);
  // 确保退出全屏状态
  if (isFullscreen.value) {
    exitFullscreen();
  }
});
</script>
<template>
  <div class="comment-container">
    <div class="topBar">
      <div class="goback" @click="handleClose">
        <font-awesome-icon icon="fa-solid fa-angle-left" />
      </div>
      <div class="label">
        评论
      </div>
    </div>

    <div class="commentView">
      <!-- 语法说明覆盖层：填满整个评论视窗 -->
      <Transition name="syntax">
        <div v-if="showSyntaxGuide" class="syntax-overlay">
          <ForumSyntaxGuide @close="handleCloseSyntax" />
        </div>
      </Transition>

      <div v-if="commentState === 'failed'" class="empty-state" @click="handleErrorClick">
        <errorHuawu>{{ t('comment.loadFailed') }}</errorHuawu>
      </div>
      <div v-else-if="commentState === 'empty'" class="empty-state" @click="handleErrorClick">
        <errorHuawu>{{ t('comment.noComment') }}</errorHuawu>
      </div>
      <div v-else-if="commentState === 'loading'" class="empty-state">
        <loadingHuawu>{{ t('comment.loading') }}</loadingHuawu>
      </div>
      <v-infinite-scroll class="commentList" v-else color="#00796B" @load="handleScrollToEnd" :disabled="commentMore"
        @scroll="handleScroll" ref="commentListRef">
        <template v-for="item in commentList" :key="item.id">
          <div class="commentItem">
            <div class="avatar">
              <v-img :src="avatarUrlMap[item.user.id] || avatarPlaceholderImg" cover height="40px" width="40px"
                style="border-radius: 50%;">
                <template v-slot:placeholder>
                  <v-img height="100%" width="100%" :src="avatarPlaceholderImg" cover style="border-radius: 50%;"></v-img>
                </template>
              </v-img>
            </div>
            <div class="elements">
              <div class="username">{{ item.user.name || item.user.username }}</div>
              <div class="content-wrapper">
                <div class="content" :class="{ fold: needToggle(item.body) && !expandedMap[item.id] }">
                  {{ item.body }}
                </div>
                <!-- 底部操作栏：始终显示 -->
                <div class="action-bar">
                  <!-- 发布时间 -->
                  <div class="created-time">{{ formatDate(item.createdAt) }}&nbsp;&nbsp;</div>
                  <!-- 回复数 + 回复按钮 -->
                  <div class="reply-section">
                    <div v-if="item.numReplies > 0" class="reply-count" @click="toggleReplies(item)">{{ t('comment.replyCount', { n: item.numReplies }) }}&nbsp;&nbsp;</div>
                    <div class="reply-btn" @click="handleReply(item)">
                      {{ t('comment.reply') }}
                    </div>
                  </div>
                  <!-- 展开/收起按钮 (仅长文本显示) -->
                  <div class="toggle-btn" v-if="needToggle(item.body)" @click="toggleExpand(item.id)">
                    {{ expandedMap[item.id] ? t('comment.collapse') : t('comment.expand') }}
                  </div>
                </div>
              </div>
            </div>
          </div>
          <!-- 回复列表：显示在当前评论和下一项之间 -->
          <div v-if="repliesExpanded[item.id] || repliesLoading[item.id]" class="replies-wrapper">
            <!-- 加载中：简单转圈 -->
            <div v-if="repliesLoading[item.id]" class="replies-loading">
              <div class="spinner"></div>
              <span>{{ t('comment.loadingReplies') }}</span>
            </div>
            <!-- 回复列表 -->
            <template v-else>
              <div class="replyItem" v-for="reply in (repliesMap[item.id] || [])" :key="reply.id">
                <div class="reply-avatar">
                  <v-img :src="avatarUrlMap[reply.user.id] || avatarPlaceholderImg" cover height="40px" width="40px"
                    style="border-radius: 50%;">
                    <template v-slot:placeholder>
                      <v-img height="100%" width="100%" :src="avatarPlaceholderImg" cover style="border-radius: 50%;"></v-img>
                    </template>
                  </v-img>
                </div>
                <div class="reply-body">
                  <div class="reply-username">{{ reply.user.name || reply.user.username }}</div>
                  <div class="reply-content">{{ reply.body }}</div>
                  <div class="reply-created-time">{{ formatDate(reply.createdAt) }}</div>
                </div>
              </div>
            </template>
          </div>
        </template>
        <template v-slot:error="{ props }">
          <div class="load-more-failed">
            <span>{{ t('comment.loadFailedHint') }}</span>
            <span class="retry-btn" v-bind=props>{{ t('comment.retry') }}</span>
          </div>
        </template>
        <template v-slot:empty>
          <div class="listEnd">
            {{ t('comment.endOfList') }}
          </div>
        </template>
      </v-infinite-scroll>

      <!-- 评论输入组件 -->
      <CommentInput
        :content-id="props.pid"
        :post-comment="(pid: string, body: string, parentId?: string) => postImageComment(pid, body, props.isAI ?? aiStore.value, parentId)"
        :reply-to="replyTarget"
        @posted="handleCommentPosted"
        @cancel-reply="handleCancelReply"
        @open-syntax="handleOpenSyntax"
      />
    </div>
  </div>
</template>
<style lang="scss" scoped>
.comment-container {
  background-color: var(--color-bg-page);
  height: 100vh;
  width: 100vw;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.topBar {
  position: fixed;
  top: 0;
  z-index: 400;
  padding-top: env(safe-area-inset-top, 0);
  height: calc(env(safe-area-inset-top, 0) + 60px);
  background-color: var(--color-primary-90);
  color: var(--color-text-on-primary);
  display: flex;
  align-items: center;
  user-select: none;
  flex-shrink: 0;
  width: 100%;

  .goback {
    padding: 0 16px;
    height: 100%;
    display: flex;
    align-items: center;
    cursor: pointer;

    svg {
      font-size: 1.5rem;
    }

    &:active {
      opacity: 0.7;
    }
  }

  .label {
    font-size: 1.2rem;
    font-weight: 500;
  }
}

.commentView {
  flex: 1;
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
  padding-top: calc(env(safe-area-inset-top, 0) + 60px);
}

.listEnd {
  color: var(--color-text-muted-light);
  padding: 4px 0;
}

.load-more-failed {
  text-align: center;
  padding: 10px 0;
  color: var(--color-text-muted-light);
  font-size: 0.9rem;

  .retry-btn {
    color: var(--color-retry-btn);
    cursor: pointer;

    &:hover {
      opacity: 0.8;
      text-decoration: underline;
    }
  }
}

.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.commentList {
  flex: 1;
  overflow-y: auto;
}

.commentItem {
  display: flex;
  padding: 10px;
  border-bottom: 1px solid var(--color-border-light);

  .avatar {
    flex-shrink: 0;

    :deep(.v-img) {
      border-radius: 50%;
      background-color: var(--color-bg-avatar);
    }
  }

  .elements {
    margin-left: 10px;
    flex: 1;
    min-width: 0;

    .username {
      font-size: 0.8rem;
      color: var(--color-text-muted);
    }

    .content-wrapper {
      margin-top: 5px;
      min-width: 0;
    }

    .content {
      font-size: 0.9rem;
      line-height: 1.5em;
      text-align: justify;
      overflow-wrap: anywhere;
      color: var(--color-text-primary);

      &.fold {
        display: -webkit-box;
        -webkit-box-orient: vertical;
        -webkit-line-clamp: 6;
        line-clamp: 6;
        overflow: hidden;
        position: relative;

        &::after {
          content: '...';
          position: absolute;
          right: 0;
          bottom: 0;
          padding-left: 5px;
          background: var(--color-bg-card);
        }
      }
    }

    /* 底部操作栏 */
    .action-bar {
      display: grid;
      grid-template-columns: auto 1fr auto;
      align-items: center;
      margin-top: 2px;
      font-size: 0.8rem;

      .created-time {
        color: var(--color-text-muted);
      }

      .reply-section {
        display: flex;
        align-items: center;
        color: var(--color-text-muted);

        .reply-btn {
          cursor: pointer;
          color: var(--color-primary);
          margin-left: auto;
        }
      }

      .toggle-btn {
        color: var(--color-primary);
        cursor: pointer;
        flex-shrink: 0;

        &:hover {
          opacity: 0.8;
        }
      }
    }
  }
}

/* 回复列表展开/收起 */
.replies-wrapper {
  padding: 8px 10px 8px 40px;
  background: var(--color-bg-code-block);
  border-bottom: 1px solid var(--color-border-light);
}

.replies-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 0;
  color: var(--color-text-muted-light);
  font-size: 0.85rem;
}

/* 简易转圈动画 */
.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid var(--color-border);
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* 单个回复项 */
.replyItem {
  display: flex;
  padding: 8px 0;
  border-bottom: 1px solid var(--color-border-lighter);

  &:last-child {
    border-bottom: none;
  }

  .reply-avatar {
    flex-shrink: 0;

    :deep(.v-img) {
      border-radius: 50%;
      background-color: var(--color-bg-avatar);
    }
  }

  .reply-body {
    margin-left: 10px;
    flex: 1;
    min-width: 0;

    .reply-username {
      font-size: 0.8rem;
      color: var(--color-text-muted);
    }

    .reply-content {
      margin-top: 5px;
      font-size: 0.9rem;
      line-height: 1.5em;
      text-align: justify;
      overflow-wrap: anywhere;
      color: var(--color-text-primary);
    }

    .reply-created-time {
      margin-top: 2px;
      font-size: 0.8rem;
      color: var(--color-text-muted);
    }
  }
}

/* 可点击的回复计数 */
.reply-count {
  cursor: pointer;
  color: var(--color-primary);

  &:hover {
    opacity: 0.8;
  }
}

/* 语法说明覆盖层 - 填满整个评论视窗 */
.syntax-enter-active {
  transition: transform 0.3s ease;
}

.syntax-leave-active {
  transition: transform 0.25s ease;
}

.syntax-enter-from,
.syntax-leave-to {
  transform: translateY(100%);
}

.syntax-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: var(--color-bg-card);
  z-index: 2000;
  display: flex;
  flex-direction: column;
  overflow: hidden;

  :deep(.syntax-drawer) {
    position: static;
    height: 100%;
    border-radius: 0;
    z-index: auto;
    display: flex;
    flex-direction: column;
  }

  :deep(.drawer-body) {
    flex: 1;
    overflow-y: auto;
  }
}
</style>
