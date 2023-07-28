# Hiwara

![GitHub](https://img.shields.io/github/license/shanmaomaoymmm/hiwara)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/shanmaomaoymmm/hiwara?include_prereleases)
![GitHub issues](https://img.shields.io/github/issues/shanmaomaoymmm/hiwara)
![GitHub repo size](https://img.shields.io/github/repo-size/shanmaomaoymmm/hiwara)
![GitHub Repo stars](https://img.shields.io/github/stars/shanmaomaoymmm/hiwara?style=social)

🕹️基於uniapp的iwara應用

<img src="./edit/img/logo.png" style="width:192px;height:192px" />

相容新版iwara用戶端，支援Android，iOS和Web端，已適配平板電腦

測試版本已發佈，僅限Android平臺 [📦測試版](https://github.com/shanmaomaoymmm/hiwara/releases/latest)

部分功能正在開發中，[📦開發版](https://github.com/shanmaomaoymmm/hiwara/releases)僅供開發測試使用，不代表最終成品效果

如果想拿來玩玩的話下HBuilderX編譯就行

友情提示，在內地的朋友需要梯子

## 🛠️環境搭建

```
npm install
```

## 💻H5端運行

```
npm run dev:h5
```

## 📱Android端運行

1.Android手機設備資訊點5下版本號打開開發者模式，打開通過USB調試（內地發售的小米手機需要插SIM卡同時打開通過USB安裝），連接充電線至電腦；  
2.使用HBuilderX打開本專案
3.打開`src/manifest.json`，在基礎配置->uni-app應用標識(AppID)點擊右側重新獲取，此操作可能需要註冊一個dcloud帳號；  
4.頂欄菜單運行->運行到手機或模擬器->運行到Android App基座；  
5.手機上勾選一律通過此電腦調試，彈出的許可權全部允許。

## 📟其他平臺運行方法參考uniapp官方文檔

<https://uniapp.dcloud.net.cn/quickstart-cli.html>

## 🗓️開發進度

### 已實現功能

* ✅登錄
* ✅影片播放
* ✅圖片查看
* ✅搜索
* ✅關注、訂閱、收藏、評論
* ✅分享及下載外鏈
* ⬜播放清單
* ✅歷史記錄(本地)
* ✅關注的人(本地)
* ⬜關注的人
* ✅設置
* ✅pad端適配
* ✅離線緩存及下載
* ⬜論壇
* ✅多語言支援

### 計畫卻無法實現的功能

* 🛑DLAN投屏

### 不考慮支援的功能

* ⛔WeChat小程式版本（懂的都懂）
* ⛔下載中斷點續傳（這是下載工具的事情）
* ⛔直連iwara（都什麼年代了還在用傳統網路？）
* ⛔投稿功能（請用網站版，給大佬遞杯子.jpg）

## ⚠️已知問題

1.uniapp對於暗黑模式的支援不是很完善，在Android端使用HBuilderX真機調試及離線打包時暗黑模式不會生效，只有使用雲打包才能使暗黑模式生效；  
2.使用者頭像無法正常顯示是iwara網站為了安全對獲取用戶頭像進行了403限制，正在嘗試其他方法獲取用戶頭像；  
3.未對iOS及折疊屏設備進行適配（問就是沒錢）。

## 🌏語言支援

 * 英語(English)
 * 簡體中文
 * 繁體中文
 * 日語(日本語)🤖
 * 韓語(한국어)🤖
 * 維吾爾語(ئۇيغۇر تىلى)🤖
 * 藏語(བོད་སྐད།)🤖
 * 法語(Français)🤖
 * 德語(Deutsch)🤖
 * 西班牙語(Español)🤖
 * 義大利語(Italiano)🤖
 * 俄語(Русский)🤖
 * 阿拉伯語(اللغة العربية)🤖
 * 泰語(ภาษาไทย)🤖
 * 越南語(Tiếng Việt)🤖

注：標有🤖為機器翻譯，存在翻譯不準確的情況

## 📒其他

<!-- 
i站hosts直通

```
2606:4700:20::ac43:479a iwara.tv
2606:4700:20::ac43:479a i.iwara.tv
2606:4700:20::681a:d60 www.iwara.tv
66.206.15.50 ecchi.iwara.tv
2606:4700:20::ac43:479a api.iwara.tv
72.52.83.100 hime.iwara.tv
163.172.40.145 aku.iwara.tv
163.172.42.175 sukone.iwara.tv
163.172.81.17 xin.iwara.tv
163.172.40.123 uta.iwara.tv
72.52.83.99 mikoto.iwara.tv
163.172.44.153 miki.iwara.tv
66.165.240.194 files.iwara.tv
51.15.162.198 a.iwara.tv
85.187.128.60 service.iwara.tv
163.172.80.31 uni.iwara.tv
163.172.39.227 cul.iwara.tv
163.172.62.89 momo.iwara.tv
163.172.40.123 uta.iwara.tv
163.172.61.193 ruko.iwara.tv
163.172.56.87 yukari.iwara.tv
163.172.57.3 piko.iwara.tv
163.172.61.159 merli.iwara.tv
163.172.42.175 sukone.iwara.tv
163.172.40.81 tei.iwara.tv
2606:4700::6812:33f www.erolabs.com
2606:4700::6812:9ca www.ero-labs.com
``` 

噓！不要告訴別人哦🤫
-->

計畫支持多語種，誠邀翻譯大佬協助開發（如果沒有就只能靠機翻力）  
shanmaomaoymmm@yandex.com

## 🥰關注永雛塔菲喵！🥰
## 🤗關注永雛塔菲謝謝喵！🤗
