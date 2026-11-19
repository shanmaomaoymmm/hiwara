# i18n 国际化支持

## 已完成的工作

### 1. 依赖安装
- ✅ 安装了 `vue-i18n@9`

### 2. 核心文件创建
- ✅ `src/core/i18n.ts` - i18n 配置和初始化（使用 BCP 47 语言标签）
- ✅ 创建了 **24 种语言**的基础翻译文件

### 3. 已支持的语言（BCP 47 标准）

| 语言代码 | 语言名称 | 本地名称 | 文件 |
|---------|---------|---------|------|
| `auto` | 跟随系统 | - | - |
| `en` | 英语 | English | ✅ en.json |
| `zh-Hans` | 简体中文 | 简体中文 | ✅ zh-Hans.json |
| `zh-Hant` | 繁体中文 | 繁體中文 | ✅ zh-Hant.json |
| `ja` | 日语 | 日本語 | ✅ ja.json |
| `ko` | 韩语 | 한국어 | ✅ ko.json |
| `fr` | 法语 | Français | ✅ fr.json |
| `es` | 西班牙语 | Español | ✅ es.json |
| `pt` | 葡萄牙语 | Português | ✅ pt.json |
| `de` | 德语 | Deutsch | ✅ de.json |
| `it` | 意大利语 | Italiano | ✅ it.json |
| `ru` | 俄语 | Русский | ✅ ru.json |
| `uk` | 乌克兰语 | Українська | ✅ uk.json |
| `th` | 泰语 | ภาษาไทย | ✅ th.json |
| `vi` | 越南语 | Tiếng Việt | ✅ vi.json |
| `km` | 高棉语 | ភាសាខ្មែរ | ✅ km.json |
| `hi` | 印地语 | भाषा | ✅ hi.json |
| `ar` | 阿拉伯语 | العربية | ✅ ar.json |
| `he` | 希伯来语 | עברית | ✅ he.json |
| `bo` | 藏文 | བོད་ཡིག | ✅ bo.json |
| `ug` | 维吾尔语 | ئۇيغۇر تىلى | ✅ ug.json |
| `kk-Cyrl` | 哈萨克语（西里尔字母） | қазақ тілі | ✅ kk-Cyrl.json |
| `kk-Arab` | 哈萨克语（阿拉伯字母） | قازاقشا | ✅ kk-Arab.json |
| `mn-Cyrl` | 蒙古语（西里尔字母） | Монгол Кирилл | ✅ mn-Cyrl.json |
| `mn-Mong` | 蒙古语（传统蒙古文） | ᠮᠣᠩᠭᠣᠯᠪᠢᠴᠢᠭ | ✅ mn-Mong.json |

### 4. 集成配置
- ✅ 在 `src/main.ts` 中集成 i18n
- ✅ 在 `src/types/i18n.d.ts` 中添加 TypeScript 类型声明
- ✅ 语言设置与 `setupStore` 和数据库同步
- ✅ 所有语言已在 `i18n.ts` 中注册

### 5. 文档
- ✅ `docs/i18n-guide.md` - 详细的使用指南

## 特性

### 语言代码规范
遵循 **BCP 47 语言标签**标准，与 `src/views/setup/language.vue` 保持一致。

### 完整的语言支持
- 已为 language.vue 中定义的所有 24 种语言创建基础翻译框架
- 每种语言包含基础翻译键：common、navigation、player、setup
- 可根据需要扩展翻译内容

### 语言检测
- 支持自动检测浏览器语言（支持所有 24 种语言）
- 可手动切换语言
- 语言设置持久化到数据库

### 与 Store 集成
- 语言设置存储在 `setupStore.language` 字段
- 修改语言时自动同步到 SQLite 数据库
- 应用启动时从数据库加载语言设置

## 使用方法

### 在组件中使用

```vue
<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()
</script>

<template>
  <div>
    <p>{{ t('common.loading') }}</p>
    <button>{{ t('navigation.home') }}</button>
  </div>
</template>
```

### 切换语言

```typescript
import { setupStore } from '@/core/store'
import { setLanguage } from '@/core/i18n'

// 更新 store 并切换语言
await setupStore().updateSetting('language', 'en')
setLanguage('en')
```

## 扩展现有翻译

当前所有语言文件都包含基础翻译示例，您可以根据需要：

1. 在任何语言文件中添加新的翻译键值对
2. 更新 `src/vite-env.d.ts` 中的类型声明
3. 在组件中使用 `t('key.path')` 引用

## 注意事项

- ✅ 所有 24 种语言的基础框架已搭建完成
- ✅ 语言文件位于 `src/locale/` 目录
- ✅ 语言代码使用 BCP 47 标准
- ⚠️ 当前翻译内容为基础示例，可根据项目需求完善
- 📖 详细的使用指南请查看 `docs/i18n-guide.md`
