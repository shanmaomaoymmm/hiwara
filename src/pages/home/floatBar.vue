<template>
	<view class="floatBar">
		<view class="item" :class="{active:i==mode}" v-for="item,i in item" :key="item.label" @click="clickTab(i)">
			<image class="icon" :src="i==mode?item.icon[1]:item.icon[0]"></image>
			<br>
			{{item.label}}
		</view>
	</view>
</template>

<script>
	export default {
		data() {
			return {
				item: [{
						label: '订阅',
						icon: [
							'../../static/icon/rss.png',
							'../../static/icon/a_rss.png'
						],
					}, {
						label: '视频',
						icon: [
							'../../static/icon/video.png',
							'../../static/icon/a_video.png'
						],
					}, {
						label: '图片',
						icon: [
							'../../static/icon/pic.png',
							'../../static/icon/a_pic.png'
						],
					},
					/* {
										label: '论坛',
										icon: [
											'../../static/icon/communication.png',
											'../../static/icon/a_communication.png'
										],
									}, */
				],
				mode: 0
			}
		},
		methods: {
			clickTab(i) {
				if (i != this.mode) {
					this.$emit('alter', i)
					switch (i) {
						case 0:
							this.mode = 0
							break
						case 1:
							this.mode = 1
							break
						case 2:
							this.mode = 2
							break
						case 3:
							this.mode = 3
							break
						default:
							break
					}
				}
			}
		}
	}
</script>

<style scoped>
	.floatBar {
		display: flex;
		text-align: center;
		font-size: 0.8rem;
	}

	.item {
		flex: 1;
		padding: 0.3rem;
		font-weight: bold;
	}

	.icon {
		width: 1.6rem;
		height: 1.6rem;
	}

	.active {
		color: #00897B;
	}

	.active .icon {
		color: #00897B;
	}

	* {
		transition: background 100ms ease;
		transition: color 100ms ease;
	}
</style>