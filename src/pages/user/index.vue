<template>
  <view>
    <view v-show="loading" style="text-align: center;padding-top: 40vh;">
      <image class="loading" src="@/static/icon/loading.png"></image>
      <br>
      <text>资源加载中……</text>
    </view>
    <view v-show="!loading">
      <view class="panel">
        <!-- <view class="back">
          <i @click="back(1)" class="fa-solid fa-angle-left backButton"></i>
          <i @click="back(0)" class="fa-solid fa-house backButton"></i>
        </view> -->
        <view class="bg">
          <view class="bgp" :style="{ backgroundImage: 'url(' + profile.background + ')' }"></view>
        </view>
        <view style="display: flex;position: relative;z-index: 3;">
          <view>
            <image class="avatar" :src="profile.avatar" />
          </view>
          <view style="flex: 1;">
            <view
              style="font-size: 1.5rem;color: #fff;text-shadow: 0 0 0.25rem #000a;padding: 1.6rem 0 0.8rem 0;overflow: hidden;white-space: nowrap;text-overflow: ellipsis;width: calc(100vw - 8rem);">
              {{
                profile.name }}</view>
            <view v-if="!self">
              <button @click="followers" size="mini">{{ profile.following ? '已关注' : '＋ 关注' }}</button>
              {{ ' ' }}
              <button size="mini">{{ profile.friend ? '已是朋友' : '＋ 朋友' }}</button>
              {{ ' ' }}
              <!-- <button size="mini"><i class="fa-regular fa-envelope fa-fw"></i>{{ ' ' }}私信</button> -->
            </view>
          </view>
        </view>
        <view style="padding:0 1rem;overflow: hidden;word-wrap: break-word;">
          {{ profile.body }}
        </view>
        <view class="tabs">
          <text class="tab" @click="tab = 0" :class="{ tabsActive: tab == 0 }">视频</text>
          <text class="tab" @click="tab = 1" :class="{ tabsActive: tab == 1 }">图片</text>
        </view>
        <view>
          <video-list ref="video" v-if="tab == 0" :uid="uid"></video-list>
          <image-list ref="image" v-if="tab == 1" :uid="uid"></image-list>
        </view>
      </view>
    </view>
    <uni-transition @click="backTop()" custom-class="back-top" mode-class="zoom-in" :duration="50"
      :show="scrollTop > 300">
      <i class="fa-solid fa-angle-up"></i>
    </uni-transition>
  </view>
</template>

<script>
import videoList from './video.vue'
import imageList from './image.vue'
import { getpProfile, followers, friends } from '@/api/api'
export default {
  components: {
    videoList,
    imageList
  },
  data() {
    return {
      uid: null,
      username: null,
      self: null,
      profile: {
        background: '/static/img/loli.png'
      },
      tab: 0,
      loading: true,
      scrollTop: 0,
    }
  },
  onPageScroll(e) {
    this.scrollTop = e.scrollTop
  },
  onLoad: function (opt) {
    this.uid = opt.uid
    this.username = opt.username
    if (typeof (opt.self) == 'undefined') {
      this.self = false
    } else {
      this.self = true
    }
  },
  onPullDownRefresh() {
    location.reload()
  },
  onReachBottom() {
    this.onReachBottom()
  },
  created() {
    getpProfile(this.username, (res, code) => {
      this.profile = res
      console.log(this.profile)
      uni.setNavigationBarTitle({
        title: this.profile.name
      })
      this.loading = false
    })
  },
  onNavigationBarButtonTap(e) {
    console.log(e)
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  methods: {
    back(v) {
      if (v == 0) {
        uni.reLaunch({
          url: '/pages/home/index'
        });
      } else {
        uni.navigateBack({
          delta: v
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
          refs = this.$refs.image
          break
        default:
          refs = null
          break
      }
      if (refs) {
        console.log(refs)
        refs.onBottom()
      }
    },
    followers() {
      if (this.profile.following) {
        followers(this.uid, 0, (res, code) => {
          if (code == 204) {
            uni.showToast({
              title: "已取消关注",
              icon: "none",
              duration: 3000,
            })
            this.profile.following = !this.profile.following
          } else {
            uni.showToast({
              title: "操作失败",
              icon: "none",
              duration: 3000,
            })
          }
        })
      } else {
        followers(this.uid, 1, (res, code) => {
          if (code == 201) {
            uni.showToast({
              title: "关注成功！！！",
              icon: "none",
              duration: 3000,
            })
            this.profile.following = !this.profile.following
          } else {
            uni.showToast({
              title: "操作失败",
              icon: "none",
              duration: 3000,
            })
          }
        })
      }
    },
    friends() {
      if (this.profile.following) {
        friends(this.uid, 0, (res, code) => {
          if (code == 204) {
            uni.showToast({
              title: "已删除好友",
              icon: "none",
              duration: 3000,
            })
            this.profile.friends = !this.profile.friends
          } else {
            uni.showToast({
              title: "操作失败",
              icon: "none",
              duration: 3000,
            })
          }
        })
      } else {
        friends(this.uid, 1, (res, code) => {
          if (code == 201) {
            uni.showToast({
              title: "加好友申请已发送",
              icon: "none",
              duration: 3000,
            })
          } else {
            uni.showToast({
              title: "操作失败",
              icon: "none",
              duration: 3000,
            })
          }
        })
      }
    },
    backTop() {
      uni.pageScrollTo({
        scrollTop: 0,
        duration: 100
      })
    }
  },
  watch: {
    flag(v) {
      if (v == 1) {
        this.tab = 1
      } else if (v == 2) {
        if (this.tab == 1) {
          this.tab = 0
        } else {
          this.back(1)
        }
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
  height: 6rem;
  position: sticky;
  top: -7.5rem;
  z-index: 2;
}

.bgp {
  background-size: cover;
  background-color: #dfdfdf;
  height: 10rem;
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
  top: 2.5rem;
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

.loading {
  width: 4rem;
  height: 4rem;
  animation: rotate 350ms linear infinite;
}

@keyframes rotate {
  0% {
    transform: rotate(0deg);
  }

  25% {
    transform: rotate(90deg);
  }

  50% {
    transform: rotate(180deg);
  }

  75% {
    transform: rotate(270deg);
  }

  100% {
    transform: rotate(360deg);
  }
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

  .back-top {
    box-shadow: 0 0 0.25rem #fff2;
  }
}
</style>