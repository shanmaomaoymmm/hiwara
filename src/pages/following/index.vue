<template>
  <view>
    <view v-if="onload" style="text-align: center;padding-top: 30vh;">
      <image class="loading" src="@/static/icon/loading.png"></image>
      <br>
      <text>{{ $t('loading1') }}</text>
    </view>
    <view v-else>
      <view v-if="data.length > 0" style="padding:0 0.5rem;">
        <view v-for="item, i in data" class="item" @click="gotoPage(item.user.id, item.user.username)">
          <view class="ava">
            <q-avatar class="img"
              :src="item.user.avatar ? 'https://i.iwara.tv/image/avatar/' + item.user.avatar.id + '/' + item.user.avatar.name : 'https://www.iwara.tv/images/default-avatar.jpg'" />
          </view>
          <view class="lab">
            {{ item.user.name }}
          </view>
        </view>
      </view>
      <view v-else style="padding-top: 38vh;text-align: center;">
        <image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
      </view>
    </view>
  </view>
</template>
<script>
import { getFollowing } from '@/api/api.js'
export default {
  data() {
    return {
      data: [],
      page: 0,
      onload: true
    }
  },
  created() {
    uni.setNavigationBarTitle({
      title: this.$t('label.following')
    });
    this.getData(() => {
      this.onload = false
    })
  },
  onNavigationBarButtonTap(e) {
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  // 下拉
  onPullDownRefresh() {
    this.refresh(() => {
      uni.stopPullDownRefresh();
    })
  },
  // 滑到底部
  onReachBottom() {
    this.onBottom()
  },
  methods: {
    // 刷新
    refresh(cb) {
      this.onload = true
      this.data = []
      this.page = 0
      this.getData(() => {
        this.onload = false
        cb()
      })
    },
    onBottom() {
      this.getData(() => { })
    },
    // 获取列表
    getData(cb) {
      getFollowing(this.page, (res, code) => {
        if (res != false) {
          if (code == 200) {
            for (let i = 0; i < res.results.length; i++) {
              this.data.push(res.results[i])
              cb()
            }
            this.page++
          }
        }
      })
    },
    gotoPage(uid, username) {
      uni.navigateTo({
        url: '/pages/user/index?uid=' + uid + '&username=' + username,
        animationType: 'slide-in-right',
        animationDuration: 100
      });
    }
  }
}
</script>
<style scoped>
.item {
  display: flex;
  padding: 0.5rem 1rem;
  background-color: #fff;
  box-shadow: 0 0 0.125rem #0004;
  margin: 0.5rem 0;
  border-radius: 0.25rem;
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.ava {
  width: 3rem;
  height: 3rem;
}

.img {
  width: 3rem;
  height: 3rem;
  border-radius: 3rem;
  box-shadow: 0 0 0.125rem #000a;
}

.lab {
  flex: 1;
  padding: 0.5rem 1rem;
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

@media (prefers-color-scheme: dark) {
  .item {
    background-color: #1c1c1c;
    box-shadow: 0 0 0.125rem #fffa;
  }

  .img {
    box-shadow: 0 0 0.125rem #fffa;
  }
}
</style>