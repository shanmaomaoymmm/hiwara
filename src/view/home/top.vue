<script lang="ts" setup>

</script>
<template>
  <div class="top">
    <div class="avatar">
      <img src="../../static/img/default-avatar.jpg" alt=""></img>
    </div>
    <div class="search">
      <div>
        <font-awesome-icon icon="fa-solid fa-magnifying-glass" />
      </div>
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
  width: 3.5rem;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;

  img {
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 50%;
  }
}

.search {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;

  >div {
    background-color: #fff;
    height: 2rem;
    width: calc(100% - 1rem);
    border-radius: 2rem;
    display: flex;
    align-items: center;
    justify-content: left;
    padding: 0 0.5rem;
    color: #424242;
  }
}

.logo {
  padding: 0 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-family: riwenlogo;
}
</style>