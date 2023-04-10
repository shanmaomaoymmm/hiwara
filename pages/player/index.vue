<template>
	<view>
		<view v-show="loading" style="text-align: center;padding-top: 40vh;">
			<image class="loading" src="../../static/icon/loading.png"></image>
			<br>
			<text>加载中……</text>
		</view>
		<view v-show="!loading">
			<view v-show="error" class="error">
				<view v-if="error==1">
					<image src="../../static/icon/leaves-two.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>一叶障目，不见泰山</text>
					</view>
					<text>你没有权限查看此内容，请到别的地方看看吧</text>
				</view>
				<view v-else>
					<image src="../../static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>大漠孤烟直，长河落日圆</text>
					</view>
					<text>这里没有任何东西，请到别的地方看看吧</text>
				</view>
			</view>
			<view v-show="!error">
				<view class="top">
					<view class="back">
						<i class="fas fa-angle-left"></i>
					</view>
					<video class="player" :src="src" :title="data.title" :mobilenet-hint-type="1" :vslide-gesture="true"> </video>
					<view class="tabs">
						<view style="flex: 1;">
							<text class="tabs-button" @click="tab=0" :class="{tabsActive:tab==0}">简介</text>
							<text class="tabs-button" @click="tab=1" :class="{tabsActive:tab==1}">评论</text>
						</view>
						<view style="flex: 1;text-align: right;">
							<text class="definitionButton" @click="$refs.definitionPopup.open('bottom')">
								<i class="fa-solid fa-film fa-fw"></i>{{' '}}{{definition}}
							</text>
						</view>
					</view>
				</view>
				<view class="bottom" @touchmove="handletouchmove" @touchstart="handletouchstart" @touchend="handletouchend">
					<view class="bottom1">
						<view class="bottom2" :style="{left:tab==0?0:'-100vw'}">
							<view class="info">
								<info v-show="tab==0" :id="id" :uid="uid" ref="info"></info>
							</view>
							<view class="comments">
								<comments v-show="tab==1" :id="id"></comments>
							</view>
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
				<view v-for="item,i in data.sources" :key="'definition'+i"
					:class="{definitionButtonSelect:item.name==definition}" style="padding:0.75rem 0;"
					@click="definitionSelect(item)">
					{{item.name}}
					<br>
					{{item.src}}
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
		getStorage
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
				lastY: 0
			}
		},
		onLoad: function(opt) {
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
					this.tab = 0
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
			},
			handletouchmove: function(event) {
				// console.log(event)
				if (this.flag !== 0) {
					return;
				}
				let currentX = event.changedTouches[0].pageX;
				let currentY = event.changedTouches[0].pageY;
				let tx = currentX - this.lastX;
				let ty = currentY - this.lastY;

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
				//将当前坐标进行保存以进行下一次计算
				this.lastX = currentX;
				this.lastY = currentY;
			},
			handletouchstart: function(event) {
				this.lastX = event.changedTouches[0].pageX;
				this.lastY = event.changedTouches[0].pageY;
			},
			handletouchend: function(event) {
				//停止滑动
				this.flag = 0;
			}
		}
	}
</script>

<style scoped>
	.back {
		color: #f5f5f5;
		text-shadow: 0 0 0.125rem #000a;
		font-size: 1.5rem;
		position: absolute;
		top: 0;
		left: 0;
		padding: 0.75rem;
	}

	.player {
		width: 100vw;
		height: 56.25vw;
	}

	.top {
		position: fixed;
		background-color: #f5f5f5;
		z-index: 10;
	}


	.tabs {
		box-shadow: 0 0.25rem 0.25rem #E0E0E0;
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
		padding-top: calc(56.25vw + 3rem);
		width: 100vw;
		height: calc(100vh - 56.25vw - 3rem);
		overflow: hidden;
	}

	.bottom1 {
		height: calc(100vh - 56.25vw - 3rem);
		overflow-y: auto;
		overflow-x: hidden;
	}

	.bottom2 {
		display: flex;
		width: 200vw;
		position: relative;
		transition: left 200ms ease;
	}

	.info {
		flex: 1;
		overflow: hidden;
	}

	.comments {
		flex: 1;
		overflow: hidden;
	}

	.definitionButton {
		padding: 0.5rem 1.5rem 0.875rem 1.5rem;
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
		animation: rotate 800ms linear infinite;
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
			box-shadow: 0 0.25rem 0.25rem #232323;
		}

		.definitionButton,
		.definitionTitle {
			color: #BDBDBD
		}
	}
</style>