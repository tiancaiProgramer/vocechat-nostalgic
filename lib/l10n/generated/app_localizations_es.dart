// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppL10nEs extends AppL10n {
  AppL10nEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'VoceChat';

  @override
  String get appLoadingSlowTitle => 'La carga está tardando más de lo habitual';

  @override
  String get appLoadingSlowBody =>
      'Seguimos intentando cargar la aplicación. Puedes seguir esperando o volver a intentarlo. Tus cuentas guardadas no se eliminarán.';

  @override
  String get appRecoveryTitle => 'No se puede mostrar esta página';

  @override
  String get appRecoveryBody =>
      'Se produjo un error al cargar la interfaz. Vuelve a intentarlo. Tus cuentas guardadas no se eliminarán.';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get actionChange => 'Cambiar';

  @override
  String get actionContact => 'Contacto';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionSend => 'Enviar';

  @override
  String get actionSearch => 'Buscar';

  @override
  String get actionMore => 'Más';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get chatToolPin => 'Fijado';

  @override
  String get chatActionReact => 'Añadir reacción';

  @override
  String get chatActionReply => 'Responder';

  @override
  String get chatActionEdit => 'Editar';

  @override
  String get chatActionDelete => 'Eliminar';

  @override
  String get chatEditMarker => '(editado)';

  @override
  String chatReplyingTo(String name) {
    return 'Respondiendo a $name';
  }

  @override
  String get chatDeleteConfirmTitle => '¿Eliminar mensaje?';

  @override
  String get chatDeleteConfirmBody => 'Esta acción no se puede deshacer.';

  @override
  String get chatEditCancel => 'Cancelar';

  @override
  String get chatEditSave => 'Guardar';

  @override
  String get chatFileDetailsTitle => 'Detalles del archivo';

  @override
  String get chatFileNameLabel => 'Nombre';

  @override
  String chatEditFailed(String error) {
    return 'Error al editar: $error';
  }

  @override
  String chatDeleteFailed(String error) {
    return 'Error al eliminar: $error';
  }

  @override
  String chatReplyFailed(String error) {
    return 'Error al responder: $error';
  }

  @override
  String get chatReplyDeleted => 'Este mensaje ha sido eliminado.';

  @override
  String get chatReplyVoiceMessage => '[Mensaje de voz]';

  @override
  String get chatToolSaved => 'Guardado';

  @override
  String get chatToolMembers => 'Miembros';

  @override
  String get chatToolEmpty => 'Todavía no hay contenido.';

  @override
  String get chatToolPinEmpty => 'No hay mensajes fijados.';

  @override
  String get chatToolSavedEmpty => 'No hay mensajes guardados.';

  @override
  String get chatToolMembersEmpty => 'No hay miembros.';

  @override
  String get chatToolUnpin => 'Desfijar';

  @override
  String get chatToolRemoveFav => 'Quitar';

  @override
  String get chatToolPinFail => 'Error al fijar';

  @override
  String get chatToolUnpinFail => 'Error al desfijar';

  @override
  String get chatToolSaveFail => 'Error al guardar';

  @override
  String get chatToolRemoveFavFail => 'Error al quitar';

  @override
  String get chatToolSavedAdded => 'Guardado';

  @override
  String get chatToolPinAdded => 'Fijado';

  @override
  String get chatToolUnpinned => 'Desfijado';

  @override
  String get chatSearchHint => 'Buscar mensajes';

  @override
  String get chatSearchEmpty => 'No hay mensajes coincidentes.';

  @override
  String get navChats => 'Chats';

  @override
  String get navContacts => 'Contactos';

  @override
  String get navSettings => 'Configuración';

  @override
  String get navSaved => 'Guardados';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get memberRoleOwner => 'Propietario';

  @override
  String get tooltipDownload => 'Descargar';

  @override
  String get downloadSaved => 'Saved';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get tooltipZoomIn => 'Acercar';

  @override
  String get tooltipZoomOut => 'Alejar';

  @override
  String get tooltipFullscreen => 'Pantalla completa';

  @override
  String get tooltipExitFullscreen => 'Salir de pantalla completa';

  @override
  String get tooltipShowPassword => 'Mostrar contraseña';

  @override
  String get tooltipHidePassword => 'Ocultar contraseña';

  @override
  String get reactionDeletedUser => 'Usuario eliminado';

  @override
  String reactionTooltipMany(String names, int count, String emoji) {
    return '$names y $count más reaccionaron con $emoji';
  }

  @override
  String reactionTooltipFew(String names, String emoji) {
    return '$names reaccionaron con $emoji';
  }

  @override
  String get expiredImageTitle => 'Imagen no encontrada';

  @override
  String get expiredImageBody => 'La imagen expiró o fue eliminada';

  @override
  String get expiredVideoTitle => 'Video no encontrado';

  @override
  String get expiredVideoBody => 'El video expiró o fue eliminado';

  @override
  String get expiredAudioTitle => 'Audio no encontrado';

  @override
  String get expiredAudioBody => 'El audio expiró o fue eliminado';

  @override
  String get expiredFileTitle => 'Archivo no encontrado';

  @override
  String get expiredFileBody => 'El archivo expiró o fue eliminado';

  @override
  String get mediaLoadFailedRetry => 'Failed to load — tap to retry';

  @override
  String get mediaLikelyIncompatible =>
      'This device can\'t play this video format. Try downloading it instead.';

  @override
  String get featureUnavailable => 'Esta función no está disponible todavía';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsGroupGeneral => 'general';

  @override
  String get settingsGroupAbout => 'acerca de';

  @override
  String get settingsMyAccount => 'Mi cuenta';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsStorage => 'Almacenamiento y datos';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsLogout => 'Cerrar sesión';

  @override
  String get settingsLogoutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get settingsLogoutConfirmContent =>
      'Deberás iniciar sesión de nuevo para acceder a este servidor.';

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
  String get accountEmail => 'Correo electrónico';

  @override
  String get accountUsername => 'Nombre de usuario';

  @override
  String get accountPassword => 'Contraseña';

  @override
  String get accountPasswordMasked => '*********';

  @override
  String get notificationsPush => 'Notificaciones push';

  @override
  String get notificationsPushSubtitle =>
      'Recibe avisos de nuevos mensajes y menciones.';

  @override
  String get notificationsSound => 'Sonidos de notificación';

  @override
  String get notificationsSoundSubtitle =>
      'Reproduce un sonido al recibir mensajes.';

  @override
  String get notificationsMentionsOnly => 'Solo menciones';

  @override
  String get notificationsMentionsOnlySubtitle =>
      'Notificar solo para @menciones.';

  @override
  String get appearanceTheme => 'TEMA';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceSystem => 'Predeterminado del sistema';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get appearanceLanguage => 'IDIOMA';

  @override
  String get languageSystem => 'Predeterminado del sistema';

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
  String get storageUsage => 'Uso de almacenamiento';

  @override
  String get storageAutoDownload => 'Descargar multimedia automáticamente';

  @override
  String get storageWifiOnly => 'Solo Wi-Fi';

  @override
  String get storageClearCache => 'Borrar caché';

  @override
  String get storageClearCacheConfirmTitle => '¿Borrar caché?';

  @override
  String get storageClearCacheConfirmBody =>
      'Esto elimina los mensajes e imágenes almacenados localmente. Se volverán a descargar cuando sea necesario.';

  @override
  String get storageClearCacheConfirm => 'Borrar';

  @override
  String get storageCacheCleared => 'Caché borrada';

  @override
  String get aboutAppVersion => 'Versión de la app';

  @override
  String get aboutServerVersion => 'Versión del servidor';

  @override
  String get aboutWebsite => 'Sitio web';

  @override
  String get aboutReportBug => 'Reportar un error';

  @override
  String get aboutReportBugSubtitle => 'Ayúdanos a mejorar VoceChat.';

  @override
  String get loginWelcomeBack => 'Bienvenido de nuevo';

  @override
  String get loginEmail => 'Correo electrónico';

  @override
  String get loginEmailRequired => 'El correo electrónico es obligatorio';

  @override
  String get loginEmailInvalid => 'Introduce una dirección de correo válida';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get loginPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get loginForgotPassword => '¿Olvidaste tu contraseña?';

  @override
  String get loginRememberMe => 'Recordar contraseña';

  @override
  String get loginSignIn => 'Iniciar sesión';

  @override
  String get loginMagicLink => 'Usar enlace mágico';

  @override
  String get loginPasskey => 'Iniciar sesión con clave de acceso';

  @override
  String get loginSwitchServer => 'Cambiar de servidor';

  @override
  String get loginNoAccount => '¿No tienes una cuenta? ';

  @override
  String get loginSignUp => 'Registrarse';

  @override
  String get loginErrorInvalidCredentials =>
      'Correo electrónico o contraseña incorrectos';

  @override
  String get loginErrorAccountFrozen =>
      'Esta cuenta ha sido congelada. Contacta con tu administrador.';

  @override
  String get loginErrorNotInvited =>
      'No se encontró ninguna cuenta asociada. Pide a un administrador un enlace de invitación.';

  @override
  String get loginErrorMethodNotSupported =>
      'El servidor no admite este método de inicio de sesión.';

  @override
  String get loginErrorCannotReachServer =>
      'No se puede contactar con el servidor. Comprueba tu red o la URL del servidor.';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get registerHeader => 'Únete a la conversación';

  @override
  String get registerSubtitle => 'Completa tus datos para empezar.';

  @override
  String get registerName => 'Nombre completo';

  @override
  String get registerNameRequired => 'El nombre es obligatorio';

  @override
  String get registerNameTooShort =>
      'El nombre debe tener al menos 2 caracteres';

  @override
  String get registerEmailRequired => 'El correo electrónico es obligatorio';

  @override
  String get registerEmailInvalid => 'Introduce un correo electrónico válido';

  @override
  String get registerPasswordRequired => 'La contraseña es obligatoria';

  @override
  String get registerPasswordTooShort => 'Se requieren al menos 6 caracteres';

  @override
  String get registerConfirmPassword => 'Confirmar contraseña';

  @override
  String get registerConfirmRequired => 'Confirma tu contraseña';

  @override
  String get registerConfirmMismatch => 'Las contraseñas no coinciden';

  @override
  String get registerCreate => 'Crear cuenta';

  @override
  String get registerMagicLink => 'Enviar enlace de invitación en su lugar';

  @override
  String get registerEmailFirst => 'Introduce primero tu correo electrónico';

  @override
  String get registerInvitationSent => 'Enlace de invitación enviado';

  @override
  String get registerHaveAccount => '¿Ya tienes una cuenta? ';

  @override
  String get registerInviteRequiresEmailConfirmation =>
      'This server requires email confirmation for invited signups, which isn\'t supported yet. Please ask your admin for help.';

  @override
  String get serverPickerTitle => 'Seleccionar servidor';

  @override
  String get serverPickerEmptyTitle => 'Conéctate a un servidor VoceChat';

  @override
  String get serverPickerEmptySubtitle =>
      'Agrega un servidor para empezar a chatear con tu equipo.';

  @override
  String get serverPickerAddFirst => 'Agrega tu primer servidor';

  @override
  String get serverPickerAdd => 'Agregar servidor';

  @override
  String get serverPickerContinue => 'Continuar';

  @override
  String get serverPickerUseInviteLink => 'Use invitation link';

  @override
  String get serverAddTitle => 'Agregar servidor';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String get serverUrlHint => 'https://chat.example.com';

  @override
  String get serverUrlRequired => 'La URL es obligatoria';

  @override
  String get serverUrlMustHttps => 'Debe empezar con http:// o https://';

  @override
  String get serverTesting => 'Probando…';

  @override
  String get serverTestConnection => 'Probar conexión';

  @override
  String get serverTestSuccess => 'Conexión exitosa';

  @override
  String get serverTestFailed => 'No se pudo conectar con el servidor';

  @override
  String get serverSave => 'Guardar y continuar';

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
  String get chatListSearch => 'Buscar...';

  @override
  String get chatListNewChat => 'Nuevo chat';

  @override
  String get chatListLoading => 'Cargando chats…';

  @override
  String get chatListUpdating => 'Actualizando…';

  @override
  String get chatListEmpty => 'Todavía no hay conversaciones';

  @override
  String chatListNoResults(String query) {
    return 'No hay resultados para \"$query\"';
  }

  @override
  String get chatListSelectTitle => 'Selecciona una conversación';

  @override
  String get chatListSelectSubtitle =>
      'Elige un chat del panel izquierdo para empezar a escribir';

  @override
  String get chatListPin => 'Fijar arriba';

  @override
  String get chatListUnpin => 'Desfijar';

  @override
  String chatListPinFailed(String error) {
    return 'Error al fijar: $error';
  }

  @override
  String chatListUnpinFailed(String error) {
    return 'Error al desfijar: $error';
  }

  @override
  String get timeJustNow => 'justo ahora';

  @override
  String timeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'hace $count horas';
  }

  @override
  String timeDaysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String get contactsSearch => 'Buscar...';

  @override
  String get contactsAdd => 'Agregar contacto';

  @override
  String get contactsLoading => 'Cargando contactos…';

  @override
  String get contactsEmpty => 'No se encontraron contactos';

  @override
  String contactsSectionBot(int count) {
    return 'BOT - $count';
  }

  @override
  String contactsSectionContact(int count) {
    return 'CONTACTO - $count';
  }

  @override
  String get contactsSelectTitle => 'Selecciona un contacto';

  @override
  String get contactsSelectSubtitle =>
      'Elige a alguien de la lista para ver su perfil';

  @override
  String get contactsMessage => 'Mensaje';

  @override
  String get contactsCall => 'Llamar';

  @override
  String get chatLoadingMessages => 'Cargando mensajes…';

  @override
  String get chatStatusOnline => 'En línea';

  @override
  String get chatStatusOffline => 'Desconectado';

  @override
  String get chatGroupIntro => '¡Preséntate a la comunidad!';

  @override
  String get chatEmpty => 'Todavía no hay mensajes';

  @override
  String chatSendFailed(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String chatMessagePlaceholderChannel(String name) {
    return 'Mensaje a #$name';
  }

  @override
  String chatMessagePlaceholderUser(String name) {
    return 'Mensaje a $name';
  }

  @override
  String get chatPinned => 'fijado';

  @override
  String get chatUnsupported => '[mensaje no compatible]';

  @override
  String get chatOpenLinkFailed =>
      'No se pudo abrir el enlace. Inténtalo de nuevo o cópialo en tu navegador.';

  @override
  String get chatMarkdown => 'Markdown';

  @override
  String get chatAttach => 'Adjuntar';

  @override
  String get chatVoiceMessage => 'Mensaje de voz';

  @override
  String get chatVideoMessage => 'Mensaje de video';

  @override
  String get chatVoiceRecording => 'Grabando mensaje de voz';

  @override
  String get chatVoiceRecordingCancel => 'Cancelar';

  @override
  String get chatVoiceRecordingSend => 'Enviar';

  @override
  String get chatRecordingPermissionDenied =>
      'Permiso denegado: habilita el acceso al micrófono o la cámara en la configuración del sistema';

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
    return 'Enviar a $name';
  }

  @override
  String get chatDropOverlayHint => 'Suelta los archivos aquí para enviarlos';

  @override
  String get chatMessageUnavailable =>
      'Este mensaje ya no está disponible o no se pudo cargar.';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String chatUserFallback(int uid) {
    return 'Usuario $uid';
  }

  @override
  String chatGroupFallback(int gid) {
    return 'Grupo $gid';
  }

  @override
  String get previewFile => '[Archivo]';

  @override
  String get previewVoice => '[Voz]';

  @override
  String get previewArchive => '[Archivo comprimido]';

  @override
  String get previewImage => '[Imagen]';

  @override
  String get previewReaction => '[Reacción]';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get errorRequestFailed => 'Error en la solicitud';

  @override
  String get authKickedFromOtherDevice =>
      'Sesión cerrada: tu cuenta acaba de iniciar sesión en otro dispositivo.';

  @override
  String get authAccountDeleted => 'Tu cuenta ha sido eliminada.';

  @override
  String get authSessionEnded =>
      'Tu sesión ha finalizado. Inicia sesión de nuevo.';

  @override
  String get chatListMarkRead => 'Marcar como leído';

  @override
  String get chatListMute => 'Silenciar';

  @override
  String get chatListUnmute => 'Quitar silencio';

  @override
  String get chatListHide => 'Ocultar';

  @override
  String get chatListLeave => 'Abandonar canal';

  @override
  String get chatListMarkReadDone => 'Marcado como leído';

  @override
  String get chatListMuteDone => 'Silenciado';

  @override
  String get chatListUnmuteDone => 'Silencio desactivado';

  @override
  String get chatListHideDone => 'Oculto';

  @override
  String get chatListLeaveDone => 'Canal abandonado';

  @override
  String chatListLeaveFailed(String error) {
    return 'Error al abandonar: $error';
  }

  @override
  String chatListMuteFailed(String error) {
    return 'Error al silenciar: $error';
  }

  @override
  String get chatListMarkReadFailed => 'Error al marcar como leído';

  @override
  String get createChannelTitle => 'Nuevo canal';

  @override
  String get createChannelNameLabel => 'Nombre del canal';

  @override
  String get channelPublicLabel => 'Canal público';

  @override
  String get createChannelPublicAdminOnly =>
      'Solo los administradores pueden crear canales públicos';

  @override
  String get createChannelSubmit => 'Crear';

  @override
  String get createChannelNameRequired => 'Introduce un nombre para el canal';

  @override
  String get createChannelFailed => 'Error al crear el canal';

  @override
  String get channelSettingsTitle => 'Configuración del canal';

  @override
  String get channelUpdated => 'Canal actualizado';

  @override
  String get avatarUpdated => 'Avatar actualizado';

  @override
  String get channelVisibilityChanged => 'Visibilidad cambiada';

  @override
  String get inviteLinkCopied => 'Enlace copiado';

  @override
  String get channelOverview => 'Resumen';

  @override
  String get channelNameLabel => 'Nombre';

  @override
  String get channelDescriptionLabel => 'Descripción';

  @override
  String get channelSaveChanges => 'Guardar cambios';

  @override
  String get channelAddMember => 'Agregar miembro';

  @override
  String get channelInviteLinkSection => 'Enlace de invitación';

  @override
  String get channelGenerateInviteLink => 'Generar enlace de invitación';

  @override
  String get channelMuteLabel => 'Silenciar canal';

  @override
  String get channelLeaveConfirmBody =>
      '¿Seguro que quieres abandonar este canal?';

  @override
  String get channelDeleteTitle => 'Eliminar canal';

  @override
  String get channelDeleteConfirmBody =>
      'Esto eliminará permanentemente el canal para todos los miembros. Esta acción no se puede deshacer.';

  @override
  String get actionLeave => 'Abandonar';

  @override
  String get accountEditNameTitle => 'Editar nombre';

  @override
  String get accountNameLabel => 'Nombre';

  @override
  String get accountNameUpdated => 'Nombre actualizado';

  @override
  String get accountChangePasswordTitle => 'Cambiar contraseña';

  @override
  String get accountCurrentPasswordLabel => 'Contraseña actual';

  @override
  String get accountNewPasswordLabel => 'Nueva contraseña';

  @override
  String get accountPasswordChanged => 'Contraseña cambiada';

  @override
  String get chatActionCopy => 'Copiar';

  @override
  String get chatActionForward => 'Reenviar';

  @override
  String get chatActionSelect => 'Seleccionar';

  @override
  String get chatCopiedToClipboard => 'Copiado al portapapeles';

  @override
  String get chatForwardedMessagePreview => '[Mensaje reenviado]';

  @override
  String get chatAutoDeleteTitle => 'Eliminación automática de mensajes';

  @override
  String chatExpiresTooltip(String duration) {
    return 'Desaparece $duration después de enviarse';
  }

  @override
  String get chatAutoDeleteOff => 'Desactivado';

  @override
  String get chatAutoDelete5Min => '5 minutos';

  @override
  String get chatAutoDelete10Min => '10 minutos';

  @override
  String get chatAutoDelete1Hour => '1 hora';

  @override
  String get chatAutoDelete1Day => '1 día';

  @override
  String get chatAutoDelete1Week => '1 semana';

  @override
  String get chatAutoDeleteSaved => 'Guardado';

  @override
  String get chatAutoDeleteSaveFailed => 'Error al guardar';

  @override
  String get forwardSheetTitle => 'Reenviar a...';

  @override
  String get forwardMessageSent => 'Mensaje reenviado';

  @override
  String forwardFailed(String error) {
    return 'Error al reenviar: $error';
  }

  @override
  String get forwardNoConversations => 'No hay conversaciones';

  @override
  String forwardSelectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get archiveForwardedLabel => 'Mensaje(s) reenviado(s)';

  @override
  String get archiveLoadFailed => 'Error al cargar el mensaje reenviado';

  @override
  String get archiveTapToView => 'Toca para ver detalles';

  @override
  String archiveViewAll(int count) {
    return 'Ver los $count mensajes';
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
  String get downloadInProgress => 'Descargando…';

  @override
  String get downloadSaving => 'Guardando…';

  @override
  String downloadSavedTo(String path) {
    return 'Guardado en $path';
  }

  @override
  String get appearanceFontSize => 'Tamaño del texto';

  @override
  String get appearanceFontSizeDescription =>
      'Desliza para ajustar el tamaño del texto en toda la app. Los cambios se guardan automáticamente.';

  @override
  String get appearanceFontSizePreview =>
      'Elige un tamaño cómodo para leer y conversar.';

  @override
  String appearanceFontSizeDefault(int percent) {
    return '$percent% (Predeterminado)';
  }

  @override
  String appearanceFontSizeValue(int percent) {
    return '$percent%';
  }

  @override
  String get appearanceFontSizeReset => 'Restablecer';

  @override
  String get appearanceFontSizeSaveFailed =>
      'No se pudo guardar el tamaño del texto. Inténtalo de nuevo.';

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
  String get appearanceFontFamily => 'Fuente';

  @override
  String get appearanceFontFamilySystem => 'Usar fuente del sistema';

  @override
  String get appearanceFontFamilyBundled => 'Fuente predeterminada de la app';

  @override
  String get appearanceFontFamilySaveFailed =>
      'No se pudo guardar la fuente. Inténtalo de nuevo.';

  @override
  String get appearanceSystemFontUnavailable =>
      'No se pudo leer la fuente del teléfono. Se usa la fuente estándar del sistema.';
}
