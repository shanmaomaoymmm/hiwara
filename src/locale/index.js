import enus from './en-us.json'
import zhHans from './zh-hans.json'
import zhHant from './zh-hant.json'
import jajp from './ja-jp.json'
import kokr from './ko-kr.json'
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
if (lag == '') {
  lag = uni.getLocale()
}
let messages = {
  'en-US': enus,
  'zh-Hans': zhHans,
  'zh-Hant': zhHant,
  'ja-JP': jajp,
  'ko-KR': kokr,
  'ru-RU': ruru,
  'fr-FR': frfr,
  'de-DE': dede,
  'es-ES': eses,
  'it-IT': itit,
  'ar-SA': arsa,
  'th-TH': thth,
  'vi-VN': vivn,
}
let i18n = new VueI18n({
  locale: lag,
  fallbackLocale: 'en-US',
  messages
})
export default i18n