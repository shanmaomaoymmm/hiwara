<template>
  <view style="font-size: 0.8rem;">
    系统信息
    <br />
    <pre>{{ JSON.stringify(SystemInfo, null, 4) }}</pre>
    <br />
    系统信息
    <br />
    <pre>{{ JSON.stringify(DeviceInfo, null, 4) }}</pre>
  </view>
</template>

<script scoped>
export default {
  data() {
    return {
      SystemInfo: null,
      DeviceInfo: null,
    }
  },
  created() {
    uni.getSystemInfo({
      success: (res) => {
        console.log(res)
        this.SystemInfo = res
      }
    })
    this.DeviceInfo=uni.getDeviceInfo()
  },
  methods: {

  }
}
</script>

<style></style>