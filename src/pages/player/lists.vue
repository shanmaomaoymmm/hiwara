<template>
  <view class="lists">
    <view dir="auto">
      <text>{{ $t('player.lists[0]') }}</text>
    </view>
    <lists :scol="scol" :data="authorOpus" type="video"></lists>
    <view dir="auto">
      <text>{{ $t('player.lists[1]') }}</text>
    </view>
    <lists :scol="scol" :data="relatedOpus" type="video"></lists>
  </view>
</template>
<script>
import lists from '@/pages/lists/index.vue'
export default {
  components: {
    lists
  },
  props: ['authorOpus', 'relatedOpus', 'scol']
}
</script>
<style>
.lists {
  padding: 0.5rem;
}
</style>