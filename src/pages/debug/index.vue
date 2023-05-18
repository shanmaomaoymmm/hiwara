<template>
  <view style="padding: 1rem;">
    <view style="font-size: 0.8rem;overflow: scroll">
      <pre>
        系统信息
        {{ JSON.stringify(SystemInfo, null, 4) }}
      </pre>
    </view>
  </view>
</template>

<script scoped>
export default {
  data() {
    return {
      SystemInfo: null,
      DeviceInfo:null,
    }
  },
  created() {
    uni.getSystemInfo({
      success: (res) => {
        console.log(res)
        this.SystemInfo = res
      }
    })
  },
  methods: {

  }
}
</script>

<style></style>