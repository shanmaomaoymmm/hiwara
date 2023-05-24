<template>
  <view style="padding: 0 1rem;">
    <view class="panel">
      <view>
        <image src="@/static/icon/game.png" style="width: 6rem;height: 6rem;" />
      </view>
      <view style="font-size: 1.5rem;padding:1.5rem 0;">
        你的网络出现了问题
      </view>
      <view>
        你已登录至iwara.tv
        <br />
        但你的网络环境无法连接至iwara.tv
        <br />
        请尝试以下方法解决：
      </view>
      <view style="padding:1.5rem 0;">
        1.请检查是否连接到互联网
        <br />
        2.请检查手机WiFi，数据网络是否正常工作
        <br />
        3.请检查路由器是否正常工作
        <br />
        4.请检查你的网络环境能否正常访问iwara.tv
      </view>
    </view>
    <view>
      <button @click="retry()">
        重试
      </button>
      <button @click="setup()">
        进入设置界面
      </button>
    </view>
  </view>
</template>
<script>
export default {
  methods: {
    setup() {
      uni.navigateTo({
        url: '/pages/setup/index?init=1',
        animationType: 'slide-in-right',
        animationDuration: 100
      });
    },
    retry() {
      uni.reLaunch({
        url: '/pages/index/index'
      });
    }
  }
}
</script>
<style>
.panel {
  padding: 5vh 0.5rem 0 0.5rem;
  font-size: 0.9rem;
}

button {
  margin: 1rem 0;
  width: 100%;
  background-color: #00897B;
  color: white;
}
</style>