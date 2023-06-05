<template>
	<view class="comments-view">
		<view style="min-height: 100%; width: 100%;position: relative;">
			<view class="comments">
				<view v-if="data.length == 0" style="text-align: center;padding-top: 20vh;" dir="auto">
					<image @click="getComments()" src="@/static/icon/cactus.png" style="width: 3rem;height: 3rem;"></image>
					<br>
					<text>{{ $t('comments.null') }}</text>
				</view>
				<view v-else>
					<view v-show="data.length > 0" class="comment" v-for="item, i in data" :key="'comment' + i">
						<view style="display: flex;">
							<view>
								<image class="avatar" :src="item.avatar"></image>
							</view>
							<view style="flex:1" class="user">{{ item.user }}</view>
						</view>
						<view class="content">{{ item.content }}</view>
						<view class="date" dir="auto">
							<text>
								<i><b>{{ $t('comments.posted') }}</b></i>{{ ' ' }}{{ formatDate(item.date) }}
							</text>
						</view>
					</view>
					<view class="bottom">
						<text v-if="loading" dir="auto">
							<i class="fa-solid fa-circle-notch fa-spin" style="color: #00897b;margin-right: 0.4rem;"></i>
							<text>{{ $t('loading2') }}</text>
						</text>
						<text v-else>
							<text><i style="transform:scale(2.5,1)" class="fa-solid fa-minus"></i></text>
						</text>
					</view>
				</view>
			</view>
			<view class="addComment" dir="auto">
				<view style="flex: 1;">
					<input class="input" v-model="text" :placeholder="$t('comments.add')" @focus="commentButton = true"
						@blur="commentButton = false" />
				</view>
				<view style="overflow: hidden;white-space: nowrap;transition: width ease 100ms;"
					:style="{ width: commentButton ? '4.5rem' : 0 }">
					<button size="mini" style="background-color:#00897b;color: #f0f0f0;margin-top: 0.9rem" @click="addComment()">{{
						$t('comments.submit') }}</button>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
import {
	formatDate,
	getVideoListForPlayInfoComments,
	addCommentForVideo
} from '@/api/api.js'
export default {
	data() {
		return {
			data: [],
			text: null,
			commentButton: false,
			loading: true,
			page: 0,
			observer: null,
		}
	},
	props: ['vid'],
	created() {
		this.getComments()
	},
	mounted() {
		this.observer = uni.createIntersectionObserver(this);
		let init = false
		this.observer.relativeTo('.comments-view').observe('.bottom', (res) => {
			if (res.intersectionRatio > 0) {
				if (init == false) {
					init = true
				} else {
					this.getComments()
				}
			}
		})
	},
	destroyed() {
		if (this.observer) {
			this.observer.disconnect()
		}
	},
	methods: {
		formatDate(t) {
			return formatDate(t)
		},
		getComments() {
			this.loading = true
			getVideoListForPlayInfoComments(this.vid, this.page, (res) => {
				if (res.results.length > 0) {
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
					this.page++
				}
				this.loading = false
			})
		},
		addComment() {
			addCommentForVideo(this.vid, this.text, (res, code) => {
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

.addComment {
	background-color: #f5f5f5;
	bottom: 0;
	width: 100%;
	box-shadow: 0 -0.25rem 0.25rem #0002;
	display: flex;
	bottom: 0;
	position: fixed;
}

.input {
	margin: 0.5rem;
	padding: 0.5rem;
	border-bottom: solid 2px #00897b;
}

.comments-view {
	height: 100%;
	overflow: auto;
}

.bottom {
	text-align: center;
	padding-bottom: 1rem;
	padding: 1rem 0 5rem 0;
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