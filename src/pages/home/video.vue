<template>
	<view>
		<view class="tabs">
			<view class="tab" :class="{ 'tab-a': tab == 0 }" @click="tab = 0">{{ $t('home.sort.date') }}</view>
			<view class="tab" :class="{ 'tab-a': tab == 1 }" @click="tab = 1">{{ $t('home.sort.trending') }}</view>
			<view class="tab" :class="{ 'tab-a': tab == 2 }" @click="tab = 2">{{ $t('home.sort.popularity') }}</view>
			<view class="tab" :class="{ 'tab-a': tab == 3 }" @click="tab = 3">{{ $t('home.sort.views') }}</view>
			<view class="tab" :class="{ 'tab-a': tab == 4 }" @click="tab = 4">{{ $t('home.sort.likes') }}</view>
			<view class="filters">
				<picker @change="filters" :range="dataList" mode="multiSelector">
					<i class="fa-regular fa-clock"></i>
				</picker>
			</view>
		</view>
		<view class="content">
			<lists0 v-if="tab == 0" :date="date" sort="date" ref="date" />
			<lists1 v-if="tab == 1" :date="date" sort="trending" ref="trending" />
			<lists2 v-if="tab == 2" :date="date" sort="popularity" ref="popularity" />
			<lists3 v-if="tab == 3" :date="date" sort="views" ref="views" />
			<lists4 v-if="tab == 4" :date="date" sort="likes" ref="likes" />
		</view>
	</view>
</template>

<script>
import lists0 from './video/video.vue'
import lists1 from './video/video.vue'
import lists2 from './video/video.vue'
import lists3 from './video/video.vue'
import lists4 from './video/video.vue'
export default {
	components: {
		lists0,
		lists1,
		lists2,
		lists3,
		lists4
	},
	data() {
		return {
			tab: 0,
			date: null,
			dataList: [
				[this.$t('home.date.year')],
				[
					this.$t('home.date.January'),
					this.$t('home.date.February'),
					this.$t('home.date.March'),
					this.$t('home.date.April'),
					this.$t('home.date.May'),
					this.$t('home.date.June'),
					this.$t('home.date.July'),
					this.$t('home.date.August'),
					this.$t('home.date.September'),
					this.$t('home.date.October'),
					this.$t('home.date.November'),
					this.$t('home.date.December'),
				]
			]
		}
	},
	created() {
		let date = new Date()
		let y = date.getFullYear()
		let sty = 2014
		while (y >= sty) {
			this.dataList[0].push(y)
			y--
		}
	},
	methods: {
		// 刷新
		refresh(cb) {
			let refs
			switch (this.tab) {
				case 0:
					refs = this.$refs.date
					break
				case 1:
					refs = this.$refs.trending
					break
				case 2:
					refs = this.$refs.popularity
					break
				case 3:
					refs = this.$refs.views
					break
				case 4:
					refs = this.$refs.likes
					break
				default:
					refs = null
					break
			}
			if (refs != null) {
				refs.refresh(() => {
					cb()
				})
			}
		},
		onBottom() {
			let refs
			switch (this.tab) {
				case 0:
					refs = this.$refs.date
					break
				case 1:
					refs = this.$refs.trending
					break
				case 2:
					refs = this.$refs.popularity
					break
				case 3:
					refs = this.$refs.views
					break
				case 4:
					refs = this.$refs.likes
					break
				default:
					refs = null
					break
			}
			if (refs != null) {
				refs.onBottom(() => { })
			}
		},
		filters: function (e) {
			let yi = e.detail.value[0]
			let mi = e.detail.value[1]
			let date
			if (yi == 0) {
				// 不选择年份
				date = null
			} else {
				date = this.dataList[0][yi] + '-' + (mi + 1)
			}
			this.date = date
		}
	}
}
</script>

<style scoped>
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

.filters {
	padding: 0.9rem 0rem 0.5rem 0rem;
	width: 2.5rem;
	text-align: center;
	border-bottom: solid 0.125rem #f5f5f5;
	color: #808080;
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

	.tab,
	.filters {
		border-color: #101010;
	}
}
</style>
