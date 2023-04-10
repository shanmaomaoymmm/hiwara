<template>
	<view class="comments">
		<view class="comment" v-for="item,i in data" :key="'comment'+i">
			<view class="user">{{item.user}}</view>
			<view class="content">{{item.content}}</view>
			<view class="date">{{formatDate(item.date)}}</view>
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
				data: [{
					user: "用户1",
					content: "这是一条评论这是一条评论这是一条评论",
					date: "2023-04-06 22:31:00",
				}]
			}
		},
		props: ['id'],
		mounted() {
			getVideoListForPlayInfoComments(this.id, 0, (res) => {
				console.log(res)
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
		padding: 1rem;
	}

	.comment {
		margin-bottom: 1rem;
	}

	.user {
		font-size: 1.1rem;
	}

	.content {
		margin: 0.4rem 0;
	}

	.date {
		text-align: right;
		color: #616161;
		font-size: 0.9rem;
	}

	@media (prefers-color-scheme: dark) {
		.date {
			color: #616161
		}
	}
</style>