# Hiwara

![GitHub](https://img.shields.io/github/license/shanmaomaoymmm/hiwara)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/shanmaomaoymmm/hiwara?include_prereleases)
![GitHub issues](https://img.shields.io/github/issues/shanmaomaoymmm/hiwara)
![GitHub repo size](https://img.shields.io/github/repo-size/shanmaomaoymmm/hiwara)
![GitHub Repo stars](https://img.shields.io/github/stars/shanmaomaoymmm/hiwara?style=social)

🕹️ Iwara for uniapp

[🀄中文](https://github.com/shanmaomaoymmm/hiwara/blob/main/README-zh.md)

<img src="./edit/img/logo.png" style="width:192px;height:192px" />

Compatible with new version of iwara client, supports Android, iOS and web side

Beta version released, Android only [📦Beta](https://github.com/shanmaomaoymmm/hiwara/releases/latest)

Some features are under development, The [📦Development Version](https://github.com/shanmaomaoymmm/hiwara/releases) is for development testing only and does not represent the final product.

If you want to play with it, then HBuilderX compile it!

Friendly reminder, you need a ladder

## 🛠️ Environment build

```
npm install
```

## 💻Run for H5

```
npm run dev:h5
```

## 📱Run for Android

1. Android phone device information point 5 under the version number to open developer mode, open via USB debugging (Xiaomi phones need to insert SIM card while open via USB installation), connect the data cable to the computer;  
2. Use HBuilderX to open this project
3. Open `src/manifest.json`, in the basic configuration->uni-app application ID (AppID) click on the right to reacquire, this operation may require registration of a dcloud account;  
4. Top bar menu Run->Run to phone or emulator->Run to Android App dock;  
5. Check all debugging through this computer on the phone, pop-up permissions all allowed.

## 📟 Other device running method refer to uniapp official documentation

<https://uniapp.dcloud.net.cn/quickstart-cli.html>

## 🗓️ Development progress

### Implemented features

* ✅Login
* ✅Video play
* ✅Image view
* ✅Search
* ✅Follow, subscribe, favorite, comment
* ✅Share and download external links
* ⬜Playlist
* ✅History (local)
* ✅Followers (local)
* ✅Settings
* ✅Adaptation for pad side
* ✅Offline caching and downloading
* ⬜DLAN
* ⬜Forum
* ✅Multi-language support

### Features not considered for support

* ⛔ WeChat mini program (FBI! OPEN THE DOOR!)
* ⛔ Download breakpoints (Please use BitComet)
* ⛔ Direct connection to iwara (What age is it still using traditional network?)
* ⛔ Contribution function (I WALLETS IS NULL!)

## ⚠️ Known issues

1. Uniapp's support for dark mode is not very perfect, dark mode will not take effect when using HBuilderX real debugging and offline packaging on the Android side, only using cloud packaging can make dark mode take effect;;  
2. User avatar can't be displayed normally because iwara website has 403 restrictions on getting user avatar for security, we are trying other methods to get user avatar;  
3. Not adapted to iOS and folding screen devices (I DON'T HAVE MONEY).

## 📒 Other

Plan to support multilingual, invite translation big brother to help develop (if there is no will have to rely on machine turning power)
shanmaomaoymmm@yandex.com

## 🥰FOLLOW ACE TAFFY NYA!🥰
## 🤗FOLLOW ACE TAFFY THINK YOU NYA!🤗

Translated with www.DeepL.com/Translator (free version)
