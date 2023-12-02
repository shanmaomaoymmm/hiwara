<template>
  <view style="padding-bottom: 1rem;">
    <view class="button" style="display: flex;padding: 0;">
      <view class="button-title" style="flex: 2;padding: 1.2rem 1.5rem;">
        {{ $t('aria2.ariaon') }}
      </view>
      <view class="button-opt" style="flex: 1;text-align: right;padding: 0.75rem 0.25rem;">
        <switch @change="ariaChange" :checked="ariaon" color="#00897b" style="transform:scale(0.8)" />
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        {{ 'Aria2 RPC' }}
      </view>
      <view class="button-opt">
        <input class="input" v-model="ariarpc" placeholder="http://127.0.0.1:6800/jsonrpc" :disabled="!ariaon" />
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        {{ 'Aria2 Token' }}
      </view>
      <view class="button-opt">
        <input class="input" v-model="ariatoken" placeholder="password" :disabled="!ariaon" />
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        {{ $t('aria2.path') }}
      </view>
      <view class="button-opt">
        <input class="input" v-model="ariapath" placeholder="/home/aria2/download" :disabled="!ariaon" />
      </view>
    </view>
    <view class="tips">
      <i class="fa-solid fa-circle-question fa-fw"></i>
      {{ $t('aria2.tips') }}<br>
      {{ $t('aria2.tips[1]') }}<br>
      {{ $t('aria2.tips[2]') }}<br>
      {{ $t('aria2.tips[3]') }}
    </view>
  </view>
</template>
<script>
import {
  getStorage,
  setStorage,
} from '@/api/api'
export default ({
  data() {
    return {
      init: 0,
      ariaon: false,
      ariarpc: null,
      ariatoken: null,
      ariapath: null,
    }
  },
  onLoad: function (opt) {
    this.init = opt.init
  },
  onNavigationBarButtonTap(e) {
    if (e.type == 'home') {
      uni.reLaunch({
        url: '/pages/index/index?check=' + this.init
      });
    }
  },
  watch: {
    ariarpc(n) {
      setStorage('ariarpc', n)
    },
    ariatoken(n) {
      setStorage('ariatoken', n)
    },
    ariapath(n) {
      setStorage('ariapath', n)
    },
  },
  created() {
    uni.setNavigationBarTitle({
      title: this.$t("setup.setup.aria2")
    });
    this.getSetup()
  },
  methods: {
    getSetup() {
      returnStorage('ariaon', false, (res) => {
        this.ariaon = res
      })
      returnStorage('ariarpc', null, (res) => {
        this.ariarpc = res
      })
      returnStorage('ariatoken', null, (res) => {
        this.ariatoken = res
      })
      returnStorage('ariapath', null, (res) => {
        this.ariapath = res
      })
      function returnStorage(key, def, cb) {
        getStorage(key, (a) => {
          let b
          if (a) {
            b = a
          } else {
            b = def
          }
          cb(b)
        })
      }
    },
    ariaChange(a) {
      this.ariaon = a.detail.value
      setStorage('ariaon', a.detail.value)
    }
  }
})
</script>
<style scoped>
.button {
  border-bottom: #aaaaaa 1px solid;
  color: #616161;
  padding: 1rem;
}

.button-title {
  padding: 0 0.5rem;
}

.button-opt {}

.input {
  margin-top: 1rem;
  border-bottom: solid 2px #00897B;
}

@media (prefers-color-scheme: dark) {
  .button {
    color: #BDBDBD;
    border-bottom: #666666 1px solid;
  }

  .button-opt {
    color: #696969;
  }

  .fa-solid {
    color: #666666;
  }
}

.tips {
  padding: 1rem;
  font-size: 0.8rem;
}
</style>