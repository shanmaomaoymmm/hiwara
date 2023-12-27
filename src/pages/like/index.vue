<template>
  <view :style="{ opacity: hideopa }">
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
      ori: false,
      scrollTopCacheX: 0,
      scrollTopCacheY: 0,
      hideopa: 1
    }
  },
  onPageScroll(e) {
    this.scrollTop = e.scrollTop
  },
  onHide: function () {
    this.hideopa = 0
    if (this.ori) {
      this.scrollTopCacheX = this.scrollTop
    } else {
      this.scrollTopCacheY = this.scrollTop
    }
  },
  onShow: function () {
    if (this.scrollTop > 0) {
      if (this.ori) {
        if (this.scrollTopCacheX !== this.scrollTop) {
          uni.pageScrollTo({
            scrollTop: this.scrollTopCacheX,
            duration: 0,
            complete: () => {
              this.hideopa = 1
            }
          })
        } else {
          this.hideopa = 1
        }
      } else {
        if (this.scrollTopCacheY !== this.scrollTop) {
          uni.pageScrollTo({
            scrollTop: this.scrollTopCacheY,
            duration: 0,
            complete: () => {
              this.hideopa = 1
            }
          })
        } else {
          this.hideopa = 1
        }
      }
    } else {
      this.hideopa = 1
    }
  },
  mounted() {
    let media = uni.createMediaQueryObserver(this)
    media.observe({
      orientation: 'landscape'
    }, (res) => {
      this.ori = res
    })
  },
  onNavigationBarButtonTap(e) {

    if (e.type == 'home') {
      this.$backhome()
    }
  },
  onLoad: function (opt) {
    this.tab = parseInt(opt.tab)
    let title = null
    if (this.tab == 0) {
      title = this.$t('like.video')
    } else if (this.tab == 1) {
      title = this.$t('like.image')
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
    uni.setNavigationBarTitle({
      title: this.$t('label.like')
    });
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
        refs.onBottom()
      }
    }
  }
})
</script>
<style scoped>
.back-top {
  position: fixed;
  bottom: 2.2rem;
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