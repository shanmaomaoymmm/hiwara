<template>
  <view style="padding: 0 1rem;">
    <view class="panel">
      <view>
        <image src="@/static/icon/game.png" style="width: 6rem;height: 6rem;" />
      </view>
      <view dir="auto">
        <view style="font-size: 1.5rem;padding:1.5rem 0;">
          {{ $t('index.netfail[0]') }}
        </view>
        <view>
          {{ $t('index.netfail[1]') }}
          <br />
          {{ $t('index.netfail[2]') }}
          <br />
          {{ $t('index.netfail[3]') }}
        </view>
        <view style="padding:1.5rem 0;">
          {{ $t('index.netfail[4]') }}
          <br />
          {{ $t('index.netfail[5]') }}
          <br />
          {{ $t('index.netfail[6]') }}
          <br />
          {{ $t('index.netfail[7]') }}
        </view>
      </view>
      <view>
        <button @click="retry()">
          {{ $t('index.netfail[8]') }}
        </button>
        <button @click="outline()">
          {{ $t('index.netfail[9]') }}
        </button>
      </view>
    </view>
  </view>
</template>
<script>
export default {
  created() {
    uni.setNavigationBarTitle({
      title: this.$t('label.netfail')
    });
  },
  methods: {
    outline() {
      uni.navigateTo({
        url: '/pages/index/outline',
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