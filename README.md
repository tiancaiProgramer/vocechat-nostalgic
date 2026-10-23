# vocechat怀旧版

新版 VoceChat 功能底座，保留旧版 Android 页面风格。

当前版本：**0.3.33+3106**。Android 应用 ID：`com.privoce.vocechatclient.legacyui`。

## 安装

从 [Releases](https://github.com/tiancaiProgramer/vocechat-nostalgic/releases) 下载 ARM64 APK。支持 Android 7.0 及以上版本。

此应用可与原版共存；升级已安装的怀旧版会保留应用数据。设备会话已被服务器拒绝时，需要在应用内重新登录一次。

## 3106 更新

- 登录改用本安装独立、持久的设备标识，避免不同客户端共用 `flutter` 设备会话。
- 更新或切换会话时关闭旧实时连接、重试任务及等待中的连接，避免遗留连接抢占新会话。
- 修复本人显示离线：服务端状态快照不含当前用户，本人状态改为跟随实时连接；其他用户仍按服务端快照和上线、下线事件更新。

已在连接手机的真实账号环境验证联系人下线、上线及本人状态显示。114 项相关 Flutter 测试通过，另有 2 项需要隔离测试账号配置的联测默认跳过。

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
