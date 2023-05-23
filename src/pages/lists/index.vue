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
			col: 0,
			limit: 24,
			ori: false,
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
				maxWidth: 425
			}, (res) => {
				if (res) {
					this.col = 2
				}
			})
			media.observe({
				minWidth: 426,
				maxWidth: 581
			}, (res) => {
				if (res) {
					this.col = 3
				}
			})
			media.observe({
				minWidth: 582,
				maxWidth: 1199
			}, (res) => {
				if (res) {
					this.col = 4
				}
			})
			media.observe({
				minWidth: 1200,
			}, (res) => {
				if (res) {
					this.col = 6
				}
			})
			media.observe({
				orientation: 'landscape'
			}, (res) => {
				this.ori = res
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