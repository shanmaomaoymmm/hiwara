<template>
  <view style="padding-bottom: 1rem;">
    <view class="button" v-for="item, i in list" @click="gotoPage(item.url)">
      <view class="button-title">
        {{ item.name }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
  </view>
</template>
<script>
export default ({
  data() {
    return {
      list: [
        {
          name: this.$t('index.outline[0]'),
          url: '/pages/download/index'
        }, {
          name: this.$t('index.outline[1]'),
          url: '/pages/setup/index?init=1'
        }
      ],
    }
  },
  onNavigationBarButtonTap(e) {
    
    if (e.type == 'home') {
      uni.reLaunch({
        url: '/pages/index/index?check=1'
      });
    }
  },
  methods: {
    gotoPage(url) {
      uni.navigateTo({
        url: url,
        animationType: 'slide-in-right',
        animationDuration: 100
      });
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