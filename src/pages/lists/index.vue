<template>
	<view class="lists">
		<view v-for="c in col" style="flex: 1;">
			<view v-for="item, i in data">
				<item v-if="(i - c + 1) % col == 0" :item="item" type="video"></item>
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
	props: ['data'],
	mounted() { },
	methods: {}
}
</script>

<style scoped>
.lists {
	text-align: center;
	display: flex;
}
</style>