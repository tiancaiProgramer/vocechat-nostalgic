// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VoceChat';

  @override
  String get appLoadingSlowTitle => 'Loading is taking longer than usual';

  @override
  String get appLoadingSlowBody =>
      'We are still trying to load the app. You can keep waiting or retry. Your saved accounts will not be removed.';

  @override
  String get appRecoveryTitle => 'Unable to display this page';

  @override
  String get appRecoveryBody =>
      'Something went wrong while loading the interface. Please retry. Your saved accounts will not be removed.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionOpen => 'Open';

  @override
  String get actionChange => 'Change';

  @override
  String get actionContact => 'Contact';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionSend => 'Send';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionMore => 'More';

  @override
  String get actionRetry => 'Retry';

  @override
  String get chatToolPin => 'Pinned';

  @override
  String get chatActionReact => 'Add reaction';

  @override
  String get chatActionReply => 'Reply';

  @override
  String get chatActionEdit => 'Edit';

  @override
  String get chatActionDelete => 'Delete';

  @override
  String get chatEditMarker => '(edited)';

  @override
  String chatReplyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get chatDeleteConfirmTitle => 'Delete message?';

  @override
  String get chatDeleteConfirmBody => 'This cannot be undone.';

  @override
  String get chatEditCancel => 'Cancel';

  @override
  String get chatEditSave => 'Save';

  @override
  String get chatFileDetailsTitle => 'File details';

  @override
  String get chatFileNameLabel => 'Name';

  @override
  String chatEditFailed(String error) {
    return 'Edit failed: $error';
  }

  @override
  String chatDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String chatReplyFailed(String error) {
    return 'Reply failed: $error';
  }

  @override
  String get chatReplyDeleted => 'This message has been deleted.';

  @override
  String get chatReplyVoiceMessage => '[Voice Message]';

  @override
  String get chatToolSaved => 'Saved';

  @override
  String get chatToolMembers => 'Members';

  @override
  String get chatToolEmpty => 'No content yet.';

  @override
  String get chatToolPinEmpty => 'No pinned messages.';

  @override
  String get chatToolSavedEmpty => 'No saved messages.';

  @override
  String get chatToolMembersEmpty => 'No members.';

  @override
  String get chatToolUnpin => 'Unpin';

  @override
  String get chatToolRemoveFav => 'Remove';

  @override
  String get chatToolPinFail => 'Pin failed';

  @override
  String get chatToolUnpinFail => 'Unpin failed';

  @override
  String get chatToolSaveFail => 'Save failed';

  @override
  String get chatToolRemoveFavFail => 'Remove failed';

  @override
  String get chatToolSavedAdded => 'Saved';

  @override
  String get chatToolPinAdded => 'Pinned';

  @override
  String get chatToolUnpinned => 'Unpinned';

  @override
  String get chatSearchHint => 'Search messages';

  @override
  String get chatSearchEmpty => 'No matching messages.';

  @override
  String get navChats => 'Chats';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navSettings => 'Settings';

  @override
  String get navSaved => 'Saved';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get memberRoleOwner => 'Owner';

  @override
  String get tooltipDownload => 'Download';

  @override
  String get downloadSaved => 'Saved';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get tooltipZoomIn => 'Zoom in';

  @override
  String get tooltipZoomOut => 'Zoom out';

  @override
  String get tooltipFullscreen => 'Fullscreen';

  @override
  String get tooltipExitFullscreen => 'Exit fullscreen';

  @override
  String get tooltipShowPassword => 'Show password';

  @override
  String get tooltipHidePassword => 'Hide password';

  @override
  String get reactionDeletedUser => 'Deleted User';

  @override
  String reactionTooltipMany(String names, int count, String emoji) {
    return '$names and $count others reacted with $emoji';
  }

  @override
  String reactionTooltipFew(String names, String emoji) {
    return '$names reacted with $emoji';
  }

  @override
  String get expiredImageTitle => 'Image not found';

  @override
  String get expiredImageBody => 'Image expired or deleted';

  @override
  String get expiredVideoTitle => 'Video not found';

  @override
  String get expiredVideoBody => 'Video expired or deleted';

  @override
  String get expiredAudioTitle => 'Audio not found';

  @override
  String get expiredAudioBody => 'Audio expired or deleted';

  @override
  String get expiredFileTitle => 'File not found';

  @override
  String get expiredFileBody => 'File expired or deleted';

  @override
  String get mediaLoadFailedRetry => 'Failed to load — tap to retry';

  @override
  String get mediaLikelyIncompatible =>
      'This device can\'t play this video format. Try downloading it instead.';

  @override
  String get featureUnavailable => 'This feature is not available yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupGeneral => 'general';

  @override
  String get settingsGroupAbout => 'about';

  @override
  String get settingsMyAccount => 'My Account';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsStorage => 'Storage & Data';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutConfirmTitle => 'Log out?';

  @override
  String get settingsLogoutConfirmContent =>
      'You will need to sign in again to access this server.';

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
  String get accountEmail => 'Email';

  @override
  String get accountUsername => 'Username';

  @override
  String get accountPassword => 'Password';

  @override
  String get accountPasswordMasked => '*********';

  @override
  String get notificationsPush => 'Message notifications';

  @override
  String get notificationsPushSubtitle =>
      'Get notified about new messages and mentions.';

  @override
  String get notificationsSound => 'Notification sounds';

  @override
  String get notificationsSoundSubtitle => 'Play a chime on incoming messages.';

  @override
  String get notificationsMentionsOnly => 'Mentions only';

  @override
  String get notificationsMentionsOnlySubtitle => 'Only notify for @mentions.';

  @override
  String get appearanceTheme => 'THEME';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceSystem => 'System default';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get appearanceLanguage => 'LANGUAGE';

  @override
  String get languageSystem => 'System default';

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
  String get storageUsage => 'Storage usage';

  @override
  String get storageAutoDownload => 'Auto-download media';

  @override
  String get storageWifiOnly => 'Wi-Fi only';

  @override
  String get storageClearCache => 'Clear cache';

  @override
  String get storageClearCacheConfirmTitle => 'Clear cache?';

  @override
  String get storageClearCacheConfirmBody =>
      'This removes locally cached messages and images. They will be re-downloaded as needed.';

  @override
  String get storageClearCacheConfirm => 'Clear';

  @override
  String get storageCacheCleared => 'Cache cleared';

  @override
  String get aboutAppVersion => 'App version';

  @override
  String get aboutServerVersion => 'Server version';

  @override
  String get aboutWebsite => 'Website';

  @override
  String get aboutReportBug => 'Report a bug';

  @override
  String get aboutReportBugSubtitle => 'Help us improve VoceChat.';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginEmailRequired => 'Email is required';

  @override
  String get loginEmailInvalid => 'Enter a valid email address';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginPasswordRequired => 'Password is required';

  @override
  String get loginPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginRememberMe => 'Remember password';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginMagicLink => 'Use magic link';

  @override
  String get loginPasskey => 'Sign in with passkey';

  @override
  String get loginSwitchServer => 'Switch server';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get loginErrorInvalidCredentials => 'Incorrect email or password';

  @override
  String get loginErrorAccountFrozen =>
      'This account has been frozen. Contact your admin.';

  @override
  String get loginErrorNotInvited =>
      'No associated account found. Ask an admin for an invitation link.';

  @override
  String get loginErrorMethodNotSupported =>
      'This login method isn\'t supported by the server.';

  @override
  String get loginErrorCannotReachServer =>
      'Can\'t reach the server. Check your network or the server URL.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerHeader => 'Join the conversation';

  @override
  String get registerSubtitle => 'Fill in your details to get started.';

  @override
  String get registerName => 'Full name';

  @override
  String get registerNameRequired => 'Name is required';

  @override
  String get registerNameTooShort => 'Name must be at least 2 characters';

  @override
  String get registerEmailRequired => 'Email is required';

  @override
  String get registerEmailInvalid => 'Enter a valid email';

  @override
  String get registerPasswordRequired => 'Password is required';

  @override
  String get registerPasswordTooShort => 'At least 6 characters required';

  @override
  String get registerConfirmPassword => 'Confirm password';

  @override
  String get registerConfirmRequired => 'Please confirm your password';

  @override
  String get registerConfirmMismatch => 'Passwords do not match';

  @override
  String get registerCreate => 'Create account';

  @override
  String get registerMagicLink => 'Send invitation link instead';

  @override
  String get registerEmailFirst => 'Please enter your email first';

  @override
  String get registerInvitationSent => 'Invitation link sent';

  @override
  String get registerHaveAccount => 'Already have an account? ';

  @override
  String get registerInviteRequiresEmailConfirmation =>
      'This server requires email confirmation for invited signups, which isn\'t supported yet. Please ask your admin for help.';

  @override
  String get serverPickerTitle => 'Select Server';

  @override
  String get serverPickerEmptyTitle => 'Connect to a VoceChat server';

  @override
  String get serverPickerEmptySubtitle =>
      'Add a server to get started chatting with your team.';

  @override
  String get serverPickerAddFirst => 'Add your first server';

  @override
  String get serverPickerAdd => 'Add server';

  @override
  String get serverPickerContinue => 'Continue';

  @override
  String get serverPickerUseInviteLink => 'Use invitation link';

  @override
  String get serverAddTitle => 'Add Server';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://chat.example.com';

  @override
  String get serverUrlRequired => 'URL is required';

  @override
  String get serverUrlMustHttps => 'Must start with http:// or https://';

  @override
  String get serverTesting => 'Testing…';

  @override
  String get serverTestConnection => 'Test connection';

  @override
  String get serverTestSuccess => 'Connection successful';

  @override
  String get serverTestFailed => 'Could not connect to server';

  @override
  String get serverSave => 'Save & Continue';

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
  String get chatListSearch => 'Search...';

  @override
  String get chatListNewChat => 'New chat';

  @override
  String get chatListLoading => 'Loading chats…';

  @override
  String get chatListUpdating => 'Updating…';

  @override
  String get chatListEmpty => 'No conversations yet';

  @override
  String chatListNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get chatListSelectTitle => 'Select a conversation';

  @override
  String get chatListSelectSubtitle =>
      'Pick a chat from the left panel to start messaging';

  @override
  String get chatListPin => 'Pin to top';

  @override
  String get chatListUnpin => 'Unpin';

  @override
  String chatListPinFailed(String error) {
    return 'Pin failed: $error';
  }

  @override
  String chatListUnpinFailed(String error) {
    return 'Unpin failed: $error';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '$count mins ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get contactsSearch => 'Search...';

  @override
  String get contactsAdd => 'Add contact';

  @override
  String get contactsLoading => 'Loading contacts…';

  @override
  String get contactsEmpty => 'No contacts found';

  @override
  String contactsSectionBot(int count) {
    return 'BOT - $count';
  }

  @override
  String contactsSectionContact(int count) {
    return 'CONTACT - $count';
  }

  @override
  String get contactsSelectTitle => 'Select a contact';

  @override
  String get contactsSelectSubtitle =>
      'Pick someone from the list to see their profile';

  @override
  String get contactsMessage => 'Message';

  @override
  String get contactsCall => 'Call';

  @override
  String get chatLoadingMessages => 'Loading messages…';

  @override
  String get chatStatusOnline => 'Online';

  @override
  String get chatStatusOffline => 'Offline';

  @override
  String get chatGroupIntro => 'Introduce yourself to the community!';

  @override
  String get chatEmpty => 'No messages yet';

  @override
  String chatSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String chatMessagePlaceholderChannel(String name) {
    return 'Message #$name';
  }

  @override
  String chatMessagePlaceholderUser(String name) {
    return 'Message $name';
  }

  @override
  String get chatPinned => 'pinned';

  @override
  String get chatUnsupported => '[unsupported message]';

  @override
  String get chatOpenLinkFailed =>
      'Could not open the link. Try again or copy it into your browser.';

  @override
  String get chatMarkdown => 'Markdown';

  @override
  String get chatAttach => 'Attach';

  @override
  String get chatVoiceMessage => 'Voice Message';

  @override
  String get chatVideoMessage => 'Video Message';

  @override
  String get chatVoiceRecording => 'Recording voice message';

  @override
  String get chatVoiceRecordingCancel => 'Cancel';

  @override
  String get chatVoiceRecordingSend => 'Send';

  @override
  String get chatRecordingPermissionDenied =>
      'Permission denied — enable microphone/camera access in system settings';

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
    return 'Send to $name';
  }

  @override
  String get chatDropOverlayHint => 'Drop files here to send them';

  @override
  String get chatMessageUnavailable =>
      'This message is no longer available or could not be loaded.';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String chatUserFallback(int uid) {
    return 'User $uid';
  }

  @override
  String chatGroupFallback(int gid) {
    return 'Group $gid';
  }

  @override
  String get previewFile => '[File]';

  @override
  String get previewVoice => '[Voice]';

  @override
  String get previewArchive => '[Archive]';

  @override
  String get previewImage => '[Image]';

  @override
  String get previewReaction => '[Reaction]';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get errorRequestFailed => 'Request failed';

  @override
  String get authKickedFromOtherDevice =>
      'Signed out: your account just signed in on another device.';

  @override
  String get authAccountDeleted => 'Your account has been deleted.';

  @override
  String get authSessionEnded => 'Your session ended. Please sign in again.';

  @override
  String get chatListMarkRead => 'Mark as read';

  @override
  String get chatListMute => 'Mute';

  @override
  String get chatListUnmute => 'Unmute';

  @override
  String get chatListHide => 'Hide';

  @override
  String get chatListLeave => 'Leave channel';

  @override
  String get chatListMarkReadDone => 'Marked as read';

  @override
  String get chatListMuteDone => 'Muted';

  @override
  String get chatListUnmuteDone => 'Unmuted';

  @override
  String get chatListHideDone => 'Hidden';

  @override
  String get chatListLeaveDone => 'Left channel';

  @override
  String chatListLeaveFailed(String error) {
    return 'Leave failed: $error';
  }

  @override
  String chatListMuteFailed(String error) {
    return 'Mute failed: $error';
  }

  @override
  String get chatListMarkReadFailed => 'Mark read failed';

  @override
  String get createChannelTitle => 'New Channel';

  @override
  String get createChannelNameLabel => 'Channel name';

  @override
  String get channelPublicLabel => 'Public channel';

  @override
  String get createChannelPublicAdminOnly =>
      'Only admins can create public channels';

  @override
  String get createChannelSubmit => 'Create';

  @override
  String get createChannelNameRequired => 'Please input a channel name';

  @override
  String get createChannelFailed => 'Failed to create channel';

  @override
  String get channelSettingsTitle => 'Channel settings';

  @override
  String get channelUpdated => 'Channel updated';

  @override
  String get avatarUpdated => 'Avatar updated';

  @override
  String get channelVisibilityChanged => 'Visibility changed';

  @override
  String get inviteLinkCopied => 'Link copied';

  @override
  String get channelOverview => 'Overview';

  @override
  String get channelNameLabel => 'Name';

  @override
  String get channelDescriptionLabel => 'Description';

  @override
  String get channelSaveChanges => 'Save changes';

  @override
  String get channelAddMember => 'Add member';

  @override
  String get channelInviteLinkSection => 'Invite link';

  @override
  String get channelGenerateInviteLink => 'Generate invite link';

  @override
  String get channelMuteLabel => 'Mute channel';

  @override
  String get channelLeaveConfirmBody =>
      'Are you sure you want to leave this channel?';

  @override
  String get channelDeleteTitle => 'Delete channel';

  @override
  String get channelDeleteConfirmBody =>
      'This will permanently delete the channel for all members. This cannot be undone.';

  @override
  String get actionLeave => 'Leave';

  @override
  String get accountEditNameTitle => 'Edit name';

  @override
  String get accountNameLabel => 'Name';

  @override
  String get accountNameUpdated => 'Name updated';

  @override
  String get accountChangePasswordTitle => 'Change password';

  @override
  String get accountCurrentPasswordLabel => 'Current password';

  @override
  String get accountNewPasswordLabel => 'New password';

  @override
  String get accountPasswordChanged => 'Password changed';

  @override
  String get chatActionCopy => 'Copy';

  @override
  String get chatActionForward => 'Forward';

  @override
  String get chatActionSelect => 'Select';

  @override
  String get chatCopiedToClipboard => 'Copied to clipboard';

  @override
  String get chatForwardedMessagePreview => '[Forwarded message]';

  @override
  String get chatAutoDeleteTitle => 'Auto-delete messages';

  @override
  String chatExpiresTooltip(String duration) {
    return 'Automatically deleted $duration after being sent';
  }

  @override
  String get chatAutoDeleteOff => 'Off';

  @override
  String get chatAutoDelete5Min => '5 minutes';

  @override
  String get chatAutoDelete10Min => '10 minutes';

  @override
  String get chatAutoDelete1Hour => '1 hour';

  @override
  String get chatAutoDelete1Day => '1 day';

  @override
  String get chatAutoDelete1Week => '1 week';

  @override
  String get chatAutoDeleteSaved => 'Saved';

  @override
  String get chatAutoDeleteSaveFailed => 'Save failed';

  @override
  String get forwardSheetTitle => 'Forward to...';

  @override
  String get forwardMessageSent => 'Message forwarded';

  @override
  String forwardFailed(String error) {
    return 'Forward failed: $error';
  }

  @override
  String get forwardNoConversations => 'No conversations';

  @override
  String forwardSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get archiveForwardedLabel => 'Forwarded message(s)';

  @override
  String get archiveLoadFailed => 'Failed to load forwarded message';

  @override
  String get archiveTapToView => 'Tap to view details';

  @override
  String archiveViewAll(int count) {
    return 'View all $count messages';
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
