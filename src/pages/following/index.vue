<template>
  <view>
    <view v-if="data.length > 0" style="padding:0 0.5rem;">
      <view v-for="item, i in data" class="item" @click="gotoPage(item.id, item.username)">
        <view class="ava">
          <q-avatar class="img" :src="item.avatar" />
        </view>
        <view class="lab">
          {{ item.name }}
        </view>
      </view>
    </view>
    <view v-else style="padding-top: 38vh;text-align: center;">
      <image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
    </view>
  </view>
</template>
<script>
import { getFollowing } from '@/api/api.js'
export default {
  data() {
    return {
      data: []
    }
  },
  created() {
    getFollowing((res) => {
      this.data = res
    })
  },
  onNavigationBarButtonTap(e) {
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  methods: {
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