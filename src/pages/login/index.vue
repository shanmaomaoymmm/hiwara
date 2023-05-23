<template>
	<view class="panel" :style="{ width: (pad && ori) ? '50%' : 'calc(100% - 2rem)' }">
		<view class="title">登录到你的iwara账号</view>
		<input class="input" :disabled="disabled" v-model="username" placeholder="请输入账号" />
		<input class="input" :disabled="disabled" v-model="passwd" password="password" placeholder="请输入密码" />
		<button @click="login()" :disabled="disabled">
			<text v-if="disabled">
				<i class="fas fa-circle-notch fa-spin fa-fw"></i>
				登录中
			</text>
			<text v-else>登录</text>
		</button>
		<view class="sub">
			<navigator url="/pages/login/regist">注册账号</navigator>
		</view>
		<view class="float">
			<navigator url="/pages/setup/language?init=1">
				<view style="padding: 1rem;">
					<i class="fa-solid fa-language" style="margin-right: 0.4rem;"></i>Language
				</view>
			</navigator>
			<view class="float-tip">
				内容源自iwara.tv，本程序禁止用于商业用途
				<br />
				©2019-2023 Maoerxiachuan
			</view>
		</view>
	</view>
</template>

<script>
import {
	login,
	setStorage,
	getStorage,
} from '@/api/api.js'
export default {
	data() {
		return {
			username: null,
			passwd: null,
			disabled: false,
			pad: false,
			ori: false
		}
	},
	created() {
		getStorage('username', (res) => {
			if (res) {
				this.username = res
			}
		})
		getStorage('passwd', (res) => {
			if (res) {
				this.passwd = res
			}
		})
	},
	mounted() {
		let media = uni.createMediaQueryObserver(this)
		media.observe({
			minWidth: 582,
			minHeight: 582
		}, (res) => {
			if (res) {
				this.pad = true
			} else {
				this.pad = false
			}
		})
		media.observe({
			orientation: 'landscape'
		}, (res) => {
			this.ori = res
		})
	},
	methods: {
		login() {
			if (this.username && this.passwd) {
				this.disabled = true
				login(this.username, this.passwd, (res, code) => {
					this.disabled = false
					if (code == 200) {
						uni.showToast({
							title: '登录成功',
							icon: 'none',
							duration: 3000
						});
						// 缓存用户名密码
						setStorage('username', this.username)
						setStorage('passwd', this.passwd)
						uni.redirectTo({
							url: '/pages/home/index'
						});
					} else if (code == 408) {
						uni.showToast({
							title: '呐！少冲一点吧\r\n无法连接到服务器',
							icon: 'none',
							duration: 3000
						});
					} else {
						uni.showModal({
							title: '登录失败',
							content: '用户名或密码错误',
							showCancel: false,
							confirmColor: '#00897B'
						});
					}
				})
			} else {
				uni.showModal({
					content: '用户名和密码不能为空',
					showCancel: false,
					confirmColor: '#00897B'
				});
			}
		}
	}
}
</script>

<style scoped>
.panel {
	padding: 8vh 1rem;
	margin: 0 auto;
	width: calc(100% - 2rem);
	position: relative;
	height: calc(100% - 16vh);
	transition: width 100ms ease;
}

.title {
	font-size: 1.4rem;
	margin: 1.5rem 0.5rem;
}

.input {
	margin: 1.5rem 0;
	padding: 0.5rem;
	border-bottom: solid 2px #00897B;
}

button {
	margin: 1rem 0;
	width: 100%;
	background-color: #00897B;
	color: white;
}

.sub {
	margin: 1rem;
	text-align: right;
	color: #505050;
}

.float {
	text-align: center;
	position: absolute;
	bottom: 1rem;
	width: calc(100% - 2rem);
	color: #505050;
}

.float-tip {
	font-size: 0.8rem;
	color: #808080;
}

@media (prefers-color-scheme: dark) {
	.button {
		color: black;
	}

	.sub,
	.float {
		color: #afafaf;
	}
}
</style>