# 实况照片与紧凑媒体（3119）

聊天图片、GIF和收藏表情最长边180个逻辑像素，视频200×113；点击查看详细内容。附件面板的快传和文件按钮保持右侧对齐。

## 使用

- 安卓动态照片从相册或文件选择器导入原文件；发送前仍需点击发送。
- iPhone导出的同名JPEG/HEIC与MOV一起在文件选择器中选择，确认“合并实况”后暂存为一张动态照片；可选择“分别添加”保持两个附件。只有一张静态照片时不会猜测或补造视频。
- 新发送的实况照片使用普通图片消息并带motion_photo标志，聊天缩略图显示LIVE。其他客户端仍可显示封面，但其动态预览取决于各自能力。
- 点击聊天图片进入详情后识别原文件中的有效视频，默认静音播放一次；用“实况”按钮重播或暂停，声音按钮开关声音。普通静态图片保持原预览操作。
- 旧消息没有标志时，在打开详情时检查原文件；不会为了聊天列表逐张下载原图扫描。原始动态部分已被压缩/转码删除时无法恢复。

## 格式与边界

单张实况文件最多64MiB。支持标准Container/Item XMP、旧MicroVideoOffset、JPEG实际编码结束后的有效附加视频、HEIC/AVIF末尾mpvd盒。视频必须通过完整ISO-BMFF边界校验，并包含ftyp、moov、mdat；只出现LIVE字样或残留XMP不会被当作可播放视频。

iPhone配套资源在客户端组合为兼容的JPEG Motion Photo，保留MOV原始视频字节；HEIC静态封面经现有图片转换路径转为兼容图像。HEIC解码、视频HEVC/AV1等实际播放依赖手机的系统解码能力，不能保证所有设备或所有厂商私有封装。此实现不生成Apple照片库原生实况配对标识，也不把下载的JPEG直接写回iPhone相册为原生Live Photo。

iOS相册的isLivePhoto及配套视频读取路径已接入Dart端，但未提供签名iOS安装包，也未在真实iPhone或iCloud相册上验证。

预览视频提取到单次预览独有的临时目录，关闭或切换账号后清理；后台暂停播放。普通消息使用账号隔离的已有图片缓存；阅后即焚消息只用临时下载，并在关闭后删除。图片缩略图、放大、下载、普通视频和GIF原有路径保留。

## 验证（未完成真机测试）

全量Flutter回归713项通过，5项环境用例跳过；新增解析、资源保留、HEIC/MOV组合、上传标志、用户确认合并/分开、预览静音/后台暂停/临时清理测试。测试图与H.264 MOV为本机生成的合成素材，不代表真实Apple相册配对标识。

自动预览测试使用播放器接口替身，部分HEIC转换测试模拟原生返回，尚未验证真实手机的HEIC/视频解码器。

3119 Android Release包以GitHub预发布形式提供，原签名、ARM64、非debug、ZIP完整性和16KiB对齐通过。真机安装、实际预览和HEIC/MOV导入等待手机重新连接，不能把自动测试视为真机全部兼容。

## 依据

- [Android Motion Photo格式](https://developer.android.com/media/platform/motion-photo-format)
- [Apple配套视频资源](https://developer.apple.com/documentation/photos/phassetresourcetype/pairedvideo)
- [Flutter平台图片解码](https://api.flutter.dev/flutter/dart-ui/instantiateImageCodec.html)
