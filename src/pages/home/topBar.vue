<template>
	<view class="topBar">
		<view style="margin:0.5rem 0.25rem;">
			<image style="width: 1.5rem;height: 1.5rem;" src="@/static/icon/system.png"></image>
		</view>
		<view style="flex: 1"><input class="input" placeholder="搜索" /></view>
		<view style="margin:0.25rem;">
			<image class="avatar" src="https://avatars.githubusercontent.com/u/39371540?v=4"></image>
		</view>
	</view>
</template>

<script>
	import {
		getStorage
	} from '@/api/api.js'
	export default {
		data() {
			return {

			}
		},
		methods: {
			users() {

			},
		},
	}
</script>

<style scoped>
	.topBar {
		display: flex;
	}

	.input {
		margin: 0 0.5rem;
		padding: 0.5rem;
		border-bottom: solid 2px #00897b;
	}

	.avatar {
		width: 2rem;
		height: 2rem;
		box-shadow: 0 0 0.125rem #000a;
		border-radius: 2rem;
	}

	@media (prefers-color-scheme: dark) {
		.avatar {
			box-shadow: 0 0 0.125rem #fffa;
		}
	}
</style>