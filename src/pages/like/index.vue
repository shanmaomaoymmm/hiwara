<template>
  <view>
    <video-list ref="video" v-if="tab == 0"></video-list>
    <image-list ref="image" v-else-if="tab == 1"></image-list>
    <uni-transition @click="backTop()" custom-class="back-top" mode-class="zoom-in" :duration="50"
      :show="scrollTop > 300">
      <i class="fa-solid fa-angle-up"></i>
    </uni-transition>
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
      tab: 0,
      scrollTop: 0,
    }
  },
  onPageScroll(e) {
    this.scrollTop = e.scrollTop
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
    backTop() {
      uni.pageScrollTo({
        scrollTop: 0,
        duration: 100
      })
    },
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
<style scoped>
.back-top {
  position: fixed;
  bottom: 5.2rem;
  right: 1.2rem;
  background-color: #00897b;
  color: #fafafa;
  font-size: 1.5rem;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 2.5rem;
  line-height: 2.5rem;
  text-align: center;
  box-shadow: 0 0 0.25rem #0002;
}

@media (prefers-color-scheme: dark) {
  .back-top {
    box-shadow: 0 0 0.25rem #fff2;
  }
}
</style>