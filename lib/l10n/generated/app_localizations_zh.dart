// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppL10nZh extends AppL10n {
  AppL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'VoceChat';

  @override
  String get appLoadingSlowTitle => '加载时间较长';

  @override
  String get appLoadingSlowBody => '仍在尝试加载。你可以继续等待，或点击重试。已保存的账号不会被删除。';

  @override
  String get appRecoveryTitle => '页面暂时无法显示';

  @override
  String get appRecoveryBody => '加载界面时发生错误，请点击重试。已保存的账号不会被删除。';

  @override
  String get actionCancel => '取消';

  @override
  String get actionOpen => '打开';

  @override
  String get actionChange => '更改';

  @override
  String get actionContact => '联系';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionSend => '发送';

  @override
  String get actionSearch => '搜索';

  @override
  String get actionMore => '更多';

  @override
  String get actionRetry => '重试';

  @override
  String get chatToolPin => '置顶';

  @override
  String get chatActionReact => '添加表情';

  @override
  String get chatActionReply => '回复';

  @override
  String get chatActionEdit => '编辑';

  @override
  String get chatActionDelete => '删除';

  @override
  String get chatEditMarker => '（已编辑）';

  @override
  String chatReplyingTo(String name) {
    return '正在回复 $name';
  }

  @override
  String get chatDeleteConfirmTitle => '删除消息？';

  @override
  String get chatDeleteConfirmBody => '此操作无法撤销。';

  @override
  String get chatEditCancel => '取消';

  @override
  String get chatEditSave => '保存';

  @override
  String get chatFileDetailsTitle => '文件详情';

  @override
  String get chatFileNameLabel => '文件名';

  @override
  String chatEditFailed(String error) {
    return '编辑失败：$error';
  }

  @override
  String chatDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String chatReplyFailed(String error) {
    return '回复失败：$error';
  }

  @override
  String get chatReplyDeleted => '被回复的消息已删除！';

  @override
  String get chatReplyVoiceMessage => '[语音消息]';

  @override
  String get chatToolSaved => '收藏';

  @override
  String get chatToolMembers => '成员';

  @override
  String get chatToolEmpty => '暂无内容';

  @override
  String get chatToolPinEmpty => '暂无置顶消息';

  @override
  String get chatToolSavedEmpty => '暂无收藏';

  @override
  String get chatToolMembersEmpty => '暂无成员';

  @override
  String get chatToolUnpin => '取消置顶';

  @override
  String get chatToolRemoveFav => '移除';

  @override
  String get chatToolPinFail => '置顶失败';

  @override
  String get chatToolUnpinFail => '取消置顶失败';

  @override
  String get chatToolSaveFail => '收藏失败';

  @override
  String get chatToolRemoveFavFail => '移除失败';

  @override
  String get chatToolSavedAdded => '已收藏';

  @override
  String get chatToolPinAdded => '已置顶';

  @override
  String get chatToolUnpinned => '已取消置顶';

  @override
  String get chatSearchHint => '搜索消息';

  @override
  String get chatSearchEmpty => '未找到匹配消息';

  @override
  String get navChats => '聊天';

  @override
  String get navContacts => '联系人';

  @override
  String get navSettings => '设置';

  @override
  String get navSaved => '收藏';

  @override
  String get comingSoon => '敬请期待';

  @override
  String get actionBack => '返回';

  @override
  String get actionClose => '关闭';

  @override
  String get memberRoleOwner => '群主';

  @override
  String get tooltipDownload => '下载';

  @override
  String get downloadSaved => '已保存';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get tooltipZoomIn => '放大';

  @override
  String get tooltipZoomOut => '缩小';

  @override
  String get tooltipFullscreen => '全屏';

  @override
  String get tooltipExitFullscreen => '退出全屏';

  @override
  String get tooltipShowPassword => '显示密码';

  @override
  String get tooltipHidePassword => '隐藏密码';

  @override
  String get reactionDeletedUser => '已注销用户';

  @override
  String reactionTooltipMany(String names, int count, String emoji) {
    return '$names 和其他 $count 人回应了 $emoji';
  }

  @override
  String reactionTooltipFew(String names, String emoji) {
    return '$names 回应了 $emoji';
  }

  @override
  String get expiredImageTitle => '图片不存在';

  @override
  String get expiredImageBody => '图片已过期或被删除';

  @override
  String get expiredVideoTitle => '视频不存在';

  @override
  String get expiredVideoBody => '视频已过期或被删除';

  @override
  String get expiredAudioTitle => '音频不存在';

  @override
  String get expiredAudioBody => '音频已过期或被删除';

  @override
  String get expiredFileTitle => '文件不存在';

  @override
  String get expiredFileBody => '文件已过期或被删除';

  @override
  String get mediaLoadFailedRetry => '加载失败，点击重试';

  @override
  String get mediaLikelyIncompatible => '该设备可能不支持此视频格式，试试下载后播放';

  @override
  String get featureUnavailable => '该功能暂未开放';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsGroupGeneral => '通用';

  @override
  String get settingsGroupAbout => '关于';

  @override
  String get settingsMyAccount => '我的账户';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsStorage => '存储与数据';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsLogoutConfirmTitle => '退出登录？';

  @override
  String get settingsLogoutConfirmContent => '再次访问该服务器需要重新登录。';

  @override
  String get settingsDeleteAccount => '注销账户';

  @override
  String get settingsDeleteAccountConfirmTitle => '注销该账户？';

  @override
  String get settingsDeleteAccountConfirmContent => '这会从当前服务器永久删除你的账户，且无法撤销。';

  @override
  String get settingsSwitchAccount => '切换账户';

  @override
  String get accountSwitcherTitle => '账户';

  @override
  String get accountSwitcherAddAccount => '添加账户';

  @override
  String get accountSwitcherLogoutAll => '退出登录';

  @override
  String get accountSwitcherRemoveConfirmTitle => '移除该账户？';

  @override
  String get accountSwitcherRemoveConfirmBody => '将删除该账户在本设备上保存的登录信息和缓存消息。';

  @override
  String get accountSwitcherRemove => '移除';

  @override
  String get accountSwitcherSignedOut => '已退出登录';

  @override
  String get accountSwitcherSwitchFailed => '无法登录该账户，请重新登录。';

  @override
  String get accountEmail => '邮箱';

  @override
  String get accountUsername => '用户名';

  @override
  String get accountPassword => '密码';

  @override
  String get accountPasswordMasked => '*********';

  @override
  String get notificationsPush => '消息通知';

  @override
  String get notificationsPushSubtitle => '接收新消息和提及的通知。';

  @override
  String get notificationsSound => '提示音';

  @override
  String get notificationsSoundSubtitle => '新消息到达时播放提示音。';

  @override
  String get notificationsMentionsOnly => '仅提及';

  @override
  String get notificationsMentionsOnlySubtitle => '仅对 @我 的消息进行通知。';

  @override
  String get appearanceTheme => '主题';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceSystem => '跟随系统';

  @override
  String get appearanceDark => '深色';

  @override
  String get appearanceLanguage => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageJapanese => '日本語';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get storageUsage => '存储用量';

  @override
  String get storageAutoDownload => '自动下载媒体';

  @override
  String get storageWifiOnly => '仅 Wi-Fi';

  @override
  String get storageClearCache => '清除缓存';

  @override
  String get storageClearCacheConfirmTitle => '清除缓存？';

  @override
  String get storageClearCacheConfirmBody => '将删除本地缓存的消息和图片，需要时会重新下载。';

  @override
  String get storageClearCacheConfirm => '清除';

  @override
  String get storageCacheCleared => '缓存已清除';

  @override
  String get aboutAppVersion => '应用版本';

  @override
  String get aboutServerVersion => '服务端版本';

  @override
  String get aboutWebsite => '官网';

  @override
  String get aboutReportBug => '反馈问题';

  @override
  String get aboutReportBugSubtitle => '帮助我们改进 VoceChat。';

  @override
  String get loginWelcomeBack => '欢迎回来';

  @override
  String get loginEmail => '邮箱';

  @override
  String get loginEmailRequired => '请输入邮箱';

  @override
  String get loginEmailInvalid => '请输入有效的邮箱地址';

  @override
  String get loginPassword => '密码';

  @override
  String get loginPasswordRequired => '请输入密码';

  @override
  String get loginPasswordTooShort => '密码至少需要 6 个字符';

  @override
  String get loginForgotPassword => '忘记密码？';

  @override
  String get loginRememberMe => '记住密码';

  @override
  String get loginSignIn => '登录';

  @override
  String get loginMagicLink => '使用魔法链接';

  @override
  String get loginPasskey => '使用通行密钥登录';

  @override
  String get loginSwitchServer => '切换服务器';

  @override
  String get loginNoAccount => '还没有账户？ ';

  @override
  String get loginSignUp => '注册';

  @override
  String get loginErrorInvalidCredentials => '邮箱或密码不正确';

  @override
  String get loginErrorAccountFrozen => '该账户已被冻结，请联系管理员。';

  @override
  String get loginErrorNotInvited => '未找到关联账户，请联系管理员获取邀请链接。';

  @override
  String get loginErrorMethodNotSupported => '服务器不支持此登录方式。';

  @override
  String get loginErrorCannotReachServer => '无法连接到服务器，请检查网络或服务器地址。';

  @override
  String get registerTitle => '创建账户';

  @override
  String get registerHeader => '加入对话';

  @override
  String get registerSubtitle => '填写你的信息以开始使用。';

  @override
  String get registerName => '昵称';

  @override
  String get registerNameRequired => '请输入昵称';

  @override
  String get registerNameTooShort => '昵称至少需要 2 个字符';

  @override
  String get registerEmailRequired => '请输入邮箱';

  @override
  String get registerEmailInvalid => '请输入有效的邮箱';

  @override
  String get registerPasswordRequired => '请输入密码';

  @override
  String get registerPasswordTooShort => '密码至少需要 6 个字符';

  @override
  String get registerConfirmPassword => '确认密码';

  @override
  String get registerConfirmRequired => '请确认你的密码';

  @override
  String get registerConfirmMismatch => '两次输入的密码不一致';

  @override
  String get registerCreate => '创建账户';

  @override
  String get registerMagicLink => '改为发送邀请链接';

  @override
  String get registerEmailFirst => '请先输入你的邮箱';

  @override
  String get registerInvitationSent => '邀请链接已发送';

  @override
  String get registerHaveAccount => '已有账户？ ';

  @override
  String get registerInviteRequiresEmailConfirmation =>
      '该服务器要求邀请注册时进行邮箱确认，目前暂不支持此流程，请联系管理员协助。';

  @override
  String get serverPickerTitle => '选择服务器';

  @override
  String get serverPickerEmptyTitle => '连接到 VoceChat 服务器';

  @override
  String get serverPickerEmptySubtitle => '添加一台服务器，开始和你的团队聊天。';

  @override
  String get serverPickerAddFirst => '添加第一台服务器';

  @override
  String get serverPickerAdd => '添加服务器';

  @override
  String get serverPickerContinue => '下一步';

  @override
  String get serverPickerUseInviteLink => '使用邀请链接';

  @override
  String get serverAddTitle => '添加服务器';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get serverUrlHint => 'https://chat.example.com';

  @override
  String get serverUrlRequired => '请输入服务器地址';

  @override
  String get serverUrlMustHttps => '地址必须以 http:// 或 https:// 开头';

  @override
  String get serverTesting => '测试中…';

  @override
  String get serverTestConnection => '测试连接';

  @override
  String get serverTestSuccess => '连接成功';

  @override
  String get serverTestFailed => '无法连接到服务器';

  @override
  String get serverSave => '保存并继续';

  @override
  String get inviteLinkSheetTitle => '使用邀请链接加入';

  @override
  String get inviteLinkHint => '粘贴你的邀请链接';

  @override
  String get inviteLinkRequired => '请粘贴邀请链接';

  @override
  String get inviteLinkPasteFromClipboard => '从剪贴板粘贴';

  @override
  String get inviteLinkInvalid => '这看起来不是有效的邀请链接';

  @override
  String get inviteLinkExpired => '该邀请链接已过期或已被使用';

  @override
  String get inviteLinkCheckFailed => '无法验证邀请链接，请检查网络后重试';

  @override
  String get inviteLinkContinue => '继续';

  @override
  String get chatListSearch => '搜索...';

  @override
  String get chatListNewChat => '新建聊天';

  @override
  String get chatListLoading => '正在加载会话…';

  @override
  String get chatListUpdating => '更新中…';

  @override
  String get chatListEmpty => '暂无会话';

  @override
  String chatListNoResults(String query) {
    return '没有找到与“$query”相关的结果';
  }

  @override
  String get chatListSelectTitle => '选择一个会话';

  @override
  String get chatListSelectSubtitle => '从左侧面板选择一个会话开始聊天';

  @override
  String get chatListPin => '置顶聊天';

  @override
  String get chatListUnpin => '取消置顶';

  @override
  String chatListPinFailed(String error) {
    return '置顶失败：$error';
  }

  @override
  String chatListUnpinFailed(String error) {
    return '取消置顶失败：$error';
  }

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get contactsSearch => '搜索...';

  @override
  String get contactsAdd => '添加联系人';

  @override
  String get contactsLoading => '正在加载联系人…';

  @override
  String get contactsEmpty => '没有联系人';

  @override
  String contactsSectionBot(int count) {
    return '机器人 - $count';
  }

  @override
  String contactsSectionContact(int count) {
    return '联系人 - $count';
  }

  @override
  String get contactsSelectTitle => '选择一位联系人';

  @override
  String get contactsSelectSubtitle => '从列表中选择以查看其个人资料';

  @override
  String get contactsMessage => '消息';

  @override
  String get contactsCall => '通话';

  @override
  String get chatLoadingMessages => '正在加载消息…';

  @override
  String get chatStatusOnline => '在线';

  @override
  String get chatStatusOffline => '离线';

  @override
  String get chatGroupIntro => '向社区成员介绍一下你自己吧！';

  @override
  String get chatEmpty => '暂无消息';

  @override
  String chatSendFailed(String error) {
    return '发送失败：$error';
  }

  @override
  String chatMessagePlaceholderChannel(String name) {
    return '发送到 #$name';
  }

  @override
  String chatMessagePlaceholderUser(String name) {
    return '发送给 $name';
  }

  @override
  String get chatPinned => '已置顶';

  @override
  String get chatUnsupported => '[不支持的消息]';

  @override
  String get chatOpenLinkFailed => '无法打开链接，请重试或复制链接到浏览器。';

  @override
  String get chatMarkdown => 'Markdown';

  @override
  String get chatAttach => '附件';

  @override
  String get chatVoiceMessage => '语音消息';

  @override
  String get chatVideoMessage => '视频消息';

  @override
  String get chatVoiceRecording => '正在录制语音消息';

  @override
  String get chatVoiceRecordingCancel => '取消';

  @override
  String get chatVoiceRecordingSend => '发送';

  @override
  String get chatRecordingPermissionDenied => '权限被拒绝，请在系统设置中开启麦克风/摄像头权限';

  @override
  String get chatPhotoPermissionDenied => '权限被拒绝，请在系统设置中开启相册访问权限';

  @override
  String get chatAttachOpenFiles => '文件';

  @override
  String get chatAttachCamera => '相机';

  @override
  String chatAttachSend(int count) {
    return '发送（$count）';
  }

  @override
  String chatDropOverlayTitle(String name) {
    return '发送到 $name';
  }

  @override
  String get chatDropOverlayHint => '拖放文件到此处以发送';

  @override
  String get chatMessageUnavailable => '该消息已不存在或暂时无法加载。';

  @override
  String get chatEmoji => '表情';

  @override
  String chatUserFallback(int uid) {
    return '用户 $uid';
  }

  @override
  String chatGroupFallback(int gid) {
    return '群组 $gid';
  }

  @override
  String get previewFile => '[文件]';

  @override
  String get previewVoice => '[语音]';

  @override
  String get previewArchive => '[压缩包]';

  @override
  String get previewImage => '[图片]';

  @override
  String get previewReaction => '[表情回应]';

  @override
  String errorPrefix(String message) {
    return '错误：$message';
  }

  @override
  String get errorRequestFailed => '请求失败';

  @override
  String get authKickedFromOtherDevice => '已退出登录：你的账号刚在另一台设备上登录。';

  @override
  String get authAccountDeleted => '你的账号已被删除。';

  @override
  String get authSessionEnded => '登录已失效，请重新登录。';

  @override
  String get chatListMarkRead => '标记为已读';

  @override
  String get chatListMute => '免打扰';

  @override
  String get chatListUnmute => '取消免打扰';

  @override
  String get chatListHide => '隐藏会话';

  @override
  String get chatListLeave => '退出频道';

  @override
  String get chatListMarkReadDone => '已标记为已读';

  @override
  String get chatListMuteDone => '已开启免打扰';

  @override
  String get chatListUnmuteDone => '已取消免打扰';

  @override
  String get chatListHideDone => '已隐藏';

  @override
  String get chatListLeaveDone => '已退出频道';

  @override
  String chatListLeaveFailed(String error) {
    return '退出失败：$error';
  }

  @override
  String chatListMuteFailed(String error) {
    return '操作失败：$error';
  }

  @override
  String get chatListMarkReadFailed => '标记已读失败';

  @override
  String get createChannelTitle => '新建频道';

  @override
  String get createChannelNameLabel => '频道名称';

  @override
  String get channelPublicLabel => '公开频道';

  @override
  String get createChannelPublicAdminOnly => '只有管理员可以创建公开频道';

  @override
  String get createChannelSubmit => '创建';

  @override
  String get createChannelNameRequired => '请输入频道名称';

  @override
  String get createChannelFailed => '创建频道失败';

  @override
  String get channelSettingsTitle => '频道设置';

  @override
  String get channelUpdated => '频道已更新';

  @override
  String get avatarUpdated => '头像已更新';

  @override
  String get channelVisibilityChanged => '可见性已更改';

  @override
  String get inviteLinkCopied => '链接已复制';

  @override
  String get channelOverview => '概览';

  @override
  String get channelNameLabel => '名称';

  @override
  String get channelDescriptionLabel => '描述';

  @override
  String get channelSaveChanges => '保存更改';

  @override
  String get channelAddMember => '添加成员';

  @override
  String get channelInviteLinkSection => '邀请链接';

  @override
  String get channelGenerateInviteLink => '生成邀请链接';

  @override
  String get channelMuteLabel => '静音频道';

  @override
  String get channelLeaveConfirmBody => '确定要退出该频道吗？';

  @override
  String get channelDeleteTitle => '删除频道';

  @override
  String get channelDeleteConfirmBody => '此操作将为所有成员永久删除该频道，且无法撤销。';

  @override
  String get actionLeave => '退出';

  @override
  String get accountEditNameTitle => '编辑姓名';

  @override
  String get accountNameLabel => '姓名';

  @override
  String get accountNameUpdated => '姓名已更新';

  @override
  String get accountChangePasswordTitle => '修改密码';

  @override
  String get accountCurrentPasswordLabel => '当前密码';

  @override
  String get accountNewPasswordLabel => '新密码';

  @override
  String get accountPasswordChanged => '密码已修改';

  @override
  String get chatActionCopy => '复制';

  @override
  String get chatActionForward => '转发';

  @override
  String get chatActionSelect => '选择';

  @override
  String get chatCopiedToClipboard => '已复制到剪贴板';

  @override
  String get chatForwardedMessagePreview => '[转发的消息]';

  @override
  String get chatAutoDeleteTitle => '自动删除消息';

  @override
  String chatExpiresTooltip(String duration) {
    return '发送后 $duration 自动删除';
  }

  @override
  String get chatAutoDeleteOff => '关闭';

  @override
  String get chatAutoDelete5Min => '5 分钟';

  @override
  String get chatAutoDelete10Min => '10 分钟';

  @override
  String get chatAutoDelete1Hour => '1 小时';

  @override
  String get chatAutoDelete1Day => '1 天';

  @override
  String get chatAutoDelete1Week => '1 周';

  @override
  String get chatAutoDeleteSaved => '已保存';

  @override
  String get chatAutoDeleteSaveFailed => '保存失败';

  @override
  String get forwardSheetTitle => '转发给...';

  @override
  String get forwardMessageSent => '消息已转发';

  @override
  String forwardFailed(String error) {
    return '转发失败：$error';
  }

  @override
  String get forwardNoConversations => '暂无会话';

  @override
  String forwardSelectedCount(int count) {
    return '已选择 $count 个';
  }

  @override
  String get archiveForwardedLabel => '转发的消息';

  @override
  String get archiveLoadFailed => '加载转发消息失败';

  @override
  String get archiveTapToView => '点击查看详情';

  @override
  String archiveViewAll(int count) {
    return '查看全部 $count 条消息';
  }

  @override
  String get voiceStartCall => '发起语音通话';

  @override
  String get voiceIncomingCall => '来电';

  @override
  String get voiceCallingOut => '正在呼叫...';

  @override
  String get voiceMute => '静音';

  @override
  String get voiceUnmute => '取消静音';

  @override
  String get voiceDeafen => '屏蔽声音';

  @override
  String get voiceUndeafen => '取消屏蔽';

  @override
  String get voiceCameraOn => '打开摄像头';

  @override
  String get voiceCameraOff => '关闭摄像头';

  @override
  String get voiceSwitchCamera => '切换摄像头';

  @override
  String get voiceSelectCamera => '选择摄像头';

  @override
  String get voiceNoCameras => '没有可用的摄像头';

  @override
  String voiceCameraFallback(int index) {
    return '摄像头 $index';
  }

  @override
  String get voiceShareScreen => '共享屏幕';

  @override
  String get voiceFullscreen => '全屏';

  @override
  String get voiceLeave => '结束通话';

  @override
  String get voiceConnected => '语音已连接';

  @override
  String get voiceReconnecting => '正在重新连接...';

  @override
  String get avoDescription =>
      '根据名字生成专属 Avo：相同名字会生成相同形象。还可以调整造型、颜色和活跃度，保存后在关闭摄像头时显示。';

  @override
  String get avoNameLabel => '名称';

  @override
  String get avoStyleLabel => '样式';

  @override
  String get avoStyleBlob => '团子';

  @override
  String get avoStyleRing => '圆环';

  @override
  String get avoStyleWave => '波浪';

  @override
  String avoEnergy(int percent) {
    return '活力 $percent%';
  }

  @override
  String get avoSave => '保存';

  @override
  String get avoSaved => 'Avo 已保存';

  @override
  String get avoServerUnsupported => '服务端不支持保存 Avo 形象。';

  @override
  String avoServerVersionUnsupported(String version) {
    return '当前服务端（版本 $version）不支持保存 Avo 形象。';
  }

  @override
  String avoSaveFailed(String error) {
    return '无法保存 Avo：$error';
  }

  @override
  String get avoPreviewHint => '将指针移到 Avo 上，轻抚它的身体，或点击它。';

  @override
  String get avoPreviewNameLabel => '名称（默认 Han）';

  @override
  String avoVoiceLevel(int percent) {
    return '音量 $percent%';
  }

  @override
  String get avoNextVariant => '换个造型';

  @override
  String appUpdateTitle(String version) {
    return '发现新版本：$version';
  }

  @override
  String get appUpdateRequired => '请安装此必要更新后继续使用 VoceChat。';

  @override
  String get appUpdateAvailable => 'VoceChat 有新版本可供更新。';

  @override
  String get appUpdateOpenFailed => '无法打开下载链接，请重试。';

  @override
  String get appUpdateLater => '稍后再说';

  @override
  String get appUpdateDownload => '下载更新';

  @override
  String get appUpdateSkipVersion => '跳过此版本';

  @override
  String appUpdateEmergencySkip(int remaining) {
    return '应急跳过 1 天（剩余 $remaining 次）';
  }

  @override
  String get appUpdateEmergencyHint => '应急情况下可跳过 3 次，每次 24 小时内不再提醒，重启应用后同样有效。';

  @override
  String get appUpdateSkipFailed => '无法保存更新偏好，暂时不能跳过，请重试或下载更新。';

  @override
  String appUpdateDownloading(int percent) {
    return '正在下载… $percent%';
  }

  @override
  String appUpdateDownloadingUnknown(String megabytes) {
    return '正在下载… $megabytes MB';
  }

  @override
  String get appUpdateCancelDownload => '取消下载';

  @override
  String get appUpdateInstall => '安装更新';

  @override
  String get appUpdateAllowInstall => '允许安装';

  @override
  String get appUpdateInstallPermission =>
      '请在 Android 设置中允许 VoceChat 安装应用，返回后继续安装。';

  @override
  String get appUpdateInvalidApk => '下载的文件不是本应用的有效更新，请检查 APK 直链及构建号后重新下载。';

  @override
  String get appUpdateInstallerOpened =>
      '请在 Android 系统安装界面确认安装。如果已取消，可点击“安装更新”重试。';

  @override
  String get appUpdateDownloadFailed => '下载失败，请检查网络和可用存储空间后重试。';

  @override
  String get appUpdateInstallFailed => '无法打开系统安装界面，请重试。';

  @override
  String get authSavedSessionMissing => '未找到本机保存的登录信息，请重新登录。';

  @override
  String get authSavedSessionRejected => '服务器已拒绝原来的登录凭据，请重新登录。';

  @override
  String get authServerChanged => '此地址的服务器身份已变更，请重新登录。';

  @override
  String get authRememberedReadFailed => '暂时无法读取已保存的密码，请重试或手动输入。';

  @override
  String get authRetrySavedPassword => '重新读取密码';

  @override
  String get authSaveFailed => '登录信息未能保存到本机，请重试。';

  @override
  String get backgroundTitle => '后台消息通知';

  @override
  String get backgroundDescription => '通过常驻后台连接接收消息，开启后自动关闭 FCM 推送。';

  @override
  String get backgroundActionFailed => '无法更新后台设置，请重试。';

  @override
  String get backgroundSetupRequired => '请先允许通知，并点击“关闭电池优化”完成设置，再启用常驻后台。';

  @override
  String get backgroundRunning => '后台服务正在运行';

  @override
  String get backgroundNotRunning => '已启用，但服务尚未运行，请返回应用重试。';

  @override
  String get backgroundDisabled => '后台服务已关闭';

  @override
  String get backgroundNotificationPermission => '允许消息通知与前台服务通知';

  @override
  String get backgroundGranted => '已允许';

  @override
  String get backgroundBattery => '关闭电池优化';

  @override
  String get backgroundBatteryDescription => '允许不受限制的电池使用，以便锁屏后保持消息连接。';

  @override
  String get backgroundManufacturer => '自启动与后台限制';

  @override
  String get backgroundManufacturerDescription =>
      '在手机应用或电池设置中允许后台活动、自启动；如有最近任务锁定功能，请锁定 VoceChat。不同品牌的设置入口可能不同。';

  @override
  String get backgroundLimitations =>
      '开启后耗电会增加；通话继续运行，后台空闲时减少处理任务。仅接收当前账号的消息。强制停止、重启手机或厂商清理可能中断服务，需要重新打开应用恢复。关闭此开关不会撤销系统通知与电池权限。';

  @override
  String get backgroundBatteryVisited =>
      '已点击设置，可开启常驻后台。部分手机无法准确检测，请在系统中确认已允许不受限制的电池使用。';

  @override
  String get serverConnectionTimeout => '连接超时，请检查服务器地址和网络后重试。';

  @override
  String get serverConnectionFailed => '无法连接，请检查网络、服务器地址和端口。';

  @override
  String get serverCertificateError => '服务器证书验证失败，请检查 HTTPS 证书。';

  @override
  String get serverInvalidResponse => '该地址未返回有效的 VoceChat 服务器信息，请检查服务器地址。';

  @override
  String serverHttpError(int status) {
    return '服务器返回 HTTP $status，请检查服务器地址。';
  }

  @override
  String get serverConnecting => '正在连接服务器…';

  @override
  String get serverSettingsFailed => '无法保存服务器设置，请重试。';

  @override
  String get serverPreparingTimeout => '准备登录超时，请重试。';

  @override
  String get serverUrlInvalid => '请输入完整的服务器地址，例如 https://chat.example.com。';

  @override
  String get serverRemoveTitle => '删除服务器';

  @override
  String get serverRemoveBody => '从本机列表移除该服务器，保留已保存的账号和聊天记录。';

  @override
  String get serverRemoveAction => '删除';

  @override
  String get serverRemoveFailed => '无法删除服务器，请重试。';

  @override
  String get settingsAppearanceLanguage => '外观和语言';

  @override
  String get settingsAccountAndStorage => '账号、存储与数据';

  @override
  String get accountSwitcherServersTitle => '服务器';

  @override
  String get accountSwitcherAdd => '添加';

  @override
  String get chatStatusSyncing => '状态同步中…';

  @override
  String get stickerFavorites => '收藏表情';

  @override
  String get stickerImport => '导入图片 / GIF';

  @override
  String get stickerManage => '管理';

  @override
  String get stickerDone => '完成';

  @override
  String get stickerAddFromChat => '添加到表情';

  @override
  String get stickerEmpty => '还没有收藏的表情';

  @override
  String get stickerLocalHint => '从手机导入，或长按聊天图片添加。接入表情服务后可跨手机同步。';

  @override
  String get stickerAdded => '已添加到表情';

  @override
  String get stickerAlreadySaved => '这张表情已经收藏过了';

  @override
  String stickerImportSummary(int added, int duplicates, int failed) {
    return '已添加 $added 张，重复 $duplicates 张，失败 $failed 张';
  }

  @override
  String get stickerTooLarge => '表情图片不能超过 10 MB';

  @override
  String get stickerUnsupported => '请选择有效的 PNG、JPG、GIF 或 WebP 图片';

  @override
  String get stickerMissing => '表情文件已丢失或损坏，请删除后重新导入';

  @override
  String get stickerOperationFailed => '表情操作失败，请重试';

  @override
  String get stickerDownloadFailed => '图片下载失败，请检查连接后重试';

  @override
  String get stickerRemoveTitle => '删除这张表情？';

  @override
  String get stickerRemoveBody => '从个人表情中删除；接入同步后也会从服务器删除，不影响聊天记录。';

  @override
  String get stickerSend => '发送表情';

  @override
  String get stickerSaving => '正在添加表情…';

  @override
  String get chatCameraGestureHint => '点按拍照 · 长按录像';

  @override
  String get chatCaptureFailed => '拍摄失败，请检查相机后重试';

  @override
  String get chatMediaReadFailed => '无法读取所选图片或视频，请重新选择';

  @override
  String get stickerSyncLocal => '本机收藏 · 未接入表情同步服务';

  @override
  String get stickerSyncing => '正在同步表情';

  @override
  String get stickerSynced => '已与服务器同步';

  @override
  String get stickerSyncPending => '已保存在本机 · 待同步，点云朵重试';

  @override
  String get stickerSyncUnavailable => '同步暂不可用 · 本机收藏仍可使用';

  @override
  String get searchPeopleTitle => '查找联系人';

  @override
  String get searchPeopleHint => '名字、账号邮箱或用户 ID';

  @override
  String get searchPeopleEmpty => '未找到匹配的联系人';

  @override
  String get searchPeopleDisabled => '服务器已关闭用户查询，仍显示匹配的已有联系人。';

  @override
  String get searchPeopleUnavailable => '暂时无法查询服务器，仍显示匹配的已有联系人。';

  @override
  String get searchMessagesTitle => '搜索聊天记录';

  @override
  String get searchMessagesPrompt => '输入关键词搜索消息内容';

  @override
  String get searchMessagesMore => '继续搜索更早的消息';

  @override
  String get searchMessagesUnavailable => '部分聊天记录暂未加载，已保留当前结果，可点击重试继续搜索。';

  @override
  String get searchMessagesComplete => '已搜索全部可用聊天记录';

  @override
  String get draftLabel => '草稿';

  @override
  String get draftSaveFailed => '草稿保存失败，请暂时保留此聊天并重试。';

  @override
  String get stickerSort => '排序';

  @override
  String get stickerSortTitle => '表情排序';

  @override
  String get stickerSortHint => '拖动右侧手柄调整顺序';

  @override
  String get shareTitle => '分享到怀旧版';

  @override
  String get shareChooseTarget => '选择文件传输，或选择会话并在输入框中确认后发送。';

  @override
  String get shareNoConversations => '暂无可选会话，请先建立聊天后再分享。';

  @override
  String get shareImportFailed => '部分分享文件无法读取，请重新分享。';

  @override
  String get shareTooLarge => '分享文件超出支持的范围。';

  @override
  String get shareTooMany => '一次最多分享16个文件，请减少选择后重试。';

  @override
  String get shareTransferHint => '带入文件传输待发送区，选择设备并确认后再发送。';

  @override
  String get shareReceiveFailed => '无法接收分享内容，请重新分享。';

  @override
  String get shareStaged => '分享内容已加入待发送区，请确认后发送。';

  @override
  String get searchFilters => '筛选';

  @override
  String get filterConversation => '会话';

  @override
  String get filterSender => '发送人';

  @override
  String get filterDate => '日期范围';

  @override
  String get filterKind => '消息类型';

  @override
  String get filterAll => '全部';

  @override
  String get filterText => '文字';

  @override
  String get filterImages => '图片';

  @override
  String get filterVideos => '视频';

  @override
  String get filterFiles => '文件';

  @override
  String get filterReset => '重置筛选';

  @override
  String get filterApply => '应用';

  @override
  String get filterNoDates => '不限日期';

  @override
  String get filterMediaHint => '可直接筛选媒体，或输入关键词查找正文和文件名。';

  @override
  String get fcmTitle => 'FCM 推送通知';

  @override
  String get fcmConnecting => '正在连接并登记设备…';

  @override
  String get fcmRegistered => '设备已登记，消息送达仍需验证。';

  @override
  String get fcmStandby => 'FCM 已关闭，当前使用后台消息通知。';

  @override
  String get fcmDisabled => '消息通知已关闭。';

  @override
  String get fcmUnavailable => '暂不可用，请检查 Google Play 服务和网络后重试。';

  @override
  String get fcmSignInRequired => '登录后登记推送设备。';

  @override
  String get fcmSettingsNotice =>
      'FCM 声音在系统“聊天消息”通知中设置，群通知遵循服务器免打扰。上方“声音”和“仅提及”开关用于后台常驻模式。';

  @override
  String get fcmDescription => '通过 Google Play 服务接收推送，开启后自动关闭后台消息通知。';

  @override
  String get fcmStatusTitle => 'FCM 连接状态';

  @override
  String get notificationMethodExclusive =>
      '两种通知方式只能选择一种，切换时会自动关闭另一种。停止提醒请关闭上方“消息通知”。';

  @override
  String get fcmDisconnecting => '正在关闭 FCM 设备登记…';

  @override
  String get fcmUnregisterFailed => 'FCM 登记尚未移除，请检查 VC 连接后重试。';

  @override
  String get localTransferTitle => '文件传输';

  @override
  String get localTransferQuick => '互传';

  @override
  String get localTransferDescription => '通过局域网直接传输。两台设备都需打开此页面，文件只在这两台设备之间传输。';

  @override
  String get localTransferMyDevice => '本机设备';

  @override
  String get localTransferCopyConnection => '复制连接信息';

  @override
  String get localTransferCopied => '已复制连接信息';

  @override
  String get localTransferAddDevice => '添加设备';

  @override
  String get localTransferConnectionHint => '粘贴另一台设备的连接信息';

  @override
  String get localTransferConnectionInvalid => '连接信息无效，请从另一台设备的文件传输页面复制。';

  @override
  String get localTransferNearby => '附近设备';

  @override
  String get localTransferNearbyHint =>
      '两台设备都打开“文件传输”，并连接同一 Wi-Fi。无法发现时，可复制对方的连接信息来添加设备。';

  @override
  String get localTransferNoDevices => '正在查找附近设备…';

  @override
  String get localTransferSelected => '待发送文件';

  @override
  String get localTransferChooseFiles => '选择文件';

  @override
  String get localTransferChooseHint => '最多选择16个文件，再点击附近设备旁的“发送”。';

  @override
  String get localTransferIncoming => '收到文件传输请求';

  @override
  String get localTransferCode => '确认码';

  @override
  String get localTransferCompareCode => '接收前请核对两台设备上的确认码是否一致。';

  @override
  String get localTransferAccept => '接收';

  @override
  String get localTransferReject => '拒绝';

  @override
  String get localTransferReady => '已就绪';

  @override
  String get localTransferPreparing => '正在检查文件…';

  @override
  String get localTransferWaiting => '等待对方确认…';

  @override
  String get localTransferSending => '正在发送…';

  @override
  String get localTransferReceiving => '正在接收…';

  @override
  String get localTransferVerifying => '正在校验文件…';

  @override
  String get localTransferCompleted => '传输完成';

  @override
  String get localTransferFailed => '传输失败';

  @override
  String get localTransferCancelled => '已取消传输';

  @override
  String get localTransferRejected => '对方拒绝或未确认接收。';

  @override
  String get localTransferBusy => '对方正在传输，请稍后重试。';

  @override
  String get localTransferIntegrityError => '文件校验失败，请重新发送。';

  @override
  String get localTransferFileError => '无法读取或保存文件，请检查存储空间，且单次最多选择16个文件。';

  @override
  String get localTransferTimeout => '连接超时，请确认两台设备仍保持连接。';

  @override
  String get localTransferNetworkError =>
      '无法连接，请检查 Wi-Fi、VPN 的局域网访问设置，以及路由器是否开启设备隔离。';

  @override
  String get localTransferReceived => '本机已接收';

  @override
  String get localTransferSave => '另存';

  @override
  String get localTransferReceivedHint => '文件已保存在下方位置，另存可移动到其他文件夹。';

  @override
  String get localTransferStorageSettings => '接收设置';

  @override
  String get localTransferStorageHint =>
      '图片与其他文件可分别选择文件夹，仅用于之后新接收的文件。现有文件保留原位置。';

  @override
  String get localTransferImageFolder => '图片目录';

  @override
  String get localTransferFileFolder => '文件目录';

  @override
  String get localTransferPrivateStorage => '应用内存储';

  @override
  String get localTransferChooseFolder => '选择文件夹';

  @override
  String get localTransferResetFolder => '恢复默认目录';

  @override
  String get localTransferStorageError => '无法使用该目录，请重新选择并授权。';

  @override
  String get localTransferStorageFallback => '自定义目录不可用，文件已保留在应用内，可另存。';

  @override
  String get localTransferNearbyShort => '连接同一 Wi-Fi，双方打开此页即可传输。';

  @override
  String get localTransferSavedAs => '已另存到所选位置';

  @override
  String get localTransferLeaveTitle => '停止当前传输？';

  @override
  String get localTransferLeaveBody => '离开此页面会取消当前传输。传输过程中可以将应用切到后台。';

  @override
  String get localTransferStopAndLeave => '停止并离开';

  @override
  String get livePhotoLabel => '实况';

  @override
  String get livePhotoRetry => '重试实况';

  @override
  String get livePhotoSound => '切换实况声音';

  @override
  String get livePhotoPairTitle => '导入实况照片';

  @override
  String get livePhotoPairBody => '检测到同名照片与 MOV 视频，是否将每组组合成一张实况照片？';

  @override
  String get livePhotoPairMerge => '合并实况';

  @override
  String get livePhotoPairSeparate => '分别添加';

  @override
  String get downloadInProgress => '正在下载';

  @override
  String get downloadSaving => '正在保存';

  @override
  String downloadSavedTo(String path) {
    return '已保存到 $path';
  }

  @override
  String get appearanceFontSize => '字体大小';

  @override
  String get appearanceFontSizeDescription => '滑动调节应用内的字体大小，设置会自动保存。';

  @override
  String get appearanceFontSizePreview => '选择舒适的字号，让阅读和聊天更轻松。';

  @override
  String appearanceFontSizeDefault(int percent) {
    return '$percent%（默认）';
  }

  @override
  String appearanceFontSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get appearanceFontSizeReset => '恢复默认';

  @override
  String get appearanceFontSizeSaveFailed => '字体大小保存失败，请重试。';

  @override
  String get aboutGithubProject => 'GitHub 项目';

  @override
  String get aboutCheckUpdates => '检查更新';

  @override
  String get aboutGithubUpdateSource => '怀旧版 · GitHub 正式发行版';

  @override
  String get aboutNoRelease => 'GitHub 暂无正式发行版本。';

  @override
  String aboutUpToDate(String version) {
    return '当前版本无需更新。GitHub 发行版：$version';
  }

  @override
  String get aboutUpdateCheckFailed => '检查更新失败，请检查网络后重试。';

  @override
  String get aboutViewRelease => '在 GitHub 查看';

  @override
  String get appearanceFontFamily => '字体';

  @override
  String get appearanceFontFamilySystem => '跟随系统字体';

  @override
  String get appearanceFontFamilyBundled => '应用默认字体';

  @override
  String get appearanceFontFamilySaveFailed => '字体保存失败，请重试。';

  @override
  String get appearanceSystemFontUnavailable => '暂时无法读取手机字体，已使用系统默认字体。';
}
