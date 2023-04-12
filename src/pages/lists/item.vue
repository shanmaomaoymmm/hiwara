<template>
	<view class="item" @click="gotoPage(item.id, item.uid)">
		<el-image class="img" :src="item.img">
			<view slot="placeholder" style="text-align: center;line-height: 6.4rem;font-size: 2rem;color:#00897b;">
				<i class="fa-solid fa-circle-notch fa-spin"></i>
			</view>
			<view slot="error">
				<img src="@/static/img/not-img.jpg" alt="" style="width: 100%;height: 100%;">
			</view>
		</el-image>
		<view style="width: 9.6rem;overflow: hidden;text-overflow: ellipsis;">
			<text style="font-weight: bold;font-size: 1rem;">{{ item.label }}</text>
		</view>
		<view style="display: flex;width: 9.6rem;padding: 0.1rem 0;">
			<view>
				<el-avatar class="avatar" :src="item.avatar">
					<view style="line-height: 2rem;">
						<i class="fa-solid fa-user"></i>
					</view>
				</el-avatar>
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
			}
		}
	}
}
</script>

<style scoped>
.item {
	text-align: left;
	white-space: nowrap;
	display: inline-block;
	margin: 0.5rem 0;
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