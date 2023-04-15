<template>
	<view>
		<view class="comments">
			<view v-show="data.length == 0" style="text-align: center;padding-top: 20vh;">
				<image src="@/static/icon/cactus.png" style="width: 3rem;height: 3rem;"></image>
				<br>
				<text>还没有评论</text>
			</view>
			<view v-show="data.length > 0" class="comment" v-for="item, i in data" :key="'comment' + i">
				<view style="display: flex;">
					<view>
						<image class="avatar" :src="data.avatar"></image>
					</view>
					<view style="flex:1" class="user">{{ item.user }}</view>
				</view>
				<view class="content">{{ item.content }}</view>
				<view class="date">
					<text>
						<i><b>发布于</b></i>{{ ' ' }}{{ formatDate(item.date) }}
					</text>
				</view>
			</view>
		</view>
		<view class="addComment">
			<view style="flex: 1;">
				<input class="input" v-model="text" placeholder="添加你的评论" @focus="commentButton = true"
					@blur="commentButton = false" />
			</view>
			<view style="overflow: hidden;white-space: nowrap;transition: width ease 100ms;"
				:style="{ width: commentButton ? '4.5rem' : 0 }">
				<button size="mini" style="background-color:#00897b;color: #f0f0f0;margin-top: 0.9rem"
					@click="addComment()">评论</button>
			</view>
		</view>
	</view>
</template>

<script>
import {
	formatDate,
	getVideoListForPlayInfoComments,
	addComment
} from '@/api/api.js'
export default {
	data() {
		return {
			data: [],
			text: null,
			commentButton: false
		}
	},
	props: ['id'],
	mounted() {
		this.getVideoListForPlayInfoComments()
	},
	methods: {
		formatDate(t) {
			return formatDate(t)
		},
		getVideoListForPlayInfoComments() {
			getVideoListForPlayInfoComments(this.id, 0, (res) => {
				for (let i = 0; i < res.results.length; i++) {
					this.data.push({
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
		addComment() {
			addComment(this.id, this.text, (res, code) => {
				if (code == 201) {
					uni.showToast({
						title: "评论发表成功",
						icon: "none",
						duration: 3000,
					})
					this.getVideoListForPlayInfoComments()
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
.comments {
	padding: 0 1rem 5rem 1rem;
}

.comment {
	padding: 1rem 0;
	border-bottom: solid 1px #BDBDBD;
}

.user {
	font-size: 1.1rem;
	padding: 0.2rem 0.5rem;
}

.content {
	margin: 0.4rem 0;
}

.date {
	text-align: right;
	color: #616161;
	font-size: 0.9rem;
}

.avatar {
	width: 1.75rem;
	height: 1.75rem;
	box-shadow: 0 0 0.125rem #000a;
	border-radius: 2rem;
}

.addComment {
	background-color: #f5f5f5;
	position: fixed;
	bottom: 0;
	width: 100%;
	box-shadow: 0 -0.25rem 0.25rem #0002;
	display: flex;
}

.input {
	margin: 0.5rem;
	padding: 0.5rem;
	border-bottom: solid 2px #00897b;
}

@media (prefers-color-scheme: dark) {
	.date {
		color: #BDBDBD
	}

	.comment {
		border-color: #616161;
	}

	.addComment {
		background-color: #101010;
		box-shadow: 0 -0.25rem 0.25rem #fff2;
	}
}
</style>