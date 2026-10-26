# Android 本地消息通知去重

## 范围

本功能仅修改 Flutter/Android 客户端，使用现有服务端接口。FCM 使用 FlutterFire 接收推送，设备登记通过现有接口更新，不新增服务端 API 或推送协议。

WebSocket 本地通知进入 `MessageNotificationRouter`，用 SQLite `(session, mid)` 唯一约束记录是否已处理；`session = serverId::recipientUid`。不使用消息内容或最大 mid 推测重复。

## 行为

- 通知前提交记录。清空通知栏、切换账号、关闭常驻、进程重启都不删除记录；并发或重连补收不会重复提醒同一条本地消息。
- 前台收到的消息及被通知偏好过滤的消息也记录为已处理，避免退到后台后补收重新提醒。通知权限阻止展示时不占用记录，允许后续本地投递重试。
- 通知设置提供互斥的 FCM/后台消息方式。后台模式上传 JSON null 移除 FCM 登记且不获取 Google 令牌；FCM 模式登记令牌并关闭常驻消息连接，WebSocket 不展示本地通知。即使通话仍保持前台服务，原生入口也会拒绝已排队的本地消息提醒。通知去重不会跳过消息落盘与聊天内容更新。
- 不接收当前账号以外的消息；通知 PendingIntent 使用包含完整账号和会话的 URI。私聊标题显示联系人名，群聊标题显示群名，正文包含发送者名。优先使用已加载的名称，其次读取本地缓存，不额外请求网络。
- 记录保留 8 天，拒绝创建时间超过 7 天或明显超前的消息通知。聊天历史仍正常同步。不以固定条数淘汰记录，避免大量消息把仍有效的记录挤掉。

## 限制

现有服务端 FCM payload 不包含与 WebSocket 一致的消息 ID，后台 notification 消息由 Firebase SDK 自动展示，不经过本地去重入口。因此本版仅允许选择一种通知方式，没有双通道兜底。服务端移除登记需要网络请求；失败时显示错误并重试。切换前已进入投递的 FCM 消息仍可能送达，不能将互斥模式描述为跨通道消息去重，也不按正文与时间猜测重复而误吞消息。

SQLite 提交与 Android NotificationManager 之间不能原子执行。如果进程在提交后、展示前崩溃，该条本地提醒可能缺失；重放仍会被去重，聊天内容可由同步恢复。

## 验证

- Flutter：`flutter test --no-pub test/core/notifications test/core/background`，覆盖本地去重 key、前后台路由、名称与缓存回退、账号切换及通知过滤。
- Android：`cd android && bash gradlew :app:testStandaloneDebugUnitTest --tests '*MessageNotificationTest'`，覆盖重复投递、并发争抢、数据库重开、清空通知、账号隔离、乱序 mid、前台/过滤消息及过期记录。
- 真机：断线重连与清空通知后补收不重复；私聊和群聊名称显示正确；通知点击进入正确会话；分别检查常驻开启/关闭及 FCM 可用/不可用时的行为。

原生 Robolectric 和 Android 构建需要完整的 Android SDK/Java。通知打开时的 Activity 复用、引擎所有权和可见错误恢复见 [白屏排查与恢复](blank-screen-recovery.md)。
