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
		name: '中文(简体)',
		code: 'zh-Hans'
	}, {
		name: '中文(繁體)',
		code: 'zh-Hant'
	}, {
		name: 'English',
		code: 'en-US'
	}, {
		name: '日本語',
		code: 'ja-JP'
	}, {
		name: '한국어',
		code: 'ko-KR'
	}, {
		// 	name: 'Français',
		// 	code: 'fr-fr'
		// }, {
		// 	name: 'Español',
		// 	code: 'es-es'
		// }, {
		name: 'Русский',
		code: 'ru-RU'
		// }, {
		// 	name: 'བོད་སྐད།',
		// 	code: 'tib'
		// }, {
		// 	name: 'ئۇيغۇر تىلى',
		// 	code: 'uey'
		// }, {
		// 	name: 'Tiếng Việt',
		// 	code: 'vi'
		// }, {
		// 	name: 'اللغة العربية',
		// 	code: 'ar-sa'
	}
]

/**全局组件 */
import qImg from '@/pages/component/q-img.vue'
import qAvatar from '@/pages/component/q-avatar.vue'
Vue.component('q-img', qImg)
Vue.component('q-avatar', qAvatar)
