<template>
	<view class="showLeft">
		<view v-if="user" class="user">
			<view>
				<image class="avatar" :src="user.user.avatar != null
						? 'https://i.iwara.tv/image/avatar/' +
						this.user.user.avatar.id +
						'/' +
						this.user.user.avatar.name
						: 'https://www.iwara.tv/images/default-avatar.jpg'"></image>
			</view>
			<view class="userName">
				{{ user.user.name }}
			</view>
			<view class="profileBody">
				<i>
					{{ user.profile.body || "该用户是个神秘人，不喜欢被人围观。" }}
				</i>
			</view>
		</view>
		<view @click="gotoUser" class="button">我的主页</view>
		<view @clice="gotoLike" class="button">我的收藏</view>
		<view class="button">历史记录</view>
		<view class="button">设置</view>
		<view @click="logout" class="button">退出登录</view>
	</view>
</template>

<script>
import { removeStorage } from '@/api/api'
export default {
	data() {
		return {}
	},
	props: ['user'],
	mounted() {
		console.log(this.user)
	},
	methods: {
		logout() {
			removeStorage('token', () => {
				uni.reLaunch({
					url: '/'
				});
			})
		},
		gotoUser() {
			uni.navigateTo({
				url: '/pages/user/index?uid=' + this.user.user.id + '&username=' + this.user.user.username + '&self',
				animationType: 'slide-in-right',
				animationDuration: 100
			});
		},
		gotoLike() {
			console.log('gotoLike')
			uni.navigateTo({
				url: '/pages/like/index',
				animationType: 'slide-in-right',
				animationDuration: 100
			});
		}
	}
}
</script>

<style scoped>
.showLeft {
	background-color: #f5f5f5;
	height: 100%;
}

.user {
	text-align: center;
	padding: 3rem 1rem 1rem 1rem;
}

.avatar {
	width: 7.5rem;
	height: 7.5rem;
	border-radius: 7.5rem;
	box-shadow: 0 0 0.2rem #000a;
}

.userName {
	padding: 0.5rem 0;
	font-size: 1.5rem;
}

.profileBody {
	font-size: 0.9rem;
	color: #616161;
}

.button {
	padding: 1rem 1.5rem;
	font-size: 1rem;
}

@media (prefers-color-scheme: dark) {
	.showLeft {
		background-color: #101010;
	}


	.avatar {
		box-shadow: 0 0 0.2rem #fffa;
	}

	.profileBody {
		color: #BDBDBD;
	}
}
</style>
