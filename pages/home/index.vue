<template>
	<view class="panel">
		<top-bar class="topBar"></top-bar>
		<view v-show="!err" class="main">
			<lists :data="pageData"></lists>
			<uni-load-more :status="loading?'loading':'no-more'" icon-type="circle"></uni-load-more>
		</view>
		<error v-show="err"></error>
		<float-bar class="floatBar" @alter="mode=$event"></float-bar>
	</view>
</template>

<script>
	import topBar from './topBar.vue'
	import floatBar from './floatBar.vue'
	import error from './error.vue'
	import lists from '@/pages/lists/index.vue'
	import {
		getVideoList,
		getSubscribeList,
		getPictureList,
	} from '@/api/api.js'
	export default {
		components: {
			topBar,
			floatBar,
			error,
			lists
		},
		data() {
			return {
				err: true,
				pageData: [],
				pageIndex: 0,
				loading: true,
				mode: 0,
			}
		},
		onPullDownRefresh() {
			this.err = true
			this.pageData = []
			this.pageIndex = 0
			this.getPage((res, code) => {
				if (code == 200 && res.results.length != 0) {
					this.err = false
				}
				uni.stopPullDownRefresh()
			})
		},
		onReachBottom() {
			this.pageIndex++
			this.getPage((res, code) => {
				if (code != 200 || res.results.length == 0) {
					this.loading = false
				}
			})
		},
		mounted() {
			uni.startPullDownRefresh()
		},
		watch: {
			mode(nv, ov) {
				if ([0, 1, 2].includes(nv))
					uni.startPullDownRefresh()
			}
		},
		methods: {
			// 页面绘制
			getPage(cb) {
				switch (this.mode) {
					case 0: {
						this.getSubscribe(this.pageIndex, (res, code) => {
							cb(res, code)
						})
					}
					break
					case 1: {
						this.getVideo(this.pageIndex, (res, code) => {
							cb(res, code)
						})
					}
					break
					case 2: {
						this.getPicture(this.pageIndex, (res, code) => {
							cb(res, code)
						})
					}
					default:
						break
				}

			},
			// 获取视频列表
			getVideo(index, cb) {
				getVideoList(index, (res, code) => {
					this.setPageData(0, res, code)
					cb(res, code)
				})
			},
			// 获取订阅列表
			getSubscribe(index, cb) {
				getSubscribeList(index, (res, code) => {
					this.setPageData(0, res, code)
					cb(res, code)
				})
			},
			// 获取图片列表
			getPicture(index, cb) {
				getPictureList(index, (res, code) => {
					this.setPageData(1, res, code)
					cb(res, code)
				})
			},
			// 生成列表
			setPageData(type, res, code) {
				if (code == 200) {
					if (type == 0) {
						for (let i = 0; i < res.results.length; i++) {
							let rs = res.results[i]
							this.pageData.push({
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
								uid:rs.user.id
							})
						}
					} else if (type == 1) {
						for (let i = 0; i < res.results.length; i++) {
							let rs = res.results[i]
							this.pageData.push({
								id: rs.id,
								label: rs.title,
								img: rs.thumbnail != null ? 'https://i.iwara.tv/image/thumbnail/' + rs.thumbnail.id + '/' + rs
									.thumbnail.name : '/static/img/nachoneko.jpg',
								date: this.formatDate(rs.createdAt),
								author: rs.user.name,
								avatar: rs.user.avatar != null ? 'https://i.iwara.tv/image/avatar/' + rs.user.avatar
									.id + '/' + rs.user
									.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg',
								watch: rs.numViews,
								like: rs.numLikes,
							})
						}
					} else {}
				} else if (code == 408) {
					uni.showToast({
						title: '呐！少冲一点吧\r\n无法连接到服务器',
						icon: 'none',
						duration: 3000
					});
				} else {}
			},
			// 时间格式化
			formatDate(t) {
				let d = new Date;
				let year = t.slice(0, 4)
				let month = t.slice(5, 7)
				let day = t.slice(8, 10)
				if (d.getFullYear() == year) {
					t = month + '月' + day + '日'
				} else {
					t = year + '年' + month + '月' + day + '日'
				}
				return t
			}
		},
	};
</script>

<style scoped>
	.panel {
		height: 100%;
	}

	.topBar {
		position: fixed;
		top: 0;
		width: calc(100% - 1rem);
		padding: 2rem 0.5rem 0.5rem 0.5rem;
		background-color: #f5f5f5;
		z-index: 10;
	}

	.main {
		padding: 5rem 0.5rem 5rem 0.5rem;
		z-index: 1;
	}

	.floatBar {
		position: fixed;
		bottom: 0;
		width: calc(100% - 0.4rem);
		padding: 0.2rem;
		background-color: #f5f5f5;
		z-index: 11;
	}

	@media (prefers-color-scheme: dark) {

		.topBar,
		.floatBar {
			background-color: #101010;
		}
	}
</style>