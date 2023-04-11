<template>
	<view class="comments">
		<view v-show="data.length==0" style="text-align: center;padding: 20vh 0;">
			<image src="../../static/icon/cactus.png" style="width: 3rem;height: 3rem;"></image>
			<br>
			<text>还没有评论</text>
		</view>
		<view class="comment" v-for="item,i in data" :key="'comment'+i">
			<view style="display: flex;">
				<view>
					<image class="avatar" :src="item.avatar"></image>
				</view style="flex:1">
				<view class="user">{{item.user}}</view>
			</view>
			<view class="content">{{item.content}}</view>
			<view class="date">
				<text>
					<i><b>发布于</b></i>{{' '}}{{formatDate(item.date)}}
				</text>
			</view>
		</view>
	</view>
</template>

<script>
	import {
		formatDate,
		getVideoListForPlayInfoComments
	} from '@/api/api.js'
	export default {
		data() {
			return {
				data: []
			}
		},
		props: ['id'],
		mounted() {
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
		methods: {
			formatDate(t) {
				return formatDate(t)
			}
		}
	}
</script>

<style scoped>
	.comments {
		padding: 0 1rem;
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

	@media (prefers-color-scheme: dark) {
		.date {
			color: #BDBDBD
		}

		.comment {
			border-color: #616161;
		}
	}
</style>