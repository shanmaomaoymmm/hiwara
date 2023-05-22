<template>
  <view class="qimg" @click="$emit('click')">
    <view v-show="show" :class="error ? 'error' : 'loading'">
      <i v-if="error" class="fa-solid fa-circle-user"></i>
      <i v-else class="fa-brands fa-digital-ocean"></i>
    </view>
    <img v-show="!show" class="img" :src="path" @load="imgLoad()" @error="imgError()" />
  </view>
</template>
<script>
export default {
  data() {
    return {
      path: null,
      show: true,
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
      this.show = false
    },
    imgError() {
      this.error = true
    },
  }
}
</script>
<style scoped>
.qimg {
  font-size: 0;
  text-align: center;
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.img {
  width: 100%;
  height: 100%;
}

.loading,
.error {
  font-size: 1.5rem;
  text-align: center;
}

.loading {
  animation: rotate 175ms steps(1) infinite;
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
</style>