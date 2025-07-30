<script lang="ts" setup>
import { ref, defineProps } from 'vue'
const props = defineProps<{
  type: 'video' | 'image'
}>()
</script>
<template>
  <v-lazy class="grid-item">
    <div>
      <v-img class="preview" cover src="/src/static/img/not-img.jpg">
        <template v-slot:placeholder>
          <img class="preview-loading" src="../../static/img/placeholder.png" alt="">
        </template>
        <template v-slot:error>
          <img class="preview-error" src="../../src/static/img/not-img.jpg" alt="">
        </template>
      </v-img>
      <div class="tips">
        <div class="r-18">
          R-18
        </div>
        <div class="msg">
          <span v-if="props.type == 'video'">
            <font-awesome-icon icon="fa-regular fa-circle-play" />
            1000
          </span>
          <span v-else-if="props.type == 'image'">
            <font-awesome-icon icon="fa-regular fa-eye" />
            1000
          </span>
          <font-awesome-icon icon="fa-regular fa-heart" />
          100
          <span v-if="props.type == 'video'" class="duration">
            00:12
          </span>
          <span v-else-if="props.type == 'image'" class="imgNum">
            12
          </span>
        </div>
      </div>
      <div class="title">
        <div>
          QAQ
        </div>
      </div>
      <div class="info">
        <div class="author">
          <div>
            <font-awesome-icon icon="fa-regular fa-user" />
            QAQ
          </div>
        </div>
        <div class="uptime">
          <div>
            <font-awesome-icon icon="fa-regular fa-clock" />
            2021-09-09
          </div>
        </div>
      </div>
    </div>
  </v-lazy>
</template>
<style lang="scss" scoped>
.grid-item {
  box-shadow: 0.1rem 0.1rem 0.3rem #E0E0E0;
  border-radius: 0.2rem;
  overflow: hidden;

  >div {
    background-color: #fff;
    position: relative;
    cursor: pointer;
    user-select: none;
  }
}

.preview {
  width: 100%;
  aspect-ratio: 16/10;
}

.preview-loading,
.preview-error {
  width: 100%;
  object-fit: cover;
}

.tips {
  position: absolute;
  width: 100%;
  aspect-ratio: 16/10;
  // background-color: aqua;
  top: 0;

  .r-18 {
    font-size: 0.8rem;
    background-color: #ff5622a0;
    position: absolute;
    padding: 0 0.2rem;
    top: 0.5rem;
    right: 0.5rem;
    color: #fff;
    text-shadow: 0.05rem 0.05rem 0.1rem #616161;
  }

  .msg {
    font-size: 0.8rem;
    padding: 0.5rem 0.2rem;
    width: calc(100% - 0.4rem);
    position: absolute;
    bottom: 0;
    color: #fff;
    // text-shadow: 0.05rem 0.05rem 0.1rem #616161;
    filter: drop-shadow(0.1rem 0.1rem 0.04rem #757575);

    .duration,
    .imgNum {
      float: right;
    }
  }
}

.title {
  position: relative;
  overflow: hidden;
  padding: 0.5rem;
  max-height: 3.25rem;

  /* 精确两行高度 */
  >div {
    font-size: 1rem;
    line-height: 1.25;
    /* 优化行距 */

    /* 双行省略核心方案 */
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    max-height: 2.5rem;
    /* 字体16px×行高1.25×2行=40px≈2.5rem */

    /* 跨浏览器兼容 */
    display: -moz-box;
    display: -ms-flexbox;
    -ms-line-clamp: 2;
    -ms-box-orient: vertical;

    /* 修复Firefox问题 */
    overflow: hidden;
    text-overflow: ellipsis;

    /* 处理文本超出 */
    &:after {
      content: '';
      position: absolute;
      right: 0.5rem;
      bottom: 0;
      width: 1rem;
      height: 1.25rem;
      background: linear-gradient(90deg, transparent, #fff 60%);
    }
  }
}

.info {
  display: flex;
  font-size: 0.8rem;
  padding: 0.3rem 0.5rem;

  .author,
  .uptime {
    flex: 1;
    display: flex;
    align-items: center;
    overflow: hidden;

    div {
      overflow: hidden;
      white-space: nowrap;
      text-overflow: ellipsis;
    }
  }

  .uptime>div {
    text-align: right;
  }
}
</style>