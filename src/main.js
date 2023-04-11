import Vue from 'vue'
import App from './App'
import './uni.promisify.adaptor'
// import "@fortawesome/fontawesome-free/css/all.min.css"

Vue.config.productionTip = false

App.mpType = 'app'

const app = new Vue({
	...App
})
app.$mount()

import ElementUI from 'element-ui';
Vue.use(ElementUI);