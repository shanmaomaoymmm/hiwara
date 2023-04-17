<template>
	<view class="images" :style="{ backgroundImage: 'url(' + data.files[0] + ')' }">
		<view class="top">
			<view>
				<i @click="back(1)" class="fa-solid fa-angle-left backButton"></i>
				<i @click="back(0)" class="fa-solid fa-house backButton"></i>
			</view>
			<view class="title">
				<text>{{ data.title }}</text>
			</view>
		</view>
		<view class="main">
			<view style="text-align: center;position: relative;">
				<view v-show="unfold" class="pictures">
					<img class="picture" v-for="item, i in data.files" :src="item">
				</view>
				<view v-show="!unfold" class="pictures">
					<img class="picture" :src="data.files[0]">
				</view>
				<text v-if="data.files.length > 1" class="unfold" @click="unfold = !unfold">
					{{ unfold ? "点击折叠" : "点击展开" }}
				</text>
			</view>
			<view class="info">
				<view style="display: flex;">
					<view>
						<image class="avatar" :src="data.avatar"></image>
					</view>
					<view style="flex: 1;padding:0 0.5rem;line-height: 2rem;">
						<text style="font-size: 1rem;">{{ data.author }}</text>
					</view>
					<view>
						<button size="mini" @click="followers">{{ data.following ? "已关注" : "＋ 关注"
						}}</button>
					</view>
				</view>
				<view class="synopsis">
					{{ data.body }}
				</view>
			</view>
		</view>
	</view>
</template>

<script>
import { getPicture, followers } from '@/api/api'
export default {
	data() {
		return {
			data: null,
			id: null,
			uid: null,
			unfold: false,
		}
	},
	onLoad: function (opt) {
		this.id = opt.id
		this.uid = opt.uid
	},
	mounted() {
		getPicture(this.id, (res) => {
			this.data = res
		})
	},
	methods: {
		followers() {
			if (this.data.following) {
				followers(this.uid, 0, (res, code) => {
					if (code == 204) {
						uni.showToast({
							title: "已取消关注",
							icon: "none",
							duration: 3000,
						})
						this.data.following = !this.data.following
					} else {
						uni.showToast({
							title: "操作失败",
							icon: "none",
							duration: 3000,
						})
					}
				})
			} else {
				followers(this.uid, 1, (res, code) => {
					if (code == 201) {
						uni.showToast({
							title: "关注成功！！！",
							icon: "none",
							duration: 3000,
						})
						this.data.following = !this.data.following
					} else {
						uni.showToast({
							title: "操作失败",
							icon: "none",
							duration: 3000,
						})
					}
				})
			}
		},
		back(v) {
			if (v == 0) {
				uni.reLaunch({
					url: '/pages/home/index'
				});
			} else if (v == 1) {
				uni.navigateBack({
					delta: 1
				});
			}
		},
	}
}
</script>

<style scoped>
.images {
	background: #f5f5f5 no-repeat fixed center;
	background-size: cover;
	color: #f5f5f5;
}

.top {
	padding-top: 1.8rem;
	display: flex;
	top: 0;
	position: fixed;
	width: 100%;
	z-index: 1;
	text-shadow: 0 0 0.125rem #0006;
}

.title {
	padding: 0.5rem 1rem 0.5rem 0;
	flex: 1;
	font-size: 1.2rem;
	font-weight: bold;
	overflow: hidden;
	white-space: nowrap;
	text-overflow: ellipsis;
}

.backButton {
	display: inline-block;
	padding: 0.8rem 0.8rem;
}

.main {
	padding-top: 4.5rem;
	backdrop-filter: blur(10px);
	min-height: calc(100vh - 4.5rem);
	background-color: #f5f5f510;
	color: #333;
}

.pictures {
	font-size: 0;
	overflow: hidden;
	border-radius: 0.25rem;
	margin: 1rem;
	box-shadow: 0 0 0.125rem #0006
}

.picture {
	width: 100%;
}

.unfold {
	display: inline-block;
	position: absolute;
	bottom: 0.75rem;
	right: 1.5rem;
}

.info {
	border-radius: 0.25rem;
	margin: 1rem;
	box-shadow: 0 0 0.125rem #0006;
	padding: 1rem;
	background-color: #f5f5f5;
}

.avatar {
	width: 2rem;
	height: 2rem;
	box-shadow: 0 0 0.125rem #000a;
	border-radius: 2rem;
}

button {
	background-color: #00897b;
	color: #f0f0f0;
}

.synopsis {
	color: #616161
}

@media (prefers-color-scheme: dark) {
	.main {
		background-color: #10101066;
		color: #ddd;
	}

	.info {
		background-color: #101010;
	}

	.synopsis {
		color: #BDBDBD
	}
}
</style>
