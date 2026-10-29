# Large file attachments (3117)

The previous file-picker flow requested `withData: true`, retained a complete
attachment buffer, tried to image-decode even non-image attachments, and sent
the entire file as one multipart request. A roughly 150 MB APK could therefore
exhaust Java/native/Dart memory before upload completed. The connected phone
had no retained stack trace for the reported event, so this is a code-confirmed
memory hazard rather than a captured OOM diagnosis for that exact incident.

The file picker now requests paths (`withData: false`). Generic attachments are
staged with path/name/type/length; only a 512-byte prefix is read for detection.
Existing photo conversion and memory-backed clipboard/voice previews remain.
APK/video/document uploads do not invoke the image decoder.

`MessageApi` uses the existing prepare/append/finalize protocol with sequential
512 KiB multipart chunks. Disk sources stream only the current range; clipboard
buffers use range views. Multipart overhead stays below a 1 MiB Nginx request
limit. Progress is cumulative; the final file message is sent only after the
server returns a path and (if present) a matching length. Manual retry prepares
a fresh file ID; uncertain append requests are not automatically replayed.
Account/controller disposal, message deletion, and expiry cancel pending work.

The original file-picker cache must remain available for retry. Pending file
paths are not persisted across app restarts. Large image originals still use
the preexisting photo conversion path; this change is not an image-size-limit
or image-decoding redesign. Gallery/camera acquisition and system sharing keep
their existing behavior and limits.

Protocol reference:
https://github.com/Privoce/vocechat-server-rust/blob/master/src/api/resource.rs

Verification:
- A 150 MiB + 17 byte APK uses bounded reads, produces 301 chunks, and matches
  the source SHA256 after streamed multipart parsing and append.
- Failed append/retry, empty file, cancellation between chunks, voice protocol,
  optimistic file state, and the file-picker/staging/send UI are covered.
- Actual send/delivery with the user's server still requires a real-device test.

First real-device attempt (2026-10-29): the original APK (about 141.4 MiB as
shown by the app) progressed past 60% without process death. Sampled PSS stayed
around 181–186 MiB during the observed transfer interval, but the attempt later
showed send-failed. This does not yet establish successful server delivery.
Safe diagnostic events were added for prepare/chunk/finalize/message failures;
they contain fixed stage/type, byte counts and HTTP codes only, never file names,
auth headers, resource IDs or response bodies. Further real-device diagnosis is
pending. No GitHub publication or server changes.
