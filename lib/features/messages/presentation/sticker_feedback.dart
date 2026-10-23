import '../../../l10n/generated/app_localizations.dart';
import '../data/custom_sticker_store.dart';

String stickerErrorLabel(AppL10n l, Object error) => switch (error) {
      StickerException(reason: StickerFailure.tooLarge) => l.stickerTooLarge,
      StickerException(reason: StickerFailure.unsupported) =>
        l.stickerUnsupported,
      StickerException(reason: StickerFailure.missing) => l.stickerMissing,
      StickerException(reason: StickerFailure.download) =>
        l.stickerDownloadFailed,
      _ => l.stickerOperationFailed,
    };
