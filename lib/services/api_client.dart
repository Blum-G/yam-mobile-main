import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'runtime_config.dart';

/// Client REST de l'API Yam. Routes : config, ring, signal.
class ApiClient {
  ApiClient(
    this.baseUrlProvider, {
    String? Function()? tokenProvider,
    http.Client? client,
  })  : _tokenProvider = tokenProvider,
        _client = client ?? http.Client();

  /// Fournit l'URL courante (modifiable dans les réglages de l'app).
  final String Function() baseUrlProvider;
  final String? Function()? _tokenProvider;

  /// Client HTTP utilisé pour les requêtes. Injectable pour les tests
  /// (MockClient de package:http/testing) ; par défaut un vrai client.
  final http.Client _client;

  Uri _uri(String path) {
    final base = baseUrlProvider().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  /// Récupère la configuration runtime (Reverb + TURN) depuis le backend.
  /// Retourne null si l'endpoint est injoignable ou illisible (l'app garde
  /// alors ses valeurs par défaut locales).
  Future<RuntimeConfig?> fetchConfig() async {
    try {
      final res = await _client
          .get(_uri('/api/v1/config'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map<String, dynamic>) return null;
      return RuntimeConfig.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _headers({bool authenticated = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = _tokenProvider?.call();
    if (authenticated && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// [timeout] : durée max avant abandon de la requête. Par défaut 10s,
  /// mais certaines routes (ex. `ring`, qui déclenche un envoi FCM côté
  /// serveur) ont besoin de plus de marge pour éviter un abandon client
  /// prématuré alors que le traitement serveur se poursuit en arrière-plan.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final res = await _client
        .post(
          _uri(path),
          headers: _headers(authenticated: authenticated),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    final decoded = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final map = decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
      final errors = map['errors'];
      final message = errors is Map && errors.isNotEmpty
          ? (errors.values.first is List && (errors.values.first as List).isNotEmpty
              ? (errors.values.first as List).first
              : null)
          : map['message'] ?? map['error']?['message'];
      throw Exception(message ?? 'API $path → HTTP ${res.statusCode}');
    }
    return decoded as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
    required String deviceId,
    required String platform,
    String? label,
  }) => _post('/api/v1/auth/login', {
        'phone_number': phoneNumber,
        'password': password,
        'device_id': deviceId,
        'platform': platform,
        if (label != null && label.isNotEmpty) 'label': label,
      });

  Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNumber,
    required String password,
    required String deviceId,
    required String platform,
    String? username,
  }) => _post('/api/v1/auth/register', {
        'name': name,
        'phone_number': phoneNumber,
        'password': password,
        'device_id': deviceId,
        'platform': platform,
        if (username != null && username.isNotEmpty) 'username': username,
      });

  Future<void> logout() async {
    await _post('/api/v1/auth/logout', const {}, authenticated: true);
  }

  /// Fait sonner l'appareil cible. Retourne le call_id si fourni.
  ///
  /// [type] : `'audio'` (défaut) ou `'video'` — détermine le type d'appel.
  ///
  /// Timeout étendu à 25s (au lieu des 10s par défaut) : cette route
  /// déclenche un envoi de notification push FCM côté serveur, qui peut
  /// prendre plus de 10s selon la latence réseau vers Google. Un timeout
  /// trop court coupait l'écran d'appel côté appelant alors que le push
  /// finissait par arriver en retard chez le destinataire.
  Future<String?> ring({
    required String toUserId,
    required String fromDeviceId,
    required String fromUsername,
    String type = 'audio',
  }) async {
    final data = await _post(
      '/api/v1/call/ring',
      {
        'to_user_id': int.tryParse(toUserId) ?? toUserId,
        'from_device_id': fromDeviceId,
        'from_username': fromUsername,
        'type': type,
      },
      authenticated: true,
      timeout: const Duration(seconds: 25),
    );
    return (data['data'] as Map?)?['call_id'] as String? ?? data['call_id'] as String?;
  }

  /// Envoie un signal WebRTC (offer / answer / candidate / bye).
  ///
  /// [callId] : identifiant de l'appel, requis pour le stockage différé de
  /// l'offre côté serveur (type=offer) et l'invalidation au raccrochage
  /// (type=bye).
  ///
  /// Pour le type 'bye', cette méthode effectue jusqu'à 3 tentatives
  /// avec backoff exponentiel (500 ms, 1000 ms, 2000 ms) en cas d'échec
  /// du serveur, afin de garantir que le correspondant arrête de sonner.
  Future<void> signal({
    String? toDeviceId,
    String? toUserId,
    required String fromDeviceId,
    required String type,
    required Map<String, dynamic> payload,
    required String callId, // rendu obligatoire pour tous les signaux
  }) async {
    if ((toDeviceId == null || toDeviceId.isEmpty) &&
        (toUserId == null || toUserId.isEmpty)) {
      return;
    }

    final body = {
      if (toDeviceId != null && toDeviceId.isNotEmpty) 'to_device_id': toDeviceId,
      if (toUserId != null && toUserId.isNotEmpty)
        'to_user_id': int.tryParse(toUserId) ?? toUserId,
      'from_device_id': fromDeviceId,
      'type': type,
      'payload': payload,
      if (callId.isNotEmpty) 'call_id': callId,
    };

    // Détermine le nombre de tentatives et le délai initial
    final bool isBye = type == 'bye';
    final int maxAttempts = isBye ? 3 : 1;
    final Duration initialDelay = const Duration(milliseconds: 500);

    int attempt = 0;
    while (attempt < maxAttempts) {
      try {
        await _post('/api/v1/call/signal', body, authenticated: true);
        return; // Succès
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          // Dernière tentative échouée – on relance l'exception
          rethrow;
        }
        // Backoff exponentiel : 500ms, 1000ms, 2000ms...
        final delay = initialDelay * attempt;
        await Future.delayed(delay);
        // On pourrait logger l'erreur, mais on laisse silencieux pour ne pas polluer
      }
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final res = await _client.get(
      _uri('/api/v1/users/search?q=${Uri.encodeQueryComponent(query)}&limit=8'),
      headers: _headers(authenticated: true),
    ).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body);
    final data = json is Map ? (json['data'] ?? json['users']) : null;
    if (data is! List) return [];
    return data.whereType<Map>().map((u) => u.cast<String, dynamic>()).toList();
  }

  /// Récupère l'offre SDP différée stockée par le serveur pour un appel.
  ///
  /// Retourne le payload de l'offre (`{sdp, type}`) ou null si l'offre est
  /// introuvable, expirée ou interdite (l'appelant a raccroché, timeout...).
  Future<Map<String, dynamic>?> fetchDeferredOffer({
    required String callId,
    required String deviceId,
  }) async {
    try {
      final uri = _uri(
          '/api/v1/call/${Uri.encodeComponent(callId)}/offer'
          '?device_id=${Uri.encodeComponent(deviceId)}');
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map<String, dynamic>) return null;
      return (json['payload'] as Map?)?.cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }
}