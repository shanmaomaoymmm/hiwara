import Vue from 'vue'
import App from './App'
import './uni.promisify.adaptor'

Vue.config.productionTip = false

App.mpType = 'app'

const app = new Vue({
	...App
})

app.$mount()


/**全局方法与变量 */
Vue.prototype.$backhome = () => {
	uni.reLaunch({
		url: '/pages/index/index?check=0'
	});
}
Vue.prototype.$languageList = [
	{
		name: '中文(简体)',
		code: 'zh-hans'
	}, {
		name: '中文(繁體)',
		code: 'zh-hant'
	}, {
		name: 'English',
		code: 'en-us'
	}, {
		name: '日本語',
		code: 'ja-jp'
	}, {
		name: '한국어',
		code: 'ko-kr'
	}, {
		name: 'Français',
		code: 'fr-fr'
	}, {
		name: 'Español',
		code: 'es-es'
	}, {
		name: 'Русский',
		code: 'ru-ru'
	}, {
		name: 'བོད་སྐད།',
		code: 'tib'
	}, {
		name: 'ئۇيغۇر تىلى',
		code: 'uey'
	}, {
		name: 'Tiếng Việt',
		code: 'vi'
	}, {
		name: 'اللغة العربية',
		code: 'ar-sa'
	}
]

/**全局组件 */
import qImg from '@/pages/component/q-img.vue'
import qAvatar from '@/pages/component/q-avatar.vue'
Vue.component('q-img', qImg)
Vue.component('q-avatar', qAvatar)