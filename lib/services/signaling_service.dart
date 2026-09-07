import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import 'runtime_config.dart';

enum ConnStatus { connecting, connected, disconnected }

class SignalingService {
  PusherChannelsClient? _client;
  StreamSubscription<PusherChannelsClientLifeCycleState>? _lifecycleSub;

  void Function(Map<String, dynamic>)? onIncomingCall;
  void Function(Map<String, dynamic>)? onSignal;
  void Function(ConnStatus)? onStatus;

  Future<void> connect({
    required String serverUrl,
    required String deviceId,
    RuntimeConfig? config,
    String? authToken, // gardé pour compatibilité, mais non utilisé
  }) async {
    await disconnect();

    PusherChannelsPackageLogger.enableLogs();

    final uri = Uri.parse(serverUrl);
    final secure = uri.scheme == 'https';

    final rawScheme = config?.reverbScheme.isNotEmpty == true
        ? config!.reverbScheme
        : (secure ? 'https' : 'http');
    final scheme = rawScheme == 'https' ? 'wss' : 'ws';
    final host = config?.reverbHost.isNotEmpty == true
        ? config!.reverbHost
        : uri.host;
    final port = config?.reverbPort ?? (secure ? 443 : 8080);
    final key = config?.reverbKey.isNotEmpty == true ? config!.reverbKey : 'local';

    debugPrint('[YAM][WS] connexion Reverb → $scheme://$host:$port (clé $key)');

    // Utilisation de fromHost (sans auth) – canal public
    final options = PusherChannelsOptions.fromHost(
      scheme: scheme,
      host: host,
      port: port,
      key: key,
    );

    final client = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) => refresh(),
    );
    _client = client;

    _lifecycleSub = client.lifecycleStream.listen((state) {
      debugPrint('[YAM][WS] état cycle de vie : $state');
      switch (state) {
        case PusherChannelsClientLifeCycleState.establishedConnection:
          onStatus?.call(ConnStatus.connected);
        case PusherChannelsClientLifeCycleState.pendingConnection:
        case PusherChannelsClientLifeCycleState.reconnecting:
        case PusherChannelsClientLifeCycleState.inactive:
          onStatus?.call(ConnStatus.connecting);
        default:
          onStatus?.call(ConnStatus.disconnected);
      }
    });

    // Canal PUBLIC (compatible backend)
    final channel = client.publicChannel('device.$deviceId');
    channel.bind('incoming-call').listen((event) {
      debugPrint('[YAM][WS] incoming-call reçu : ${event.data}');
      _dispatch(event, onIncomingCall);
    });
    channel.bind('call-signal').listen((event) {
      debugPrint('[YAM][WS] call-signal (${event.name}) reçu');
      _dispatch(event, onSignal);
    });

    // Abonnement après connexion (indispensable)
    client.onConnectionEstablished.listen((_) {
      debugPrint('[YAM][WS] connexion établie → abonnement à device.$deviceId');
      channel.subscribe();
    });

    onStatus?.call(ConnStatus.connecting);
    client.connect();
  }

  void _dispatch(ChannelReadEvent event, void Function(Map<String, dynamic>)? cb) {
    if (cb == null) return;
    try {
      final raw = event.data;
      if (raw == null) return;
      final Map<String, dynamic> map;
      if (raw is Map<String, dynamic>) {
        map = raw;
      } else if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return;
        map = decoded;
      } else {
        return;
      }
      cb(map);
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _lifecycleSub?.cancel();
    _lifecycleSub = null;
    final c = _client;
    _client = null;
    try {
      await c?.disconnect();
      c?.dispose();
    } catch (_) {}
  }
}