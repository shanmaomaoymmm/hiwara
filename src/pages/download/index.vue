<template>
  <view>
    <view v-for="it, i in data">
      {{ it.name }}
    </view>
  </view>
</template>
<script>
export default {
  data() {
    return {
      data: [
        {
          name: 'name',
          downloadedSize: '20',
          totalSize: '100',
          path: '/download/base.apk'
        }, {
          name: 'name',
          downloadedSize: '20',
          totalSize: '100',
          path: '/download/base.apk'
        },
      ]
    }
  },
  created() {
    plus.downloader.enumerate((res) => {
      console.log(res)
      this.data = res
    })
  }
}
</script>
<style scoped></style>