import Vue from 'vue'
import App from './App'
import './uni.promisify.adaptor'

Vue.config.productionTip = false

App.mpType = 'app'

/**国际化 */
import messages from '@/locale/index.js'
let lag = uni.getStorageSync('language')
if (lag == '') {
	lag = uni.getLocale()
}

let i18nConfig = {
	locale: lag,
	fallbackLocale: 'en-US',
	messages
}

import VueI18n from 'vue-i18n'
Vue.use(VueI18n)
const i18n = new VueI18n(i18nConfig)

const app = new Vue({
	...App,
	i18n
})

app.$mount()


/**全局方法与变量 */
// 设备类型
Vue.prototype.$deviceType = uni.getSystemInfoSync().deviceType
// 返回起始页
Vue.prototype.$backhome = () => {
	uni.reLaunch({
		url: '/pages/index/index?check=0'
	});
}
// 语言列表
Vue.prototype.$languageList = [
	{
		name: 'English',
		code: 'en-US'
	}, {
		name: '中文(简体)',
		code: 'zh-Hans'
	}, {
		name: '中文(繁體)',
		code: 'zh-Hant'
	}, {
		name: '日本語',
		code: 'ja-JP'
	}, {
		name: '한국어',
		code: 'ko-KR'
	}, {
		name: 'Français',
		code: 'fr-FR'
	}, {
		name: 'Deutsch',
		code: 'de-DE'
	}, {
		name: 'Español',
		code: 'es-ES'
	}, {
		name: 'Italiano',
		code: 'it-IT'
	}, {
		name: 'Русский',
		code: 'ru-RU'
	}, {
		name: 'اللغة العربية',
		code: 'ar-SA'
	}, {
		name: 'ภาษาไทย',
		code: 'th-TH'
	}, {
		name: 'Tiếng Việt',
		code: 'vi-VN'
	}
]
// 更改语言
Vue.prototype.$languageChange = (l) => {
	i18n.locale = l
}

/**全局组件 */
import qImg from '@/pages/component/q-img.vue'
import qAvatar from '@/pages/component/q-avatar.vue'
Vue.component('q-img', qImg)
Vue.component('q-avatar', qAvatar)
