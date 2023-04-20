<template>
	<view class="info">
		<view style="padding:0 1rem;">
			<view style="display: flex;">
				<view>
					<image class="avatar" :src="data.avatar"></image>
				</view>
				<view style="flex: 1;padding:0 0.5rem;line-height: 2rem;">
					<text style="font-size: 1rem;">{{ data.author }}</text>
				</view>
				<view>
					<button size="mini" @click="followers"><text>{{ data.following ? "已关注" : "＋ 关注"
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
						<text>{{ data.liked ? '已点赞' : '点赞' }}</text>
					</view>
				</view>
				<view class="opt">
					<image class="icon" src="@/static/icon/share-one.png"></image>
					<view :style="{ height: allinfo ? '1rem' : 0 }" style="overflow: hidden;">
						<text>分享</text>
					</view>
				</view>
				<view class="opt">
					<image class="icon" src="@/static/icon/download-four.png"></image>
					<view :style="{ height: allinfo ? '1rem' : 0 }" style="overflow: hidden;">
						<text>缓存</text>
					</view>
				</view>
				<view class="opt" @click="copyLinkButton = !copyLinkButton">
					<image class="icon" src="@/static/icon/copy-link.png"></image>
					<view :style="{ height: allinfo ? '1rem' : 0 }" style="overflow: hidden;">
						<text>复制链接</text>
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
		<view>
			<view style="padding:0.5rem 1rem">
				<text>该作者的其他作品</text>
			</view>
			<lists :data="authorOpus" type="video"></lists>
			<view style="padding:0.5rem 1rem">
				<text>相关作品</text>
			</view>
			<lists :data="relatedOpus" type="video"></lists>
		</view>
	</view>
</template>

<script>
import lists from '@/pages/lists/index.vue'
import {
	formatDate,
	getVideoListForPlayInfoUser,
	getVideoListForPlayInfoRelated,
	fill0,
	followers,
	likeVideo
} from '@/api/api.js'
export default {
	components: {
		lists
	},
	data() {
		return {
			data: {
				title: null,
				author: null,
				avatar: null,
				synopsis: null,
				date: null,
				numView: 0,
				numLikes: 0,
				liked: false,
				private: false,
				following: false,
				sources: []
			},
			allinfo: false,
			height: {
				title1: null,
				title2: null,
				synopsis: null
			},
			copyLinkButton: false,
			authorOpus: [],
			relatedOpus: [],
		}
	},
	props: ['vid', 'uid'],
	watch: {
		data: {
			handler() {
				this.$nextTick(() => {
					this.setHeight()
				})
			},
			immediate: true
		},
	},
	onBackPress: () => {
		console.log('onBackPress')
	},
	mounted() {
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
	methods: {
		setHeight() {
			uni.createSelectorQuery().in(this).select("#title1").boundingClientRect(data => {
				this.height.title1 = data.height + 'px'
			}).exec()
			uni.createSelectorQuery().in(this).select("#title2").boundingClientRect(data => {
				this.height.title2 = data.height + 'px'
			}).exec()
			uni.createSelectorQuery().in(this).select("#synopsis").boundingClientRect(data => {
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
						title: "已复制",
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
		like() {
			if (this.data.liked) {
				likeVideo(this.vid, 0, (res, code) => {
					if (code == 204) {
						uni.showToast({
							title: "已取消点赞",
							icon: "none",
							duration: 3000,
						})
						this.data.liked = !this.data.liked
					} else {
						uni.showToast({
							title: "操作失败",
							icon: "none",
							duration: 3000,
						})
					}
				})
			} else {
				likeVideo(this.vid, 1, (res, code) => {
					if (code == 201) {
						uni.showToast({
							title: "点赞成功！！！",
							icon: "none",
							duration: 3000,
						})
						this.data.liked = !this.data.liked
					} else {
						uni.showToast({
							title: "操作失败",
							icon: "none",
							duration: 3000,
						})
					}
				})
			}
		}
	}
}
</script>

<style scoped>
.info {
	padding: 1rem 0;
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

@media (prefers-color-scheme: dark) {

	.synopsis,
	.status {
		color: #BDBDBD
	}

	.opt {
		color: #BDBDBD;
	}
}
</style>