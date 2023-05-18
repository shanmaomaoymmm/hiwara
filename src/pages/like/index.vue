<template>
  <view>
    <video-list ref="video" v-if="tab == 0"></video-list>
    <image-list ref="image" v-else-if="tab == 1"></image-list>
  </view>
</template>
<script>
import videoList from "./video.vue"
import imageList from "./image.vue"
export default ({
  components: {
    videoList,
    imageList
  },
  data() {
    return {
      tab: 0
    }
  },
  onNavigationBarButtonTap(e) {
    console.log(e)
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  onLoad: function (opt) {
    this.tab = parseInt(opt.tab)
    let title = null
    if (this.tab == 0) {
      title = '我收藏的视频'
    } else if (this.tab == 1) {
      title = '我收藏的图片'
    }
    uni.setNavigationBarTitle({
      title: title
    })
  },
  // 下拉
  onPullDownRefresh() {
    this.refresh(() => {
      uni.stopPullDownRefresh();
    })
  },
  // 滑到底部
  onReachBottom() {
    this.onReachBottom()
  },
  created() {
  },
  methods: {
    refresh(cb) {
      let refs
      switch (this.tab) {
        case 0:
          refs = this.$refs.video
          break
        case 1:
          refs = this.$refs.image
          break
        default:
          refs = null
          cb()
          break
      }
      if (refs) {
        refs.refresh(() => {
          cb()
        })
      }
    },
    onReachBottom() {
      let refs
      switch (this.tab) {
        case 0:
          refs = this.$refs.video
          break
        case 1:
          refs = this.$refs.image
          break
        default:
          refs = null
          break
      }
      if (refs) {
        refs.getData(() => {
        })
      }
    }
  }
})
</script>
<style scoped></style>