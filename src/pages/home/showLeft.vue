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
				{{ user.profile.body || "这用户很神秘，啥也没有写。" }}
			</view>
		</view>
		<view class="button">退出登录</view>
	</view>
</template>

<script>
export default {
	data() {
		return {}
	},
	props: ['user'],
	mounted() {

	},
	methods: {

	}
}
</script>

<style scoped>
.showLeft {
	background-color: #f5f5f5;
}

.user {
	text-align: center;
	padding: 1rem;
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
	color: #616161
}

@media (prefers-color-scheme: dark) {
	.showLeft {
		background-color: #101010;
		height: 100%;
	}

	.button {
		color: #BDBDBD
	}

	.avatar {
		box-shadow: 0 0 0.2rem #fffa;
	}

	.profileBody {
		color: #BDBDBD;
	}
}
</style>
