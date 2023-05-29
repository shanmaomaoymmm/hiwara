<template>
  <view>
    <view v-if="data.length > 0">
      <view v-for="it, i in data" class="item" @click="gotoPage(it.id, it.uid, it.type)">
        <view style="flex: 1;overflow: hidden;">
          <view class="label">
            <text>{{ it.title }}</text>
          </view>
          <view style="padding: 0.5rem 1rem;display: flex;">
            <view>
              <q-avatar class="avatar" :src="it.avatar"></q-avatar>
            </view>
            <view class="username">{{ it.username }}</view>
          </view>
        </view>
        <view class="preview">
          <q-img :src="it.preview"></q-img>
        </view>
      </view>
    </view>
    <view v-else style="padding-top: 38vh;text-align: center;">
      <image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
    </view>
  </view>
</template>
<script>
import { getHistory } from '@/api/api.js'
export default {
  data() {
    return {
      data: []
    }
  },
  created() {
    uni.setNavigationBarTitle({
      title: this.$t('label.history')
    });
    getHistory((res) => {
      this.data = res
    })
  },
  onNavigationBarButtonTap(e) {
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  methods: {
    gotoPage(id, uid, type) {
      if (type == 'video') {
        uni.navigateTo({
          url: '/pages/player/index?id=' + id + '&uid=' + uid,
          animationType: 'slide-in-right',
          animationDuration: 100
        });
      } else if (type == 'image') {
        uni.navigateTo({
          url: '/pages/image/index?id=' + id + '&uid=' + uid,
          animationType: 'slide-in-right',
          animationDuration: 100
        });
      }
    }
  }
}
</script>
<style scoped>
.item {
  margin: 0.5rem;
  white-space: nowrap;
  box-shadow: 0 0 0.125rem #0004;
  border-radius: 0.25rem;
  background-color: #fff;
  font-size: 0;
  overflow: hidden;
  display: flex;
}

.label {
  overflow: hidden;
  text-overflow: ellipsis;
  font-weight: bold;
  font-size: 1rem;
  padding: 1rem 1rem 0 1rem;
}

.preview {
  width: 7rem;
}

.avatar {
  width: 2rem;
  height: 2rem;
  border-radius: 2rem;
  box-shadow: 0 0 0.125rem #000a;
}

.username {
  flex: 1;
  display: flex;
  align-items: center;
  font-size: 1rem;
  padding: 0 0.5rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: #808080;
}

@media (prefers-color-scheme: dark) {
  .item {
    background-color: #1c1c1c;
    box-shadow: 0 0 0.125rem #fffa;
  }

  .avatar {
    box-shadow: 0 0 0.125rem #fffa;
  }

  .username {
    color: #afafaf;
  }
}
</style>