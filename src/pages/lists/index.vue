<template>
	<view class="lists">
		<view v-for="c in col" style="flex: 1;">
			<view v-for="item, i in data">
				<item v-if="(i - c + 1) % col == 0" :item="item" :type="type"></item>
			</view>
		</view>
	</view>
</template>

<script>
import item from './item.vue'
export default {
	components: {
		item
	},
	data() {
		return {
			col: 2
		}
	},
	props: ['data','type'],
	methods: {
		load() {
			console.log('load')
		}
	}
}
</script>

<style scoped>
.lists {
	display: flex;
	padding: 0.25rem 0.125rem;
}
</style>