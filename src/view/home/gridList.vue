<script lang="ts" setup>
import gridItem from './gridItem.vue'
import { ref } from 'vue'
const items = ref<number[]>([])
const props = defineProps<{
  type: 'video' | 'image'
}>()
// 初始化测试数据
for (let i = 0; i < 10000; i++) {
  items.value.push(i)
}
</script>
<template>
  <v-infinite-scroll height="inherit" :items="items" color="#00796B">
    <div class="grid-list">
      <template v-for="(item, i) in items" :key="item">
        <gridItem :type="props.type"></gridItem>
      </template>
    </div>
  </v-infinite-scroll>
</template>
<style lang="scss" scoped>
.grid-list {
  background-color: #fafafa;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  ;
  grid-gap: 0.5rem;
  padding: 0.5rem 0.5rem 0 0.5rem;
}

:deep(.v-infinite-scroll__side) {
  padding: 0;

  .v-progress-circular {
    margin: 8px;
  }
}
</style>