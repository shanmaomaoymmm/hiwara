<template>
  <view>
    <view v-if="onload" style="text-align: center;padding-top: 30vh;">
      <image class="loading" src="@/static/icon/loading.png"></image>
      <br>
      <text>资源加载中……</text>
    </view>
    <view v-else>
      <view v-if="error" style="text-align: center;padding-top: 30vh;">
        <img src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;" />
        <view style="font-size: 1.3rem;font-weight: bold;;color: #00897B;margin: 0.5rem 0;">
          <text>大漠孤烟直，长河落日圆</text>
        </view>
        <text>你没有任何收藏，请到别的地方看看吧</text>
      </view>
      <view v-else style="padding: 0.5rem;">
        <view v-for="item, i in list" class="item" @click="gotoPage(item.id, item.username)">
          <view class="ava">
            <image class="img" :src="item.avatar != null
              ? 'https://i.iwara.tv/image/avatar/' +
              item.avatar.id + '/' + item.avatar.name
              : 'https://www.iwara.tv/images/default-avatar.jpg'"></image>
          </view>
          <view class="lab">
            {{ item.name }}
          </view>
        </view>
        <view style="text-align: center;padding-bottom: 1rem;">
          <text>
            <i v-if="loading" class="fa-solid fa-circle-notch fa-spin" style="color: #00897b"></i>{{ ' ' }}{{ loading ?
              '正在加载数据……' : '已加载完成' }}
          </text>
        </view>
      </view>
    </view>
  </view>
</template>
<script>
import { search } from "@/api/api.js";
export default {
  data() {
    return {
      list: [],
      page: 0,
      onload: true,
      loading: false,
      error: false
    }
  },
  props: ['s'],
  created() {
    this.getData(() => {
      this.onload = false
    })
  },
  methods: {
    refresh(cb) {
      this.onload = true
      this.list = []
      this.page = 0
      this.getData(() => {
        this.onload = false
        cb()
      })
    },
    getData(cb) {
      this.loading = true
      search('user', this.s, this.page, (res, code) => {
        this.loading = false
        if (code == 200) {
          if (res.results.length > 0) {
            this.list = this.list.concat(res.results)
            this.page++
          } else {
            if (this.page == 0) {
              this.error = true
            }
          }
        } else if (code == 408) {
          uni.showToast({
            title: "呐！少冲一点吧\r\n无法连接到服务器",
            icon: "none",
            duration: 3000,
          });
        }
        cb()
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