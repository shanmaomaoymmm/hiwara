<template>
	<view style="height: 100%;">
		<view v-if="loading" style="text-align: center;padding-top: 40vh;">
			<image class="loading" src="@/static/icon/loading.png"></image>
			<br>
			<text>{{ $t('loading1') }}</text>
		</view>
		<view v-else style="height: 100%;">
			<view v-if="error" class="error">
				<view v-if="error == 1">
					<image src="@/static/icon/leaves-two.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>{{ $t('player.player.ban[0]') }}</text>
					</view>
					<text>{{ $t('player.player.ban[1]') }}</text>
				</view>
				<view v-else>
					<image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>{{ $t('player.player.null[0]') }}</text>
					</view>
					<text>{{ $t('player.player.null[1]') }}</text>
				</view>
			</view>
			<view v-else style="display: flex;height: 100%;">
				<view class="main">
					<view class="top">
						<video id="videoPlayer" class="player" :src="src" :title="data.title" vslide-gesture="true"
							:poster="data.preview" :autoplay="autoplay">
						</video>
					</view>
					<view class="tabs" v-if="!(ori && pad)">
						<view style="flex: 1;">
							<text class="tabs-button" @click="tab = 0" :class="{ tabsActive: tab == 0 }">{{
								$t('player.player.tab.abstract') }}</text>
							<text class="tabs-button" @click="tab = 1" :class="{ tabsActive: tab == 1 }">{{
								$t('player.player.tab.comments') }}</text>
						</view>
						<view style="flex: 1;text-align: right;">
							<span class="definitionButton" @click="$refs.definitionPopup.open()">
								<i class="fa-solid fa-film fa-fw"></i>{{ ' ' }}{{ definition }}
							</span>
						</view>
					</view>
					<view class="bottom">
						<view v-if="ori && pad" style="overflow: auto;height: 100%;padding-bottom:1rem ;">
							<info :vid="vid" :uid="uid" ref="info" :data="data"></info>
						</view>
						<swiper v-else style="height: 100%;" :current="tab" @change="swiper" :duration="100">
							<swiper-item>
								<view style="height: 100%;overflow: auto;">
									<info :vid="vid" :uid="uid" ref="info" :data="data">
									</info>
									<lists :authorOpus="authorOpus" :relatedOpus="relatedOpus" :scol="pad ? null : 2"></lists>
								</view>
							</swiper-item>
							<swiper-item>
								<comments :vid="vid"></comments>
							</swiper-item>
						</swiper>
					</view>
				</view>
				<view class="right" v-show="ori && pad">
					<view class="tabs">
						<view style="flex: 1;">
							<span class="definitionButton" @click="$refs.definitionPopup.open()">
								<i class="fa-solid fa-film fa-fw"></i>{{ ' ' }}{{ definition }}
							</span>
						</view>
						<view style="flex: 1;text-align: right;">
							<text class="tabs-button" @click="tab = 0" :class="{ tabsActive: tab == 0 }">{{ $t('player.player.tab.more')
							}}</text>
							<text class="tabs-button" @click="tab = 1" :class="{ tabsActive: tab == 1 }">{{
								$t('player.player.tab.comments') }}</text>
						</view>
					</view>
					<swiper style="height: 100%;" :current="tab" @change="swiper" :duration="100">
						<swiper-item>
							<view style="height: 100%;overflow: auto;">
								<lists :authorOpus="authorOpus" :relatedOpus="relatedOpus" :scol="2"></lists>
							</view>
						</swiper-item>
						<swiper-item>
							<comments :vid="vid"></comments>
						</swiper-item>
					</swiper>
				</view>
			</view>
		</view>
		<uni-popup ref="definitionPopup" type="bottom">
			<view class="definitionPopup">
				<view class="definitionTitle">
					<text>{{ $t('player.player.definition') }}</text>
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
import lists from './lists.vue'
import {
	getVideo,
	getStorage,
	setStorage,
	getVideoListForPlayInfoUser,
	getVideoListForPlayInfoRelated,
	fill0,
	formatDate,
} from '@/api/api.js'
export default {
	components: {
		info,
		comments,
		lists,
	},
	data() {
		return {
			src: null,
			tab: 0,
			vid: null,
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
				preview: null,
				sources: [],
				username: null,
			},
			definition: null,
			videoContex: null,
			autoplay: false,
			authorOpus: [],
			relatedOpus: [],
			pad: false,
			ori: false,
		}
	},
	mounted() {
		let media = uni.createMediaQueryObserver(this)
		media.observe({
			orientation: 'landscape'
		}, (res) => {
			this.ori = res
		})
	},
	onLoad: function (opt) {
		this.vid = opt.id
		this.uid = opt.uid
	},
	watch: {
		data() {
			this.$nextTick(() => {
				this.initializeVideo(this.data.sources)
			})
		}
	},
	onNavigationBarButtonTap(e) {
		console.log(e)
		if (e.type == 'home') {
			this.$backhome()
		}
	},
	created() {
		if (this.$deviceType == 'phone') {
			this.pad = false
		} else {
			this.pad = true
		}
		getStorage('definition', (a) => {
			let b
			if (a) {
				b = a
			} else {
				b = 'Source'
			}
			this.definition = b
		})
		getStorage('autoplay', (a) => {
			let b
			if (a) {
				b = a
			} else {
				b = false
			}
			this.autoplay = b
		})
		getVideo(this.vid, (res, code) => {
			if (code == 200) {
				this.error = 0
				this.data = res
			} else if (code == 403) {
				this.error = 1
			} else if (code == 408) {
				this.error = 2
			}
			uni.setNavigationBarTitle({
				title: this.data.title
			})
			this.loading = false
		})
		getVideoListForPlayInfoUser(this.vid, this.uid, (res) => {
			for (let i = 0; i < res.results.length; i++) {
				let rs = res.results[i]
				this.authorOpus.push({
					id: rs.id,
					label: rs.title,
					img: rs.file != null ? 'https://i.iwara.tv/image/thumbnail/' + rs.file.id +
						'/thumbnail-' + fill0(rs.thumbnail, 1) + '.jpg' : '/static/img/nachoneko.jpg',
					date: this.formatDate(rs.createdAt),
					author: rs.user.name,
					avatar: rs.user.avatar != null ? 'https://i.iwara.tv/image/avatar/' + rs.user.avatar
						.id + '/' + rs.user
							.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
					watch: rs.numViews,
					like: rs.numLikes,
					uid: rs.user.id
				})
			}
		})
		getVideoListForPlayInfoRelated(this.vid, (res) => {
			for (let i = 0; i < res.results.length; i++) {
				let rs = res.results[i]
				this.relatedOpus.push({
					id: rs.id,
					label: rs.title,
					img: rs.file != null ? 'https://i.iwara.tv/image/thumbnail/' + rs.file.id +
						'/thumbnail-' + fill0(rs.thumbnail, 1) + '.jpg' : '/static/img/nachoneko.jpg',
					date: this.formatDate(rs.createdAt),
					author: rs.user.name,
					avatar: rs.user.avatar != null ? 'https://i.iwara.tv/image/avatar/' + rs.user.avatar
						.id + '/' + rs.user
							.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
					watch: rs.numViews,
					like: rs.numLikes,
					uid: rs.user.id
				})
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
			} else {
				uni.navigateBack({
					delta: v
				});
			}
		},
		swiper: function (t) {
			this.tab = t.detail.current
		},
		formatDate(t) {
			return formatDate(t)
		},
	}
}
</script>

<style scoped>
.player {
	width: 100%;
	height: 100%;
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
	width: 100%;
	aspect-ratio: 16/9;
}


.tabs {
	box-shadow: 0 0.25rem 0.25rem #0002;
	padding: 0 1rem;
	display: flex;
	white-space: nowrap;
}

.tabs-button {
	padding: 0.75rem 1.5rem;
	display: inline-block;
	border-bottom: solid 0.125rem #f5f5f5;
	transition: borderColor 100ms ease;
}

.bottom {
	flex: 1;
	width: 100%;
	overflow: hidden;
}

.bottom1 {
	display: flex;
	width: 200%;
	height: 100%;
	position: relative;
	left: 0;
	transition: left 100ms ease;
	overflow: hidden;
}

.bottom2 {
	flex: 1;
	overflow-y: auto;
	overflow-x: hidden;
	height: 100%;
}

.definitionButton {
	padding: 0.8rem 1rem;
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

.main {
	flex: 7;
	display: flex;
	flex-direction: column;
	height: 100%;
	overflow: hidden;
}

.right {
	flex: 4;
	height: 100%;
	overflow: hidden;
	display: flex;
	flex-direction: column;
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