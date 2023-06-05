# Hiwara

![GitHub](https://img.shields.io/github/license/shanmaomaoymmm/hiwara)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/shanmaomaoymmm/hiwara?include_prereleases)
![GitHub issues](https://img.shields.io/github/issues/shanmaomaoymmm/hiwara)
![GitHub repo size](https://img.shields.io/github/repo-size/shanmaomaoymmm/hiwara)
![GitHub Repo stars](https://img.shields.io/github/stars/shanmaomaoymmm/hiwara?style=social)

🕹️基于uniapp的iwara应用

<img src="./edit/img/logo.png" style="width:192px;height:192px" />

兼容新版iwara客户端，支持Android，iOS和Web端，已适配平板电脑

测试版本已发布，仅限Android平台 [📦测试版](https://github.com/shanmaomaoymmm/hiwara/releases/latest)

部分功能正在开发中，[📦开发版](https://github.com/shanmaomaoymmm/hiwara/releases)仅供开发测试使用，不代表最终成品效果

如果想拿来玩玩的话下HBuilderX编译就行

友情提示，需要梯子

## 🛠️环境搭建

```
npm install
```

## 💻H5端运行

```
npm run dev:h5
```

## 📱Android端运行

1.Android手机设备信息点5下版本号打开开发者模式，打开通过USB调试（小米手机需要插SIM卡同时打开通过USB安装），连接数据线至电脑；  
2.使用HBuilderX打开本项目
3.打开`src/manifest.json`，在基础配置->uni-app应用标识(AppID)点击右侧重新获取，此操作可能需要注册一个dcloud账号；  
4.顶栏菜单运行->运行到手机或模拟器->运行到Android App基座；  
5.手机上勾选一律通过此计算机调试，弹出的权限全部允许。

## 📟其他平台运行方法参考uniapp官方文档

<https://uniapp.dcloud.net.cn/quickstart-cli.html>

## 🗓️开发进度

### 已实现功能

* ✅登录
* ✅视频播放
* ✅图片查看
* ✅搜索
* ✅关注、订阅、收藏、评论
* ✅分享及下载外链
* ⬜播放列表
* ✅历史记录(本地)
* ✅关注的人(本地)
* ✅设置
* ✅pad端适配
* ✅离线缓存及下载
* ⬜论坛
* ✅多语言支持

### 计划却无法实现的功能

* 🛑DLAN投屏

### 不考虑支持的功能

* ⛔微信小程序版本（你号没了）
* ⛔下载断点续传（这是第三方下载工具的事情）
* ⛔直连iwara（都什么年代了还在用传统网络？）
* ⛔投稿功能（请用网站版，给大佬递杯子.jpg）

## ⚠️已知问题

1.uniapp对于暗黑模式的支持不是很完善，在Android端使用HBuilderX真机调试及离线打包时暗黑模式不会生效，只有使用云打包才能使暗黑模式生效；  
2.用户头像无法正常显示是iwara网站为了安全对获取用户头像进行了403限制，正在尝试其他方法获取用户头像；   
3.未对iOS及折叠屏设备进行适配（问就是没钱）。

## 🌏语言支持

 * 英语(English)
 * 简体中文
 * 繁體中文
 * 日语(日本語)🤖
 * 韩语(한국어)🤖
 * 维吾尔语(ئۇيغۇر تىلى)🤖
 * 藏语(བོད་སྐད།)🤖
 * 法语(Français)🤖
 * 德语(Deutsch)🤖
 * 西班牙语(Español)🤖
 * 意大利语(Italiano)🤖
 * 俄语(Русский)🤖
 * 阿拉伯语(اللغة العربية)🤖
 * 泰语(ภาษาไทย)🤖
 * 越南语(Tiếng Việt)🤖

注：标有🤖为机器翻译，存在翻译不准确的情况

## 📒其他

<!-- i站hosts直通

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
``` -->

计划支持多语种，诚邀翻译大佬协助开发（如果没有就只能靠机翻力）
shanmaomaoymmm@yandex.com

## 🥰关注永雏塔菲喵！🥰
## 🤗关注永雏塔菲谢谢喵！🤗
