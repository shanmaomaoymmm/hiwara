<script setup lang="ts">
import { RouterView } from 'vue-router'
</script>

<template>
  <div class="stateBar"></div>
  <RouterView />
</template>

<style scoped>
.stateBar {
  background: #00796B;

  @media (orientation: portrait) {
    height: calc(env(safe-area-inset-top) + env(safe-area-inset-bottom));
  }

  @media (orientation: landscape) {
    height: calc(env(safe-area-inset-left) + env(safe-area-inset-right));
  }
}
</style>