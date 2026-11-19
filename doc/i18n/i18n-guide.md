# i18n 国际化使用指南

## 概述

本项目已集成 `vue-i18n@9` 实现国际化支持。语言配置存储在 SQLite 数据库的 `setup` 表中，通过 `setupStore` 管理。

## 语言代码规则（BCP 47 标准）

项目使用 **BCP 47 语言标签**标准，与 `src/views/setup/language.vue` 保持一致：

- `auto` - 跟随系统（自动检测浏览器语言）
- `en` - 英语 (English)
- `zh-Hans` - 简体中文 (简体中文)
- `zh-Hant` - 繁体中文 (繁體中文)
- `ja` - 日语 (日本語)
- `ko` - 韩语 (한국어)
- `fr` - 法语 (Français)
- `es` - 西班牙语 (Español)
- `pt` - 葡萄牙语 (Português)
- `de` - 德语 (Deutsch)
- `it` - 意大利语 (Italiano)
- `ru` - 俄语 (Русский)
- `uk` - 乌克兰语 (Українська)
- `th` - 泰语 (ภาษาไทย)
- `vi` - 越南语 (Tiếng Việt)
- `km` - 高棉语 (ភាសាខ្មែរ)
- `hi` - 印地语 (भाषा)
- `ar` - 阿拉伯语 (العربية)
- `he` - 希伯来语 (עברית)
- `bo` - 藏文 (བོད་ཡིག)
- `ug` - 维吾尔语 (ئۇيغۇر تىلى)
- `kk-Cyrl` - 哈萨克语（西里尔字母）(қазақ тілі)
- `kk-Arab` - 哈萨克语（阿拉伯字母）(قازاقشا)
- `mn-Cyrl` - 蒙古语（西里尔字母）(Монгол Кирилл)
- `mn-Mong` - 蒙古语（传统蒙古文）(ᠮᠣᠩᠭᠣᠯᠪᠢᠴᠢᠭ)

## 当前已实现的语言文件

位于 `src/locale/` 目录下，共 24 种语言：
- `en.json` - 英语
- `zh-Hans.json` - 简体中文
- `zh-Hant.json` - 繁体中文
- `ja.json` - 日语
- `ko.json` - 韩语
- `fr.json` - 法语
- `es.json` - 西班牙语
- `pt.json` - 葡萄牙语
- `de.json` - 德语
- `it.json` - 意大利语
- `ru.json` - 俄语
- `uk.json` - 乌克兰语
- `th.json` - 泰语
- `vi.json` - 越南语
- `km.json` - 高棉语
- `hi.json` - 印地语
- `ar.json` - 阿拉伯语
- `he.json` - 希伯来语
- `bo.json` - 藏文
- `ug.json` - 维吾尔语
- `kk-Cyrl.json` / `kk-Arab.json` - 哈萨克语（西里尔 / 阿拉伯字母）
- `mn-Cyrl.json` / `mn-Mong.json` - 蒙古语（西里尔 / 传统蒙古文）

> 其他语言可根据需要添加，只需创建对应的 JSON 文件并在 `i18n.ts` 中注册即可。

## 在组件中使用

### Composition API (推荐)

```vue
<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<template>
  <div>
    <!-- 简单文本 -->
    <p>{{ t('common.loading') }}</p>
    
    <!-- 导航文本 -->
    <button>{{ t('navigation.home') }}</button>
    
    <!-- 播放器文本 -->
    <span>{{ t('player.play') }}</span>
  </div>
</template>
```

### Options API

```vue
<script lang="ts">
export default {
  methods: {
    getLoadingText() {
      return this.$t('common.loading')
    }
  }
}
</script>

<template>
  <div>
    <p>{{ $t('common.loading') }}</p>
  </div>
</template>
```

## 切换语言

### 方法 1: 通过 Store 更新（推荐）

```typescript
import { setupStore } from '@/core/store'
import { setLanguage } from '@/core/i18n'

// 更新 store 并同步到数据库
await setupStore().updateSetting('language', 'en')

// 切换 i18n 语言
setLanguage('en')
```

### 方法 2: 直接使用 i18n API

```typescript
import { setLanguage } from '@/core/i18n'

// 切换到英语
setLanguage('en')

// 切换到自动检测
setLanguage('auto')
```

## 添加新的翻译文本

1. 在所有语言文件中添加对应的键值对：

**zh-Hans.json:**
```json
{
  "newSection": {
    "title": "新标题"
  }
}
```

**en.json:**
```json
{
  "newSection": {
    "title": "New Title"
  }
}
```

2. 更新 TypeScript 类型声明 (`src/types/i18n.d.ts`)

3. 在组件中使用：
```vue
<template>
  <h1>{{ t('newSection.title') }}</h1>
</template>
```

## 添加新的语言支持

1. 在 `src/locale/` 目录下创建新的语言文件，如 `ko.json`（韩语）

2. 在 `src/core/i18n.ts` 中导入并注册：

```typescript
import ko from '../locales/ko.json';

const messages = {
  'en': en,
  'zh-Hans': zhHans,
  'zh-Hant': zhHant,
  'ja': ja,
  'ko': ko, // 添加新语言
};
```

3. 更新 `ResolvedLocale` 类型：
```typescript
type ResolvedLocale = 'en' | 'zh-Hans' | 'zh-Hant' | 'ja' | 'ko';
```

4. 在 `detectBrowserLanguage()` 中添加检测逻辑：
```typescript
if (browserLang.startsWith('ko')) {
  return 'ko';
}
```

## 语言检测逻辑

当语言设置为 `auto` 时，系统会按以下优先级检测：

1. 浏览器语言为 `zh`, `zh-CN`, `zh-SG` → 简体中文 (`zh-Hans`)
2. 浏览器语言为 `zh-TW`, `zh-HK`, `zh-MO` → 繁体中文 (`zh-Hant`)
3. 浏览器语言以 `ja` 开头 → 日语 (`ja`)
4. 其他情况 → 英语 (`en`)

## 注意事项

1. **语言代码规范**: 必须使用 BCP 47 标准（如 `zh-Hans` 而非 `zh-CN`）
2. **语言切换时机**: 建议在用户明确操作后切换语言（如设置页面）
3. **持久化**: 语言设置会自动保存到数据库，下次启动时恢复
4. **默认回退**: 如果某个翻译键不存在，会回退到 `en`
5. **类型安全**: 所有翻译键都有 TypeScript 类型提示

## 示例：完整的使用场景

```vue
<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { setupStore } from '@/core/store'
import { setLanguage } from '@/core/i18n'

const { t, locale } = useI18n()

// 切换语言函数
async function changeLanguage(lang: string) {
  // 更新 store 和数据库
  await setupStore().updateSetting('language', lang)
  
  // 切换 i18n 语言
  setLanguage(lang as any)
}
</script>

<template>
  <div>
    <h1>{{ t('setup.title') }}</h1>
    
    <select :value="locale" @change="changeLanguage($event.target.value)">
      <option value="auto">{{ t('setup.language') }} - Auto</option>
      <option value="zh-Hans">简体中文</option>
      <option value="zh-Hant">繁體中文</option>
      <option value="en">English</option>
      <option value="ja">日本語</option>
    </select>
    
    <button>{{ t('common.save') }}</button>
    <button>{{ t('common.cancel') }}</button>
  </div>
</template>
```
