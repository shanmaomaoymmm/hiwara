<template>
  <view>
    <view v-if="check">
      <view style="text-align: center;padding-top:14vh">
        <image src="@/static/logo-dev.png" class="logo" :style="{ 'left': logop + 'rem' }"></image>
        <br />
        <view class="lable" :style="{ 'right': titlep + 'rem' }">
          Hiwara
        </view>
      </view>
      <view class="bottom" :style="{ 'bottom': bottom + 'rem' }">
        <i class="fa-solid fa-circle-notch fa-spin" style="color: #00897b;margin-right: 0.4rem;"></i>软件启动中
      </view>
    </view>
    <view v-else>

    </view>
  </view>
</template>
<script>
import { getAccessToken, getStorage } from '@/api/api';
export default {
  data() {
    return {
      check: 1,
      logop: 0,
      titlep: 0,
      bottom: -1.5
    }
  },
  onLoad: function (opt) {
    if (opt.check) {
      this.check = parseInt(opt.check)
    }
  },
  created() {
    if (this.check) {
      this.anime()
      getAccessToken((at) => {
        getStorage('token', (ln) => {
          if (ln) {
            if (at) {
              this.gotoPage('/pages/home/index')
            } else {
              this.gotoPage('/pages/index/netfail')
            }
          } else {
            setTimeout(() => {
              this.gotoPage('/pages/login/index')
            }, 1000)
          }
        })
      })
    } else {
      getStorage('token', (ln) => {
        if (ln) {
          this.gotoPage('/pages/home/index')
        } else {
          setTimeout(() => {
            this.gotoPage('/pages/login/index')
          }, 1000)
        }
      })
    }
  },
  methods: {
    anime() {
      setTimeout(() => {
        this.logop = -5
        this.titlep = -4.6
        this.bottom = 4
      }, 200)
    },
    gotoPage(page) {
      uni.reLaunch({
        url: page
      })
    }
  }
}
</script>
<style scoped>
.logo {
  width: 9rem;
  height: 9rem;
  box-shadow: 0 0 1rem #0002;
  border-radius: 1.6rem;
  display: inline-block;
  vertical-align: middle;
  z-index: 3;
  position: relative;
  transition: left 200ms ease;
}

.lable {
  font-size: 2rem;
  font-family: label;
  color: #616161;
  display: inline-block;
  padding: 1rem;
  z-index: 2;
  position: relative;
  top: -6.5rem;
  transition: right 200ms ease;
}

@font-face {
  font-family: label;
  src: url('/static/font/riwenlogo.ttf');
}

.bottom {
  position: absolute;
  text-align: center;
  width: 100%;
  font-size: 1.1rem;
  color: #616161;
  transition: bottom 200ms ease;
}

@media (prefers-color-scheme: dark) {
  .lable {
    color: #aaaaaa;
  }

  .logo {
    box-shadow: 0 0 1rem #fff2;
  }

  .bottom {
    color: #aaaaaa;
  }
}
</style>