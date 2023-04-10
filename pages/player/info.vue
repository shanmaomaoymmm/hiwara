<template>
	<view class="info">
		<view style="display: flex;">
			<view>
				<image class="author
" :src="data.avatar"></image>
			</view>
			<view style="flex: 1;padding:0 0.5rem;line-height: 2rem;">
				<text style="font-size: 1.1rem;">{{data.author}}</text>
			</view>
			<view>
				<button size="mini" class="concern"><text>{{data.following?"已关注":"＋ 关注"}}</text></button>
			</view>
		</view>
		<view @click="allinfo=!allinfo" class="title" :style="{height:allinfo?height.title2:height.title1}">
			<i class="fas fa-chevron-down titletip" :style="{transform:allinfo?'rotate(180deg)':'rotate(0deg)'}"></i>
			<view id="title1" v-show="!allinfo"
				style="whiteSpace:nowrap;overflow: hidden;text-overflow: ellipsis;margin-bottom: 2rem;">
				<text>{{data.title}}</text>
			</view>
			<view id="title2">
				<text>{{data.title}}</text>
			</view>
		</view>
		<view class="status">
			<text decode="true">
				<i class="fa-regular fa-circle-play fa-fw"></i>{{' '}}{{data.numView}}
				<i style="width: 0.8rem;display: inline-block;"></i>
				<i class="fa-regular fa-heart fa-fw"></i>{{' '}}{{data.numLikes}}
				<i style="width: 0.8rem;display: inline-block;"></i>
				<text>{{formatDate(data.date)}}</text>
			</text>
		</view>
		<view class="synopsis" :style="{height:allinfo?height.synopsis:'0px'}">
			<view id="synopsis">
				<text>{{data.synopsis}}</text>
			</view>
		</view>
		<view style="display: flex;text-align: center;">
			<view class="opt">
				<image class="icon" :src="data.liked?'/static/icon/a_like.png':'/static/icon/like.png'"></image>
				<br>
				<text>{{data.liked?'已喜欢':'喜欢'}}</text>
			</view>
			<view class="opt">
				<image class="icon" src="@/static/icon/share-one.png"></image>
				<br>
				<text>分享</text>
			</view>
			<view class="opt">
				<image class="icon" src="@/static/icon/download-four.png"></image>
				<br>
				<text>缓存</text>
			</view>
			<view class="opt" @click="copyLinkButton=!copyLinkButton">
				<image class="icon" src="@/static/icon/copy-link.png"></image>
				<br>
				<text>复制链接</text>
			</view>
		</view>
		<view style="overflow: hidden;text-align: center" :style="{height:copyLinkButton?'3.2rem':0}">
			<view style="padding: 0.5rem 0;display: flex;">
				<view v-for="item,i in data.sources" style="flex: 1;">
					<button size="mini">
						<i class="fa-solid fa-link fa-fw"></i>{{' '}}{{item.name}}
					</button>
				</view>
			</view>
		</view>
		<view style="font-size: 1.1rem;">
			<text>该作者的其他作品</text>
			<lists :data="authorOpus"></lists>
			<text>相关作品</text>
			<lists :data="relatedOpus"></lists>
		</view>
	</view>
</template>

<script>
	import lists from '@/pages/lists/index.vue'
	import {
		formatDate,
		getVideoListForPlayInfoUser,
		getVideoListForPlayInfoRelated
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
		props: ['id', 'uid'],
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
			getVideoListForPlayInfoUser(this.id, this.uid, (res) => {
				for (let i = 0; i < res.results.length; i++) {
					let rs = res.results[i]
					this.authorOpus.push({
						id: rs.id,
						label: rs.title,
						img: rs.file != null ? 'https://i.iwara.tv/image/thumbnail/' + rs.file.id +
							'/thumbnail-00.jpg' : '/static/img/nachoneko.jpg',
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
			getVideoListForPlayInfoRelated(this.id, (res) => {
				for (let i = 0; i < res.results.length; i++) {
					let rs = res.results[i]
					this.relatedOpus.push({
						id: rs.id,
						label: rs.title,
						img: rs.file != null ? 'https://i.iwara.tv/image/thumbnail/' + rs.file.id +
							'/thumbnail-00.jpg' : '/static/img/nachoneko.jpg',
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
			}
		}
	}
</script>

<style scoped>
	.info {
		padding: 1rem;
		position: relative;
	}

	.author {
		width: 2rem;
		height: 2rem;
		box-shadow: 0 0 0.125rem #000a;
		border-radius: 2rem;
	}

	button {
		background-color: #00897b;
		color: #f0f0f0;
	}

	.concern {
		width: 4.9rem;
	}

	.title {
		font-size: 1.3rem;
		padding-top: 0.5rem;
		overflow: hidden;
	}

	.titletip {
		position: absolute;
		right: 1rem;
		font-size: 0.5rem;
		transform: rotate(0deg);
		transition: transform ease 200ms;
	}

	.status {
		padding: 0.5rem 0;
		font-size: 0.9rem;
	}

	.synopsis {
		overflow: hidden;
		word-wrap: break-word;
	}

	.synopsis,
	.status {
		color: #616161
	}

	.icon {
		width: 1.5rem;
		height: 1.5rem;
	}

	.opt {
		padding: 0.5rem 0;
		flex: 1;
	}

	* {
		transition: height ease 200ms;
	}

	@media (prefers-color-scheme: dark) {

		.synopsis,
		.status {
			color: #BDBDBD
		}
	}
</style>