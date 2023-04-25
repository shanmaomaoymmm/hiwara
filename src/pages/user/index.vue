<template>
  <view class="panel">
    <view class="back">
      <i @click="back(1)" class="fa-solid fa-angle-left backButton"></i>
      <i @click="back(0)" class="fa-solid fa-house backButton"></i>
    </view>
    <view class="bg">
      <view class="bgp" :style="{ backgroundImage: 'url(' + profile.background + ')' }"></view>
    </view>
    <view style="display: flex;position: relative;z-index: 3;">
      <view>
        <img class="avatar" :src="profile.avatar" />
      </view>
      <view style="flex: 1;">
        <view
          style="font-size: 1.5rem;color: #fff;text-shadow: 0 0 0.25rem #000a;padding: 1.6rem 0 0.8rem 0;overflow: hidden;white-space: nowrap;text-overflow: ellipsis;width: calc(100vw - 8rem);">
          {{
            profile.name }}</view>
        <view>
          <button size="mini">＋ 关注</button>
          {{ ' ' }}
          <button size="mini">+ 朋友</button>
          {{ ' ' }}
          <button size="mini"><i class="fa-regular fa-envelope fa-fw"></i>{{ ' ' }}私信</button>
        </view>
      </view>
    </view>
    <view style="padding:0 1rem;">
      {{ profile.body }}
    </view>
    <view class="tabs">
      <text class="tab" @click="tab = 0" :class="{ tabsActive: tab == 0 }">视频</text>
      <text class="tab" @click="tab = 1" :class="{ tabsActive: tab == 1 }">图片</text>
    </view>
    <view style="min-height: calc(100vh - 8.125rem);">
      <video-list ref="video" v-if="tab == 0" :uid="uid"></video-list>
      <picture-list ref="picture" v-if="tab == 1" :uid="uid"></picture-list>
    </view>
  </view>
</template>

<script>
import videoList from './video.vue'
import pictureList from './picture.vue'
import { getpProfile } from '@/api/api'
export default {
  components: {
    videoList,
    pictureList
  },
  data() {
    return {
      uid: null,
      username: null,
      profile: null,
      tab: 0,
    }
  },
  onLoad: function (opt) {
    this.uid = opt.id
    this.username = opt.username
  },
  onPullDownRefresh() {
    location.reload()
  },
  onReachBottom() {
    this.onReachBottom()
  },
  mounted() {
    getpProfile(this.username, (res, code) => {
      console.log(res)
      console.log(code)
      this.profile = res
    })
  },
  methods: {
    back(v) {
      if (v == 0) {
        uni.reLaunch({
          url: '/pages/home/index'
        });
      } else if (v == 1) {
        uni.navigateBack({
          delta: 1
        });
      }
    },
    onReachBottom() {
      let refs
      switch (this.tab) {
        case 0:
          refs = this.$refs.video
          break
        case 1:
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
}
</script>

<style scoped>
.panel {}

.back {
  position: fixed;
  top: 2rem;
  z-index: 100;
  color: #fff;
  text-shadow: 0 0 0.5rem #0008;
}

.backButton {
  display: inline-block;
  padding: 0.8rem 0.8rem;
}

.bg {
  height: 7rem;
  position: sticky;
  top: -6rem;
  z-index: 2;
}

.bgp {
  background-size: cover;
  background-color: #dfdfdf;
  height: 11rem;
  box-shadow: 0 0 0.25rem #0003;
}

button {
  background-color: #00897b;
  color: #fff;
}

.avatar {
  width: 5rem;
  height: 5rem;
  /* box-shadow: 0 0 0.125rem #000a; */
  border-radius: 6rem;
  margin: 0.8rem 1.2rem;
  backdrop-filter: blur(10px);
  border: solid 0.15rem #f5f5f5;
}

.tabs {
  box-shadow: 0 0.15rem 0.3rem #0001;
  padding: 0 1rem;
  display: flex;
  background-color: #f5f5f5;
  position: sticky;
  top: 5rem;
  z-index: 1;
}

.tab {
  padding: 1rem;
  display: inline-block;
  border-bottom: solid 0.125rem #f5f5f5;
  transition: borderColor 100ms ease;
}

.tabsActive {
  border-color: #00897b !important;
  color: #00897b;
}

@media (prefers-color-scheme: dark) {
  .bgp {
    background-color: #3b3b3b;
  }

  .tabs {
    background-color: #101010;
  }

  .avatar {
    border: solid 0.15rem #101010;
  }

  .tabs {
    box-shadow: 0 0.15rem 0.3rem #fff3;
  }

  .tab {
    border-bottom: solid 0.125rem #101010;
  }

  .bgp {
    box-shadow: 0 0 0.25rem #fff8;
  }
}
</style>