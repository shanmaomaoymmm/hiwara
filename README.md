# Hiwara

![GitHub](https://img.shields.io/github/license/shanmaomaoymmm/hiwara)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/shanmaomaoymmm/hiwara?include_prereleases)
![GitHub issues](https://img.shields.io/github/issues/shanmaomaoymmm/hiwara)
![GitHub repo size](https://img.shields.io/github/repo-size/shanmaomaoymmm/hiwara)
![GitHub Repo stars](https://img.shields.io/github/stars/shanmaomaoymmm/hiwara?style=social)

🕹️ Iwara for uniapp | 基於uniapp的iwara應用

<img src="./edit/img/logo.png" style="width:192px;height:192px" />

Compatible with new version of iwara client, supports Android, iOS and web side. Already adapted for Pad  
相容新版iwara用戶端，支援Android，iOS和Web端，已適配平板電腦

Beta version released, Android only [📦Beta](https://github.com/shanmaomaoymmm/hiwara/releases/latest)  
測試版本已發佈，僅限Android平臺 [📦測試版](https://github.com/shanmaomaoymmm/hiwara/releases/latest)

Some features are under development, The [📦Development Version](https://github.com/shanmaomaoymmm/hiwara/releases) is for development testing only and does not represent the final product  
部分功能正在開發中，[📦開發版](https://github.com/shanmaomaoymmm/hiwara/releases)僅供開發測試使用，不代表最終成品效果

If you want to play with it, then HBuilderX compile it!
如果想拿來玩玩的話下HBuilderX編譯就行

Friendly reminder, if you are in China, Iran, Saudi and Korea, you must use VPN.  
友情提示，在內地的朋友需要梯子

## 🛠️ Environment build | 環境搭建

```
npm install
```

## 💻Run for H5 | H5端運行

```
npm run dev:h5
```

## 📱Run for Android | Android端運行

1. Android phone device information point 5 under the version number to open developer mode, open via USB debugging (Xiaomi phones need to insert SIM card while open via USB installation), connect the data cable to the computer;  
   Android手機設備資訊點5下版本號打開開發者模式，打開通過USB調試（內地發售的小米手機需要插SIM卡同時打開通過USB安裝），連接充電線至電腦；
2. Use HBuilderX to open this project;  
   使用HBuilderX打開本專案；
3. Open `src/manifest.json`, in the basic configuration->uni-app application ID (AppID) click on the right to reacquire, this operation may require registration of a dcloud account;  
   打開`src/manifest.json`，在基礎配置->uni-app應用標識(AppID)點擊右側重新獲取，此操作可能需要註冊一個dcloud帳號；
4. Top bar menu Run->Run to phone or emulator->Run to Android App dock;  
   頂欄菜單運行->運行到手機或模擬器->運行到Android App基座；  
5. Check all debugging through this computer on the phone, pop-up permissions all allowed.  
   手機上勾選一律通過此電腦調試，彈出的許可權全部允許。

## 📟 Other Platform Operation Methods | 其他平臺運行方法

Please refer to the official documentation of uniapp  
請參考uniapp官方文檔

[English]<https://en.uniapp.dcloud.io/quickstart-cli.html>  
[中文]<https://uniapp.dcloud.net.cn/quickstart-cli.html>

## 🗓️ Development progress | 開發進度

### Implemented features | 已實現功能

* ✅Login | 登錄
* ✅Video play | 影片播放
* ✅Image view | 圖片查看
* ✅Search | 搜索
* ✅Follow, subscribe, favorite, comment | 關注、訂閱、收藏、評論
* ✅Share and download external links | 分享及下載外鏈
* ⬜Playlist | 播放清單
* ✅History (local) | 歷史記錄(本地)
* ✅Followers | 關注的人
* ✅Settings | 設置
* ✅Adaptation for pad side | pad端適配
* ✅Offline caching and downloading | 離線緩存及下載
* ⬜Forum | 論壇
* ✅Multi-language support | 多語言支援

### Planned but unachievable functions | 計畫卻無法實現的功能

* 🛑DLAN | DLAN投屏

### Features not considered for support | 不考慮支援的功能

* ⛔ WeChat mini program (FBI! OPEN THE DOOR!) | WeChat小程式版本（懂的都懂）
* ⛔ Download breakpoints (Please use BitComet) | 下載中斷點續傳（這是下載工具的事情）
* ⛔ Direct connection to iwara (ma ma sheng te) | 直連iwara（都什麼年代了還在用傳統網路？）
* ⛔ Contribution function (Please use source website) | 投稿功能（請用網站版，給大佬遞杯子.jpg）

### Deprecated functionality | 已廢棄功能

* 🚮Followers (local) | 關注的人(本地)

## ⚠️ Known issues

1. Uniapp's support for dark mode is not very perfect, dark mode will not take effect when using HBuilderX real debugging and offline packaging on the Android side, only using cloud packaging can make dark mode take effect;  
   uniapp對於暗黑模式的支援不是很完善，在Android端使用HBuilderX真機調試及離線打包時暗黑模式不會生效，只有使用雲打包才能使暗黑模式生效；
2. User avatar can't be displayed normally because iwara website has 403 restrictions on getting user avatar for security, we are trying other methods to get user avatar;  
   使用者頭像無法正常顯示是iwara網站為了安全對獲取用戶頭像進行了403限制，正在嘗試其他方法獲取用戶頭像；
3. Not adapted to iOS and folding screen devices (I DON'T HAVE MONEY).  
   未對iOS及折疊屏設備進行適配（問就是沒錢）。

## 🌏Multilingual support | 語言支援

 * English
 * Simplified Chinese(简体中文)
 * Traditional Chinese(繁體中文)
 * Japanese(日本語)🤖
 * Korean(한국어)🤖
 * Uighur(ئۇيغۇر تىلى)🤖
 * Tibetan(བོད་སྐད།)🤖
 * French(Français)🤖
 * German(Deutsch)🤖
 * Spanish(Español)🤖
 * Italian(Italiano)🤖
 * Russian(Русский)🤖
 * Arabic(اللغة العربية)🤖
 * Thai(ภาษาไทย)🤖
 * Vietnamese(Tiếng Việt)🤖

Note: marked with 🤖 for machine translation, there is inaccurate translation  
注：標有🤖為機器翻譯，存在翻譯不準確的情況

## 📒 Other | 其他

<!-- 
hosts

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

🤫
-->

Plan to support multilingual, invite translation big brother to help develop (if there is no will have to rely on machine turning power)  
計畫支持多語種，誠邀翻譯大佬協助開發（如果沒有就只能靠機翻力）    
shanmaomaoymmm@yandex.com

## 🥰FOLLOW ACE TAFFY NYA!🥰
## 🤗FOLLOW ACE TAFFY THINK YOU NYA!🤗

## 🥰關注永雛塔菲喵！🥰
## 🤗關注永雛塔菲謝謝喵！🤗