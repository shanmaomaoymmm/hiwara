<template>
  <view>
    <view class="tabs">
      <view class="tab" :class="{ 'tab-a': tab == 0 }" @click="tab = 0">{{ $t('search.tab.video') }}</view>
      <view class="tab" :class="{ 'tab-a': tab == 1 }" @click="tab = 1">{{ $t('search.tab.image') }}</view>
      <view class="tab" :class="{ 'tab-a': tab == 2 }" @click="tab = 2">{{ $t('search.tab.user') }}</view>
    </view>
    <view style="padding-top: 3.2rem;" :style="{ opacity: hideopa }">
      <video-list ref="video" :s="s" v-if="tab == 0"></video-list>
      <image-list ref="image" :s="s" v-else-if="tab == 1"></image-list>
      <user-list ref="user" :s="s" v-else-if="tab == 2"></user-list>
    </view>
    <uni-transition @click="backTop()" custom-class="back-top" mode-class="zoom-in" :duration="50"
      :show="scrollTop > 300">
      <i class="fa-solid fa-angle-up"></i>
    </uni-transition>
  </view>
</template>
<script>
import videoList from "./video.vue"
import imageList from "./image.vue"
import userList from "./user.vue"
export default ({
  components: {
    videoList,
    imageList,
    userList
  },
  data() {
    return {
      s: null,
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
  onLoad: function (o) {
    this.s = o.s;
    this.tab = parseInt(o.tab)
  },
  onNavigationBarButtonTap(e) {
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  onNavigationBarSearchInputConfirmed(e) {
    uni.navigateTo({
      url: '/pages/search/index?s=' + e.text + '&tab=' + this.tab
    });
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
  created() { },
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
        case 2:
          refs = this.$refs.user
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
        case 2:
          refs = this.$refs.user
          break
        default:
          refs = null
          break
      }
      if (refs) {
        refs.onBottom()
      }
    },
    backTop() {
      uni.pageScrollTo({
        scrollTop: 0,
        duration: 100
      })
    }
  }
})
</script>
<style scoped>
.tabs {
  box-shadow: 0 0.1rem 0.25rem #0002;
  background-color: #f5f5f5;
  display: flex;
  width: 100%;
  position: fixed;
  z-index: 10;
}

.tab {
  flex: 1;
  padding: 1rem 0;
  text-align: center;
  border-bottom: solid 0.125rem #f5f5f5;
}

.tab-a {
  border-color: #00897b !important;
  color: #00897b;
}

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
  .tabs {
    background-color: #101010;
    box-shadow: 0 0.1rem 0.25rem #fff2;
  }

  .tab {
    border-color: #101010;
  }

  .back-top {
    box-shadow: 0 0 0.25rem #fff2;
  }
}
</style>