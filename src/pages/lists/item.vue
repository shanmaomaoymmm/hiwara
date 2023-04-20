<template>
	<view class="item" @click="gotoPage(item.id, item.uid)">
		<img :src="item.img || '/static/img/not-img.jpg'" class="img" />
		<view
			style="overflow: hidden;text-overflow: ellipsis;font-weight: bold;font-size: 1rem;width:calc(100vw / 2 - 0.375rem)">
			<text>{{ item.label }}</text>
		</view>
		<view style="display: flex;width: calc(100vw / 2 - 0.375rem);padding: 0.1rem 0;">
			<view>
				<image class="avatar" :src="item.avatar"></image>
			</view>
			<view
				style="flex: 1;font-size: 0.8rem;padding: 0 0.3rem;line-height: 1rem;overflow: hidden;text-overflow: ellipsis;">
				<text>{{ item.author }}</text>
				<br>
				<text>{{ item.date }}</text>
			</view>
		</view>
	</view>
</template>

<script>
export default {
	data() {
		return {}
	},
	props: ['item', 'type'],
	methods: {
		gotoPage(id, uid) {
			if (this.type == 'video') {
				uni.navigateTo({
					url: '/pages/player/index?id=' + id + '&uid=' + uid,
					animationType: 'slide-in-right',
					animationDuration: 100
				});
			} else if (this.type == 'image') {
				uni.navigateTo({
					url: '/pages/image/index?id=' + id + '&uid=' + uid,
					animationType: 'slide-in-right',
					animationDuration: 100
				});
			}
		}
	}
}
</script>

<style scoped>
.item {
	padding: 0.125rem;
	white-space: nowrap;
}

.img {
	width: calc(100vw / 2 - 0.375rem);
	height: calc((100vw / 2 - 0.375rem) * 2 / 3);
	box-shadow: 0 0 0.125rem #000a;
}

.avatar {
	width: 2rem;
	height: 2rem;
	border-radius: 2rem;
	box-shadow: 0 0 0.125rem #000a;
}

@media (prefers-color-scheme: dark) {

	.img,
	.avatar {
		box-shadow: 0 0 0.125rem #fffa;
	}
}
</style>