<template>
  <view>
    <view style="padding: 2rem;text-align: center;">
      <view>
        <image src="@/static/logo-beta.png" class="logo"></image>
      </view>
      <view class="lable">
        Hiwara
      </view>
    </view>
    <view class="opt">
      <view class="button">
        <view class="button-title">
          Hiwara
        </view>
        <view class="button-opt" style="padding: 1.2rem 1.5rem;">
          {{ $t('setup.about.dev') }}
        </view>
      </view>
      <view class="button">
        <view class="button-title">
          {{ $t('setup.about.version') }}
        </view>
        <view class="button-opt" style="padding: 1rem 1.5rem;">
          v{{ SystemInfo.appVersion }}
        </view>
      </view>
      <view class="button">
        <view class="button-title">
          {{ $t('setup.about.webviewVersion') }}
        </view>
        <view class="button-opt" style="padding: 1rem 1.5rem;">
          v{{ SystemInfo.browserVersion }}
        </view>
      </view>
      <view class="button">
        <view class="button-title">
          {{ $t('setup.about.device') }}
        </view>
        <view class="button-opt" style="padding: 1rem 1.5rem;">
          <i :class="osName(SystemInfo.osName, 1)"></i>
          {{ ' ' }}
          {{ osName(SystemInfo.osName, 0) }}
        </view>
      </view>
    </view>
    <view class="float" dir="auto">
      {{ $t('tip[0]') }}
      <br />
      {{ $t('tip[1]') }}
      <br />
      ©2019-2023 Maoerxiachuan
    </view>
  </view>
</template>
<script>
export default {
  data() {
    return {
      SystemInfo: null,
      init: 0,
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
  created() {
    uni.setNavigationBarTitle({
      title: this.$t('label.about')
    });
    uni.getSystemInfo({
      success: (res) => {
        console.log(res)
        this.SystemInfo = res
      }
    })
  },
  methods: {
    osName(a, c) {
      let b, d
      switch (a) {
        case 'ios':
          b = 'iOS'
          d = 'fa-brands fa-apple'
          break
        case 'android':
          b = 'Android'
          d = 'fa-brands fa-android'
          break
        case 'windows':
          b = 'Windows'
          d = 'fa-brands fa-windows'
          break
        case 'macos':
          b = 'MacOS'
          d = 'fa-brands fa-apple'
          break
        case 'linux':
          b = 'Linux'
          d = 'fa-brands fa-linux'
          break
        default:
          b = 'Others'
          d = 'fa-solid fa-dice-d6'
          break
      }
      if (c == 0) {
        return b
      } else if (c == 1) {
        return d
      }
    }
  }
}
</script>
<style scoped>
.lable {
  padding-top: 1rem;
  font-size: 2rem;
  font-family: label;
  color: #616161;
}

@font-face {
  font-family: label;
  src: url('/static/font/riwenlogo.ttf');
}

.logo {
  width: 8rem;
  height: 8rem;
  box-shadow: 0 0 1rem #0002;
  border-radius: 1.6rem;
}

.opt {
  border-top: #aaaaaa 1px solid;
}

.button {
  border-bottom: #aaaaaa 1px solid;
  color: #616161;
  display: flex;
}

.button-title {
  padding: 1rem 1.5rem;
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

.float {
  text-align: center;
  font-size: 0.8rem;
  position: absolute;
  bottom: 1rem;
  width: 100%;
  color: #808080;
}

@media (prefers-color-scheme: dark) {
  .lable {
    color: #aaaaaa;
  }

  .opt {
    border-top: #666666 1px solid;
  }

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


  .logo {
    box-shadow: 0 0 1rem #fff2;
  }
}
</style>