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
				<text style="color: #f5f5f5;" v-if="data.files.length > 1" class="unfold" @click="unfold = !unfold">
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
			</view>
			<view class="comments">
				<view style="font-weight: bold;padding: 0.5rem;">
					评论
				</view>
				<view style="padding: 0.5rem;">
					<view v-show="comments.length == 0" style="text-align: center;padding: 2rem;">
						<image src="@/static/icon/cactus.png" style="width: 3rem;height: 3rem;"></image>
						<br>
						<text>还没有评论</text>
					</view>
					<view v-show="comments.length > 0" v-for="item, i in comments" :key="'comment' + i">
						<view style="display: flex;">
							<view>
								<image class="avatar" :src="item.avatar"></image>
							</view>
							<view style="flex:1">{{ item.user }}</view>
						</view>
						<view style="margin: 0.4rem 0;">{{ item.content }}</view>
						<view class="date">
							<text>
								<i><b>发布于</b></i>{{ ' ' }}{{ formatDate(item.date) }}
							</text>
						</view>
					</view>
				</view>
				<view class="addComment">
					<view style="flex:1">
						<input v-model="addCommentBody" placeholder="添加你的评论" class="addCommentInput" @focus="addCommentActive = true"
							@blur="addCommentActive = false" />
					</view>
					<view :style="{ width: addCommentActive ? '4.5rem' : 0 }"
						style="width: 4.5rem;text-align: center;transition: width ease 100ms;overflow: hidden;white-space: nowrap;">
						<button size="mini" style="margin-top: 0.5rem" @click="addComment()">发布</button>
					</view>
				</view>
			</view>
			<view>
				<view
					style="color: #f5f5f5;text-shadow: 0 0 0.125rem #0006;font-weight: bold;font-size: 1rem;padding:0.5rem 1rem">
					更多来自用户
				</view>
				<lists :data="authorOpus" type="image"></lists>
				<view
					style="color: #f5f5f5;text-shadow: 0 0 0.125rem #0006;font-weight: bold;font-size: 1rem;padding:0.5rem 1rem">
					更像这样
				</view>
				<lists :data="relatedOpus" type="image"></lists>
			</view>
		</view>
	</view>
</template>

<script>
import {
	getPicture,
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
			data: null,
			id: null,
			uid: null,
			unfold: false,
			comments: [],
			authorOpus: [],
			relatedOpus: [],
			addCommentActive: false,
			addCommentBody: null
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
		addComment() {
			addCommentForImage(this.id, this.addCommentBody, (res, code) => {
				if (code == 201) {
					uni.showToast({
						title: "评论发表成功",
						icon: "none",
						duration: 3000,
					})
					this.getComments()
				} else {
					uni.showToast({
						title: "评论发表失败",
						icon: "none",
						duration: 3000,
					})
				}
			})
		}
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
	background-color: #000;

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

@media (prefers-color-scheme: dark) {
	.main {
		background-color: #10101066;
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
