<template>
	<view class="panel" v-show="display">
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
			<!-- <uni-link href="https://www.iwara.tv/register">注册账号</uni-link> -->
		</view>
		<view class="float">
			内容源自iwara.tv，本程序禁止用于商业用途
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
			display: false
		}
	},
	created() {
		getStorage('token', (res) => {
			if (res) {
				uni.redirectTo({
					url: '/pages/home/index'
				});
			} else {
				this.display = true
			}
		})
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
	padding: 10vh 1rem
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
}

.float {
	text-align: center;
	font-size: 0.8rem;
	position: absolute;
	bottom: 20px;
	width: calc(100% - 2rem);
	color: #808080;
}

@media (prefers-color-scheme: dark) {
	.button {
		color: black;
	}
}
</style>