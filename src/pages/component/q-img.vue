<template>
  <view class="qimg" @click="$emit('click')">
    <view style="flex: 1;"></view>
    <view>
      <view v-show="loading" class="loading">
        <i class="fa-brands fa-digital-ocean "></i>
      </view>
      <img v-show="!loading" class="img" :src="path" @load="imgLoad()" @error="imgError()" />
    </view>
    <view style="flex: 1;"></view>
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
  display: flex;
  flex-direction: column;
}

.img {
  width: 100%;
  min-height: 100%;
}

.loading {
  font-size: 2rem;
  text-align: center;
  line-height: 100%;
  height: 100%;
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
</style>