<template>
	<view class="item" @click="gotoPage(item.id,item.uid)">
		<img class="img" :src="item.img" />
		<view style="width: 9.6rem;overflow: hidden;text-overflow: ellipsis;">
			<text style="font-weight: bold;font-size: 1.1rem;">{{item.label}}</text>
		</view>
		<view style="display: flex;width: 9.6rem">
			<view>
				<img class="avatar" :src="item.avatar" />
			</view>
			<view
				style="flex: 1;font-size: 0.7rem;padding: 0 0.3rem;line-height: 1rem;overflow: hidden;text-overflow: ellipsis;">
				<text>{{item.author}}</text>
				<br>
				<text>{{item.date}}</text>
			</view>
		</view>
	</view>
</template>

<script>
	export default {
		data() {
			return {

			}
		},
		props: ['item'],
		methods: {
			gotoPage(id, uid) {
				uni.navigateTo({
					url: '/pages/player/index?id=' + id + '&uid=' + uid
				});
			}
		}
	}
</script>

<style scoped>
	.item {
		text-align: left;
		white-space: nowrap;
		display: inline-block;
		margin:0.5rem 0;
	}

	.img {
		width: 9.6rem;
		height: 6.4rem;
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