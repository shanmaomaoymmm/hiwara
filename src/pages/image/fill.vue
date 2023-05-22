<template>
  <view class="fill">
    <swiper style="height: 100%;" @change="swiper" :current="i">
      <swiper-item v-for="item in data.files" style="display: flex;flex-direction: column;height: 100%;">
        <view style="flex: 1;"></view>
        <view>
          <q-img class="img" :src="item" />
        </view>
        <view style="flex: 1;"></view>
      </swiper-item>
    </swiper>
    <view class="tips">
      第{{ ' ' + (p + 1) + '/' + data.files.length + ' ' }}P
    </view>
  </view>
</template>
<script>
export default {
  data() {
    return {
      img: null,
      i: 1,
      p: 0,
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
    uni.setNavigationBarTitle({
      title: this.data.title
    })
  },
  methods: {
    swiper: function (t) {
      this.p = t.detail.current
    },
  }
}
</script>
<style scoped>
.fill {
  width: 100%;
  height: 100%;
  background-color: black;
  text-align: center;
  font-size: 0;
}

.item {
  height: 400px;
}

.img {
  max-width: 100%;
  max-height: 100%;
}

.tips {
  position: fixed;
  bottom: 1rem;
  right: 1rem;
  color: #fff;
  font-size: 1rem;
}
</style>