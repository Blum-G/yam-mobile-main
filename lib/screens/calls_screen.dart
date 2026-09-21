import 'package:flutter/material.dart';

import '../models/missed_call.dart';
import '../services/call_service.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Historique des appels (manqués avec badge orange + émis terminés).
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key, required this.app});

  final AppState app;

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (app.calls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: YamColors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: YamColors.border),
                ),
                child: const Icon(
                  Icons.phone_missed_rounded,
                  size: 28,
                  color: YamColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun appel pour le moment',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: YamColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vos appels récents et manqués apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: YamColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: app.calls
          .map((r) => _CallTile(app, r, fmt: _fmt, key: ValueKey(r.id)))
          .toList(),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile(this.app, this.record, {super.key, required this.fmt});

  final AppState app;
  final CallRecord record;
  final String Function(DateTime) fmt;

  Future<void> _startCall(BuildContext context, {bool video = false}) async {
    String rawId = record.peerId.trim();
    String targetName = record.peerName.trim();
    String? resolvedUserId;

    // 1. Si l'identifiant est déjà un entier valide
    if (int.tryParse(rawId) != null) {
      resolvedUserId = rawId;
    }

    // 2. Si ce n'est pas un entier, chercher dans les contacts enregistrés
    if (resolvedUserId == null) {
      for (final c in app.contacts) {
        if ((c.userId.isNotEmpty && (c.userId == rawId || int.tryParse(c.userId) != null)) ||
            (c.name.isNotEmpty && targetName.isNotEmpty && c.name.toLowerCase() == targetName.toLowerCase()) ||
            (c.phoneNumber != null && c.phoneNumber!.isNotEmpty && (c.phoneNumber == rawId || c.phoneNumber == targetName))) {
          if (int.tryParse(c.userId) != null) {
            resolvedUserId = c.userId;
            if (c.name.isNotEmpty) targetName = c.name;
            break;
          }
        }
      }
    }

    // 3. Si toujours non résolu, chercher l'utilisateur sur le serveur par son nom / téléphone
    if (resolvedUserId == null) {
      final query = targetName.isNotEmpty ? targetName : rawId;
      if (query.isNotEmpty) {
        try {
          final users = await app.searchUsers(query);
          if (users.isNotEmpty) {
            final first = users.first;
            final idStr = first['id']?.toString();
            if (idStr != null && int.tryParse(idStr) != null) {
              resolvedUserId = idStr;
              targetName = first['name']?.toString() ?? targetName;
            }
          }
        } catch (_) {}
      }
    }

    // 4. Si l'identifiant n'est toujours pas un entier valide
    if (resolvedUserId == null || int.tryParse(resolvedUserId) == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Identifiant utilisateur introuvable pour "${targetName.isNotEmpty ? targetName : rawId}". Veuillez rechercher ce contact dans l\'onglet Contacts.',
            ),
            backgroundColor: YamColors.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (app.call.phase != CallPhase.idle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un appel est déjà en cours.'),
          backgroundColor: YamColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Lancement de l\'appel ${video ? 'vidéo' : 'audio'} vers ${targetName.isNotEmpty ? targetName : 'Utilisateur #$resolvedUserId'}...',
        ),
        backgroundColor: YamColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await app.call.startOutgoing(
        resolvedUserId,
        targetName: targetName.isNotEmpty ? targetName : 'Utilisateur #$resolvedUserId',
        video: video,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'appel : $e'),
            backgroundColor: YamColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: YamColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.peerName.isEmpty ? record.peerId : record.peerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: YamColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${record.peerId} • ${fmt(record.at)}',
                style: mono(size: 13, color: YamColors.muted),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: YamColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call_rounded, color: YamColors.primary),
                ),
                title: const Text(
                  'Appel vocal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _startCall(context, video: false);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: YamColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: YamColors.primary),
                ),
                title: const Text(
                  'Appel vidéo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _startCall(context, video: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: YamColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: YamColors.danger),
                ),
                title: const Text(
                  'Supprimer de l\'historique',
                  style: TextStyle(fontWeight: FontWeight.w600, color: YamColors.danger),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  app.removeCall(record);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: YamColors.surface,
        borderRadius: kCardRadius,
        border: Border.all(color: YamColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: kCardRadius,
        child: InkWell(
          borderRadius: kCardRadius,
          onTap: () => _showCallOptions(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Avatar icône cliquable (rappel direct)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _startCall(context, video: false),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: record.missed
                        ? YamColors.accentSoft
                        : YamColors.primarySoft,
                    child: Icon(
                      record.missed
                          ? Icons.call_missed_rounded
                          : Icons.call_made_rounded,
                      color: record.missed ? YamColors.accent : YamColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              record.peerName.isEmpty ? record.peerId : record.peerName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: record.missed ? YamColors.accent : YamColors.text,
                              ),
                            ),
                          ),
                          if (record.missed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: YamColors.accentSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Manqué',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: YamColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.peerId} · ${fmt(record.at)}',
                        style: mono(size: 12, color: YamColors.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Bouton Appel vocal direct
                IconButton(
                  tooltip: 'Appel vocal',
                  onPressed: () => _startCall(context, video: false),
                  icon: const Icon(Icons.call_rounded, color: YamColors.primary),
                ),
                // Bouton Appel vidéo direct
                IconButton(
                  tooltip: 'Appel vidéo',
                  onPressed: () => _startCall(context, video: true),
                  icon: const Icon(Icons.videocam_rounded, color: YamColors.primary),
                ),
                // Bouton Supprimer
                IconButton(
                  tooltip: 'Effacer',
                  onPressed: () => app.removeCall(record),
                  icon: const Icon(Icons.delete_outline_rounded, color: YamColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
