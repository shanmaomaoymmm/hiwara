<template>
	<view class="showLeft">
		<view v-if="user" class="user">
			<view>
				<q-avatar class="avatar" :src="user.user.avatar != null
					? 'https://i.iwara.tv/image/avatar/' +
					this.user.user.avatar.id +
					'/' +
					this.user.user.avatar.name
					: 'https://www.iwara.tv/images/default-avatar.jpg'" />
			</view>
			<view class="userName">
				{{ user.user.name }}
			</view>
			<view class="profileBody">
				<i>
					{{ user.profile.body || $t("home.left.nullSignature") }}
				</i>
			</view>
		</view>
		<view dir="auto">
			<view @click="gotoPage('/pages/user/index?uid=' + user.user.id + '&username=' + user.user.username + '&self')"
				class="button">{{ $t('home.left.myPage') }}</view>
			<view @click="gotoPage('/pages/like/index?tab=0')" class="button">{{ $t('home.left.favoriteVideo') }}</view>
			<view @click="gotoPage('/pages/like/index?tab=1')" class="button">{{ $t('home.left.favoriteImage') }}</view>
			<!-- #ifdef APP-PLUS -->
			<view @click="gotoPage('/pages/following/index')" class="button">{{ $t('home.left.concerns') }}</view>
			<view @click="gotoPage('/pages/history/index')" class="button">{{ $t('home.left.history') }}</view>
			<view @click="gotoPage('/pages/download/index')" class="button">{{ $t('home.left.download') }}</view>
			<!-- #endif -->
			<view @click="gotoPage('/pages/setup/index?init=0')" class="button">{{ $t('home.left.setup') }}</view>
			<view @click="logout" class="button">{{ $t('home.left.logout') }}</view>
		</view>
	</view>
</template>

<script>
import { removeStorage } from '@/api/api'
export default {
	data() {
		return {}
	},
	props: ['user'],
	methods: {
		logout() {
			uni.showModal({
				title: this.$t('logout.title'),
				content: this.$t('logout.confirmed'),
				confirmColor: '#00897B',
				success: function (res) {
					this.logoutopt()
				}.bind(this)
			});
		},
		logoutopt() {
			uni.showToast({
				title: this.$t('logout.success'),
				icon: 'none',
				duration: 3000
			});
			removeStorage('token', () => {
				uni.reLaunch({
					url: '/pages/index/index'
				});
			})
		},
		gotoPage(url) {
			uni.navigateTo({
				url: url,
				animationType: 'slide-in-right',
				animationDuration: 100
			});
		}
	}
}
</script>

<style scoped>
.showLeft {
	padding: 2rem 0 1rem 0;
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
}

@media (prefers-color-scheme: dark) {

	.avatar {
		box-shadow: 0 0 0.2rem #fffa;
	}

	.profileBody {
		color: #BDBDBD;
	}
}
</style>
