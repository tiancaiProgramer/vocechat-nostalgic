# vocechat怀旧版

新版 VoceChat 功能底座，保留旧版 Android 页面风格。

当前版本：**0.3.33+3112**。Android 应用 ID：`com.privoce.vocechatclient.legacyui`。

## 安装

从 [Releases](https://github.com/tiancaiProgramer/vocechat-nostalgic/releases) 下载 ARM64 APK。支持 Android 7.0 及以上版本。

此应用可与原版共存；升级已安装的怀旧版会保留应用数据。设备会话已被服务器拒绝时，需要在应用内重新登录一次。

## 3112 更新

- 移除本地恢复页进入首页时的额外缩放过渡，避免与 Android 系统打开动画叠加。
- 会话、联系人列表加载和后台刷新提示改为右下角灰色小字，完成后自动消失。
- 启动优先恢复本地账号，服务器身份和登录验证在后台完成，网络超时保留本地会话。

本次发布同时包含此前未发布到此仓库的 3107–3110 功能：个人收藏表情、多张图片/GIF 导入、分类记忆与同服务器收藏同步；相册混选图片和视频，拍照/录像后加入待发送区。

3112 已通过 27 项路由、冷启动和登录恢复测试、相关静态检查以及 ARM64 Release 构建。已在连接的 Android 手机上保留数据覆盖升级并录屏复测启动过渡；3111 已实机核对登录、原会话、历史文字与图片显示。收藏同步的真实账号跨设备业务链路尚未完成验证。

## 保留的功能

新版会话、表情与回应、RTC 通话、Avo、通话小窗、后台消息及来电通知；页面、设置和服务器账号面板沿用旧版风格。不启用应用内更新。

后台接收需要启用后台消息连接及系统通知权限。通话和 Avo 需要服务器相应功能支持。

## 构建

环境：Flutter 3.35.7 / Dart 3.9.2、JDK 17、Android SDK 36、NDK 27.0.12077973。

按 [BUILD-LEGACY-UI.txt](BUILD-LEGACY-UI.txt) 配置 Android SDK 和签名后：

```sh
flutter pub get
flutter build apk --release --flavor standalone --target-platform android-arm64 --no-pub
flutter test --no-pub
```

签名私钥、密码、本机路径、测试账号和手机诊断记录不在仓库中。覆盖已安装的交付包需要沿用原签名。

上游商店发布和桌面构建工作流保留在 `docs/upstream-workflows/`，未在本仓库自动运行。

## 源码来源

- 新版底座：[haorwen/vocechat-client-flutter](https://github.com/haorwen/vocechat-client-flutter)，基线 `fbfa4cf85a6306bfbe9c13b67cf0aab85f8cf5ab`。
- 旧版界面参考：[imdingji/vocechat-android](https://github.com/imdingji/vocechat-android)，参考提交 `ecb4562ca5f56329a0d3b1a75c56ea21e879c7ff`。
- [上游说明](docs/UPSTREAM_README.md) 及源码中的第三方许可文件均已保留。
