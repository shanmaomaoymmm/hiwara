<template>
  <view class="fill">
    <view style="flex: 1;">
      <swiper style="height: 100%;" :current="i">
        <swiper-item v-for="item in data.files" style="display: flex;flex-direction: column;height: 100%;">
          <view style="flex: 1;"></view>
          <view>
            <q-img class="img" :src="item" />
          </view>
          <view style="flex: 1;"></view>
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
      i: 1,
      data: {
        files: []
      }
    }
  },
  onLoad: function (e) {
    this.data = JSON.parse(decodeURIComponent(e.data))
    this.i = e.index
    console.log(this.i)
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