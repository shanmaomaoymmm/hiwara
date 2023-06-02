import Vue from 'vue'
import App from './App'
import './uni.promisify.adaptor'

Vue.config.productionTip = false

App.mpType = 'app'

/**国际化 */
import i18n from '@/locale/index.js'
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
		code: 'en-US',
		author: ""
	}, {
		name: '中文(简体)',
		code: 'zh-Hans',
		author: ""
	}, {
		name: '中文(繁體)',
		code: 'zh-Hant',
		author: ""
	}, {
		name: '日本語',
		code: 'ja-JP',
		author: "google"
	}, {
		name: '한국어',
		code: 'ko-KR',
		author: "google"
	}, {
		name: 'ئۇيغۇر تىلى',
		code: 'ug-CN',
		author: "google"
	}, {
		name: 'བོད་སྐད།',
		code: 'bo-CN',
		author: "google"
	}, {
		name: 'Français',
		code: 'fr-FR',
		author: "google"
	}, {
		name: 'Deutsch',
		code: 'de-DE',
		author: "google"
	}, {
		name: 'Español',
		code: 'es-ES',
		author: "google"
	}, {
		name: 'Italiano',
		code: 'it-IT',
		author: "google"
	}, {
		name: 'Русский',
		code: 'ru-RU',
		author: "google"
	}, {
		name: 'اللغة العربية',
		code: 'ar-SA',
		author: "google"
	}, {
		name: 'ภาษาไทย',
		code: 'th-TH',
		author: "google"
	}, {
		name: 'Tiếng Việt',
		code: 'vi-VN',
		author: "google"
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
