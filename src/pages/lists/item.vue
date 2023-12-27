<template>
	<view class="item">
		<q-img :src="item.img || '/static/img/not-img.jpg'" class="img" @click="gotoPage(item.id, item.uid)" />
		<view style="padding:0.25rem;">
			<view class="label" @click="gotoPage(item.id, item.uid)">
				<text>{{ item.label }}</text>
			</view>
			<view style="display: flex;padding: 0.1rem 0;" @click="gotoUser(item.uid, item.username)">
				<view>
					<q-avatar class="avatar" :src="item.avatar" />
				</view>
				<view
					style="flex: 1;font-size: 0.8rem;padding: 0 0.3rem;line-height: 1rem;overflow: hidden;text-overflow: ellipsis;">
					<text>{{ item.author }}</text>
					<br>
					<text>{{ item.date }}</text>
				</view>
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
		},
		gotoUser(uid, username) {
			uni.navigateTo({
				url: '/pages/user/index?uid=' + uid + '&username=' + username,
				animationType: 'slide-in-right',
				animationDuration: 100
			})
		}
	}
}
</script>

<style scoped>
.item {
	margin: 0.35rem 0.125rem;
	white-space: nowrap;
	box-shadow: 0 0 0.125rem #0004;
	border-radius: 0.25rem;
	background-color: #fff;
	font-size: 0;
	overflow: hidden;
	min-height: 12rem;
}

.img {
	width: 100%;
	height: 7.5rem;
}

.label {
	overflow: hidden;
	text-overflow: ellipsis;
	font-weight: bold;
	font-size: 1rem;
	padding-bottom: 0.25rem;
}

.avatar {
	width: 2rem;
	height: 2rem;
	border-radius: 2rem;
	box-shadow: 0 0 0.125rem #000a;
}

@media (prefers-color-scheme: dark) {
	.item {
		background-color: #1c1c1c;
		box-shadow: 0 0 0.125rem #fffa;
	}

	.avatar {
		box-shadow: 0 0 0.125rem #fffa;
	}
}
</style>