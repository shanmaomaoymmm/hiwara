<template>
  <view class="qimg" @click="$emit('click')">
    <img class="img" :src="path" @load="imgLoad()" @error="imgError()" />
    <transition name="fade">
      <view v-show="loading" class="loading">
        <i class="fa-brands fa-digital-ocean "></i>
      </view>
    </transition>
  </view>
</template>
<script>
export default {
  data() {
    return {
      path: null,
      def: '/static/img/not-img.jpg',
      loading: true,
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
      this.loading = false
    },
    imgError() {
      this.path = this.def
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
  display: inline-block;
  position: relative;
}

.img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.loading {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 100%;
  height: 100%;
  font-size: 2rem;
  margin: auto;
  display: flex;
  justify-content: center;
  align-items: center;
  backdrop-filter: blur(0.4rem);
}

.fa-digital-ocean {
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

.fade-enter-active,
.fade-leave-active {
  transition: opacity 100ms;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}
</style>