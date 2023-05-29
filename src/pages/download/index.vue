<template>
  <view style="display: flex;flex-flow: column;height: 100%;">
    <view class="tabs">
      <view class="tab" :class="{ 'tab-a': tab == 0 }" @click="tab = 0">{{ $t('download.doing') }}</view>
      <view class="tab" :class="{ 'tab-a': tab == 1 }" @click="tab = 1">{{ $t('download.end') }}</view>
    </view>
    <view style="flex: 1">
      <swiper style="height: 100%;" :current="tab" @change="swiper" :duration="100">
        <swiper-item>
          <view v-if="progress.length > 0" style="height: 100%;overflow: auto;">
            <view style="padding: 0.5rem">
              <view v-for="it, i in progress" class="item">
                <view class="bar-o">
                  <view class="bar" style="background-color: #29B6F6;"></view>
                </view>
                <view style="flex: 3;" class="item-con">
                  <view style="padding:0.5rem 0.25rem;overflow: hidden;text-overflow: ellipsis;white-space: nowrap;">
                    {{ it.filename.slice(it.filename.lastIndexOf('/') + 1, it.filename.indexOf('.')) }}
                  </view>
                  <view style="padding:0.5rem 0.5rem 0 0.25rem;font-size: 0.9rem;color:#808080;display: flex;">
                    <view style="flex: 1;">
                      {{ formatBytes(it.downloadedSize) }}/{{ formatBytes(it.totalSize) }}
                    </view>
                    <view style="flex: 1;text-align: right;">
                      {{ (it.totalSize > 0 ? (it.downloadedSize / it.totalSize * 100).toFixed(1) : 0) + '%' }}
                    </view>
                  </view>
                  <view class="progress-bar">
                    <view class="progress-bar-o">
                      <view class="progress-bar-i"
                        :style="{ width: (it.totalSize > 0 ? (it.downloadedSize / it.totalSize * 100) : 0) + '%' }">
                      </view>
                    </view>
                  </view>
                </view>
                <view style="flex: 1;display: flex;align-items: center;text-align: center;">
                  <i @click="abort(it)" class="fa-solid fa-trash-can" style="width: 100%;font-size: 1.2rem;"></i>
                </view>
              </view>
              <button @click="clearDownloading()">{{ $t('download.stopall') }}</button>
            </view>
          </view>
          <view else style="padding-top: 38vh;text-align: center;">
            <image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
          </view>
        </swiper-item>
        <swiper-item>
          <view v-if="end.length > 0" style="height: 100%;overflow: auto;">
            <view style="padding: 0.5rem">
              <view v-for="it, i in end" class="item" @click="open(it)">
                <view class="bar-o">
                  <view class="bar" :style="{ backgroundColor: barColor(it.filename) }"></view>
                </view>
                <view style="flex: 3;" class="item-con">
                  <view
                    style="padding:0.5rem 0.25rem 0.25rem 0.25rem;overflow: hidden;text-overflow: ellipsis;white-space: nowrap;">
                    {{ it.filename.slice(it.filename.lastIndexOf('/') + 1, it.filename.indexOf('.')) }}
                  </view>
                  <view style="padding:0 0.5rem 0 0.25rem;font-size: 0.9rem;color:#808080;display: flex;">
                    <view style="flex: 1;">
                      {{ formatBytes(it.downloadedSize) }}
                    </view>
                    <view style="flex: 1;text-align: right;">
                      {{ $t('download.dled') }}
                    </view>
                  </view>
                  <view
                    style="padding:0 0.5rem 0 0.25rem;font-size: 0.9rem;color:#808080;overflow: hidden;white-space: nowrap;">
                    <view class="path">
                      <text style="margin-right: 4rem;" v-for="i in 2">
                        {{ it.filename.slice(6) }}
                      </text>
                    </view>
                  </view>
                </view>
              </view>
              <button @click="clearDownloadLogs()">{{ $t('download.clearall') }}</button>
            </view>
          </view>
          <view v-else style="padding-top: 38vh;text-align: center;">
            <image src="@/static/icon/cactus.png" style="width: 4rem;height: 4rem;"></image>
          </view>
        </swiper-item>
      </swiper>
    </view>
  </view>
</template>
<script>
import Image from '../home/image.vue'

export default {
  data() {
    return {
      tab: 0,
      progress: [],
      end: []
    };
  },
  created() {
    uni.setNavigationBarTitle({
      title: this.$t('label.download')
    });
    this.getData();
  },
  methods: {
    getData() {
      plus.downloader.enumerate((res) => {
        this.progress = res;
      });
      plus.downloader.enumerate((res) => {
        this.end = res;
      }, "4");
    },
    formatBytes(v) {
      let u;
      let n;
      if (v < 1000) {
        n = v;
        u = "B";
      }
      else if (v >= 1000 && v < 1000000) {
        n = (v / 1000).toFixed(1);
        u = "KB";
      }
      else if (v >= 1000000 && v < 1000000000) {
        n = (v / 1000000).toFixed(1);
        u = "MB";
      }
      else {
        n = (v / 1000000000).toFixed(1);
        u = "GB";
      }
      return n + u;
    },
    swiper: function (t) {
      this.tab = t.detail.current;
    },
    abort(it) {
      it.abort();
      this.getData();
    },
    open(it) {
      plus.runtime.openFiles(it.filename, (err) => {
        console.log(err);
      });
    },
    barColor(v) {
      let a = v.slice(v.lastIndexOf("."));
      let c;
      switch (a) {
        case ".mp4":
          c = "#00897b";
          break;
        case ".jpg":
          c = "#FBC02D";
          break;
        default:
          c = "#81fcf0";
      }
      return c;
    },
    clearDownloading() {
      plus.downloader.clear();
    },
    clearDownloadLogs() {
      plus.downloader.clear(4);
    }
  },
  components: { Image }
}
</script>
<style scoped>
.item {
  background-color: #fff;
  box-shadow: 0 0 0.125rem #0004;
  margin: 0.5rem 0;
  border-radius: 0.25rem;
  display: flex;
  overflow: hidden;
  height: 5.3rem;
}

.item-con {
  padding: 0.25rem;
  overflow: hidden;
}

.bar-o {
  padding: 0.8rem 0.4rem;
}

.bar {
  width: 0.25rem;
  border-radius: 0.25rem;
  height: 100%;
}

.progress-bar {
  padding: 0.25rem 0.5rem 0.5rem 0;
}

.progress-bar-o {
  background-color: #8886;
  height: 0.25rem;
  border-radius: 0.25rem;
  overflow: hidden;
}

.progress-bar-i {
  height: 100%;
  background-color: #00897b;
}

.tabs {
  box-shadow: 0 0.1rem 0.25rem #0002;
  background-color: #f5f5f5;
  display: flex;
  width: 100%;
  z-index: 10;
}

.tab {
  flex: 1;
  padding: 1rem 0;
  text-align: center;
  border-bottom: solid 0.125rem #f5f5f5;
}

.tab-a {
  border-color: #00897b !important;
  color: #00897b;
}

.path {
  display: inline-block;
  animation: sliding 10s linear infinite;
}

button {
  margin: 1rem 0;
  width: 100%;
  background-color: #00897B;
  color: white;
}

@keyframes sliding {
  0% {
    transform: translateX(0%);
  }

  100% {
    transform: translateX(-50%);
  }
}

@media (prefers-color-scheme: dark) {
  .item {
    background-color: #1c1c1c;
  }

  .tabs {
    background-color: #101010;
    box-shadow: 0 0.1rem 0.25rem #fff2;
  }

  .tab {
    border-color: #101010;
  }
}
</style>