<template>
	<view>
		<view class="tabs">
			<view class="tab" :class="{ 'tab-a': tab == 0 }" @click="tab = 0">{{ $t('home.tab.video') }}</view>
			<view class="tab" :class="{ 'tab-a': tab == 1 }" @click="tab = 1">{{ $t('home.tab.image') }}</view>
		</view>
		<view class="content">
			<video-list ref="video" v-if="tab == 0"></video-list>
			<image-list ref="image" v-if="tab == 1"></image-list>
		</view>
	</view>
</template>

<script>
import videoList from './subscribe/video.vue'
import imageList from './subscribe/image.vue'
export default {
	components: {
		videoList,
		imageList
	},
	data() {
		return {
			tab: 0
		}
	},
	watch: {
		tab() {
			this.refresh(() => { })
		}
	},
	created() {

	},
	methods: {
		// 刷新
		refresh(cb) {
			let refs
			switch (this.tab) {
				case 0:
					refs = this.$refs.video
					break
				case 1:
					refs = this.$refs.image
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
					refs = this.$refs.video
					break
				case 1:
					refs = this.$refs.image
					break
				default:
					refs = null
					break
			}
			if (refs != null) {
				refs.onBottom(() => { })
			}
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

.tab-a {
	border-color: #00897b !important;
	color: #00897b;
}

.content {
	padding-top: 2.75rem;
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
