<template>
	<view>
		<view class="lists">
			<view v-for="c in col" style="flex: 1;overflow: hidden;">
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
	props: ['data', 'type', 'scol'],
	mounted() {
		if (this.scol) {
			this.col = this.scol
		} else {
			let media = uni.createMediaQueryObserver(this)
			media.observe({
				minWidth: 0,
				maxWidth: 500
			}, (res) => {
				if (res) {
					console.log('1:' + res)
					this.col = 2
				}
			})
			media.observe({
				minWidth: 501
			}, (res) => {
				if (res) {
					console.log('2:' + res)
					this.col = 4
				}
			})
		}
	},
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