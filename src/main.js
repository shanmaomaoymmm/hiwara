import Vue from 'vue'
import App from './App'
import './uni.promisify.adaptor'
import {
	getAccessToken
} from '@/api/api.js'

Vue.config.productionTip = false

App.mpType = 'app'

const app = new Vue({
	...App
})

getAccessToken(() => {
	app.$mount()
})
