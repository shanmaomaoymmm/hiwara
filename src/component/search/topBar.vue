<script setup lang="ts">
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { insertSearchHistory } from '../../core/database';

const { t } = useI18n();

const props = defineProps<{
  keyword?: string;
}>();

const emit = defineEmits<{
  (e: 'back'): void;
  (e: 'search', keyword: string): void;
}>();

const searchText = ref('');

// 监听 keyword 变化，同步到输入框（immediate 以支持从标签点击跳转进入时显示初始关键词）
watch(() => props.keyword, (newKeyword) => {
  if (newKeyword !== undefined) {
    searchText.value = newKeyword;
  }
}, { immediate: true });

const handleBack = () => {
  emit('back');
};

// 执行搜索
const handleSearch = async () => {
  const keyword = searchText.value.trim();
  if (!keyword) {
    console.log('搜索关键词为空');
    return;
  }
  
  console.log('执行搜索:', keyword);
  
  // 保存搜索历史到数据库（异常独立捕获）
  try {
    await insertSearchHistory(keyword);
    console.log('搜索历史已保存:', keyword);
  } catch (error) {
    console.error('保存搜索历史失败:', error);
  }
  
  // 通知父组件切换到 loading 状态并传递关键词
  emit('search', keyword);
};

// 处理回车键
const handleKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Enter') {
    handleSearch();
  }
};
</script>

<template>
  <div class="top-view">
    <div class="goback" @click="handleBack">
      <font-awesome-icon icon="fa-solid fa-angle-left" />
    </div>
    <div class="search">
      <input 
        type="text" 
        v-model="searchText"
        @keydown="handleKeydown"
        :placeholder="t('search.placeholder')"
      >
      <span class="icon">
        <font-awesome-icon icon="fa-solid fa-magnifying-glass" />
      </span>
    </div>
    <div class="submit-btn" @click="handleSearch">
      {{ t('search.submit') }}
    </div>
  </div>
</template>

<style lang="scss" scoped>
.top-view {
  background-color: var(--color-primary-90);
  backdrop-filter: blur(10px);
  height: calc(60px + env(safe-area-inset-top, 0));
  width: 100%;
  padding: env(safe-area-inset-top, 0) env(safe-area-inset-right, 0) 0 env(safe-area-inset-left, 0);
  display: flex;
}

.goback {
  width: 45px;
  height: 60px;
  color: var(--color-text-on-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  user-select: none;
  font-size: 1.4rem;
}

.search {
  flex: 1;
  display: flex;
  align-items: center;
  user-select: none;
  cursor: pointer;
  position: relative;

  input {
    background-color: var(--color-bg-card);
    border-radius: 30px;
    flex: 1;
    height: 32px;
    outline: none;
    padding: 0 10px 0 36px;
    font-size: 0.9rem;
    line-height: 32px;
    border: none;
    width: 100%;
    color: var(--color-text-primary);

    &::placeholder {
      color: var(--color-text-placeholder);
    }
  }

  .icon {
    position: absolute;
    left: 10px;
    top: 50%;
    transform: translateY(-50%);
    color: var(--color-text-muted);
    font-size: 14px;
    pointer-events: none;
  }
}

.submit-btn {
  height: 60px;
  color: var(--color-text-on-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 1rem;
  padding: 0 14px 0 10px;
}
</style>
