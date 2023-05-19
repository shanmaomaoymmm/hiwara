<template>
  <view style="padding-bottom: 1rem;">
    <view class="button" v-for="item, i in list">
      <view class="button-title">
        {{ item.name }}
      </view>
      <view class="button-opt" style="padding: 1.2rem 1.5rem;">
        {{ item.code }}{{ ' ' }}
        <i class="fa-solid fa-angle-right"></i>
      </view>
    </view>
  </view>
</template>
<script>
export default ({
  components: {

  },
  data() {
    return {
      list: [
        {
          name: '中文(简体)',
          code: 'zh-hans'
        }, {
          name: '中文(繁體)',
          code: 'zh-hant'
        }, {
          name: 'English',
          code: 'en-us'
        }, {
          name: '日本語',
          code: 'ja-jp'
        }, {
          name: '한국어',
          code: 'ko-kr'
        }, {
          name: 'Français',
          code: 'fr-fr'
        }, {
          name: 'Español',
          code: 'es-es'
        }, {
          name: 'Русский',
          code: 'ru-ru'
        }, {
          name: 'བོད་སྐད།',
          code: 'tib'
        }, {
          name: 'ئۇيغۇر تىلى',
          code: 'uey'
        }, {
          name: 'Tiếng Việt',
          code: 'vi'
        },{
          name:'اللغة العربية',
          code:'ar-sa'
        }
      ]
    }
  },
  onNavigationBarButtonTap(e) {
    console.log(e)
    if (e.type == 'home') {
      this.$backhome()
    }
  },
  created() {
  },
  methods: {

  }
})
</script>
<style scoped>
.button {
  border-bottom: #aaaaaa 1px solid;
  color: #616161;
  display: flex;
}

.button-title {
  padding: 1.2rem 1.5rem;
  flex: 2;
}

.button-opt {
  flex: 1;
  text-align: right;
}

@media (prefers-color-scheme: dark) {
  .button {
    color: #BDBDBD;
    border-bottom: #666666 1px solid;

  }
}
</style>