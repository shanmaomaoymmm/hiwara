<template>
  <view class="panel">
    <view class="bg" :style="{ backgroundImage: 'url(' + profile.background + ')' }"></view>
    <img :src="profile.avatar" />
  </view>
</template>

<script>
import { getpProfile } from '@/api/api'
export default {
  data() {
    return {
      uid: null,
      username: 'mushokuflyer',
      profile: null,
    }
  },
  mounted() {
    getpProfile(this.username, (res, code) => {
      console.log(res)
      console.log(code)
      this.profile = res
    })
  }
}
</script>

<style scoped>
.panel {
  padding-top: 3rem;
}

.bg {
  background: #f5f5f5 no-repeat fixed center;
  background-size: cover;
  height: 5rem;
}

.avatar {
  width: 4rem;
  height: 4rem;
  box-shadow: 0 0 0.125rem #000a;
  border-radius: 6rem;
  margin: 1rem 1.5rem;
}
</style>