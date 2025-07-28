<script lang="ts" setup>

</script>
<template>
  <div class="top">
    <div class="avatar"></div>
    <div class="search">
      <div></div>
    </div>
    <div class="logo">Hiwara</div>
  </div>
</template>
<style lang="scss" scoped>
.top {
  background-color: #00796B;
  height: 4rem;
  display: flex;
}
.avatar { 
  width: 2rem;
}
.search {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  >div {
    background-color: #fff;
    height: 2rem;
    width: 100%;
    border-radius: 2rem;
  }
}

.logo {
  padding: 0 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}
</style>