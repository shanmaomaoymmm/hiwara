<template>
  <view>
    <web-view src="https://www.iwara.tv/account/profile"></web-view>
  </view>
</template>
<script>
export default {
  onNavigationBarButtonTap(e) {
    console.log(e)
    if (e.type == 'home') {
      this.$backhome()
    }
  },
}
</script>