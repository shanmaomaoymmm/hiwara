<script setup lang="ts">
import { RouterView } from 'vue-router'
</script>

<template>
  <div class="app">
    <div class="stateBar"></div>
    <RouterView class="main" />
    <div class="navigationBar"></div>
  </div>
</template>

<style scoped>
.stateBar {
  background: #00796B;

  @media (orientation: portrait) {
    height: env(safe-area-inset-top);
  }

  @media (orientation: landscape) {
    height: calc(env(safe-area-inset-left) + env(safe-area-inset-right));
  }
}

.navigation {
  height: env(safe-area-inset-bottom);
}
</style>