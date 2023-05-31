<template>
	<view class="panel" :style="{ width: (pad && ori) ? '50%' : 'calc(100% - 2rem)' }">
		<view class="title">{{ $t('login.title') }}</view>
		<input class="input" :disabled="disabled" v-model="username" :placeholder="$t('login.user')" />
		<input class="input" :disabled="disabled" v-model="passwd" password="password" :placeholder="$t('login.passwd')" />
		<button @click="login()" :disabled="disabled">
			<text v-if="disabled">
				<i class="fas fa-circle-notch fa-spin fa-fw"></i>
				{{ $t('login.logining') }}
			</text>
			<text v-else>{{ $t('login.login') }}</text>
		</button>
		<view class="sub">
			<navigator url="/pages/login/regist">{{ $t('login.regist') }}</navigator>
		</view>
		<view class="float">
			<navigator url="/pages/setup/language?init=1">
				<view style="padding: 1rem;">
					<i class="fa-solid fa-language" style="margin-right: 0.4rem;"></i>Language
				</view>
			</navigator>
			<view class="float-tip">
				{{ $t('tip[2]') }}
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
		uni.setNavigationBarTitle({
			title: this.$t('label.login')
		});
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
							title: this.$t('login.success'),
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
							title: this.$t('dontLink'),
							icon: 'none',
							duration: 3000
						});
					} else {
						uni.showModal({
							title: this.$t('login.fail'),
							content: this.$t('login.failMsg'),
							showCancel: false,
							confirmColor: '#00897B'
						});
					}
				})
			} else {
				uni.showModal({
					content: this.$t('login.null'),
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