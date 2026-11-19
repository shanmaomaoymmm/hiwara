import { createI18n } from 'vue-i18n';
import { setupStore } from './store';

// 导入语言文件（使用 BCP 47 语言标签）
import zhHans from '../locale/zh-Hans.json';
import zhHant from '../locale/zh-Hant.json';
import en from '../locale/en.json';
import ja from '../locale/ja.json';
import ko from '../locale/ko.json';
import fr from '../locale/fr.json';
import es from '../locale/es.json';
import pt from '../locale/pt.json';
import de from '../locale/de.json';
import it from '../locale/it.json';
import ru from '../locale/ru.json';
import uk from '../locale/uk.json';
import th from '../locale/th.json';
import vi from '../locale/vi.json';
import km from '../locale/km.json';
import hi from '../locale/hi.json';
import ar from '../locale/ar.json';
import he from '../locale/he.json';
import bo from '../locale/bo.json';
import ug from '../locale/ug.json';
import kkCyrl from '../locale/kk-Cyrl.json';
import kkArab from '../locale/kk-Arab.json';
import mnCyrl from '../locale/mn-Cyrl.json';
import mnMong from '../locale/mn-Mong.json';

// 定义支持的语言类型（BCP 47 标准）
type SupportedLocale = 'auto' | 'en' | 'zh-Hans' | 'zh-Hant' | 'ja' | 'ko' | 'fr' | 'es' | 'pt' | 'de' | 'it' | 'ru' | 'uk' | 'th' | 'vi' | 'km' | 'hi' | 'ar' | 'he' | 'bo' | 'ug' | 'kk-Cyrl' | 'kk-Arab' | 'mn-Cyrl' | 'mn-Mong';
type ResolvedLocale = 'en' | 'zh-Hans' | 'zh-Hant' | 'ja' | 'ko' | 'fr' | 'es' | 'pt' | 'de' | 'it' | 'ru' | 'uk' | 'th' | 'vi' | 'km' | 'hi' | 'ar' | 'he' | 'bo' | 'ug' | 'kk-Cyrl' | 'kk-Arab' | 'mn-Cyrl' | 'mn-Mong';

// 使用西里尔字母的语言。这些语言下强制使用系统底层默认字体，
// 避免部分安卓设备（如小米）的用户自定义字体导致西里尔字形宽度异常。
export const CYRILLIC_LOCALES: readonly ResolvedLocale[] = ['ru', 'uk', 'kk-Cyrl', 'mn-Cyrl'];

export function isCyrillicLocale(locale: string): boolean {
  return (CYRILLIC_LOCALES as readonly string[]).includes(locale);
}

// 语言消息对象
const messages = {
  'en': en,
  'zh-Hans': zhHans,
  'zh-Hant': zhHant,
  'ja': ja,
  'ko': ko,
  'fr': fr,
  'es': es,
  'pt': pt,
  'de': de,
  'it': it,
  'ru': ru,
  'uk': uk,
  'th': th,
  'vi': vi,
  'km': km,
  'hi': hi,
  'ar': ar,
  'he': he,
  'bo': bo,
  'ug': ug,
  'kk-Cyrl': kkCyrl,
  'kk-Arab': kkArab,
  'mn-Cyrl': mnCyrl,
  'mn-Mong': mnMong,
};

// 全局 i18n 实例引用（由 createI18nInstance 创建后保存，供 setLanguage / initI18nLanguage 使用）
let i18nInstance: ReturnType<typeof createI18nInstance> | null = null;

// 检测浏览器语言并转换为 BCP 47 标签
function detectBrowserLanguage(): ResolvedLocale {
  const browserLang = navigator.language;

  // 匹配简体中文 (zh-CN, zh-SG, zh)
  if (browserLang === 'zh' || browserLang.startsWith('zh-CN') || browserLang.startsWith('zh-SG')) {
    return 'zh-Hans';
  }
  // 匹配繁体中文 (zh-TW, zh-HK, zh-MO)
  if (browserLang.startsWith('zh-TW') || browserLang.startsWith('zh-HK') || browserLang.startsWith('zh-MO')) {
    return 'zh-Hant';
  }
  // 匹配日语
  if (browserLang.startsWith('ja')) {
    return 'ja';
  }
  // 匹配韩语
  if (browserLang.startsWith('ko')) {
    return 'ko';
  }
  // 匹配法语
  if (browserLang.startsWith('fr')) {
    return 'fr';
  }
  // 匹配西班牙语
  if (browserLang.startsWith('es')) {
    return 'es';
  }
  // 匹配葡萄牙语
  if (browserLang.startsWith('pt')) {
    return 'pt';
  }
  // 匹配德语
  if (browserLang.startsWith('de')) {
    return 'de';
  }
  // 匹配意大利语
  if (browserLang.startsWith('it')) {
    return 'it';
  }
  // 匹配俄语
  if (browserLang.startsWith('ru')) {
    return 'ru';
  }
  // 匹配乌克兰语
  if (browserLang.startsWith('uk')) {
    return 'uk';
  }
  // 匹配泰语
  if (browserLang.startsWith('th')) {
    return 'th';
  }
  // 匹配越南语
  if (browserLang.startsWith('vi')) {
    return 'vi';
  }
  // 匹配高棉语
  if (browserLang.startsWith('km')) {
    return 'km';
  }
  // 匹配印地语
  if (browserLang.startsWith('hi')) {
    return 'hi';
  }
  // 匹配阿拉伯语
  if (browserLang.startsWith('ar')) {
    return 'ar';
  }
  // 匹配希伯来语
  if (browserLang.startsWith('he')) {
    return 'he';
  }
  // 匹配藏文
  if (browserLang.startsWith('bo')) {
    return 'bo';
  }
  // 匹配维吾尔语
  if (browserLang.startsWith('ug')) {
    return 'ug';
  }
  // 匹配哈萨克语阿拉伯字母（须在 kk 之前检测，避免 kk-Arab 被误匹配为 kk）
  if (browserLang.startsWith('kk-Arab')) {
    return 'kk-Arab';
  }
  // 匹配哈萨克语（西里尔字母）
  if (browserLang.startsWith('kk-Cyrl')) {
    return 'kk-Cyrl';
  }
  // 匹配蒙古语（西里尔字母）
  if (browserLang.startsWith('mn-Cyrl')) {
    return 'mn-Cyrl';
  }
  // 匹配蒙古语（传统蒙文，须在 mn 之前检测）
  if (browserLang.startsWith('mn-Mong')) {
    return 'mn-Mong';
  }
  // 匹配蒙古语（通用标签回退到西里尔）
  if (browserLang.startsWith('mn')) {
    return 'mn-Cyrl';
  }
  // 默认返回英语
  return 'en';
}

// 获取当前语言
function getCurrentLocale(): ResolvedLocale {
  const storeLanguage = setupStore().language;

  // 如果设置为 auto,则检测浏览器语言
  if (storeLanguage === 'auto') {
    return detectBrowserLanguage();
  }

  // 否则使用设置的语言,如果不在支持列表中则返回默认值
  // 回退值与 fallbackLocale 保持一致（en）
  return (messages[storeLanguage as keyof typeof messages] ? storeLanguage : 'en') as ResolvedLocale;
}

// 创建 i18n 实例的工厂函数
export function createI18nInstance() {
  const i18n = createI18n({
    legacy: false, // 使用 Composition API 模式
    locale: getCurrentLocale(), // 初始语言
    fallbackLocale: 'en', // 回退语言
    messages: messages as any, // 语言包
  });

  // 保存实例引用，供 setLanguage / initI18nLanguage 使用
  i18nInstance = i18n;

  return i18n;
}

// 导出语言切换函数
export function setLanguage(locale: SupportedLocale) {
  if (!i18nInstance) return;

  // 如果设置为 auto,则检测浏览器语言
  let resolvedLocale: ResolvedLocale;
  if (locale === 'auto') {
    resolvedLocale = detectBrowserLanguage();
  } else {
    resolvedLocale = (messages[locale as keyof typeof messages] ? locale : 'en') as ResolvedLocale;
  }

  // 更新 i18n 实例的语言
  i18nInstance.global.locale.value = resolvedLocale;
}

// 导出初始化函数(用于在应用启动时根据 store 设置语言)
export function initI18nLanguage() {
  if (!i18nInstance) return;
  const currentLocale = getCurrentLocale();
  i18nInstance.global.locale.value = currentLocale;
}
