<template>
  <view style="padding-bottom: 1rem;">
    <view class="button" v-for="item, i in list" @click="setDefinition(item)">
      <view class="button-title">
        {{ item }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
  </view>
</template>
<script>
import { setStorage } from '@/api/api.js'
export default ({
  data() {
    return {
      list: ['Source', '540p', '360p'],
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
      title: this.$t('label.definition')
    });
  },
  methods: {
    setDefinition(def) {
      setStorage('definition', def)
      uni.navigateBack({
        delta: 1
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