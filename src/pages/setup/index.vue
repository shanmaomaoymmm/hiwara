<template>
  <view>
    <view class="button">
      <view class="button-title">
        自动播放
      </view>
      <view class="button-opt" style="padding: 0.75rem 0.25rem;">
        <switch checked color="#00897b" style="transform:scale(0.8)" />
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        默认播放清晰度
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        原画{{ ' ' }}
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
    <view class="button" @click="gotoPage('/pages/setup/language')">
      <view class="button-title">
        语言(Language)
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        中文(简体){{ ' ' }}
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        修改个人信息
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-angles-right"></i>
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        此应用信息
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        退出登录
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-door-open"></i>
      </view>
    </view>
  </view>
</template>
<script>
export default ({
  components: {

  },
  data() {
    return {

    }
  },
  onNavigationBarButtonTap(e) {
    console.log(e)
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  created() {
  },
  methods: {
    gotoPage(url) {
      uni.navigateTo({
        url: url,
        animationType: 'slide-in-right',
        animationDuration: 100
      });
    }
  }
})
</script>
<style scoped>
.button {
  border-bottom: #aaaaaa 1px solid;
  color: #616161;
  display: flex;
}

.button-title {
  padding: 1.2rem 1.5rem;
  flex: 2;
}

.button-opt {
  flex: 1;
  text-align: right;
}

@media (prefers-color-scheme: dark) {
  .button {
    color: #BDBDBD;
    border-bottom: #666666 1px solid;

  }
}
</style>