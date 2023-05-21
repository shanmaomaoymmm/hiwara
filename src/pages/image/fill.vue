<template>
  <view class="fill">
    <view style="flex: 1;">
      <swiper style="height: 100%;">
        <swiper-item v-for="item in data.files">
          <img class="img" :src="item" />
        </swiper-item>
      </swiper>
    </view>
    <view>

    </view>
  </view>
</template>
<script>
export default {
  data() {
    return {
      img: null,
      i: 0,
      data: {
        files
      }
    }
  },
  onLoad: function (e) {
    this.data = JSON.parse(decodeURIComponent(e.data))
    this.i = e.index
    console.log(this.index)
    console.log(this.data)
    this.img = this.data.files[this.i]
  },
}
</script>
<style scoped>
.fill {
  width: 100%;
  height: 100%;
  background-color: black;
  text-align: center;
  display: flex;
  flex-direction: column;
  font-size: 0;
}

.item {
  height: 400px;
}

.img {
  max-width: 100%;
  max-height: 100%;
}
</style>