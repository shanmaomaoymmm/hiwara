import enus from './en-us.json'
import zhHans from './zh-hans.json'
import zhHant from './zh-hant.json'
import jajp from './ja-jp.json'
import kokr from './ko-kr.json'
import ugcn from './ug-cn.json'
import bocn from './bo-cn.json'
import ruru from './ru-ru.json'
import frfr from './fr-fr.json'
import dede from './de-de.json'
import eses from './es-es.json'
import itit from './it-it.json'
import arsa from './ar-sa.json'
import thth from './th-th.json'
import vivn from './vi-vn.json'
import VueI18n from 'vue-i18n'
import Vue from 'vue'
Vue.use(VueI18n)
let lag = uni.getStorageSync('language')
if (lag === 'auto' || lag === '') {
  lag = uni.getLocale()
}
let messages = {
  'en': enus,
  'en-US': enus,
  'en-us': enus,
  'zh-Hans': zhHans,
  'zh-CN': zhHans,
  'zh-cn': zhHans,
  'zh-Hant': zhHant,
  'zh-HK': zhHant,
  'zh-hk': zhHant,
  'zh-MO': zhHant,
  'zh-mo': zhHant,
  'zh-TW': zhHant,
  'zh-tw': zhHant,
  'ja': jajp,
  'ja-JP': jajp,
  'ja-jp': jajp,
  'ko': kokr,
  'ko-KR': kokr,
  'ko-kr': kokr,
  'ug-CN': ugcn,
  'ug-cn': ugcn,
  'bo-CN': bocn,
  'bo-cn': bocn,
  'ru': ruru,
  'ru-RU': ruru,
  'ru-ru': ruru,
  'fr': frfr,
  'fr-FR': frfr,
  'fr-fr': frfr,
  'de': dede,
  'de-de': dede,
  'es': eses,
  'es-ES': eses,
  'es-es': eses,
  'it': itit,
  'it-IT': itit,
  'it-it': itit,
  'ar': arsa,
  'ar-SA': arsa,
  'ar-sa': arsa,
  'th': thth,
  'th-TH': thth,
  'th-th': thth,
  'vi': vivn,
  'vi-VN': vivn,
  'vi-vn': vivn,
}
let i18n = new VueI18n({
  locale: lag,
  fallbackLocale: 'en-US',
  messages
})
export default i18n