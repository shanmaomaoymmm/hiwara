<template>
	<view class="info">
		<view style="padding:0 1rem;">
			<view style="display: flex;">
				<view @click="gotoUser()">
					<q-avatar class="avatar" :src="data.avatar" />
				</view>
				<view @click="gotoUser()" style="flex: 1;padding:0 0.5rem;line-height: 2rem;">
					<text style="font-size: 1rem;">{{ data.author }}</text>
				</view>
				<view>
					<button size="mini" @click="followers"><text>{{ data.following ? $t('following.opt[0]')
						: $t('following.opt[1]')
					}}</text></button>
				</view>
			</view>
			<view @click="allinfo = !allinfo" class="title" :style="{ height: allinfo ? height.title2 : height.title1 }">
				<i class="fas fa-chevron-down titletip" :style="{ transform: allinfo ? 'rotate(180deg)' : 'rotate(0deg)' }"></i>
				<view id="title1" v-show="!allinfo"
					style="whiteSpace:nowrap;overflow: hidden;text-overflow: ellipsis;margin-bottom: 2rem;">
					<text>{{ data.title }}</text>
				</view>
				<view id="title2">
					<text>{{ data.title }}</text>
				</view>
			</view>
			<view class="status">
				<text decode="true">
					<i class="fa-regular fa-circle-play fa-fw"></i>{{ ' ' }}{{ data.numView }}
					<i style="width: 0.8rem;display: inline-block;"></i>
					<i class="fa-regular fa-heart fa-fw"></i>{{ ' ' }}{{ data.numLikes }}
					<i style="width: 0.8rem;display: inline-block;"></i>
					<text>{{ formatDate(data.date) }}</text>
				</text>
			</view>
			<view class="synopsis" :style="{ height: allinfo ? height.synopsis : '0px' }">
				<view id="synopsis">
					<text>{{ data.synopsis }}</text>
				</view>
			</view>
			<view style="display: flex;text-align: center;overflow: hidden;">
				<view class="opt" @click="like()">
					<image class="icon" :src="data.liked ? '/static/icon/a_like.png' : '/static/icon/like.png'"></image>
					<view :style="{ height: allinfo ? '1rem' : 0 }" style="overflow: hidden;">
						<text>{{ data.liked ? $t('liked.opt[0]') : $t('liked.opt[1]') }}</text>
					</view>
				</view>
				<view class="opt" @click="share()">
					<image class="icon" src="@/static/icon/share-one.png"></image>
					<view :style="{ height: allinfo ? '1rem' : 0 }" style="overflow: hidden;">
						<text>{{ $t('player.info.share') }}</text>
					</view>
				</view>
				<view class="opt" @click="openDownloadPopup()">
					<image class="icon" src="@/static/icon/download-four.png"></image>
					<view :style="{ height: allinfo ? '1rem' : 0 }" style="overflow: hidden;">
						<text>{{ $t('player.info.download') }}</text>
					</view>
				</view>
				<view class="opt" @click="copyLinkButton = !copyLinkButton">
					<image class="icon" src="@/static/icon/copy-link.png"></image>
					<view :style="{ height: allinfo ? '1rem' : 0 }" style="overflow: hidden;">
						<text>{{ $t('player.info.copy') }}</text>
					</view>
				</view>
			</view>
			<view style="overflow: hidden;text-align: center" :style="{ height: copyLinkButton ? '3.2rem' : 0 }">
				<view style="padding: 0.5rem 0;display: flex;">
					<view v-for="item, i in data.sources" style="flex: 1;">
						<button size="mini" @click="copyLink('https:' + item.download)">
							<i class="fa-solid fa-link fa-fw"></i>{{ ' ' }}{{ item.name }}
						</button>
					</view>
				</view>
			</view>
		</view>
		<uni-popup ref="downloadPopup" type="bottom">
			<view class="downloadPopup">
				<view class="downloadTitle">
					<text>{{ $t('player.info.download') }}</text>
				</view>
				<view v-for="item, i in data.sources" :key="'download' + i" style="padding:0.75rem 0;" @click="download(item)">
					{{ item.name }}
				</view>
			</view>
		</uni-popup>
	</view>
</template>

<script>
import {
	formatDate,
	followers,
	likeVideo,
	download,
	storagePermission,
	getStorage,
	ariaDownload,
} from '@/api/api.js'
export default {
	data() {
		return {
			allinfo: false,
			height: {
				title1: null,
				title2: null,
				synopsis: null
			},
			copyLinkButton: false,
			authorOpus: [],
			relatedOpus: [],
			ariaon: false,
		}
	},
	props: ['vid', 'uid', 'data'],
	created() {
		getStorage('ariaon', (a) => {
			let b
			if (a) {
				b = a
			} else {
				b = false
			}
			this.ariaon = b
		})
	},
	mounted() {
		this.setHeight()
	},
	methods: {
		setHeight() {
			uni.createSelectorQuery().in(this).select('#title1').boundingClientRect(data => {
				this.height.title1 = data.height + 'px'
			}).exec()
			uni.createSelectorQuery().in(this).select('#title2').boundingClientRect(data => {
				this.height.title2 = data.height + 'px'
			}).exec()
			uni.createSelectorQuery().in(this).select('#synopsis').boundingClientRect(data => {
				this.height.synopsis = data.height + 'px'
			}).exec()
		},
		formatDate(t) {
			return formatDate(t)
		},
		copyLink(val) {
			uni.setClipboardData({
				data: val,
				success: function () {
					uni.showToast({
						title: this.$t('player.info.copied'),
						icon: "none",
						duration: 3000,
					})
				}
			});
		},
		followers() {
			if (this.data.following) {
				followers(this.uid, 0, (res, code) => {
					if (code == 204) {
						uni.showToast({
							title: this.$t('following.del'),
							icon: "none",
							duration: 3000,
						})
						this.data.following = !this.data.following
					} else {
						uni.showToast({
							title: this.$t('optFail'),
							icon: "none",
							duration: 3000,
						})
					}
				})
			} else {
				followers(this.uid, 1, (res, code) => {
					if (code == 201) {
						uni.showToast({
							title: this.$t('following.push'),
							icon: "none",
							duration: 3000,
						})
						this.data.following = !this.data.following
					} else {
						uni.showToast({
							title: this.$t('optFail'),
							icon: "none",
							duration: 3000,
						})
					}
				})
			}
		},
		like() {
			if (this.data.liked) {
				likeVideo(this.vid, 0, (res, code) => {
					if (code == 204) {
						uni.showToast({
							title: this.$t('liked.del'),
							icon: "none",
							duration: 3000,
						})
						this.data.liked = !this.data.liked
					} else {
						uni.showToast({
							title: this.$t('optFail'),
							icon: "none",
							duration: 3000,
						})
					}
				})
			} else {
				likeVideo(this.vid, 1, (res, code) => {
					if (code == 201) {
						uni.showToast({
							title: this.$t('liked.push'),
							icon: "none",
							duration: 3000,
						})
						this.data.liked = !this.data.liked
					} else {
						uni.showToast({
							title: this.$t('optFail'),
							icon: "none",
							duration: 3000,
						})
					}
				})
				if (this.ariaon) {
					const url = 'https:' + this.data.sources[this.data.sources.length - 1].download
					const replaceSpecialCharacters = (str, replacement = '_') => str.replace(/([ /?*:\<\>\\|@#\$%&()]+)/g, replacement);
					const title = replaceSpecialCharacters(this.data.title)
					const name = title + '[' + this.data.id.toLowerCase() + ']' + this.data.username + '.mp4'
					ariaDownload(url, name)
				}
			}
		},
		gotoUser() {
			uni.navigateTo({
				url: '/pages/user/index?uid=' + this.uid + '&username=' + this.data.username,
				animationType: 'slide-in-right',
				animationDuration: 100
			});
		},
		share() {
			// #ifdef APP-PLUS
			uni.shareWithSystem({
				type: 'text',
				summary: this.data.title,
				href: 'https://www.iwara.tv/video/' + this.data.id + '/' + this.data.slug
			})
			// #endif

			// #ifndef APP-PLUS
			uni.showToast({
				title: this.$t('player.info.device'),
				icon: "none",
				duration: 3000,
			})
			// #endif
		},
		openDownloadPopup() {
			// #ifdef APP-PLUS
			if (storagePermission() == true) {
				this.$refs.downloadPopup.open()
			}
			// #endif
			// #ifndef APP-PLUS
			uni.showToast({
				title: this.$t('player.info.device'),
				icon: "none",
				duration: 3000,
			})
			// #endif
		},
		download(it) {
			let dlUrl = 'https:' + it.download
			const replaceSpecialCharacters = (str, replacement = '_') => str.replace(/([ /?*:\<\>\\|@#\$%&()]+)/g, replacement);
			const title = replaceSpecialCharacters(this.data.title)
			download('video', dlUrl, title, () => {
				this.$refs.downloadPopup.close()
			})
		}
	}
}
</script>

<style scoped>
.info {
	padding-top: 1rem;
	position: relative;
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

.title {
	font-size: 1.1rem;
	padding-top: 0.5rem;
	overflow: hidden;
}

.titletip {
	position: absolute;
	right: 1rem;
	font-size: 0.5rem;
	transform: rotate(0deg);
	transition: transform ease 100ms;
}

.status {
	padding: 0.5rem 0;
	font-size: 0.85rem;
}

.synopsis {
	overflow: hidden;
	word-wrap: break-word;
	font-size: 0.9rem;
}

.synopsis,
.status {
	color: #616161
}

.icon {
	width: 1.6rem;
	height: 1.6rem;
}

.opt {
	padding: 0.5rem 0;
	flex: 1;
	font-size: 0.8rem;
	color: #616161
}

* {
	transition: height ease 100ms;
}

.downloadTitle {
	padding: 0.75rem 0;
	font-weight: bold;
	color: #616161;
}

.downloadPopup {
	text-align: center;
	font-size: 1.1rem;
	padding: 0.5rem 0;
	background-color: #f5f5f5;
}

@media (prefers-color-scheme: dark) {

	.synopsis,
	.status {
		color: #BDBDBD
	}

	.opt {
		color: #BDBDBD;
	}

	.downloadPopup {
		background-color: #4f4f4f;
	}

	.downloadButton,
	.downloadTitle {
		color: #BDBDBD
	}
}
</style>