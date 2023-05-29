<template>
  <view>
    <view class="button">
      <view class="button-title">
        {{ $t("setup.setup.autoplay") }}
      </view>
      <view class="button-opt" style="padding: 0.75rem 0.25rem;">
        <switch @change="autoplayChange" :checked="autoplay" color="#00897b" style="transform:scale(0.8)" />
      </view>
    </view>
    <view class="button" @click="gotoPage('/pages/setup/definition')">
      <view class="button-title">
        {{ $t("setup.setup.definition") }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        {{ definition }}{{ ' ' }}
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
    <view class="button">
      <view class="button-title">
        {{ $t("setup.setup.retry") }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-minus" @click="retryChange(0)"></i>
        <text style="width: 3rem;text-align: center;display: inline-block;">{{ retry }}</text>
        <i class="fa-solid fa-plus" @click="retryChange(1)"></i>
      </view>
    </view>
    <view class="button" @click="gotoPage('/pages/setup/language')">
      <view class="button-title">
        {{ $t("setup.setup.language") }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        {{ $languageList.find((item) => { return item.code == language }).name }}{{ ' ' }}
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
    <view v-if="init == 0" class="button" @click="gotoPage('/pages/setup/userInfo')">
      <view class="button-title">
        {{ $t("setup.setup.userInfo") }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-angles-right"></i>
      </view>
    </view>
    <view class="button" @click="gotoPage('/pages/setup/about')">
      <view class="button-title">
        {{ $t("setup.setup.about") }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
    <view class="button" @click="gotoPage('/pages/debug/index')">
      <view class="button-title">
        Debug
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
    <view v-if="init == 0" class="button" @click="logout()">
      <view class="button-title">
        {{ $t("setup.setup.logout") }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-door-open"></i>
      </view>
    </view>
  </view>
</template>
<script>
import {
  getStorage,
  setStorage,
  removeStorage
} from '@/api/api'
export default ({
  data() {
    return {
      definition: null,
      language: null,
      autoplay: false,
      retry: 16,
      init: 0,
    }
  },
  onLoad: function (opt) {
    this.init = opt.init
  },
  onNavigationBarButtonTap(e) {
    console.log(e)
    if (e.type == 'home') {
      uni.reLaunch({
        url: '/pages/index/index?check=' + this.init
      });
    }
  },
  onShow() {
    this.getSteup()
  },
  created() { },
  methods: {
    getSteup() {
      returnStorage('autoplay', false, (res) => {
        this.autoplay = res
      })
      returnStorage('definition', 'Source', (res) => {
        this.definition = res
      })
      returnStorage('language', 'zh-hans', (res) => {
        this.language = res
      })
      returnStorage('retry', 16, (res) => {
        this.retry = res
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
    gotoPage(url) {
      uni.navigateTo({
        url: url + '?init=' + this.init,
        animationType: 'slide-in-right',
        animationDuration: 100
      });
    },
    autoplayChange: (a) => {
      setStorage('autoplay', a.detail.value)
    },
    retryChange(t) {
      if (t == 0) {
        if (this.retry > 4) {
          this.retry--
        }
      } else if (t == 1) {
        if (this.retry < 256) {
          this.retry++
        }
      }
      setStorage('retry', this.retry)
      uni.showToast({
        title: '连接数修改成功\r\n在下次应用启动后生效',
        icon: 'none',
        duration: 2000
      });
    },
    logout() {
      uni.showModal({
        title: '退出登录',
        content: '是否退出此账号？\n',
        confirmColor: '#00897B',
        success: function (res) {
          this.logoutopt()
        }.bind(this)
      });
    },
    logoutopt() {
      uni.showToast({
        title: '已退出登录',
        icon: 'none',
        duration: 3000
      });
      removeStorage('token', () => {
        uni.reLaunch({
          url: '/pages/index/index'
        });
      })
    }
  }
})
</script>
<style scoped>
.button {
  border-bottom: #aaaaaa 1px solid;
  color: #616161;
  display: flex;
}

.button-title {
  padding: 1.2rem 1.5rem;
  flex: 2;
}

.button-opt {
  flex: 1;
  text-align: right;
  color: #969696;
}

.fa-solid {
  color: #616161;
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
</style>