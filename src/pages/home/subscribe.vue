<template>
	<view>
		<view v-if="onload" style="text-align: center;padding-top: 30vh;">
			<image class="loading" src="@/static/icon/loading.png"></image>
			<br>
			<text>{{ $t('loading1') }}</text>
		</view>
		<view v-else>
			<view v-if="error" style="text-align: center;padding-top: 30vh;">
				<image src="@/static/icon/game.png" style="width: 4rem;height: 4rem;" />
			</view>
			<view v-else>
				<view class="tabs">
					<view class="tab" :class="{ 'tab-a': tab == 0 }" @click="tab = 0">{{ $t('home.tab.video') }}</view>
					<view class="tab" :class="{ 'tab-a': tab == 1 }" @click="tab = 1">{{ $t('home.tab.image') }}</view>
				</view>
				<view class="content">
					<lists v-if="tab == 0" :data="video" ref="lists" type="video"></lists>
					<lists v-if="tab == 1" :data="image" ref="lists" type="image"></lists>
					<view style="text-align: center;padding-bottom: 1rem;">
						<text v-if="loading">
							<i class="fa-solid fa-circle-notch fa-spin" style="color: #00897b;margin-right: 0.4rem;"></i>
							<text>{{ $t('loading2') }}</text>
						</text>
						<text v-else>
							<text><i style="transform:scale(2.5,1)" class="fa-solid fa-minus"></i></text>
						</text>
					</view>
				</view>
			</view>
		</view>
	</view>
</template>

<script>
import lists from "@/pages/lists/index.vue";
import { getSubscribeList, fill0 } from "@/api/api.js";
export default {
	components: {
		lists,
	},
	data() {
		return {
			video: [],
			image: [],
			page: 0,
			onload: true,
			loading: false,
			error: false,
			tab: 0
		}
	},
	watch: {
		tab() {
			this.refresh(() => { })
		}
	},
	created() {
		this.getData(() => {
			this.onload = false
		})
	},
	methods: {
		// 刷新
		refresh(cb) {
			this.onload = true
			this.video = []
			this.image = []
			this.page = 0
			this.getData(() => {
				this.onload = false
				cb()
			})
		},
		onBottom() {
			if (this.error == false && this.loading == false) {
				this.getData(() => { })
			}
		},
		// 获取订阅列表
		getData(cb) {
			this.loading = true
			let type
			let tab = this.tab
			if (tab == 0) {
				type = 'video'
			} else if (tab == 1) {
				type = 'image'
			}
			getSubscribeList(type, this.page, (res, code) => {
				this.loading = false
				if (code == 200) {
					if (res.results.length > 0) {
						if (tab == this.tab) {
							this.setPageData(res, type);
							this.page++
						}
					} else {
						if (this.page == 0) {
							this.error = true
						}
					}
				} else if (code == 408) {
					uni.showToast({
						title: this.$t('dontLink'),
						icon: "none",
						duration: 3000,
					});
				} else { }
				cb()
			})
		},
		// 生成列表
		setPageData(res, type) {
			if (type == 'video') {
				for (let i = 0; i < res.results.length; i++) {
					let rs = res.results[i];
					this.video.push({
						id: rs.id,
						label: rs.title,
						img:
							rs.file != null
								? "https://i.iwara.tv/image/thumbnail/" +
								rs.file.id +
								"/thumbnail-" + fill0(rs.thumbnail, 1) + ".jpg"
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
					});
				}
			} else if (type == 'image') {
				for (let i = 0; i < res.results.length; i++) {
					let rs = res.results[i];
					this.image.push({
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
					});
				}
			}
		},
		// 时间格式化
		formatDate(t) {
			let d = new Date();
			let year = t.slice(0, 4);
			let month = t.slice(5, 7);
			let day = t.slice(8, 10);
			if (d.getFullYear() == year) {
				t = month + "-" + day;
			} else {
				t = year + "-" + month + "-" + day;
			}
			return t;
		},
	}
}
</script>

<style scoped>
.loading {
	width: 4rem;
	height: 4rem;
	animation: rotate 350ms linear infinite;
}

.tabs {
	box-shadow: 0 0.1rem 0.25rem #0002;
	background-color: #f5f5f5;
	display: flex;
	width: 100%;
	z-index: 10;
	position: fixed;
}

.tab {
	flex: 1;
	padding: 0.75rem 0;
	text-align: center;
	border-bottom: solid 0.125rem #f5f5f5;
}

.tab-a {
	border-color: #00897b !important;
	color: #00897b;
}

.content {
	padding-top: 2.75rem;
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

@media (prefers-color-scheme: dark) {
	.tabs {
		background-color: #101010;
		box-shadow: 0 0.1rem 0.25rem #fff2;
	}

	.tab {
		border-color: #101010;
	}
}
</style>
