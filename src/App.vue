<script>
export default {
  onLaunch: function () {
    console.log("App Launch");
    // 检测系统暗黑模式
    uni.onThemeChange(function (res) {
      console.log(res.theme);
    });
  },
  onShow: function () {
    console.log("App Show");
  },
  onHide: function () {
    console.log("App Hide");
  },
};
</script>

<style>
/*每个页面公共css */

page {
  color: #333;
  height: 100%;
  font-size: 1rem;
}

* {
  transition: color 100ms ease;
  transition: background 100ms ease;
}

@media (prefers-color-scheme: dark) {
  page {
    color: #ddd;
  }
}
</style>

<style src="@fortawesome/fontawesome-free/css/all.min.css"></style>
