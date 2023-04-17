<template>
	<view>
		<view v-show="loading" style="text-align: center;padding-top: 40vh;">
			<image class="loading" src="@/static/icon/loading.png"></image>
			<br>
			<text>资源加载中……</text>
		</view>
		<view v-show="!loading">
			<view v-show="error" class="error">
				<view v-if="error == 1">
					<image src="@/static/icon/leaves-two.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>一叶障目，不见泰山</text>
					</view>
					<text>你没有权限查看此内容，请到别的地方看看吧</text>
				</view>
				<view v-else>
					<image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>大漠孤烟直，长河落日圆</text>
					</view>
					<text>这里没有任何东西，请到别的地方看看吧</text>
				</view>
			</view>
			<view v-show="!error">
				<view class="back">
					<i @click="back(1)" class="fa-solid fa-angle-left backButton"></i>
					<i @click="back(0)" class="fa-solid fa-house backButton"></i>
				</view>
				<view class="top">
					<video id="videoPlayer" class="player" :src="src" :title="data.title" :mobilenet-hint-type="1"
						:vslide-gesture="true">
					</video>
					<view class="tabs">
						<view style="flex: 1;">
							<text class="tabs-button" @click="tab = 0" :class="{ tabsActive: tab == 0 }">简介</text>
							<text class="tabs-button" @click="tab = 1" :class="{ tabsActive: tab == 1 }">评论</text>
						</view>
						<view style="flex: 1;text-align: right;">
							<span class="definitionButton" @click="$refs.definitionPopup.open()">
								<i class="fa-solid fa-film fa-fw"></i>{{ ' ' }}{{ definition }}
							</span>
						</view>
					</view>
				</view>
				<view class="bottom" @touchmove="handletouchmove" @touchstart="handletouchstart" @touchend="handletouchend">
					<view class="bottom1" :style="{ left: tab == 0 ? 0 : '-100vw' }">
						<view class="bottom2">
							<info :id="id" :uid="uid" ref="info"></info>
						</view>
						<view class="bottom2">
							<comments :id="id"></comments>
						</view>
					</view>
				</view>
			</view>
		</view>
		<uni-popup ref="definitionPopup" type="bottom">
			<view class="definitionPopup">
				<view class="definitionTitle">
					<text>画质</text>
				</view>
				<view v-for="item, i in data.sources" :key="'definition' + i"
					:class="{ definitionButtonSelect: item.name == definition }" style="padding:0.75rem 0;"
					@click="definitionSelect(item)">
					{{ item.name }}
					<br>
					{{ item.src }}
				</view>
			</view>
		</uni-popup>
	</view>
</template>

<script>
import info from './info.vue'
import comments from './comments.vue'
import {
	getVideo,
	getStorage,
	setStorage
} from '@/api/api.js'
export default {
	components: {
		info,
		comments
	},
	data() {
		return {
			src: null,
			tab: 0,
			id: null,
			uid: null,
			loading: true,
			error: 0,
			data: {
				id: null,
				title: null,
				author: null,
				avatar: null,
				synopsis: null,
				date: null,
				numView: null,
				numLikes: null,
				liked: null,
				private: null,
				sources: []
			},
			definition: null,
			//滑动
			flag: 0, //1向左滑动,2向右滑动,3向上滑动 4向下滑动
			lastX: 0,
			lastY: 0,
			videoContex: null
		}
	},
	onLoad: function (opt) {
		this.id = opt.id
		this.uid = opt.uid
	},
	watch: {
		data() {
			this.$nextTick(() => {
				this.initializeVideo(this.data.sources)
				this.$refs.info.data = this.data
			})
		},
		flag(v) {
			if (v == 1) {
				this.tab = 1
			} else if (v == 2) {
				if (this.tab == 1) {
					this.tab = 0
				} else {
					this.back(1)
				}
			}
		}
	},
	mounted() {
		getStorage('definition', (a) => {
			let b
			if (a) {
				b = a
			} else {
				b = 'Source'
			}
			this.definition = b
		})
		getVideo(this.id, (res, code) => {
			this.loading = false
			if (code == 200) {
				this.error = 0
				this.data = res
			} else if (code == 403) {
				this.error = 1
			} else if (code == 408) {
				this.error = 2
			}
		})
	},
	onHide: function () {
		uni.createVideoContext('videoPlayer').pause()
	},
	methods: {
		initializeVideo(sources) {
			for (let i = 0; i < sources.length; i++) {
				if (sources[i].name == this.definition) {
					this.src = sources[i].view
				}
			}
		},
		definitionSelect(item) {
			this.definition = item.name
			this.src = item.view
			setStorage('definition', item.name)
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
		handletouchmove: function (event) {
			// console.log(event)
			if (this.flag !== 0) {
				return;
			}
			let currentX = event.changedTouches[0].pageX;
			let currentY = event.changedTouches[0].pageY;
			let tx = currentX - this.lastX;
			let ty = currentY - this.lastY;
			let sensitivity = 10
			//调节灵敏度
			if (Math.abs(tx) > Math.abs(ty) + sensitivity) {
				//左右方向滑动
				if (Math.abs(tx) > Math.abs(ty)) {
					if (tx < 0) {
						// 向左滑动
						this.flag = 1;

					} else if (tx > 0) {
						//向右滑动 
						this.flag = 2;
					}
				}
				//上下方向滑动
				else {
					if (ty < 0) {
						//向上滑动
						this.flag = 3;
					} else if (ty > 0) {
						//向下滑动
						this.flag = 4;
					}
				}
			}
			//将当前坐标进行保存以进行下一次计算
			this.lastX = currentX;
			this.lastY = currentY;
		},
		handletouchstart: function (event) {
			this.lastX = event.changedTouches[0].pageX;
			this.lastY = event.changedTouches[0].pageY;
		},
		handletouchend: function (event) {
			//停止滑动
			this.flag = 0;
		}
	}
}
</script>

<style scoped>
.player {
	width: 100vw;
	height: 56.25vw;
}

.back {
	font-size: 1rem;
	padding: 1.8rem 0.5rem 0 0.5rem;
	background-color: #000;
	color: #f0f0f0;
}

.backButton {
	padding: 0.7rem 0.8rem;
	display: inline-block;
}

.top {
	background-color: #f5f5f5;
	z-index: 10;
}


.tabs {
	box-shadow: 0 0.25rem 0.25rem #0002;
	padding: 0 1rem;
	display: flex;
}

.tabs-button {
	padding: 0.5rem 1.5rem 0.75rem 1.5rem;
	display: inline-block;
	border-bottom: solid 0.125rem #f5f5f5;
	transition: borderColor 100ms ease;
}

.bottom {
	width: 100vw;
	height: calc(100vh - 56.25vw - 7.2rem);
	overflow: hidden;
}

.bottom1 {
	display: flex;
	width: 200vw;
	position: relative;
	left: 0;
	transition: left 100ms ease;
}

.bottom2 {
	flex: 1;
	height: calc(100vh - 56.25vw - 7.2rem);
	overflow: auto;
}

.definitionButton {
	padding: 0.6rem 1rem 0.7rem 1rem;
	display: inline-block;
	color: #616161;
}

.definitionPopup {
	text-align: center;
	font-size: 1.1rem;
	padding: 0.5rem 0;
	background-color: #f5f5f5;
}

.definitionButtonSelect {
	background-color: #00897b55;
}

.definitionTitle {
	padding: 0.75rem 0;
	font-weight: bold;
	color: #616161;
}

.tabsActive {
	border-color: #00897b !important;
	color: #00897b;
}

.loading {
	width: 4rem;
	height: 4rem;
	animation: rotate 350ms linear infinite;
}

@keyframes rotate {
	0% {
		transform: rotate(0deg);
	}

	25% {
		transform: rotate(90deg);
	}

	50% {
		transform: rotate(180deg);
	}

	75% {
		transform: rotate(270deg);
	}

	100% {
		transform: rotate(360deg);
	}
}

.error {
	text-align: center;
	padding-top: 38vh;
}

@media (prefers-color-scheme: dark) {

	.top {
		background-color: #101010;
	}

	.tabs-button {
		border-color: #101010;
	}

	.definitionPopup {
		background-color: #4f4f4f;
	}

	.tabs {
		box-shadow: 0 0.25rem 0.25rem #fff2;
	}

	.definitionButton,
	.definitionTitle {
		color: #BDBDBD
	}
}
</style>