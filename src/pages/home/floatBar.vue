<template>
	<view class="floatBar" dir="auto">
		<view class="item" :class="{ active: i == tab }" v-for="item, i in item" :key="item.label" @click="clickTab(i)">
			<image class="icon" v-if="i == tab" :src="item.icon[1]"></image>
			<image class="icon" v-else :src="item.icon[0]"></image>
			<br>
			{{ item.label }}
		</view>
	</view>
</template>

<script>
export default {
	data() {
		return {
			item: [{
				label: this.$t('home.tab.subscribe'),
				icon: [
					'/static/icon/rss.png',
					'/static/icon/a_rss.png'
				],
			}, {
				label: this.$t('home.tab.video'),
				icon: [
					'/static/icon/video.png',
					'/static/icon/a_video.png'
				],
			}, {
				label: this.$t('home.tab.image'),
				icon: [
					'/static/icon/pic.png',
					'/static/icon/a_pic.png'
				],
			}],
			tab: 0
		}
	},
	methods: {
		clickTab(i) {
			if (i != this.tab) {
				this.$emit('alter', i)
				switch (i) {
					case 0:
						this.tab = 0
						break
					case 1:
						this.tab = 1
						break
					case 2:
						this.tab = 2
						break
					case 3:
						this.tab = 3
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

* {
	transition: background 100ms ease;
	transition: color 100ms ease;
}
</style>