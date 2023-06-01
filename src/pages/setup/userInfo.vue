<template>
  <view>
    <web-view src="https://www.iwara.tv/account/profile"></web-view>
  </view>
</template>
<script>
export default {
  onNavigationBarButtonTap(e) {
    
    if (e.type == 'home') {
      uni.reLaunch({
        url: '/pages/index/index?check=1'
      });
    }
  },
}
</script>