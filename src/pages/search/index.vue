<template>
  <view>
    <view class="tabs">
      <view class="tab" :class="{ 'tab-a': tab == 0 }" @click="tab = 0">视频</view>
      <view class="tab" :class="{ 'tab-a': tab == 1 }" @click="tab = 1">图片</view>
      <view class="tab" :class="{ 'tab-a': tab == 2 }" @click="tab = 2">用户</view>
    </view>
    <view style="padding-top: 3.2rem;">
      <video-list ref="video" :s="s" v-if="tab == 0"></video-list>
      <image-list ref="image" :s="s" v-else-if="tab == 1"></image-list>
      <user-list ref="user" :s="s" v-else-if="tab == 2"></user-list>
    </view>
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
      tab: 0
    }
  },
  onLoad: function (o) {
    this.s = o.s;
    this.tab = parseInt(o.tab)
  },
  onNavigationBarButtonTap(e) {
    console.log(e)
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  onNavigationBarSearchInputConfirmed(e) {
    console.log(e)
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
        refs.getData(() => {
        })
      }
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

@media (prefers-color-scheme: dark) {
  .tabs {
    background-color: #f5f5f5;
    box-shadow: 0 0.1rem 0.25rem #fff2;
  }

  .tab {
    border-color: #101010;
  }
}
</style>