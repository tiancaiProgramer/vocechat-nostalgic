// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppL10nRu extends AppL10n {
  AppL10nRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'VoceChat';

  @override
  String get appLoadingSlowTitle =>
      'Загрузка занимает больше времени, чем обычно';

  @override
  String get appLoadingSlowBody =>
      'Мы всё ещё пытаемся загрузить приложение. Можно подождать или повторить попытку. Сохранённые аккаунты не будут удалены.';

  @override
  String get appRecoveryTitle => 'Не удалось отобразить страницу';

  @override
  String get appRecoveryBody =>
      'При загрузке интерфейса произошла ошибка. Повторите попытку. Сохранённые аккаунты не будут удалены.';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionOpen => 'Открыть';

  @override
  String get actionChange => 'Изменить';

  @override
  String get actionContact => 'Контакт';

  @override
  String get actionEdit => 'Редактировать';

  @override
  String get actionSend => 'Отправить';

  @override
  String get actionSearch => 'Поиск';

  @override
  String get actionMore => 'Ещё';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get chatToolPin => 'Закреплённые';

  @override
  String get chatActionReact => 'Добавить реакцию';

  @override
  String get chatActionReply => 'Ответить';

  @override
  String get chatActionEdit => 'Редактировать';

  @override
  String get chatActionDelete => 'Удалить';

  @override
  String get chatEditMarker => '(изменено)';

  @override
  String chatReplyingTo(String name) {
    return 'Ответ пользователю $name';
  }

  @override
  String get chatDeleteConfirmTitle => 'Удалить сообщение?';

  @override
  String get chatDeleteConfirmBody => 'Это действие невозможно отменить.';

  @override
  String get chatEditCancel => 'Отмена';

  @override
  String get chatEditSave => 'Сохранить';

  @override
  String get chatFileDetailsTitle => 'Информация о файле';

  @override
  String get chatFileNameLabel => 'Имя';

  @override
  String chatEditFailed(String error) {
    return 'Не удалось изменить: $error';
  }

  @override
  String chatDeleteFailed(String error) {
    return 'Не удалось удалить: $error';
  }

  @override
  String chatReplyFailed(String error) {
    return 'Не удалось ответить: $error';
  }

  @override
  String get chatReplyDeleted => 'Это сообщение было удалено.';

  @override
  String get chatReplyVoiceMessage => '[Голосовое сообщение]';

  @override
  String get chatToolSaved => 'Сохранённые';

  @override
  String get chatToolMembers => 'Участники';

  @override
  String get chatToolEmpty => 'Пока нет содержимого.';

  @override
  String get chatToolPinEmpty => 'Нет закреплённых сообщений.';

  @override
  String get chatToolSavedEmpty => 'Нет сохранённых сообщений.';

  @override
  String get chatToolMembersEmpty => 'Нет участников.';

  @override
  String get chatToolUnpin => 'Открепить';

  @override
  String get chatToolRemoveFav => 'Удалить';

  @override
  String get chatToolPinFail => 'Не удалось закрепить';

  @override
  String get chatToolUnpinFail => 'Не удалось открепить';

  @override
  String get chatToolSaveFail => 'Не удалось сохранить';

  @override
  String get chatToolRemoveFavFail => 'Не удалось удалить';

  @override
  String get chatToolSavedAdded => 'Сохранено';

  @override
  String get chatToolPinAdded => 'Закреплено';

  @override
  String get chatToolUnpinned => 'Откреплено';

  @override
  String get chatSearchHint => 'Поиск сообщений';

  @override
  String get chatSearchEmpty => 'Совпадений не найдено.';

  @override
  String get navChats => 'Чаты';

  @override
  String get navContacts => 'Контакты';

  @override
  String get navSettings => 'Настройки';

  @override
  String get navSaved => 'Сохранённые';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get actionBack => 'Назад';

  @override
  String get actionClose => 'Закрыть';

  @override
  String get memberRoleOwner => 'Владелец';

  @override
  String get tooltipDownload => 'Скачать';

  @override
  String get downloadSaved => 'Saved';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get tooltipZoomIn => 'Увеличить';

  @override
  String get tooltipZoomOut => 'Уменьшить';

  @override
  String get tooltipFullscreen => 'Полный экран';

  @override
  String get tooltipExitFullscreen => 'Выйти из полного экрана';

  @override
  String get tooltipShowPassword => 'Показать пароль';

  @override
  String get tooltipHidePassword => 'Скрыть пароль';

  @override
  String get reactionDeletedUser => 'Удалённый пользователь';

  @override
  String reactionTooltipMany(String names, int count, String emoji) {
    return '$names и ещё $count человек отреагировали $emoji';
  }

  @override
  String reactionTooltipFew(String names, String emoji) {
    return '$names отреагировали $emoji';
  }

  @override
  String get expiredImageTitle => 'Изображение не найдено';

  @override
  String get expiredImageBody => 'Изображение истекло или было удалено';

  @override
  String get expiredVideoTitle => 'Видео не найдено';

  @override
  String get expiredVideoBody => 'Видео истекло или было удалено';

  @override
  String get expiredAudioTitle => 'Аудио не найдено';

  @override
  String get expiredAudioBody => 'Аудио истекло или было удалено';

  @override
  String get expiredFileTitle => 'Файл не найден';

  @override
  String get expiredFileBody => 'Файл истёк или был удалён';

  @override
  String get mediaLoadFailedRetry => 'Failed to load — tap to retry';

  @override
  String get mediaLikelyIncompatible =>
      'This device can\'t play this video format. Try downloading it instead.';

  @override
  String get featureUnavailable => 'Эта функция пока недоступна';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsGroupGeneral => 'общие';

  @override
  String get settingsGroupAbout => 'о приложении';

  @override
  String get settingsMyAccount => 'Мой аккаунт';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsAppearance => 'Внешний вид';

  @override
  String get settingsStorage => 'Хранилище и данные';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsLogout => 'Выйти';

  @override
  String get settingsLogoutConfirmTitle => 'Выйти из аккаунта?';

  @override
  String get settingsLogoutConfirmContent =>
      'Для доступа к этому серверу потребуется войти снова.';

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
  String get accountEmail => 'Электронная почта';

  @override
  String get accountUsername => 'Имя пользователя';

  @override
  String get accountPassword => 'Пароль';

  @override
  String get accountPasswordMasked => '*********';

  @override
  String get notificationsPush => 'Push-уведомления';

  @override
  String get notificationsPushSubtitle =>
      'Получать уведомления о новых сообщениях и упоминаниях.';

  @override
  String get notificationsSound => 'Звук уведомлений';

  @override
  String get notificationsSoundSubtitle =>
      'Воспроизводить звук при новых сообщениях.';

  @override
  String get notificationsMentionsOnly => 'Только упоминания';

  @override
  String get notificationsMentionsOnlySubtitle =>
      'Уведомлять только при упоминаниях (@).';

  @override
  String get appearanceTheme => 'ТЕМА';

  @override
  String get appearanceLight => 'Светлая';

  @override
  String get appearanceSystem => 'Как в системе';

  @override
  String get appearanceDark => 'Тёмная';

  @override
  String get appearanceLanguage => 'ЯЗЫК';

  @override
  String get languageSystem => 'Как в системе';

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
  String get storageUsage => 'Использование хранилища';

  @override
  String get storageAutoDownload => 'Автозагрузка медиафайлов';

  @override
  String get storageWifiOnly => 'Только через Wi-Fi';

  @override
  String get storageClearCache => 'Очистить кэш';

  @override
  String get storageClearCacheConfirmTitle => 'Очистить кэш?';

  @override
  String get storageClearCacheConfirmBody =>
      'Локально кэшированные сообщения и изображения будут удалены. При необходимости они будут загружены заново.';

  @override
  String get storageClearCacheConfirm => 'Очистить';

  @override
  String get storageCacheCleared => 'Кэш очищен';

  @override
  String get aboutAppVersion => 'Версия приложения';

  @override
  String get aboutServerVersion => 'Версия сервера';

  @override
  String get aboutWebsite => 'Веб-сайт';

  @override
  String get aboutReportBug => 'Сообщить об ошибке';

  @override
  String get aboutReportBugSubtitle => 'Помогите нам сделать VoceChat лучше.';

  @override
  String get loginWelcomeBack => 'С возвращением';

  @override
  String get loginEmail => 'Электронная почта';

  @override
  String get loginEmailRequired => 'Введите адрес электронной почты';

  @override
  String get loginEmailInvalid =>
      'Введите действительный адрес электронной почты';

  @override
  String get loginPassword => 'Пароль';

  @override
  String get loginPasswordRequired => 'Введите пароль';

  @override
  String get loginPasswordTooShort =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get loginForgotPassword => 'Забыли пароль?';

  @override
  String get loginRememberMe => 'Запомнить пароль';

  @override
  String get loginSignIn => 'Войти';

  @override
  String get loginMagicLink => 'Использовать magic-ссылку';

  @override
  String get loginPasskey => 'Войти с помощью passkey';

  @override
  String get loginSwitchServer => 'Сменить сервер';

  @override
  String get loginNoAccount => 'Нет аккаунта? ';

  @override
  String get loginSignUp => 'Зарегистрироваться';

  @override
  String get loginErrorInvalidCredentials =>
      'Неверный адрес электронной почты или пароль';

  @override
  String get loginErrorAccountFrozen =>
      'Этот аккаунт заморожен. Обратитесь к администратору.';

  @override
  String get loginErrorNotInvited =>
      'Связанный аккаунт не найден. Попросите администратора отправить ссылку-приглашение.';

  @override
  String get loginErrorMethodNotSupported =>
      'Этот способ входа не поддерживается сервером.';

  @override
  String get loginErrorCannotReachServer =>
      'Не удаётся подключиться к серверу. Проверьте сеть или адрес сервера.';

  @override
  String get registerTitle => 'Создать аккаунт';

  @override
  String get registerHeader => 'Присоединиться к общению';

  @override
  String get registerSubtitle => 'Заполните данные, чтобы начать.';

  @override
  String get registerName => 'Полное имя';

  @override
  String get registerNameRequired => 'Введите имя';

  @override
  String get registerNameTooShort => 'Имя должно содержать не менее 2 символов';

  @override
  String get registerEmailRequired => 'Введите адрес электронной почты';

  @override
  String get registerEmailInvalid =>
      'Введите действительный адрес электронной почты';

  @override
  String get registerPasswordRequired => 'Введите пароль';

  @override
  String get registerPasswordTooShort => 'Требуется не менее 6 символов';

  @override
  String get registerConfirmPassword => 'Подтвердите пароль';

  @override
  String get registerConfirmRequired => 'Пожалуйста, подтвердите пароль';

  @override
  String get registerConfirmMismatch => 'Пароли не совпадают';

  @override
  String get registerCreate => 'Создать аккаунт';

  @override
  String get registerMagicLink => 'Отправить ссылку-приглашение вместо этого';

  @override
  String get registerEmailFirst => 'Сначала введите адрес электронной почты';

  @override
  String get registerInvitationSent => 'Ссылка-приглашение отправлена';

  @override
  String get registerHaveAccount => 'Уже есть аккаунт? ';

  @override
  String get registerInviteRequiresEmailConfirmation =>
      'This server requires email confirmation for invited signups, which isn\'t supported yet. Please ask your admin for help.';

  @override
  String get serverPickerTitle => 'Выбор сервера';

  @override
  String get serverPickerEmptyTitle => 'Подключение к серверу VoceChat';

  @override
  String get serverPickerEmptySubtitle =>
      'Добавьте сервер, чтобы начать общение с командой.';

  @override
  String get serverPickerAddFirst => 'Добавить первый сервер';

  @override
  String get serverPickerAdd => 'Добавить сервер';

  @override
  String get serverPickerContinue => 'Продолжить';

  @override
  String get serverPickerUseInviteLink => 'Use invitation link';

  @override
  String get serverAddTitle => 'Добавить сервер';

  @override
  String get serverUrl => 'Адрес сервера';

  @override
  String get serverUrlHint => 'https://chat.example.com';

  @override
  String get serverUrlRequired => 'Введите адрес';

  @override
  String get serverUrlMustHttps =>
      'Адрес должен начинаться с http:// или https://';

  @override
  String get serverTesting => 'Проверка…';

  @override
  String get serverTestConnection => 'Проверить подключение';

  @override
  String get serverTestSuccess => 'Подключение успешно';

  @override
  String get serverTestFailed => 'Не удалось подключиться к серверу';

  @override
  String get serverSave => 'Сохранить и продолжить';

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
  String get chatListSearch => 'Поиск...';

  @override
  String get chatListNewChat => 'Новый чат';

  @override
  String get chatListLoading => 'Загрузка чатов…';

  @override
  String get chatListUpdating => 'Обновление…';

  @override
  String get chatListEmpty => 'Пока нет ни одного чата';

  @override
  String chatListNoResults(String query) {
    return 'Нет результатов по запросу «$query»';
  }

  @override
  String get chatListSelectTitle => 'Выберите чат';

  @override
  String get chatListSelectSubtitle =>
      'Выберите чат в левой панели, чтобы начать общение';

  @override
  String get chatListPin => 'Закрепить сверху';

  @override
  String get chatListUnpin => 'Открепить';

  @override
  String chatListPinFailed(String error) {
    return 'Не удалось закрепить: $error';
  }

  @override
  String chatListUnpinFailed(String error) {
    return 'Не удалось открепить: $error';
  }

  @override
  String get timeJustNow => 'только что';

  @override
  String timeMinutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дн назад';
  }

  @override
  String get contactsSearch => 'Поиск...';

  @override
  String get contactsAdd => 'Добавить контакт';

  @override
  String get contactsLoading => 'Загрузка контактов…';

  @override
  String get contactsEmpty => 'Контакты не найдены';

  @override
  String contactsSectionBot(int count) {
    return 'БОТЫ — $count';
  }

  @override
  String contactsSectionContact(int count) {
    return 'КОНТАКТЫ — $count';
  }

  @override
  String get contactsSelectTitle => 'Выберите контакт';

  @override
  String get contactsSelectSubtitle =>
      'Выберите пользователя из списка, чтобы увидеть его профиль';

  @override
  String get contactsMessage => 'Сообщение';

  @override
  String get contactsCall => 'Вызов';

  @override
  String get chatLoadingMessages => 'Загрузка сообщений…';

  @override
  String get chatStatusOnline => 'В сети';

  @override
  String get chatStatusOffline => 'Не в сети';

  @override
  String get chatGroupIntro => 'Расскажите сообществу о себе!';

  @override
  String get chatEmpty => 'Пока нет сообщений';

  @override
  String chatSendFailed(String error) {
    return 'Не удалось отправить: $error';
  }

  @override
  String chatMessagePlaceholderChannel(String name) {
    return 'Сообщение в #$name';
  }

  @override
  String chatMessagePlaceholderUser(String name) {
    return 'Сообщение $name';
  }

  @override
  String get chatPinned => 'закреплено';

  @override
  String get chatUnsupported => '[неподдерживаемое сообщение]';

  @override
  String get chatOpenLinkFailed =>
      'Не удалось открыть ссылку. Повторите попытку или скопируйте её в браузер.';

  @override
  String get chatMarkdown => 'Markdown';

  @override
  String get chatAttach => 'Прикрепить';

  @override
  String get chatVoiceMessage => 'Голосовое сообщение';

  @override
  String get chatVideoMessage => 'Видеосообщение';

  @override
  String get chatVoiceRecording => 'Запись голосового сообщения';

  @override
  String get chatVoiceRecordingCancel => 'Отмена';

  @override
  String get chatVoiceRecordingSend => 'Отправить';

  @override
  String get chatRecordingPermissionDenied =>
      'Доступ запрещён — включите доступ к микрофону/камере в настройках системы';

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
    return 'Отправить $name';
  }

  @override
  String get chatDropOverlayHint => 'Перетащите файлы сюда, чтобы отправить их';

  @override
  String get chatMessageUnavailable =>
      'Это сообщение больше недоступно или его не удалось загрузить.';

  @override
  String get chatEmoji => 'Эмодзи';

  @override
  String chatUserFallback(int uid) {
    return 'Пользователь $uid';
  }

  @override
  String chatGroupFallback(int gid) {
    return 'Группа $gid';
  }

  @override
  String get previewFile => '[Файл]';

  @override
  String get previewVoice => '[Голосовое]';

  @override
  String get previewArchive => '[Архив]';

  @override
  String get previewImage => '[Изображение]';

  @override
  String get previewReaction => '[Реакция]';

  @override
  String errorPrefix(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get errorRequestFailed => 'Запрос не выполнен';

  @override
  String get authKickedFromOtherDevice =>
      'Вы вышли из системы: ваш аккаунт только что вошёл на другом устройстве.';

  @override
  String get authAccountDeleted => 'Ваш аккаунт был удалён.';

  @override
  String get authSessionEnded => 'Сессия завершена. Пожалуйста, войдите снова.';

  @override
  String get chatListMarkRead => 'Отметить как прочитанное';

  @override
  String get chatListMute => 'Отключить уведомления';

  @override
  String get chatListUnmute => 'Включить уведомления';

  @override
  String get chatListHide => 'Скрыть';

  @override
  String get chatListLeave => 'Покинуть канал';

  @override
  String get chatListMarkReadDone => 'Отмечено как прочитанное';

  @override
  String get chatListMuteDone => 'Уведомления отключены';

  @override
  String get chatListUnmuteDone => 'Уведомления включены';

  @override
  String get chatListHideDone => 'Скрыто';

  @override
  String get chatListLeaveDone => 'Вы покинули канал';

  @override
  String chatListLeaveFailed(String error) {
    return 'Не удалось покинуть канал: $error';
  }

  @override
  String chatListMuteFailed(String error) {
    return 'Не удалось выполнить действие: $error';
  }

  @override
  String get chatListMarkReadFailed => 'Не удалось отметить как прочитанное';

  @override
  String get createChannelTitle => 'Новый канал';

  @override
  String get createChannelNameLabel => 'Название канала';

  @override
  String get channelPublicLabel => 'Публичный канал';

  @override
  String get createChannelPublicAdminOnly =>
      'Только администраторы могут создавать публичные каналы';

  @override
  String get createChannelSubmit => 'Создать';

  @override
  String get createChannelNameRequired => 'Введите название канала';

  @override
  String get createChannelFailed => 'Не удалось создать канал';

  @override
  String get channelSettingsTitle => 'Настройки канала';

  @override
  String get channelUpdated => 'Канал обновлён';

  @override
  String get avatarUpdated => 'Аватар обновлён';

  @override
  String get channelVisibilityChanged => 'Видимость изменена';

  @override
  String get inviteLinkCopied => 'Ссылка скопирована';

  @override
  String get channelOverview => 'Обзор';

  @override
  String get channelNameLabel => 'Название';

  @override
  String get channelDescriptionLabel => 'Описание';

  @override
  String get channelSaveChanges => 'Сохранить изменения';

  @override
  String get channelAddMember => 'Добавить участника';

  @override
  String get channelInviteLinkSection => 'Ссылка-приглашение';

  @override
  String get channelGenerateInviteLink => 'Создать ссылку-приглашение';

  @override
  String get channelMuteLabel => 'Отключить уведомления канала';

  @override
  String get channelLeaveConfirmBody =>
      'Вы уверены, что хотите покинуть этот канал?';

  @override
  String get channelDeleteTitle => 'Удалить канал';

  @override
  String get channelDeleteConfirmBody =>
      'Канал будет безвозвратно удалён для всех участников. Это действие невозможно отменить.';

  @override
  String get actionLeave => 'Покинуть';

  @override
  String get accountEditNameTitle => 'Изменить имя';

  @override
  String get accountNameLabel => 'Имя';

  @override
  String get accountNameUpdated => 'Имя обновлено';

  @override
  String get accountChangePasswordTitle => 'Изменить пароль';

  @override
  String get accountCurrentPasswordLabel => 'Текущий пароль';

  @override
  String get accountNewPasswordLabel => 'Новый пароль';

  @override
  String get accountPasswordChanged => 'Пароль изменён';

  @override
  String get chatActionCopy => 'Копировать';

  @override
  String get chatActionForward => 'Переслать';

  @override
  String get chatActionSelect => 'Выбрать';

  @override
  String get chatCopiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get chatForwardedMessagePreview => '[Пересланное сообщение]';

  @override
  String get chatAutoDeleteTitle => 'Автоудаление сообщений';

  @override
  String chatExpiresTooltip(String duration) {
    return 'Исчезнет через $duration после отправки';
  }

  @override
  String get chatAutoDeleteOff => 'Выключено';

  @override
  String get chatAutoDelete5Min => '5 минут';

  @override
  String get chatAutoDelete10Min => '10 минут';

  @override
  String get chatAutoDelete1Hour => '1 час';

  @override
  String get chatAutoDelete1Day => '1 день';

  @override
  String get chatAutoDelete1Week => '1 неделя';

  @override
  String get chatAutoDeleteSaved => 'Сохранено';

  @override
  String get chatAutoDeleteSaveFailed => 'Не удалось сохранить';

  @override
  String get forwardSheetTitle => 'Переслать...';

  @override
  String get forwardMessageSent => 'Сообщение переслано';

  @override
  String forwardFailed(String error) {
    return 'Не удалось переслать: $error';
  }

  @override
  String get forwardNoConversations => 'Нет чатов';

  @override
  String forwardSelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get archiveForwardedLabel => 'Пересланное(ые) сообщение(я)';

  @override
  String get archiveLoadFailed => 'Не удалось загрузить пересланное сообщение';

  @override
  String get archiveTapToView => 'Нажмите, чтобы посмотреть подробности';

  @override
  String archiveViewAll(int count) {
    return 'Показать все $count сообщений';
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

  @override
  String get downloadInProgress => 'Загрузка…';

  @override
  String get downloadSaving => 'Сохранение…';

  @override
  String downloadSavedTo(String path) {
    return 'Сохранено в $path';
  }

  @override
  String get appearanceFontSize => 'Размер текста';

  @override
  String get appearanceFontSizeDescription =>
      'Перемещайте ползунок, чтобы изменить размер текста в приложении. Изменения сохраняются автоматически.';

  @override
  String get appearanceFontSizePreview =>
      'Выберите удобный размер текста для чтения и общения.';

  @override
  String appearanceFontSizeDefault(int percent) {
    return '$percent% (По умолчанию)';
  }

  @override
  String appearanceFontSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get appearanceFontSizeReset => 'Сбросить';

  @override
  String get appearanceFontSizeSaveFailed =>
      'Не удалось сохранить размер текста. Попробуйте ещё раз.';

  @override
  String get aboutGithubProject => 'GitHub project';

  @override
  String get aboutCheckUpdates => 'Check for updates';

  @override
  String get aboutGithubUpdateSource => 'VoceChat Nostalgic · GitHub Releases';

  @override
  String get aboutNoRelease => 'No published releases yet.';

  @override
  String aboutUpToDate(String version) {
    return 'Your version is up to date. GitHub release: $version';
  }

  @override
  String get aboutUpdateCheckFailed =>
      'Could not check for updates. Check your network and try again.';

  @override
  String get aboutViewRelease => 'View on GitHub';

  @override
  String get appearanceFontFamily => 'Шрифт';

  @override
  String get appearanceFontFamilySystem => 'Использовать системный шрифт';

  @override
  String get appearanceFontFamilyBundled => 'Шрифт приложения по умолчанию';

  @override
  String get appearanceFontFamilySaveFailed =>
      'Не удалось сохранить шрифт. Попробуйте ещё раз.';

  @override
  String get appearanceSystemFontUnavailable =>
      'Не удалось прочитать шрифт телефона. Используется стандартный системный шрифт.';
}
