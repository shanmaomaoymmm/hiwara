<template>
  <view class="qavatar">
    <view class="tips" v-show="!show">
      <i v-if="error" class="fa-solid fa-circle-user error"></i>
      <i v-else class="fa-brands fa-digital-ocean loading"></i>
    </view>
    <transition name="fade">
      <image v-show="show" :src="path" mode="aspectFill" @error="imgError" @load="imgLoad" class="img"></image>
    </transition>
  </view>
</template>
<script>
export default {
  data() {
    return {
      path: null,
      show: false,
      error: false,
    }
  },
  props: ['src'],
  created() {
    this.path = this.src
  },
  watch: {
    src: function (n) {
      this.path = n
    }
  },
  methods: {
    imgLoad() {
      this.show = true
    },
    imgError() {
      this.show = false
      this.error = true
    },
  }
}
</script>
<style scoped>
.qavatar {
  height: 100%;
  width: 100%;
  font-size: 0;
  overflow: hidden;
  display: inline-block;
}

.tips {
  text-align: center;
  height: inherit;
  width: inherit;
  display: flex;
  align-items: center;
}

.error {
  width: 100%;
  font-size: 2rem;
}

.loading {
  width: 100%;
  font-size: 1.2rem;
  animation: rotate 175ms steps(1) infinite;
}

.img {
  object-fit: cover;
  height: 100%;
  width: 100%;
}

@keyframes rotate {
  0% {
    transform: rotate(0deg);
  }

  25% {
    transform: rotate(90deg);
  }

  50% {
    transform: rotate(180deg);
  }

  75% {
    transform: rotate(270deg);
  }

  100% {
    transform: rotate(360deg);
  }
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 100ms;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}
</style>