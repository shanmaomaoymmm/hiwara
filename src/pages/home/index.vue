<template>
  <view class="panel">
    <view style="padding:0 0 4rem 0" @touchmove="handletouchmove" @touchstart="handletouchstart"
      @touchend="handletouchend" :style="{ opacity: hideopa }">
      <subscribe-list ref="subscribe" v-if="tab == 0"></subscribe-list>
      <video-list ref="video" v-else-if="tab == 1"></video-list>
      <image-list ref="image" v-else-if="tab == 2"></image-list>
    </view>
    <float-bar ref="floatBar" class="floatBar" @alter="tab = $event"></float-bar>
    <uni-drawer ref="showLeftDrawer" mode="left" :width="250">
      <view class="show-left">
        <scroll-view class="svb" scroll-y="true">
          <show-left ref="showLeft" :user="user"></show-left>
        </scroll-view>
      </view>
    </uni-drawer>
    <uni-transition @click="backTop()" custom-class="back-top" mode-class="zoom-in" :duration="50"
      :show="scrollTop > 300">
      <i class="fa-solid fa-angle-up"></i>
    </uni-transition>
  </view>
</template>

<script>
import floatBar from "./floatBar.vue"
import subscribeList from "./subscribe.vue"
import videoList from "./video.vue"
import imageList from "./image.vue"
import showLeft from "./showLeft.vue"
export default {
  components: {
    floatBar,
    subscribeList,
    videoList,
    imageList,
    showLeft,
  },
  data() {
    return {
      err: false,
      tab: 0,
      user: {
        profile: {
          body: '-'
        },
        user: {
          id: null,
          avatar: null,
          name: '-',
          username: null,
        }
      },
      //滑动
      flag: 0, //1向左滑动,2向右滑动,3向上滑动 4向下滑动
      lastX: 0,
      lastY: 0,
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
    if (e.type == 'menu') {
      this.showLeftDrawerOpen()
    }
  },
  onNavigationBarSearchInputConfirmed(e) {
    uni.navigateTo({
      url: '/pages/search/index?tab=0&s=' + e.text
    });
  },
  onPullDownRefresh() {
    this.refresh(() => {
      uni.stopPullDownRefresh();
    })
  },
  onReachBottom() {
    this.onReachBottom()
  },
  watch: {
    mode(n) {
      console.log(n)
    },
    flag(v) {
      if (v == 2) {
        this.showLeftDrawerOpen()
      }
    }
  },
  methods: {
    refresh(cb) {
      let refs
      switch (this.tab) {
        case 0:
          refs = this.$refs.subscribe
          break
        case 1:
          refs = this.$refs.video
          break
        case 2:
          refs = this.$refs.image
          break
        default:
          refs = null
          cb()
          break
      }
      if (refs != null) {
        refs.refresh(() => {
          cb()
        })
      }
    },
    onReachBottom() {
      let refs
      switch (this.tab) {
        case 0:
          refs = this.$refs.subscribe
          break
        case 1:
          refs = this.$refs.video
          break
        case 2:
          refs = this.$refs.image
          break
        default:
          refs = null
          break
      }
      if (refs != null) {
        refs.onBottom()
      }
    },
    showLeftDrawerOpen() {
      this.$refs.showLeftDrawer.open()
    },
    /* 页面滑动检测 */
    handletouchmove: function (event) {
      // console.log(event)
      if (this.flag !== 0) {
        return;
      }
      let currentX = event.changedTouches[0].pageX;
      let currentY = event.changedTouches[0].pageY;
      let tx = currentX - this.lastX;
      let ty = currentY - this.lastY;
      let sensitivity = 10
      //调节灵敏度
      if (Math.abs(tx) || Math.abs(ty)) {
        //左右方向滑动
        if (Math.abs(tx) > Math.abs(ty) + sensitivity) {
          if (tx < 0) {
            // 向左滑动
            this.flag = 1;

          } else if (tx > 0) {
            //向右滑动 
            this.flag = 2;
          }
        }
        //上下方向滑动
        else {
          if (ty < 0) {
            //向上滑动
            this.flag = 3;
          } else if (ty > 0) {
            //向下滑动
            this.flag = 4;
          }
        }
      }
      //将当前坐标进行保存以进行下一次计算
      this.lastX = currentX;
      this.lastY = currentY;
    },
    handletouchstart: function (event) {
      this.lastX = event.changedTouches[0].pageX;
      this.lastY = event.changedTouches[0].pageY;
    },
    handletouchend: function (event) {
      //停止滑动
      this.flag = 0;
    },
    backTop() {
      uni.pageScrollTo({
        scrollTop: 0,
        duration: 100
      })
    }
  }
}
</script>

<style scoped>
.panel {
  height: 100%;
}

.floatBar {
  position: fixed;
  bottom: 0;
  width: calc(100% - 0.4rem);
  padding: 0.2rem;
  background-color: #eeeeee;
  z-index: 8;
}

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

.show-left {
  flex: 1
}

.svb {
  flex: 1;
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background-color: #f5f5f5;
}

@media (prefers-color-scheme: dark) {
  .svb {
    background-color: #101010;
  }

  .floatBar {
    background-color: #292929;
  }

  .back-top {
    box-shadow: 0 0 0.25rem #fff2;
  }
}
</style>