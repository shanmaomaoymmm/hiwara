/**
 * 日期显示格式化工具
 *
 * 卡片日期规则：
 *   - 今天：hh:mm
 *   - 今年但不是今天：中文 M月D日 hh:mm / 日文 M月D日 hh:mm / 韩文 M월 D일 hh:mm / 其他 MM-DD hh:mm
 *   - 非今年：中文 YYYY年M月D日 / 日文 YYYY年M月D日 / 韩文 YYYY년 M월 D일 / 其他 YYYY-MM-DD
 *
 * 详情页日期规则：
 *   - 中文：YYYY年M月D日 hh:mm
 *   - 日文：YYYY年M月D日 hh:mm
 *   - 韩文：YYYY년 M월 D일 hh:mm
 *   - 其他：YYYY-MM-DD hh:mm
 */

type DateStyle = 'zh' | 'ja' | 'ko' | 'other';

function getDateStyle(locale: string): DateStyle {
  if (locale === 'zh-Hans' || locale === 'zh-Hant') return 'zh';
  if (locale === 'ja') return 'ja';
  if (locale === 'ko') return 'ko';
  return 'other';
}

function isSameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear()
    && a.getMonth() === b.getMonth()
    && a.getDate() === b.getDate();
}

function pad(value: number): string {
  return String(value).padStart(2, '0');
}

/** 卡片上的日期显示 */
export function formatCardDate(timeStr: string | undefined, locale: string): string {
  if (!timeStr) return '';

  const date = new Date(timeStr);
  if (Number.isNaN(date.getTime())) return '';

  const now = new Date();
  const time = `${pad(date.getHours())}:${pad(date.getMinutes())}`;

  // 今天只显示时间
  if (isSameDay(date, now)) return time;

  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();
  const isThisYear = year === now.getFullYear();

  switch (getDateStyle(locale)) {
    case 'zh': {
      const md = `${month}月${day}日`;
      return isThisYear ? `${md} ${time}` : `${year}年${md}`;
    }
    case 'ja': {
      const md = `${month}月${day}日`;
      return isThisYear ? `${md} ${time}` : `${year}年${md}`;
    }
    case 'ko': {
      const md = `${month}월 ${day}일`;
      return isThisYear ? `${md} ${time}` : `${year}년 ${md}`;
    }
    default: {
      const md = `${pad(month)}-${pad(day)}`;
      return isThisYear ? `${md} ${time}` : `${year}-${md}`;
    }
  }
}

/** 详情页的发布日期显示 */
export function formatDetailDate(timeStr: string | undefined, locale: string): string {
  if (!timeStr) return '';

  const date = new Date(timeStr);
  if (Number.isNaN(date.getTime())) return '';

  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();
  const time = `${pad(date.getHours())}:${pad(date.getMinutes())}`;

  switch (getDateStyle(locale)) {
    case 'zh':
      return `${year}年${month}月${day}日 ${time}`;
    case 'ja':
      return `${year}年${month}月${day}日 ${time}`;
    case 'ko':
      return `${year}년 ${month}월 ${day}일 ${time}`;
    default:
      return `${year}-${pad(month)}-${pad(day)} ${time}`;
  }
}
