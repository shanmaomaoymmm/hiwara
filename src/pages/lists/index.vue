<template>
	<view>
		<view class="lists">
			<view v-for="c in col" style="flex: 1;">
				<view v-for="item, i in data" v-if="(i - c + 1) % col == 0">
					<item :item="item" :type="type" :id="'item' + i" :name="'item' + i"></item>
				</view>
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
			col: 2,
			limit: 24,
		}
	},
	props: ['data', 'type'],
	methods: {
		load() {
			console.log('load')
		},
		goAnchor(e) {
			uni.pageScrollTo({
				selector: e,
				duration: 100
			})
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