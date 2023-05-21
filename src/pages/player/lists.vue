<template>
  <view>
    <view style="padding:0.5rem 1rem;">
      <text>该作者的其他作品</text>
    </view>
    <lists :scol="2" :data="authorOpus" type="video"></lists>
    <view style="padding:0.5rem 1rem;width: 100%;">
      <text>相关作品</text>
    </view>
    <lists :scol="2" :data="relatedOpus" type="video"></lists>
  </view>
</template>
<script>
import lists from '@/pages/lists/index.vue'
export default {
  components: {
    lists
  },
  props: ['authorOpus', 'relatedOpus']
}
</script>