<template>
  <view class="panel">
    <top-bar class="topBar" @left="showLeftDrawerOpen()"></top-bar>
    <view style="padding:5rem 0" @touchmove="handletouchmove" @touchstart="handletouchstart" @touchend="handletouchend">
      <subscribe ref="subscribe" v-if="tab == 0"></subscribe>
      <video-page ref="video" v-else-if="tab == 1"></video-page>
      <picture-page ref="picture" v-else-if="tab == 2"></picture-page>
    </view>
    <float-bar ref="floatBar" class="floatBar" @alter="tab = $event"></float-bar>
    <uni-drawer ref="showLeftDrawer" mode="left" :width="250">
      <show-left ref="showLeft" :user="user"></show-left>
    </uni-drawer>
  </view>
</template>

<script>
import topBar from "./topBar.vue"
import floatBar from "./floatBar.vue"
import subscribe from "@/pages/subscribe/index.vue"
import videoPage from "@/pages/video/index.vue"
import picturePage from "@/pages/picture/index.vue"
import showLeft from "./showLeft.vue"
import { getSelfData } from "@/api/api"
export default {
  components: {
    topBar,
    floatBar,
    subscribe,
    videoPage,
    picturePage,
    showLeft
  },
  data() {
    return {
      err: false,
      tab: 0,
      user: null,
      //滑动
      flag: 0, //1向左滑动,2向右滑动,3向上滑动 4向下滑动
      lastX: 0,
      lastY: 0,
    }
  },
  onPullDownRefresh() {
    this.refresh(() => {
      uni.stopPullDownRefresh();
    })
  },
  onReachBottom() {
    this.onReachBottom()
  },
  mounted() {
    getSelfData((res, code) => {
      this.user = res
      this.$refs.floatBar.avatar = this.user.user.avatar != null
        ? "https://i.iwara.tv/image/avatar/" +
        this.user.user.avatar.id +
        "/" +
        this.user.user.avatar.name
        : "https://www.iwara.tv/images/default-avatar.jpg"
    })
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
          refs = this.$refs.picture
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
        refs = this.$refs.picture
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
</script>

<style scoped>
.panel {
  height: 100%;
}

.topBar {
  position: fixed;
  top: 0;
  width: calc(100% - 1rem);
  padding: 2rem 0.5rem 0.5rem 0.5rem;
  background-color: #f5f5f5;
  z-index: 10;
}

.floatBar {
  position: fixed;
  bottom: 0;
  width: calc(100% - 0.4rem);
  padding: 0.2rem;
  background-color: #f5f5f5;
  z-index: 11;
}

@media (prefers-color-scheme: dark) {

  .topBar,
  .floatBar {
    background-color: #101010;
  }
}
</style>