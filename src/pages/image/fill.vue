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
    <!-- #ifdef APP-PLUS -->
    <view class="download" @click="download()">
      {{ $t('image.download') }}
    </view>
    <!-- #endif -->
    <view class="tips">
      {{ $t('image.tip[0]') }} {{ ' ' + (p + 1) + '/' + data.files.length + ' ' }}{{ $t('image.tip[1]') }}
    </view>
  </view>
</template>
<script>
import { download, storagePermission } from '@/api/api'
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
  onNavigationBarButtonTap(e) {
    if (e.type == 'home') {
      this.$backhome()
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
    download() {
      if (storagePermission() == true) {
        let dlUrl = this.data.files[this.p]
        download('image', dlUrl, this.data.title, () => { })
      }
    }
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

.download {
  position: fixed;
  bottom: 1rem;
  left: 0;
  right: 0;
  margin: 0 auto;
  color: #fff;
  font-size: 1rem;
  background-color: #00897b88;
  border: #81fcf0 2px solid;
  padding: 0.5rem;
  width: 5rem;
  border-radius: 0.5rem
}
</style>