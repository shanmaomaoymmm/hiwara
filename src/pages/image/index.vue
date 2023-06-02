<template>
	<view>
		<view v-show="loading" style="text-align: center;padding-top: 40vh;">
			<image class="loading" src="@/static/icon/loading.png"></image>
			<br>
			<text dir="auto">{{ $t('loading1') }}</text>
		</view>
		<view v-show="!loading">
			<view v-show="error" class="error" dir="auto">
				<view v-if="error == 1">
					<image src="@/static/icon/leaves-two.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>{{ $t('image.ban[0]') }}</text>
					</view>
					<text>{{ $t('image.ban[1]') }}</text>
				</view>
				<view v-else>
					<image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
					<view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
						<text>{{ $t('image.null[0]') }}</text>
					</view>
					<text>{{ $t('image.null[1]') }}</text>
				</view>
			</view>
			<view v-show="!error" class="images"
				:style="{ backgroundImage: 'url(' + (data.files[0] || '/static/img/loli.png') + ')' }">
				<view class="panel">
					<view class="main">
						<view style="text-align: center;position: relative;font-size: 1rem;">
							<view v-show="unfold" class="pictures">
								<!-- 多图 -->
								<q-img class="picture" v-for="item, i in data.files" :src="item" @click="fillScreen(i)" />
							</view>
							<view v-show="!unfold" class="pictures">
								<!-- 单图 -->
								<q-img class="picture" :src="data.files[0]" @click="unfold = !unfold" />
							</view>
							<text dir="auto" v-if="data.files.length > 1" class="unfold" @click="unfold = !unfold">
								{{ unfold ? $t('image.unfold[0]') : $t('image.unfold[1]') }}
							</text>
						</view>
						<view class="info">
							<view style="display: flex;">
								<view @click="gotoUser()">
									<q-avatar class="avatar" :src="data.avatar" />
								</view>
								<view @click="gotoUser()" style="flex: 1;padding:0 0.5rem;line-height: 2rem;">
									<text style="font-size: 1rem;">{{ data.author }}</text>
								</view>
								<view>
									<button size="mini" @click="followers">{{ data.following ? $t('following.opt[0]') :
										$t('following.opt[1]')
									}}</button>
								</view>
							</view>
							<view class="synopsis">
								{{ data.body || data.title }}
							</view>
							<view class="status">
								<text decode="true">
									<i class="fa-regular fa-circle-play fa-fw"></i>{{ ' ' }}{{ data.numViews }}
									<i style="width: 0.8rem;display: inline-block;"></i>
									<i class="fa-regular fa-heart fa-fw"></i>{{ ' ' }}{{ data.numLikes }}
									<i style="width: 0.8rem;display: inline-block;"></i>
									<text>{{ formatDate(data.date) }}</text>
								</text>
							</view>
							<view class="opts">
								<view style="flex: 1;">
									<image class="opt" :src="data.liked ? '/static/icon/a_like.png' : '/static/icon/like.png'"
										@click="like"></image>
								</view>
								<view style="flex: 1;">
									<image class="opt" src="/static/icon/share-one.png" @click="share()"></image>
								</view>
							</view>
						</view>
						<view class="comments">
							<view style="font-weight: bold;padding: 0.5rem;" dir="auto">
								{{ $t('comments.title') }}
							</view>
							<view style="padding: 0.5rem;">
								<view v-show="comments.length == 0" style="text-align: center;padding: 2rem;" dir="auto">
									<image src="@/static/icon/cactus.png" style="width: 3rem;height: 3rem;"></image>
									<br>
									<text>{{ $t('comments.null') }}</text>
								</view>
								<view v-show="comments.length > 0" v-for="item, i in comments" :key="'comment' + i">
									<view style="display: flex;">
										<view>
											<image class="avatar" :src="item.avatar"></image>
										</view>
										<view style="flex:1;padding: 0.25rem 0.5rem;">{{ item.user }}</view>
									</view>
									<view style="margin: 0.4rem 0;">{{ item.content }}</view>
									<view class="date" dir="auto">
										<text>
											<i><b>{{ $t('comments.posted') }}</b></i>{{ ' ' }}{{ formatDate(item.date) }}
										</text>
									</view>
								</view>
							</view>
							<view class="addComment" dir="auto">
								<view style="flex:1">
									<input v-model="addCommentBody" :placeholder="$t('comments.add')" class="addCommentInput"
										@focus="addCommentActive = true" @blur="addCommentActive = false" />
								</view>
								<view :style="{ width: addCommentActive ? '4.5rem' : 0 }"
									style="width: 4.5rem;text-align: center;transition: width ease 100ms;overflow: hidden;white-space: nowrap;">
									<button size="mini" style="margin-top: 0.5rem" @click="addComment()">{{ $t('comments.submit')
									}}</button>
								</view>
							</view>
						</view>
						<view v-if="!(ori && pad)">
							<view style="padding: 0 0.5rem;">
								<view dir="auto"
									style="color: #f5f5f5;text-shadow: 0 0 0.125rem #0006;font-weight: bold;font-size: 1rem;padding:0.5rem 1rem">
									{{ $t('image.lists[0]') }}
								</view>
								<lists :data="authorOpus" type="image"></lists>
								<view dir="auto"
									style="color: #f5f5f5;text-shadow: 0 0 0.125rem #0006;font-weight: bold;font-size: 1rem;padding:0.5rem 1rem">
									{{ $t('image.lists[1]') }}
								</view>
								<lists :data="relatedOpus" type="image"></lists>
							</view>
						</view>
					</view>
					<view class="right" v-if="ori && pad">
						<view style="padding: 0 0.5rem;">
							<view
								style="color: #f5f5f5;text-shadow: 0 0 0.125rem #0006;font-weight: bold;font-size: 1rem;padding:0.5rem 1rem">
								{{ $t('image.lists[0]') }}
							</view>
							<lists :scol="2" :data="authorOpus" type="image"></lists>
							<view
								style="color: #f5f5f5;text-shadow: 0 0 0.125rem #0006;font-weight: bold;font-size: 1rem;padding:0.5rem 1rem">
								{{ $t('image.lists[1]') }}
							</view>
							<lists :scol="2" :data="relatedOpus" type="image"></lists>
						</view>
					</view>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
import {
	getImage,
	followers,
	formatDate,
	getImageInfoComments,
	getImageListForImageInfoRelated,
	getImageListForImageInfoUser,
	addCommentForImage,
	likeImage
} from '@/api/api'
import lists from "@/pages/lists/index.vue";
export default {
	components: {
		lists,
	},
	data() {
		return {
			data: {
				files: [null]
			},
			id: null,
			uid: null,
			unfold: false,
			comments: [],
			authorOpus: [],
			relatedOpus: [],
			addCommentActive: false,
			addCommentBody: null,
			loading: true,
			error: false,
			pad: false,
			ori: false
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
		this.id = opt.id
		this.uid = opt.uid
	},
	onNavigationBarButtonTap(e) {
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
		getImage(this.id, (res, code) => {
			if (code == 200) {
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
		getImageListForImageInfoUser(this.id, this.uid, (res) => {
			for (let i = 0; i < res.results.length; i++) {
				let rs = res.results[i]
				this.authorOpus.push({
					id: rs.id,
					label: rs.title,
					img:
						rs.thumbnail != null
							? "https://i.iwara.tv/image/thumbnail/" +
							rs.thumbnail.id +
							"/" +
							rs.thumbnail.name
							: null,
					date: this.formatDate(rs.createdAt),
					author: rs.user.name,
					avatar:
						rs.user.avatar != null
							? "https://i.iwara.tv/image/avatar/" +
							rs.user.avatar.id +
							"/" +
							rs.user.avatar.name
							: "https://www.iwara.tv/images/default-avatar.jpg",
					watch: rs.numViews,
					like: rs.numLikes,
					uid: rs.user.id,
				})
			}
		})
		getImageListForImageInfoRelated(this.id, (res) => {
			for (let i = 0; i < res.results.length; i++) {
				let rs = res.results[i]
				this.relatedOpus.push({
					id: rs.id,
					label: rs.title,
					img:
						rs.thumbnail != null
							? "https://i.iwara.tv/image/thumbnail/" +
							rs.thumbnail.id +
							"/" +
							rs.thumbnail.name
							: null,
					date: this.formatDate(rs.createdAt),
					author: rs.user.name,
					avatar:
						rs.user.avatar != null
							? "https://i.iwara.tv/image/avatar/" +
							rs.user.avatar.id +
							"/" +
							rs.user.avatar.name
							: "https://www.iwara.tv/images/default-avatar.jpg",
					watch: rs.numViews,
					like: rs.numLikes,
					uid: rs.user.id,
				})
			}
		})
		this.getComments()
	},
	methods: {
		formatDate(t) {
			return formatDate(t)
		},
		getComments() {
			getImageInfoComments(this.id, 0, (res) => {
				for (let i = 0; i < res.results.length; i++) {
					this.comments.push({
						user: res.results[i].user.name,
						content: res.results[i].body,
						date: res.results[i].createdAt,
						avatar: res.results[i].user.avatar ? 'https://i.iwara.tv/image/avatar/' + res.results[i].user.avatar
							.id + '/' + res.results[i].user
								.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg'
					})
				}
			})
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
		addComment() {
			addCommentForImage(this.id, this.addCommentBody, (res, code) => {
				if (code == 201) {
					uni.showToast({
						title: this.$t('comments.success'),
						icon: "none",
						duration: 3000,
					})
					this.getComments()
				} else {
					uni.showToast({
						title: this.$t('comments.fail'),
						icon: "none",
						duration: 3000,
					})
				}
			})
		},
		gotoUser() {
			uni.navigateTo({
				url: '/pages/user/index?uid=' + this.uid + '&username=' + this.data.username,
				animationType: 'slide-in-right',
				animationDuration: 100
			});
		},
		fillScreen(i) {
			let send = encodeURIComponent(JSON.stringify(this.data))
			uni.navigateTo({
				url: '/pages/image/fill?index=' + i + '&data=' + send,
				animationType: 'slide-in-right',
				animationDuration: 100,
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
		like() {
			if (this.data.liked) {
				likeImage(this.id, 0, (res, code) => {
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
				likeImage(this.id, 1, (res, code) => {
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
			}
		},
	}
}
</script>

<style scoped>
.images {
	background: #acacac no-repeat fixed center;
	background-size: cover;
	color: #f5f5f5;
}

.top {
	padding-top: 2rem;
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

.panel {
	backdrop-filter: blur(10px);
	height: calc(100vh - var(--window-top));
	background-color: #f5f5f510;
	display: flex;
}

.main {
	padding-top: 0.2rem;
	color: #333;
	flex: 2;
	overflow: auto;
}

.right {
	flex: 1;
	padding-top: 0.2rem;
	color: #333;
	overflow: auto;
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
	background-color: #0006;
	aspect-ratio: 16/9;
	color: #c0c0c0;
}

.unfold {
	display: inline-block;
	position: absolute;
	bottom: 0.75rem;
	right: 1.5rem;
	color: #f5f5f5;
	text-shadow: 0 0 0.5rem #000a;
}

.info {
	border-radius: 0.25rem;
	margin: 1rem;
	box-shadow: 0 0 0.125rem #0006;
	padding: 1rem;
	background-color: #f5f5f5;
}

.comments {
	border-radius: 0.25rem;
	margin: 1rem;
	box-shadow: 0 0 0.125rem #0006;
	background-color: #f5f5f5;
	padding: 0.5rem;
}

.addComment {
	display: flex;
}

.addCommentInput {
	padding: 0.5rem;
	border-bottom: solid 2px #00897b;
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
	color: #616161;
	padding: 1rem 0;
	font-size: 0.9rem;
	word-wrap: break-word;
}

.status {
	font-size: 0.85rem;
}

.date {
	text-align: right;
	color: #616161;
	font-size: 0.9rem;
}

.error {
	text-align: center;
	padding-top: 38vh;
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

.opts {
	display: flex;
	text-align: center;
	padding-top: 1rem;
}

.opt {
	width: 1.6rem;
	height: 1.6rem;
}

@media (prefers-color-scheme: dark) {

	.images {
		background-color: #616161;
	}

	.panel {
		background-color: #10101066;
	}

	.main,
	.right {
		color: #ddd;
	}

	.info,
	.comments {
		background-color: #101010;
	}

	.synopsis,
	.status {
		color: #BDBDBD
	}
}
</style>
