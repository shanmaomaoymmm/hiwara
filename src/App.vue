<script>
export default {
  onLaunch: function () {
    console.log("App Launch");
    //  #ifdef APP-PLUS
    uni.getSystemInfo({
      success: (res) => {
        if (res.deviceType == 'phone') {
          plus.screen.lockOrientation("portrait-primary")
        } else if (res.deviceType == 'unknown') {
          if (Math.min(res.screenHeight, res.screenWidth) < 768) {
            plus.screen.lockOrientation("portrait-primary")
          }
        }
      }
    })
    // #endif
  },
  onShow: function () {
    console.log("App Show");
  },
  onHide: function () {
    console.log("App Hide");
  }
};
</script>

<style>
/*每个页面公共css */

page {
  color: #333;
  height: 100%;
  font-size: 1rem;
  background-color: #f5f5f5;
}

* {
  transition: color 100ms ease;
  transition: background 100ms ease;
}

@media (prefers-color-scheme: dark) {
  page {
    color: #ddd;
    background-color: #101010;
  }
}
</style>

<style src="@fortawesome/fontawesome-free/css/all.min.css"></style>
