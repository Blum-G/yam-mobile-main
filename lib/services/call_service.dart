import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

import 'api_client.dart';
import 'runtime_config.dart';

enum CallPhase { idle, calling, incoming, inCall }

/// Machine à états d'un appel audio/vidéo de bout en bout.
class CallService extends ChangeNotifier {
  CallService(this._api);

  final ApiClient _api;

  CallPhase phase = CallPhase.idle;
  String? targetUserId;
  String? remoteId;
  String? remoteName;
  bool micMuted = false;
  bool speakerOn = true;
  bool cameraOn = false;
  bool videoEnabled = false;

  String? currentCallId;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  String myDeviceId = '';
  String myName = 'Moi';

  RuntimeConfig? config;

  void Function(String peerId, String peerName, bool missed)? onCallEnded;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCSessionDescription? _pendingOffer;
  bool _acceptRequested = false;
  bool _answered = false;
  bool _answering = false;
  Timer? _ringTimeout;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  final List<RTCIceCandidate> _pendingLocalCandidates = [];

  final AudioPlayer _ringtone = AudioPlayer();

  // Timer de grâce annulable pour le disconnected
  Timer? _disconnectGraceTimer;

  // ─────────────────────────── Appel sortant ───────────────────────────

  Future<void> startOutgoing(String targetId, {String? targetName, bool video = false}) async {
    final clean = targetId.trim();
    if (phase != CallPhase.idle || clean.isEmpty) return;
    phase = CallPhase.calling;
    targetUserId = clean;
    remoteId = null;
    remoteName = targetName ?? clean;
    videoEnabled = video;
    notifyListeners();
    try {
      final callId = await _api.ring(
        toUserId: clean,
        fromDeviceId: myDeviceId,
        fromUsername: myName,
        type: video ? 'video' : 'audio',
      );
      currentCallId = callId;
      await _ensureMedia(video: video);
      await _createPeer(video: video);
      final offerConstraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': video,
      };
      final offer = await _pc!.createOffer(offerConstraints);
      await _pc!.setLocalDescription(offer);
      await _api.signal(
        toUserId: clean,
        fromDeviceId: myDeviceId,
        type: 'offer',
        callId: callId!, // on est sûr que callId n'est pas null
        payload: {
          'sdp': {'type': offer.type, 'sdp': offer.sdp},
        },
      );
      unawaited(_startRingback());
      _ringTimeout = Timer(const Duration(seconds: 45), () {
        if (phase == CallPhase.calling) hangUp();
      });
    } catch (_) {
      final rid = remoteId;
      if ((rid != null || targetUserId != null) && currentCallId != null) {
        unawaited(_api.signal(
          toDeviceId: rid,
          toUserId: rid == null ? targetUserId : null,
          fromDeviceId: myDeviceId,
          type: 'bye',
          callId: currentCallId!, // non nul ici
          payload: {},
        ).catchError((_) {}));
      }
      await teardown();
      rethrow;
    }
  }

  // ─────────────────────────── Appel entrant ───────────────────────────

  Future<void> handleIncomingCall(Map<String, dynamic> data) async {
    debugPrint('[YAM][CALL] incoming-call → $data');
    if (phase != CallPhase.idle) return;
    remoteId = data['from_device_id'] as String?;
    remoteName = (data['from_username'] as String?) ?? remoteId ?? 'Inconnu';
    currentCallId = data['call_id'] as String?;
    videoEnabled = (data['media'] as String?) == 'video';
    phase = CallPhase.incoming;
    _pendingOffer = null;
    _acceptRequested = false;
    _answered = false;
    _answering = false;
    notifyListeners();

    unawaited(_startRingtone());
    unawaited(Vibration.hasVibrator().then((ok) {
      if (ok == true) {
        Vibration.vibrate(pattern: [400, 200, 400, 200, 400], repeat: 0);
      }
    }));
  }

  Future<void> accept() async {
    if (phase != CallPhase.incoming) return;
    _stopRing();
    _acceptRequested = true;
    notifyListeners();
    try {
      await _ensureMedia(video: videoEnabled);
      await _createPeer(video: videoEnabled);
      final offer = _pendingOffer;
      if (offer != null) {
        await _answer(offer);
      } else {
        final recovered = await _fetchDeferredOffer();
        if (recovered != null) {
          await _answer(recovered);
        } else {
          debugPrint('[YAM][CALL] Aucune offre différée récupérable → abandon');
          await teardown();
        }
      }
    } catch (_) {
      await teardown();
      rethrow;
    }
  }

  Future<void> refuse() async {
    if (phase != CallPhase.incoming) return;
    final rid = remoteId;
    final rname = remoteName ?? rid ?? '';
    if (rid != null) {
      unawaited(_api.signal(
        toDeviceId: rid,
        fromDeviceId: myDeviceId,
        type: 'bye',
        callId: currentCallId!, // non nul en incoming
        payload: {'reason': 'reject'},
      ).catchError((_) {}));
    }
    await teardown();
    if (rid != null) onCallEnded?.call(rid, rname, true);
  }

  // ─────────────────────── Signalisation reçue ─────────────────────────

  Future<void> handleSignal(Map<String, dynamic> data) async {
    if (data['from_device_id'] == myDeviceId) return;
    final type = data['type'] as String?;
    final payload = ((data['payload'] as Map?)?.cast<String, dynamic>()) ?? const {};

    switch (type) {
      case 'offer':
        final offer = _descriptionFromPayload(payload, fallbackType: 'offer');
        if (offer == null || phase != CallPhase.incoming) return;
        if (_acceptRequested && !_answered && _pc != null) {
          await _answer(offer);
        } else {
          _pendingOffer = offer;
        }
        break;

      case 'candidate':
        final c = (payload['candidate'] as Map?)?.cast<String, dynamic>();
        if (c == null || c['candidate'] == null) return;
        final cand = RTCIceCandidate(
          c['candidate'] as String,
          c['sdpMid'] as String?,
          (c['sdpMLineIndex'] as num?)?.toInt(),
        );
        if (_answered && _pc != null) {
          try {
            await _pc!.addCandidate(cand);
          } catch (e) {
            debugPrint('[YAM][CALL] addCandidate ignoré : $e');
          }
        } else {
          _pendingRemoteCandidates.add(cand);
        }
        break;

      case 'answer':
        final answer = _descriptionFromPayload(payload, fallbackType: 'answer');
        if (_pc == null || answer == null || _answered) return;
        try {
          remoteId = data['from_device_id']?.toString();
          await _pc!.setRemoteDescription(answer);
          _answered = true;
          await _flushLocalCandidates();
          _stopRing();
          await _drainCandidates();
          await Helper.setSpeakerphoneOn(speakerOn);
          phase = CallPhase.inCall;
          _ringTimeout?.cancel();
          notifyListeners();
        } catch (e) {
          debugPrint('[YAM][CALL] Erreur setRemoteDescription (answer) : $e');
          await teardown();
        }
        break;

      case 'bye':
        if (phase == CallPhase.idle) break;
        final from = data['from_device_id']?.toString();
        if (remoteId != null && from != null && remoteId != from) break;
        if (remoteId == null) {
          final byeCallId = data['call_id']?.toString();
          if (byeCallId != null && byeCallId.isNotEmpty &&
              currentCallId != null && byeCallId != currentCallId) {
            break;
          }
          if (from == null) break;
        }
        {
          final rid = remoteId ?? from ?? '';
          final rname = remoteName ?? rid;
          final wasInCall = phase == CallPhase.inCall;
          final wasIncoming = phase == CallPhase.incoming;
          await teardown();
          if (wasInCall) {
            onCallEnded?.call(rid, rname, false);
          } else if (wasIncoming) {
            onCallEnded?.call(rid, rname, true);
          }
        }
        break;
    }
  }

  Future<void> _answer(RTCSessionDescription offer) async {
    if (_pc == null || _answered || _answering) return;
    final peerId = remoteId;
    if (peerId == null) {
      debugPrint('[YAM][CALL] _answer appelé sans remoteId → abandon');
      await teardown();
      return;
    }
    _answering = true;
    try {
      await _pc!.setRemoteDescription(offer);
      await _drainCandidates();
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      // ==== CORRECTION : ajout de callId ====
      await _api.signal(
        toDeviceId: peerId,
        fromDeviceId: myDeviceId,
        type: 'answer',
        payload: {
          'sdp': {'type': answer.type, 'sdp': answer.sdp},
        },
        callId: currentCallId!, // non nul en incoming
      );
      _answered = true;
      await Helper.setSpeakerphoneOn(speakerOn);
      phase = CallPhase.inCall;
      notifyListeners();
    } finally {
      _answering = false;
    }
  }

  // ────────────────────────── Fin d'appel ──────────────────────────────

  Future<void> hangUp() async {
    if (phase == CallPhase.idle) return;
    final rid = remoteId;
    final rname = remoteName ?? rid ?? '';
    final wasInCall = phase == CallPhase.inCall;
    if (rid != null || targetUserId != null) {
      unawaited(_api.signal(
        toDeviceId: rid,
        toUserId: rid == null ? targetUserId : null,
        fromDeviceId: myDeviceId,
        type: 'bye',
        callId: currentCallId ?? '', // fournir une chaîne vide en dernier recours
        payload: phase == CallPhase.calling ? {'reason': 'cancel'} : {},
      ).catchError((_) {}));
    }
    await teardown();
    if (rid != null && wasInCall) onCallEnded?.call(rid, rname, false);
  }

  /// Libère TOUT
  Future<void> teardown() async {
    _stopRing();
    unawaited(Vibration.cancel());
    _ringTimeout?.cancel();
    _disconnectGraceTimer?.cancel();
    _disconnectGraceTimer = null;

    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      _remoteStream?.getTracks().forEach((t) => t.stop());
      await _remoteStream?.dispose();
    } catch (_) {}
    _remoteStream = null;
    _pendingOffer = null;
    _acceptRequested = false;
    _answered = false;
    _answering = false;
    _pendingRemoteCandidates.clear();
    _pendingLocalCandidates.clear();
    micMuted = false;
    speakerOn = true;
    cameraOn = false;
    videoEnabled = false;
    phase = CallPhase.idle;
    remoteId = null;
    targetUserId = null;
    remoteName = null;
    currentCallId = null;
    notifyListeners();
  }

  // ─────────────────────────── Contrôles ───────────────────────────────

  void toggleMute() {
    micMuted = !micMuted;
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = !micMuted;
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    await Helper.setSpeakerphoneOn(speakerOn);
    notifyListeners();
  }

  Future<void> toggleCamera() async {
    if (!videoEnabled) return;
    cameraOn = !cameraOn;
    for (final t in _localStream?.getVideoTracks() ?? const []) {
      t.enabled = cameraOn;
    }
    notifyListeners();
  }

  // ─────────────────────────── Internes ────────────────────────────────

  Future<void> _ensureMedia({bool video = false}) async {
    if (_localStream != null) return;
    final st = await Permission.microphone.request();
    if (!st.isGranted) throw Exception('Permission micro refusée');
    if (video) {
      final camSt = await Permission.camera.request();
      if (!camSt.isGranted) throw Exception('Permission caméra refusée');
    }
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video,
    });
    if (video) cameraOn = true;
  }

  Future<void> _createPeer({bool video = false}) async {
    if (_pc != null) return;
    final pc = await createPeerConnection({
      'iceServers': config?.iceServers ??
          [
            {
              'urls': [
                'stun:stun.l.google.com:19302',
                'stun:stun1.l.google.com:19302',
                'stun:stun2.l.google.com:19302',
              ]
            },
            {'urls': ['stun:stun.cloudflare.com:3478']},
          ],
      'sdpSemantics': 'unified-plan',
    });

    pc.onIceCandidate = (cand) {
      if (cand.candidate == null) return;
      if (remoteId == null) {
        _pendingLocalCandidates.add(cand);
      } else {
        _sendCandidate(cand);
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final prev = _remoteStream;
        _remoteStream = event.streams.first;
        if (prev != null && prev != _remoteStream) {
          try {
            prev.getTracks().forEach((t) => t.stop());
            prev.dispose();
          } catch (_) {}
        }
        notifyListeners();
      }
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        unawaited(teardown());
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _disconnectGraceTimer?.cancel();
        final captured = pc;
        _disconnectGraceTimer = Timer(const Duration(milliseconds: 5000), () {
          if (identical(_pc, captured) &&
              captured.connectionState ==
                  RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
            unawaited(teardown());
          }
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        _disconnectGraceTimer?.cancel();
        _disconnectGraceTimer = null;
      }
    };

    final local = _localStream;
    if (local != null) {
      for (final track in local.getTracks()) {
        await pc.addTrack(track, local);
      }
    }
    _pc = pc;
  }

  Future<void> _drainCandidates() async {
    final pc = _pc;
    if (pc == null) return;
    for (final c in List.of(_pendingRemoteCandidates)) {
      try {
        await pc.addCandidate(c);
      } catch (e) {
        debugPrint('[YAM][CALL] Candidate différé ignoré : $e');
      }
    }
    _pendingRemoteCandidates.clear();
  }

  void _sendCandidate(RTCIceCandidate candidate) {
    final rid = remoteId;
    if (rid == null) return;
    unawaited(_api.signal(
      toDeviceId: rid,
      fromDeviceId: myDeviceId,
      type: 'candidate',
      callId: currentCallId ?? '',
      payload: {
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      },
    ));
  }

  Future<void> _flushLocalCandidates() async {
    for (final candidate in List<RTCIceCandidate>.of(_pendingLocalCandidates)) {
      _sendCandidate(candidate);
    }
    _pendingLocalCandidates.clear();
  }

  Future<RTCSessionDescription?> _fetchDeferredOffer() async {
    final callId = currentCallId;
    if (callId == null || callId.isEmpty) return null;
    debugPrint('[YAM][CALL] Récupération de l\'offre différée ($callId)...');
    final payload = await _api.fetchDeferredOffer(
      callId: callId,
      deviceId: myDeviceId,
    );
    if (payload == null) return null;
    return _descriptionFromPayload(payload, fallbackType: 'offer');
  }

  RTCSessionDescription? _descriptionFromPayload(
    Map<String, dynamic> payload, {
    required String fallbackType,
  }) {
    final rawSdp = payload['sdp'];
    if (rawSdp is String && rawSdp.isNotEmpty) {
      return RTCSessionDescription(sdpNormalise(rawSdp), payload['type']?.toString() ?? fallbackType);
    }
    if (rawSdp is Map) {
      final nested = rawSdp.cast<String, dynamic>();
      final sdp = nested['sdp']?.toString();
      if (sdp == null || sdp.isEmpty) return null;
      return RTCSessionDescription(sdpNormalise(sdp), nested['type']?.toString() ?? fallbackType);
    }
    return null;
  }

  Future<void> _startRingback() async {
    try {
      await _ringtone.stop();
      await _ringtone.setReleaseMode(ReleaseMode.loop);
      await _ringtone.play(AssetSource('sounds/freesound_community-ring-tone-68676 (1).mp3'));
      debugPrint('[YAM][RINGBACK] sonnerie de sortie démarrée');
    } catch (e) {
      debugPrint('[YAM][RINGBACK] ERREUR sonnerie de sortie : $e');
    }
  }

  Future<void> _startRingtone() async {
    try {
      await _ringtone.stop();
      await _ringtone.setReleaseMode(ReleaseMode.loop);
      await _ringtone.play(AssetSource('sounds/ringtone.mp3'));
      debugPrint('[YAM][RING] sonnerie démarrée');
    } catch (e) {
      debugPrint('[YAM][RING] ERREUR sonnerie : $e');
    }
  }

  void _stopRing() {
    debugPrint('[YAM][RING] arrêt sonnerie / tonalité');
    try {
      unawaited(_ringtone.stop());
    } catch (_) {}
  }
}

String sdpNormalise(String sdp) => sdp.endsWith('\r\n') ? sdp : '$sdp\r\n';