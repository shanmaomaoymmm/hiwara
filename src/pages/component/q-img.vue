<template>
  <view class="qimg" @click="$emit('click')">
    <img class="img" :src="path" @load="imgLoad()" @error="imgError()" />
  </view>
</template>
<script>
export default {
  data() {
    return {
      path: null,
      def: '/static/img/not-img.jpg'
    }
  },
  props: ['src'],
  created() {
    console.log(this.src)
    this.path = this.src
  },
  watch: {
    src: function (n) {
      this.path = n
      console.log(n)
    }
  },
  methods: {
    imgLoad() { },
    imgError() {
      this.path = this.def
    },
  }
}
</script>
<style scoped>
.qimg {
  /* font-size: 0; */
  text-align: center;
  width: 100%;
  height: 100%;
}

.img {
  max-width: 100%;
  max-height: 100%;
}
</style>