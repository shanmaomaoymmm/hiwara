<template>
	<view>
		<view class="lists">
			<view v-for="item, i in data">
				<item class="item" :item="item" :type="type" :id="'item' + i" :name="'item' + i"></item>
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
			col: 0,
			limit: 24,
		}
	},
	props: ['data', 'type', 'scol'],
}
</script>

<style scoped>
.lists {
	padding: 0.125rem;
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr));
	justify-content: space-between;
}

.item {
	min-width: 10rem;
}
</style>