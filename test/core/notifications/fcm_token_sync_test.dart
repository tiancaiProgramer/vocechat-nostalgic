import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocechat_client/core/notifications/fcm_token_sync.dart';

void main() {
  test('switching methods removes FCM registration without probing Google',
      () async {
    final uploads = <String?>[];
    final events = <String>[];
    final sync = FcmTokenSync(
        getToken: () async {
          events.add('probe');
          return 'token';
        },
        upload: (token, _) async {
          uploads.add(token);
          events.add('upload:$token');
        },
        onPhase: (phase) => events.add(phase.name),
        retryDelay: null);
    addTearDown(sync.dispose);
    await sync.update(account: 'server::1', enabled: true, keepAlive: false);
    expect(uploads, ['token']);
    expect(events.last, 'registered');
    events.clear();
    await sync.update(account: 'server::1', enabled: true, keepAlive: true);
    expect(uploads, ['token', null]);
    expect(events, isNot(contains('probe')));
    expect(events.last, 'standby');
    await sync.update(account: 'server::1', enabled: true, keepAlive: false);
    expect(uploads.last, 'token');
  });

  test('background mode works even when Google token retrieval would fail',
      () async {
    final uploads = <String?>[];
    final phases = <FcmPhase>[];
    final sync = FcmTokenSync(
        getToken: () async => throw StateError('Google unavailable'),
        upload: (token, _) async => uploads.add(token),
        onPhase: phases.add,
        retryDelay: null);
    addTearDown(sync.dispose);
    await sync.update(account: 'server::1', enabled: true, keepAlive: true);
    expect(uploads, [null]);
    expect(phases.last, FcmPhase.standby);
  });

  test('turning notifications off unregisters without contacting Google',
      () async {
    final uploads = <String?>[];
    var fetched = false;
    final phases = <FcmPhase>[];
    final sync = FcmTokenSync(
        getToken: () async {
          fetched = true;
          return 'token';
        },
        upload: (token, _) async => uploads.add(token),
        onPhase: phases.add,
        retryDelay: null);
    addTearDown(sync.dispose);
    await sync.update(account: 'server::1', enabled: false, keepAlive: false);
    expect(uploads, [null]);
    expect(fetched, isFalse);
    expect(phases.last, FcmPhase.disabled);
  });

  test('late token after switching to background is never registered',
      () async {
    final token = Completer<String>();
    final started = Completer<void>();
    final uploads = <String?>[];
    final sync = FcmTokenSync(
        getToken: () {
          started.complete();
          return token.future;
        },
        upload: (value, _) async => uploads.add(value),
        onPhase: (_) {},
        retryDelay: null);
    addTearDown(sync.dispose);
    final fcm =
        sync.update(account: 'server::1', enabled: true, keepAlive: false);
    await started.future;
    final background =
        sync.update(account: 'server::1', enabled: true, keepAlive: true);
    token.complete('late-token');
    await Future.wait([fcm, background]);
    expect(uploads, [null]);
  });

  test('late token for a replaced account is never uploaded', () async {
    final firstToken = Completer<String>();
    final started = Completer<void>();
    var reads = 0;
    final uploads = <String?>[];
    final sync = FcmTokenSync(
        getToken: () {
          if (++reads == 1) {
            started.complete();
            return firstToken.future;
          }
          return Future.value('new-account-token');
        },
        upload: (token, _) async => uploads.add(token),
        onPhase: (_) {},
        retryDelay: null);
    addTearDown(sync.dispose);
    final old = sync.update(account: 'old::1', enabled: true, keepAlive: false);
    await started.future;
    final next =
        sync.update(account: 'new::2', enabled: true, keepAlive: false);
    firstToken.complete('old-account-token');
    await Future.wait([old, next]);
    expect(uploads, ['new-account-token']);
  });

  test('registration changes are serialized and latest disabled state wins',
      () async {
    final sent = Completer<void>();
    final completed = Completer<void>();
    final uploads = <String?>[];
    final sync = FcmTokenSync(
        getToken: () async => 'token',
        upload: (token, _) async {
          uploads.add(token);
          if (token != null) {
            sent.complete();
            await completed.future;
          }
        },
        onPhase: (_) {},
        retryDelay: null);
    addTearDown(sync.dispose);
    final first =
        sync.update(account: 'server::1', enabled: true, keepAlive: false);
    await sent.future;
    final off =
        sync.update(account: 'server::1', enabled: false, keepAlive: false);
    expect(uploads, ['token']);
    completed.complete();
    await Future.wait([first, off]);
    expect(uploads, ['token', null]);
  });

  test('registration errors are visible and a later retry recovers', () async {
    var fail = true;
    final phases = <FcmPhase>[];
    final sync = FcmTokenSync(
        getToken: () async => 'token',
        upload: (_, __) async {
          if (fail) throw StateError('unreachable');
        },
        onPhase: phases.add,
        retryDelay: null);
    addTearDown(sync.dispose);
    await sync.update(account: 'server::1', enabled: true, keepAlive: false);
    expect(phases.last, FcmPhase.unavailable);
    fail = false;
    await sync.update(account: 'server::1', enabled: true, keepAlive: false);
    expect(phases.last, FcmPhase.registered);
  });

  test('disposal cancels request and cannot report a stale success', () async {
    final sent = Completer<void>();
    final completed = Completer<void>();
    late CancelToken request;
    final phases = <FcmPhase>[];
    final sync = FcmTokenSync(
        getToken: () async => 'token',
        upload: (_, cancel) async {
          request = cancel;
          sent.complete();
          await completed.future;
        },
        onPhase: phases.add,
        retryDelay: null);
    final update =
        sync.update(account: 'server::1', enabled: true, keepAlive: false);
    await sent.future;
    sync.dispose();
    expect(request.isCancelled, isTrue);
    completed.complete();
    await update;
    expect(phases, [FcmPhase.connecting]);
  });
}
