<template>
  <view class="panel">
    <top-bar class="topBar"></top-bar>
    <view style="padding:5rem 0">
      <subscribe ref="subscribe" v-if="tab == 0"></subscribe>
      <video-page ref="video" v-else-if="tab == 1"></video-page>
      <picture-page ref="picture" v-else-if="tab == 2"></picture-page>
    </view>
    <float-bar ref="floatBar" class="floatBar" @alter="tab = $event"></float-bar>
  </view>
</template>

<script>
import topBar from "./topBar.vue"
import floatBar from "./floatBar.vue"
import subscribe from "@/pages/subscribe/index.vue"
import videoPage from "@/pages/video/index.vue"
import picturePage from "@/pages/picture/index.vue"
export default {
  components: {
    topBar,
    floatBar,
    subscribe,
    videoPage,
    picturePage
  },
  data() {
    return {
      err: false,
      tab: 0,
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
  mounted() { },
  watch: {
    mode(n) {
      console.log(n)
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
        refs = this.$refpictureo
        
      break
      default:
        refs = null
        cb()
        break
    }
    if (refs) {
      refs.getData(() => {
        cb()
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