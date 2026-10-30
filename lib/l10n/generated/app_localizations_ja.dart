// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppL10nJa extends AppL10n {
  AppL10nJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'VoceChat';

  @override
  String get appLoadingSlowTitle => '読み込みに時間がかかっています';

  @override
  String get appLoadingSlowBody =>
      'アプリの読み込みを続けています。このまま待つか、再試行してください。保存済みのアカウントは削除されません。';

  @override
  String get appRecoveryTitle => 'このページを表示できません';

  @override
  String get appRecoveryBody =>
      '画面の読み込み中にエラーが発生しました。再試行してください。保存済みのアカウントは削除されません。';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionOpen => '開く';

  @override
  String get actionChange => '変更';

  @override
  String get actionContact => '連絡先';

  @override
  String get actionEdit => '編集';

  @override
  String get actionSend => '送信';

  @override
  String get actionSearch => '検索';

  @override
  String get actionMore => 'その他';

  @override
  String get actionRetry => '再試行';

  @override
  String get chatToolPin => 'ピン留め';

  @override
  String get chatActionReact => 'リアクションを追加';

  @override
  String get chatActionReply => '返信';

  @override
  String get chatActionEdit => '編集';

  @override
  String get chatActionDelete => '削除';

  @override
  String get chatEditMarker => '（編集済み）';

  @override
  String chatReplyingTo(String name) {
    return '$name に返信中';
  }

  @override
  String get chatDeleteConfirmTitle => 'メッセージを削除しますか？';

  @override
  String get chatDeleteConfirmBody => 'この操作は取り消せません。';

  @override
  String get chatEditCancel => 'キャンセル';

  @override
  String get chatEditSave => '保存';

  @override
  String get chatFileDetailsTitle => 'ファイル詳細';

  @override
  String get chatFileNameLabel => '名前';

  @override
  String chatEditFailed(String error) {
    return '編集に失敗しました：$error';
  }

  @override
  String chatDeleteFailed(String error) {
    return '削除に失敗しました：$error';
  }

  @override
  String chatReplyFailed(String error) {
    return '返信に失敗しました：$error';
  }

  @override
  String get chatReplyDeleted => 'このメッセージは削除されました。';

  @override
  String get chatReplyVoiceMessage => '[音声メッセージ]';

  @override
  String get chatToolSaved => 'お気に入り';

  @override
  String get chatToolMembers => 'メンバー';

  @override
  String get chatToolEmpty => 'まだ内容がありません。';

  @override
  String get chatToolPinEmpty => 'ピン留めされたメッセージはありません。';

  @override
  String get chatToolSavedEmpty => 'お気に入りのメッセージはありません。';

  @override
  String get chatToolMembersEmpty => 'メンバーがいません。';

  @override
  String get chatToolUnpin => 'ピン留め解除';

  @override
  String get chatToolRemoveFav => '削除';

  @override
  String get chatToolPinFail => 'ピン留めに失敗しました';

  @override
  String get chatToolUnpinFail => 'ピン留め解除に失敗しました';

  @override
  String get chatToolSaveFail => 'お気に入り登録に失敗しました';

  @override
  String get chatToolRemoveFavFail => '削除に失敗しました';

  @override
  String get chatToolSavedAdded => 'お気に入りに追加しました';

  @override
  String get chatToolPinAdded => 'ピン留めしました';

  @override
  String get chatToolUnpinned => 'ピン留めを解除しました';

  @override
  String get chatSearchHint => 'メッセージを検索';

  @override
  String get chatSearchEmpty => '一致するメッセージがありません。';

  @override
  String get navChats => 'チャット';

  @override
  String get navContacts => '連絡先';

  @override
  String get navSettings => '設定';

  @override
  String get navSaved => 'お気に入り';

  @override
  String get comingSoon => '近日公開';

  @override
  String get actionBack => '戻る';

  @override
  String get actionClose => '閉じる';

  @override
  String get memberRoleOwner => 'オーナー';

  @override
  String get tooltipDownload => 'ダウンロード';

  @override
  String get downloadSaved => 'Saved';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get tooltipZoomIn => '拡大';

  @override
  String get tooltipZoomOut => '縮小';

  @override
  String get tooltipFullscreen => '全画面表示';

  @override
  String get tooltipExitFullscreen => '全画面表示を終了';

  @override
  String get tooltipShowPassword => 'パスワードを表示';

  @override
  String get tooltipHidePassword => 'パスワードを隠す';

  @override
  String get reactionDeletedUser => '削除されたユーザー';

  @override
  String reactionTooltipMany(String names, int count, String emoji) {
    return '$names と他 $count 人が $emoji でリアクションしました';
  }

  @override
  String reactionTooltipFew(String names, String emoji) {
    return '$names が $emoji でリアクションしました';
  }

  @override
  String get expiredImageTitle => '画像が見つかりません';

  @override
  String get expiredImageBody => '画像の有効期限が切れたか削除されました';

  @override
  String get expiredVideoTitle => '動画が見つかりません';

  @override
  String get expiredVideoBody => '動画の有効期限が切れたか削除されました';

  @override
  String get expiredAudioTitle => '音声が見つかりません';

  @override
  String get expiredAudioBody => '音声の有効期限が切れたか削除されました';

  @override
  String get expiredFileTitle => 'ファイルが見つかりません';

  @override
  String get expiredFileBody => 'ファイルの有効期限が切れたか削除されました';

  @override
  String get mediaLoadFailedRetry => 'Failed to load — tap to retry';

  @override
  String get mediaLikelyIncompatible =>
      'This device can\'t play this video format. Try downloading it instead.';

  @override
  String get featureUnavailable => 'この機能はまだご利用いただけません';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsGroupGeneral => '一般';

  @override
  String get settingsGroupAbout => 'このアプリについて';

  @override
  String get settingsMyAccount => 'マイアカウント';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsAppearance => '外観';

  @override
  String get settingsStorage => 'ストレージとデータ';

  @override
  String get settingsAbout => 'このアプリについて';

  @override
  String get settingsLogout => 'ログアウト';

  @override
  String get settingsLogoutConfirmTitle => 'ログアウトしますか？';

  @override
  String get settingsLogoutConfirmContent =>
      'このサーバーに再度アクセスするには、もう一度ログインする必要があります。';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Delete this account?';

  @override
  String get settingsDeleteAccountConfirmContent =>
      'This permanently deletes your account from this server. This action cannot be undone.';

  @override
  String get settingsSwitchAccount => 'Switch account';

  @override
  String get accountSwitcherTitle => 'Accounts';

  @override
  String get accountSwitcherAddAccount => 'Add account';

  @override
  String get accountSwitcherLogoutAll => 'Log out';

  @override
  String get accountSwitcherRemoveConfirmTitle => 'Remove this account?';

  @override
  String get accountSwitcherRemoveConfirmBody =>
      'This removes the saved sign-in and cached messages for this account on this device.';

  @override
  String get accountSwitcherRemove => 'Remove';

  @override
  String get accountSwitcherSignedOut => 'Signed out';

  @override
  String get accountSwitcherSwitchFailed =>
      'Couldn\'t sign in to that account — please log in again.';

  @override
  String get accountEmail => 'メールアドレス';

  @override
  String get accountUsername => 'ユーザー名';

  @override
  String get accountPassword => 'パスワード';

  @override
  String get accountPasswordMasked => '*********';

  @override
  String get notificationsPush => 'プッシュ通知';

  @override
  String get notificationsPushSubtitle => '新しいメッセージやメンションの通知を受け取ります。';

  @override
  String get notificationsSound => '通知音';

  @override
  String get notificationsSoundSubtitle => 'メッセージ受信時に着信音を鳴らします。';

  @override
  String get notificationsMentionsOnly => 'メンションのみ';

  @override
  String get notificationsMentionsOnlySubtitle => '@メンションのみ通知します。';

  @override
  String get appearanceTheme => 'テーマ';

  @override
  String get appearanceLight => 'ライト';

  @override
  String get appearanceSystem => 'システムに従う';

  @override
  String get appearanceDark => 'ダーク';

  @override
  String get appearanceLanguage => '言語';

  @override
  String get languageSystem => 'システムに従う';

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
  String get storageUsage => 'ストレージ使用量';

  @override
  String get storageAutoDownload => 'メディアを自動ダウンロード';

  @override
  String get storageWifiOnly => 'Wi-Fi のみ';

  @override
  String get storageClearCache => 'キャッシュを削除';

  @override
  String get storageClearCacheConfirmTitle => 'キャッシュを削除しますか？';

  @override
  String get storageClearCacheConfirmBody =>
      'ローカルに保存されたメッセージと画像のキャッシュが削除されます。必要に応じて再ダウンロードされます。';

  @override
  String get storageClearCacheConfirm => '削除';

  @override
  String get storageCacheCleared => 'キャッシュを削除しました';

  @override
  String get aboutAppVersion => 'アプリのバージョン';

  @override
  String get aboutServerVersion => 'サーバーのバージョン';

  @override
  String get aboutWebsite => 'ウェブサイト';

  @override
  String get aboutReportBug => '不具合を報告';

  @override
  String get aboutReportBugSubtitle => 'VoceChat の改善にご協力ください。';

  @override
  String get loginWelcomeBack => 'ようこそ';

  @override
  String get loginEmail => 'メールアドレス';

  @override
  String get loginEmailRequired => 'メールアドレスを入力してください';

  @override
  String get loginEmailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get loginPassword => 'パスワード';

  @override
  String get loginPasswordRequired => 'パスワードを入力してください';

  @override
  String get loginPasswordTooShort => 'パスワードは6文字以上で入力してください';

  @override
  String get loginForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get loginRememberMe => 'パスワードを保存';

  @override
  String get loginSignIn => 'ログイン';

  @override
  String get loginMagicLink => 'マジックリンクを使用';

  @override
  String get loginPasskey => 'パスキーでログイン';

  @override
  String get loginSwitchServer => 'サーバーを切り替える';

  @override
  String get loginNoAccount => 'アカウントをお持ちでない方は ';

  @override
  String get loginSignUp => '新規登録';

  @override
  String get loginErrorInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get loginErrorAccountFrozen => 'このアカウントは凍結されています。管理者にお問い合わせください。';

  @override
  String get loginErrorNotInvited => '関連するアカウントが見つかりません。管理者に招待リンクを依頼してください。';

  @override
  String get loginErrorMethodNotSupported => 'このログイン方法はサーバーでサポートされていません。';

  @override
  String get loginErrorCannotReachServer =>
      'サーバーに接続できません。ネットワークまたはサーバーの URL を確認してください。';

  @override
  String get registerTitle => 'アカウントを作成';

  @override
  String get registerHeader => '会話に参加する';

  @override
  String get registerSubtitle => '情報を入力して始めましょう。';

  @override
  String get registerName => '氏名';

  @override
  String get registerNameRequired => '名前を入力してください';

  @override
  String get registerNameTooShort => '名前は2文字以上で入力してください';

  @override
  String get registerEmailRequired => 'メールアドレスを入力してください';

  @override
  String get registerEmailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get registerPasswordRequired => 'パスワードを入力してください';

  @override
  String get registerPasswordTooShort => '6文字以上で入力してください';

  @override
  String get registerConfirmPassword => 'パスワードの確認';

  @override
  String get registerConfirmRequired => 'パスワードを再入力してください';

  @override
  String get registerConfirmMismatch => 'パスワードが一致しません';

  @override
  String get registerCreate => 'アカウントを作成';

  @override
  String get registerMagicLink => '招待リンクを送信する';

  @override
  String get registerEmailFirst => '先にメールアドレスを入力してください';

  @override
  String get registerInvitationSent => '招待リンクを送信しました';

  @override
  String get registerHaveAccount => 'すでにアカウントをお持ちですか？ ';

  @override
  String get registerInviteRequiresEmailConfirmation =>
      'This server requires email confirmation for invited signups, which isn\'t supported yet. Please ask your admin for help.';

  @override
  String get serverPickerTitle => 'サーバーを選択';

  @override
  String get serverPickerEmptyTitle => 'VoceChat サーバーに接続';

  @override
  String get serverPickerEmptySubtitle => 'サーバーを追加して、チームとのチャットを始めましょう。';

  @override
  String get serverPickerAddFirst => '最初のサーバーを追加';

  @override
  String get serverPickerAdd => 'サーバーを追加';

  @override
  String get serverPickerContinue => '続ける';

  @override
  String get serverPickerUseInviteLink => 'Use invitation link';

  @override
  String get serverAddTitle => 'サーバーを追加';

  @override
  String get serverUrl => 'サーバー URL';

  @override
  String get serverUrlHint => 'https://chat.example.com';

  @override
  String get serverUrlRequired => 'URL を入力してください';

  @override
  String get serverUrlMustHttps => 'http:// または https:// で始まる必要があります';

  @override
  String get serverTesting => 'テスト中…';

  @override
  String get serverTestConnection => '接続をテスト';

  @override
  String get serverTestSuccess => '接続に成功しました';

  @override
  String get serverTestFailed => 'サーバーに接続できませんでした';

  @override
  String get serverSave => '保存して続ける';

  @override
  String get inviteLinkSheetTitle => 'Join with invitation link';

  @override
  String get inviteLinkHint => 'Paste your invitation link here';

  @override
  String get inviteLinkRequired => 'Please paste an invitation link';

  @override
  String get inviteLinkPasteFromClipboard => 'Paste from clipboard';

  @override
  String get inviteLinkInvalid =>
      'This doesn\'t look like a valid invitation link';

  @override
  String get inviteLinkExpired =>
      'This invitation link has expired or already been used';

  @override
  String get inviteLinkCheckFailed =>
      'Couldn\'t verify the invitation link. Check your network and try again.';

  @override
  String get inviteLinkContinue => 'Continue';

  @override
  String get chatListSearch => '検索...';

  @override
  String get chatListNewChat => '新規チャット';

  @override
  String get chatListLoading => 'チャットを読み込み中…';

  @override
  String get chatListUpdating => '更新中…';

  @override
  String get chatListEmpty => 'まだ会話がありません';

  @override
  String chatListNoResults(String query) {
    return '「$query」に一致する結果はありません';
  }

  @override
  String get chatListSelectTitle => '会話を選択してください';

  @override
  String get chatListSelectSubtitle => '左のパネルからチャットを選んでメッセージを始めましょう';

  @override
  String get chatListPin => '上部にピン留め';

  @override
  String get chatListUnpin => 'ピン留め解除';

  @override
  String chatListPinFailed(String error) {
    return 'ピン留めに失敗しました：$error';
  }

  @override
  String chatListUnpinFailed(String error) {
    return 'ピン留め解除に失敗しました：$error';
  }

  @override
  String get timeJustNow => 'たった今';

  @override
  String timeMinutesAgo(int count) {
    return '$count 分前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count 時間前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count 日前';
  }

  @override
  String get contactsSearch => '検索...';

  @override
  String get contactsAdd => '連絡先を追加';

  @override
  String get contactsLoading => '連絡先を読み込み中…';

  @override
  String get contactsEmpty => '連絡先が見つかりません';

  @override
  String contactsSectionBot(int count) {
    return 'ボット - $count';
  }

  @override
  String contactsSectionContact(int count) {
    return '連絡先 - $count';
  }

  @override
  String get contactsSelectTitle => '連絡先を選択してください';

  @override
  String get contactsSelectSubtitle => 'リストから選択してプロフィールを確認できます';

  @override
  String get contactsMessage => 'メッセージ';

  @override
  String get contactsCall => '通話';

  @override
  String get chatLoadingMessages => 'メッセージを読み込み中…';

  @override
  String get chatStatusOnline => 'オンライン';

  @override
  String get chatStatusOffline => 'オフライン';

  @override
  String get chatGroupIntro => 'コミュニティに自己紹介しましょう！';

  @override
  String get chatEmpty => 'まだメッセージがありません';

  @override
  String chatSendFailed(String error) {
    return '送信に失敗しました：$error';
  }

  @override
  String chatMessagePlaceholderChannel(String name) {
    return '#$name にメッセージを送信';
  }

  @override
  String chatMessagePlaceholderUser(String name) {
    return '$name にメッセージを送信';
  }

  @override
  String get chatPinned => 'ピン留め済み';

  @override
  String get chatUnsupported => '[サポートされていないメッセージ]';

  @override
  String get chatOpenLinkFailed => 'リンクを開けませんでした。再試行するか、リンクをブラウザにコピーしてください。';

  @override
  String get chatMarkdown => 'Markdown';

  @override
  String get chatAttach => '添付';

  @override
  String get chatVoiceMessage => '音声メッセージ';

  @override
  String get chatVideoMessage => '動画メッセージ';

  @override
  String get chatVoiceRecording => '音声メッセージを録音中';

  @override
  String get chatVoiceRecordingCancel => 'キャンセル';

  @override
  String get chatVoiceRecordingSend => '送信';

  @override
  String get chatRecordingPermissionDenied =>
      '権限が拒否されました — システム設定でマイク／カメラのアクセスを許可してください';

  @override
  String get chatPhotoPermissionDenied =>
      'Permission denied — enable photo library access in system settings';

  @override
  String get chatAttachOpenFiles => 'Files';

  @override
  String get chatAttachCamera => 'Camera';

  @override
  String chatAttachSend(int count) {
    return 'Send ($count)';
  }

  @override
  String chatDropOverlayTitle(String name) {
    return '$name に送信';
  }

  @override
  String get chatDropOverlayHint => 'ここにファイルをドロップして送信';

  @override
  String get chatMessageUnavailable => 'このメッセージは削除されたか、読み込めませんでした。';

  @override
  String get chatEmoji => '絵文字';

  @override
  String chatUserFallback(int uid) {
    return 'ユーザー $uid';
  }

  @override
  String chatGroupFallback(int gid) {
    return 'グループ $gid';
  }

  @override
  String get previewFile => '[ファイル]';

  @override
  String get previewVoice => '[音声]';

  @override
  String get previewArchive => '[アーカイブ]';

  @override
  String get previewImage => '[画像]';

  @override
  String get previewReaction => '[リアクション]';

  @override
  String errorPrefix(String message) {
    return 'エラー：$message';
  }

  @override
  String get errorRequestFailed => 'リクエストに失敗しました';

  @override
  String get authKickedFromOtherDevice =>
      'ログアウトしました：あなたのアカウントが別のデバイスでログインしました。';

  @override
  String get authAccountDeleted => 'あなたのアカウントは削除されました。';

  @override
  String get authSessionEnded => 'セッションが終了しました。再度ログインしてください。';

  @override
  String get chatListMarkRead => '既読にする';

  @override
  String get chatListMute => 'ミュート';

  @override
  String get chatListUnmute => 'ミュート解除';

  @override
  String get chatListHide => '非表示';

  @override
  String get chatListLeave => 'チャンネルを退出';

  @override
  String get chatListMarkReadDone => '既読にしました';

  @override
  String get chatListMuteDone => 'ミュートしました';

  @override
  String get chatListUnmuteDone => 'ミュートを解除しました';

  @override
  String get chatListHideDone => '非表示にしました';

  @override
  String get chatListLeaveDone => 'チャンネルを退出しました';

  @override
  String chatListLeaveFailed(String error) {
    return '退出に失敗しました：$error';
  }

  @override
  String chatListMuteFailed(String error) {
    return 'ミュートに失敗しました：$error';
  }

  @override
  String get chatListMarkReadFailed => '既読処理に失敗しました';

  @override
  String get createChannelTitle => '新規チャンネル';

  @override
  String get createChannelNameLabel => 'チャンネル名';

  @override
  String get channelPublicLabel => '公開チャンネル';

  @override
  String get createChannelPublicAdminOnly => '公開チャンネルを作成できるのは管理者のみです';

  @override
  String get createChannelSubmit => '作成';

  @override
  String get createChannelNameRequired => 'チャンネル名を入力してください';

  @override
  String get createChannelFailed => 'チャンネルの作成に失敗しました';

  @override
  String get channelSettingsTitle => 'チャンネル設定';

  @override
  String get channelUpdated => 'チャンネルを更新しました';

  @override
  String get avatarUpdated => 'アバターを更新しました';

  @override
  String get channelVisibilityChanged => '公開範囲を変更しました';

  @override
  String get inviteLinkCopied => 'リンクをコピーしました';

  @override
  String get channelOverview => '概要';

  @override
  String get channelNameLabel => '名前';

  @override
  String get channelDescriptionLabel => '説明';

  @override
  String get channelSaveChanges => '変更を保存';

  @override
  String get channelAddMember => 'メンバーを追加';

  @override
  String get channelInviteLinkSection => '招待リンク';

  @override
  String get channelGenerateInviteLink => '招待リンクを生成';

  @override
  String get channelMuteLabel => 'チャンネルをミュート';

  @override
  String get channelLeaveConfirmBody => '本当にこのチャンネルを退出しますか？';

  @override
  String get channelDeleteTitle => 'チャンネルを削除';

  @override
  String get channelDeleteConfirmBody =>
      'この操作を行うと、全メンバーに対してチャンネルが永久に削除されます。この操作は取り消せません。';

  @override
  String get actionLeave => '退出';

  @override
  String get accountEditNameTitle => '名前を編集';

  @override
  String get accountNameLabel => '名前';

  @override
  String get accountNameUpdated => '名前を更新しました';

  @override
  String get accountChangePasswordTitle => 'パスワードを変更';

  @override
  String get accountCurrentPasswordLabel => '現在のパスワード';

  @override
  String get accountNewPasswordLabel => '新しいパスワード';

  @override
  String get accountPasswordChanged => 'パスワードを変更しました';

  @override
  String get chatActionCopy => 'コピー';

  @override
  String get chatActionForward => '転送';

  @override
  String get chatActionSelect => '選択';

  @override
  String get chatCopiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get chatForwardedMessagePreview => '[転送されたメッセージ]';

  @override
  String get chatAutoDeleteTitle => 'メッセージの自動削除';

  @override
  String chatExpiresTooltip(String duration) {
    return '送信後 $duration で消えます';
  }

  @override
  String get chatAutoDeleteOff => 'オフ';

  @override
  String get chatAutoDelete5Min => '5分';

  @override
  String get chatAutoDelete10Min => '10分';

  @override
  String get chatAutoDelete1Hour => '1時間';

  @override
  String get chatAutoDelete1Day => '1日';

  @override
  String get chatAutoDelete1Week => '1週間';

  @override
  String get chatAutoDeleteSaved => '保存しました';

  @override
  String get chatAutoDeleteSaveFailed => '保存に失敗しました';

  @override
  String get forwardSheetTitle => '転送先...';

  @override
  String get forwardMessageSent => 'メッセージを転送しました';

  @override
  String forwardFailed(String error) {
    return '転送に失敗しました：$error';
  }

  @override
  String get forwardNoConversations => '会話がありません';

  @override
  String forwardSelectedCount(int count) {
    return '$count 件選択中';
  }

  @override
  String get archiveForwardedLabel => '転送されたメッセージ';

  @override
  String get archiveLoadFailed => '転送メッセージの読み込みに失敗しました';

  @override
  String get archiveTapToView => 'タップして詳細を表示';

  @override
  String archiveViewAll(int count) {
    return '$count 件のメッセージをすべて表示';
  }

  @override
  String get voiceStartCall => 'Start voice call';

  @override
  String get voiceIncomingCall => 'Incoming call';

  @override
  String get voiceCallingOut => 'Calling...';

  @override
  String get voiceMute => 'Mute';

  @override
  String get voiceUnmute => 'Unmute';

  @override
  String get voiceDeafen => 'Deafen';

  @override
  String get voiceUndeafen => 'Undeafen';

  @override
  String get voiceCameraOn => 'Turn on camera';

  @override
  String get voiceCameraOff => 'Turn off camera';

  @override
  String get voiceSwitchCamera => 'Switch camera';

  @override
  String get voiceSelectCamera => 'Select camera';

  @override
  String get voiceNoCameras => 'No cameras available';

  @override
  String voiceCameraFallback(int index) {
    return 'Camera $index';
  }

  @override
  String get voiceShareScreen => 'Share screen';

  @override
  String get voiceFullscreen => 'Fullscreen';

  @override
  String get voiceLeave => 'Leave call';

  @override
  String get voiceConnected => 'Voice connected';

  @override
  String get voiceReconnecting => 'Reconnecting...';

  @override
  String get avoDescription =>
      'Generate your Avo from a name: the same name always creates the same avatar. Customize its style, color and energy, then save it for when your camera is off.';

  @override
  String get avoNameLabel => 'Name';

  @override
  String get avoStyleLabel => 'Style';

  @override
  String get avoStyleBlob => 'Blob';

  @override
  String get avoStyleRing => 'Ring';

  @override
  String get avoStyleWave => 'Wave';

  @override
  String avoEnergy(int percent) {
    return 'Energy $percent%';
  }

  @override
  String get avoSave => 'Save';

  @override
  String get avoSaved => 'Avo saved';

  @override
  String get avoServerUnsupported =>
      'The server does not support saving Avo avatars.';

  @override
  String avoServerVersionUnsupported(String version) {
    return 'The current server (version $version) does not support saving Avo avatars.';
  }

  @override
  String avoSaveFailed(String error) {
    return 'Unable to save Avo: $error';
  }

  @override
  String get avoPreviewHint =>
      'Move over a creature, rub across its body, or click it.';

  @override
  String get avoPreviewNameLabel => 'Name (default Han)';

  @override
  String avoVoiceLevel(int percent) {
    return 'Voice level $percent%';
  }

  @override
  String get avoNextVariant => 'Next variant';

  @override
  String appUpdateTitle(String version) {
    return 'Update available: $version';
  }

  @override
  String get appUpdateRequired =>
      'Please install this required update to continue using VoceChat.';

  @override
  String get appUpdateAvailable => 'A new version of VoceChat is available.';

  @override
  String get appUpdateOpenFailed =>
      'Could not open the download link. Please try again.';

  @override
  String get appUpdateLater => 'Later';

  @override
  String get appUpdateDownload => 'Download update';

  @override
  String get appUpdateSkipVersion => 'Skip this version';

  @override
  String appUpdateEmergencySkip(int remaining) {
    return 'Skip for 1 day ($remaining left)';
  }

  @override
  String get appUpdateEmergencyHint =>
      'You can postpone a required update 3 times for emergencies. Each skip hides the reminder for 24 hours, including after restarting the app.';

  @override
  String get appUpdateSkipFailed =>
      'Could not save update preferences. Skipping is unavailable; please try again or download the update.';

  @override
  String appUpdateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String appUpdateDownloadingUnknown(String megabytes) {
    return 'Downloading… $megabytes MB';
  }

  @override
  String get appUpdateCancelDownload => 'Cancel download';

  @override
  String get appUpdateInstall => 'Install update';

  @override
  String get appUpdateAllowInstall => 'Allow installation';

  @override
  String get appUpdateInstallPermission =>
      'Allow VoceChat to install apps in Android settings, then return to continue installation.';

  @override
  String get appUpdateInvalidApk =>
      'The downloaded file is not a valid update for this app. Check the APK download link and build number, then download again.';

  @override
  String get appUpdateInstallerOpened =>
      'Confirm installation in the Android installer. If you cancelled, tap Install update to try again.';

  @override
  String get appUpdateDownloadFailed =>
      'Download failed. Check your network and available storage, then try again.';

  @override
  String get appUpdateInstallFailed =>
      'Could not open the installer. Please try again.';

  @override
  String get authSavedSessionMissing =>
      'Your saved sign-in information could not be found. Please sign in again.';

  @override
  String get authSavedSessionRejected =>
      'The server no longer accepts your saved session. Please sign in again.';

  @override
  String get authServerChanged =>
      'This address now belongs to a different server. Please sign in again.';

  @override
  String get authRememberedReadFailed =>
      'Your saved password could not be read. You can retry or enter it manually.';

  @override
  String get authRetrySavedPassword => 'Retry saved password';

  @override
  String get authSaveFailed =>
      'Could not save your sign-in information on this device. Please try again.';

  @override
  String get backgroundTitle => 'Background message notifications';

  @override
  String get backgroundDescription =>
      'Receive messages over a persistent background connection. Enabling this turns FCM off.';

  @override
  String get backgroundActionFailed =>
      'Unable to update background settings. Please try again.';

  @override
  String get backgroundSetupRequired =>
      'Allow notifications and tap “Disable battery optimization” to review the setting before enabling.';

  @override
  String get backgroundRunning => 'Background service is running';

  @override
  String get backgroundNotRunning =>
      'Enabled, but service is not running. Return to the app to retry.';

  @override
  String get backgroundDisabled => 'Background service is off';

  @override
  String get backgroundNotificationPermission =>
      'Allow message and foreground notifications';

  @override
  String get backgroundGranted => 'Allowed';

  @override
  String get backgroundBattery => 'Disable battery optimization';

  @override
  String get backgroundBatteryDescription =>
      'Allow unrestricted battery use so the message connection can continue while the screen is off.';

  @override
  String get backgroundManufacturer => 'Autostart and background restrictions';

  @override
  String get backgroundManufacturerDescription =>
      'In your phone’s app or battery settings, allow background activity and autostart. If available, lock VoceChat in recent apps. Options vary by manufacturer.';

  @override
  String get backgroundLimitations =>
      'Uses more battery. Calls remain active; idle background work is reduced. Only the current account receives messages. Force stop, reboot, or manufacturer cleanup can interrupt the service; reopen the app to restore it. Battery and notification permissions stay unchanged when this switch is turned off.';

  @override
  String get backgroundBatteryVisited =>
      'Settings reviewed; background mode can be enabled. Some phones cannot report this accurately. Please confirm unrestricted battery use in system settings.';

  @override
  String get serverConnectionTimeout =>
      'Connection timed out. Check the server address and network, then retry.';

  @override
  String get serverConnectionFailed =>
      'Cannot connect. Check the network, server address and port.';

  @override
  String get serverCertificateError =>
      'Server certificate validation failed. Check its HTTPS certificate.';

  @override
  String get serverInvalidResponse =>
      'This address did not return valid VoceChat server information. Check the address.';

  @override
  String serverHttpError(int status) {
    return 'Server returned HTTP $status. Check the server address.';
  }

  @override
  String get serverConnecting => 'Connecting to server…';

  @override
  String get serverSettingsFailed =>
      'Could not save server settings. Please retry.';

  @override
  String get serverPreparingTimeout =>
      'Preparing sign-in timed out. Please retry.';

  @override
  String get serverUrlInvalid =>
      'Enter a complete server address, such as https://chat.example.com.';

  @override
  String get serverRemoveTitle => 'Remove server';

  @override
  String get serverRemoveBody =>
      'Remove this server from this device\'s list. Saved accounts and chat history will be kept.';

  @override
  String get serverRemoveAction => 'Remove';

  @override
  String get serverRemoveFailed => 'Could not remove the server. Please retry.';

  @override
  String get settingsAppearanceLanguage => 'Appearance & Language';

  @override
  String get settingsAccountAndStorage => 'Account, Storage & Data';

  @override
  String get accountSwitcherServersTitle => 'Servers';

  @override
  String get accountSwitcherAdd => 'Add';

  @override
  String get chatStatusSyncing => 'Syncing status…';

  @override
  String get stickerFavorites => 'Saved stickers';

  @override
  String get stickerImport => 'Import image / GIF';

  @override
  String get stickerManage => 'Manage';

  @override
  String get stickerDone => 'Done';

  @override
  String get stickerAddFromChat => 'Add to stickers';

  @override
  String get stickerEmpty => 'No saved stickers yet';

  @override
  String get stickerLocalHint =>
      'Import an image or long press a chat image. Connect the sticker service to sync across devices.';

  @override
  String get stickerAdded => 'Added to stickers';

  @override
  String get stickerAlreadySaved => 'This sticker is already saved';

  @override
  String stickerImportSummary(int added, int duplicates, int failed) {
    return 'Added $added, duplicates $duplicates, failed $failed';
  }

  @override
  String get stickerTooLarge => 'Sticker images must be 10 MB or smaller';

  @override
  String get stickerUnsupported => 'Choose a valid PNG, JPG, GIF or WebP image';

  @override
  String get stickerMissing =>
      'Sticker file is missing or damaged. Remove it and import it again.';

  @override
  String get stickerOperationFailed =>
      'Sticker operation failed. Please try again.';

  @override
  String get stickerDownloadFailed =>
      'Image download failed. Check your connection and try again.';

  @override
  String get stickerRemoveTitle => 'Remove this sticker?';

  @override
  String get stickerRemoveBody =>
      'Remove from your stickers and, when connected, the server. Chat messages are kept.';

  @override
  String get stickerSend => 'Send sticker';

  @override
  String get stickerSaving => 'Adding sticker…';

  @override
  String get chatCameraGestureHint => 'Tap for photo · Hold for video';

  @override
  String get chatCaptureFailed =>
      'Capture failed. Check the camera and try again.';

  @override
  String get chatMediaReadFailed =>
      'Could not read the selected photos or videos. Please select them again.';

  @override
  String get stickerSyncLocal => 'Local stickers · sync service not configured';

  @override
  String get stickerSyncing => 'Syncing stickers';

  @override
  String get stickerSynced => 'Synced with server';

  @override
  String get stickerSyncPending =>
      'Saved locally · tap the cloud to retry syncing';

  @override
  String get stickerSyncUnavailable =>
      'Sync unavailable · local stickers still work';

  @override
  String get searchPeopleTitle => 'Find people';

  @override
  String get searchPeopleHint => 'Name, account email or user ID';

  @override
  String get searchPeopleEmpty => 'No matching people';

  @override
  String get searchPeopleDisabled =>
      'The server has disabled user lookup. Matching known contacts are still shown.';

  @override
  String get searchPeopleUnavailable =>
      'Unable to search the server. Matching known contacts are still shown.';

  @override
  String get searchMessagesTitle => 'Search chat history';

  @override
  String get searchMessagesPrompt =>
      'Enter a keyword to search message content';

  @override
  String get searchMessagesMore => 'Search earlier messages';

  @override
  String get searchMessagesUnavailable =>
      'Some history could not be loaded. Your current results are kept; tap Retry to continue.';

  @override
  String get searchMessagesComplete =>
      'All available history has been searched';

  @override
  String get draftLabel => 'Draft';

  @override
  String get draftSaveFailed =>
      'Draft could not be saved. Please keep this chat open and try again.';

  @override
  String get stickerSort => 'Reorder';

  @override
  String get stickerSortTitle => 'Reorder stickers';

  @override
  String get stickerSortHint => 'Drag the handles to reorder';

  @override
  String get shareTitle => 'Share to vocechat';

  @override
  String get shareChooseTarget =>
      'Choose file transfer, or a conversation to review the content before sending.';

  @override
  String get shareNoConversations =>
      'No conversations available. Start a chat first, then share again.';

  @override
  String get shareImportFailed =>
      'Some shared files could not be read. Please share them again.';

  @override
  String get shareTooLarge => 'The shared files exceed the supported range.';

  @override
  String get shareTooMany =>
      'Share up to 16 files at a time. Select fewer files and try again.';

  @override
  String get shareTransferHint =>
      'Add files to file transfer, then choose a device and confirm before sending.';

  @override
  String get shareReceiveFailed =>
      'The shared content could not be received. Please share it again.';

  @override
  String get shareStaged =>
      'Shared content is ready. Review it before sending.';

  @override
  String get searchFilters => 'Filters';

  @override
  String get filterConversation => 'Conversation';

  @override
  String get filterSender => 'Sender';

  @override
  String get filterDate => 'Date range';

  @override
  String get filterKind => 'Message type';

  @override
  String get filterAll => 'All';

  @override
  String get filterText => 'Text';

  @override
  String get filterImages => 'Images';

  @override
  String get filterVideos => 'Videos';

  @override
  String get filterFiles => 'Files';

  @override
  String get filterReset => 'Reset filters';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterNoDates => 'Any date';

  @override
  String get filterMediaHint =>
      'Filter media, or enter a keyword to search text and filenames.';

  @override
  String get fcmTitle => 'FCM push notifications';

  @override
  String get fcmConnecting => 'Connecting and registering this device…';

  @override
  String get fcmRegistered =>
      'Device registered. Message delivery still needs verification.';

  @override
  String get fcmStandby =>
      'FCM is off. Background message notifications are selected.';

  @override
  String get fcmDisabled => 'Message notifications are disabled.';

  @override
  String get fcmUnavailable =>
      'Unavailable. Check Google Play services and network, then retry.';

  @override
  String get fcmSignInRequired => 'Sign in to register this device.';

  @override
  String get fcmSettingsNotice =>
      'In FCM mode, sound is controlled by Android chat-notification settings and group alerts follow server mute settings. The sound and mentions-only switches above apply to keep-alive mode.';

  @override
  String get fcmDescription =>
      'Receive pushes through Google Play services. Enabling this turns background message notifications off.';

  @override
  String get fcmStatusTitle => 'FCM connection status';

  @override
  String get notificationMethodExclusive =>
      'Choose one notification method. Switching turns the other off. To stop alerts, turn off message notifications above.';

  @override
  String get fcmDisconnecting => 'Removing this device’s FCM registration…';

  @override
  String get fcmUnregisterFailed =>
      'FCM registration has not been removed. Check the VC connection and retry.';

  @override
  String get localTransferTitle => 'File transfer';

  @override
  String get localTransferQuick => 'Peer transfer';

  @override
  String get localTransferDescription =>
      'Transfer directly over your local network. Both devices need this page open. Files stay between the two devices.';

  @override
  String get localTransferMyDevice => 'This device';

  @override
  String get localTransferCopyConnection => 'Copy connection information';

  @override
  String get localTransferCopied => 'Connection information copied';

  @override
  String get localTransferAddDevice => 'Add device';

  @override
  String get localTransferConnectionHint =>
      'Paste the other device’s connection information';

  @override
  String get localTransferConnectionInvalid =>
      'Invalid connection information. Copy it from the other device’s file-transfer page.';

  @override
  String get localTransferNearby => 'Nearby devices';

  @override
  String get localTransferNearbyHint =>
      'Open File transfer on both devices and connect them to the same Wi-Fi. If discovery is blocked, add the other device using its connection information.';

  @override
  String get localTransferNoDevices => 'Looking for nearby devices…';

  @override
  String get localTransferSelected => 'Files to send';

  @override
  String get localTransferChooseFiles => 'Choose files';

  @override
  String get localTransferChooseHint =>
      'Choose up to 16 files, then tap Send beside a nearby device.';

  @override
  String get localTransferIncoming => 'Incoming transfer';

  @override
  String get localTransferCode => 'Verification code';

  @override
  String get localTransferCompareCode =>
      'Check that this code matches on both devices before accepting.';

  @override
  String get localTransferAccept => 'Accept';

  @override
  String get localTransferReject => 'Decline';

  @override
  String get localTransferReady => 'Ready';

  @override
  String get localTransferPreparing => 'Checking files…';

  @override
  String get localTransferWaiting => 'Waiting for confirmation…';

  @override
  String get localTransferSending => 'Sending…';

  @override
  String get localTransferReceiving => 'Receiving…';

  @override
  String get localTransferVerifying => 'Verifying file…';

  @override
  String get localTransferCompleted => 'Transfer complete';

  @override
  String get localTransferFailed => 'Transfer failed';

  @override
  String get localTransferCancelled => 'Transfer cancelled';

  @override
  String get localTransferRejected =>
      'The other device declined or did not confirm.';

  @override
  String get localTransferBusy => 'The other device is busy. Try again later.';

  @override
  String get localTransferIntegrityError =>
      'File verification failed. Please send it again.';

  @override
  String get localTransferFileError =>
      'Cannot read or save the file. Check storage space and choose up to 16 files.';

  @override
  String get localTransferTimeout =>
      'The connection timed out. Check that both devices are still connected.';

  @override
  String get localTransferNetworkError =>
      'Cannot connect. Check Wi-Fi, VPN local-network access, and router device isolation.';

  @override
  String get localTransferReceived => 'Received on this device';

  @override
  String get localTransferSave => 'Save as';

  @override
  String get localTransferReceivedHint =>
      'Files are stored at the locations below. Save as moves them to another folder.';

  @override
  String get localTransferStorageSettings => 'Receive settings';

  @override
  String get localTransferStorageHint =>
      'Choose separate folders for images and other files. This applies to new arrivals only; existing files stay in place.';

  @override
  String get localTransferImageFolder => 'Image folder';

  @override
  String get localTransferFileFolder => 'File folder';

  @override
  String get localTransferPrivateStorage => 'App storage';

  @override
  String get localTransferChooseFolder => 'Choose folder';

  @override
  String get localTransferResetFolder => 'Reset folder';

  @override
  String get localTransferStorageError =>
      'Cannot use this folder. Select it again and grant access.';

  @override
  String get localTransferStorageFallback =>
      'The custom folder is unavailable. Your file is safe in app storage and can be saved elsewhere.';

  @override
  String get localTransferNearbyShort =>
      'Connect to the same Wi-Fi and keep this page open on both devices.';

  @override
  String get localTransferSavedAs => 'Moved to the selected location';

  @override
  String get localTransferLeaveTitle => 'Stop this transfer?';

  @override
  String get localTransferLeaveBody =>
      'Leaving this page cancels the current transfer. You can keep the app in the background while transferring.';

  @override
  String get localTransferStopAndLeave => 'Stop and leave';

  @override
  String get livePhotoLabel => 'Live Photo';

  @override
  String get livePhotoRetry => 'Retry Live Photo';

  @override
  String get livePhotoSound => 'Toggle Live Photo sound';

  @override
  String get livePhotoPairTitle => 'Import Live Photos';

  @override
  String get livePhotoPairBody =>
      'Matching photos and MOV videos were selected. Combine each pair into one Live Photo?';

  @override
  String get livePhotoPairMerge => 'Combine';

  @override
  String get livePhotoPairSeparate => 'Keep separate';
}
