import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'calls_screen.dart';

class CallHubScreen extends StatefulWidget {
  final AppState app;

  const CallHubScreen({super.key, required this.app});

  @override
  State<CallHubScreen> createState() => _CallHubScreenState();
}

class _CallHubScreenState extends State<CallHubScreen> {
  final _targetCtrl = TextEditingController();

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _call({bool video = false}) async {
    final query = _targetCtrl.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    try {
      final users = await widget.app.searchUsers(query);
      if (users.isEmpty) throw Exception('Aucun utilisateur trouvé pour "$query".');
      final user = users.first;

      // Le backend exige un identifiant entier pour to_user_id.
      final rawId = user['id'];
      final userId = int.tryParse(rawId?.toString() ?? '');
      if (userId == null) {
        throw Exception('Identifiant utilisateur invalide (entier requis).');
      }

      await widget.app.call.startOutgoing(
        userId.toString(),
        targetName: user['name']?.toString() ?? user['phone_number']?.toString(),
        video: video,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Échec de l'appel : $e"),
          backgroundColor: YamColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamColors.pageBg,
      appBar: AppBar(
        title: const Text('Centre d\'Appels'),
        backgroundColor: YamColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: YamColors.border, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Haut : Appel ponctuel
          Container(
            color: YamColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'APPEL DIRECT',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.1,
                    color: YamColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetCtrl,
                  style: mono(size: 15, color: YamColors.text),
                  decoration: const InputDecoration(
                    hintText: 'Téléphone, nom ou nom d’utilisateur',
                    prefixIcon: Icon(Icons.person_search_rounded, color: YamColors.muted),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Appel vocal
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: YamColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _call(video: false),
                        icon: const Icon(Icons.call_rounded, size: 20),
                        label: const Text('Appel Vocal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Appel vidéo
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: YamColors.primaryDark,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _call(video: true),
                        icon: const Icon(Icons.videocam_rounded, size: 20),
                        label: const Text('Appel Vidéo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Séparateur discret
          Container(height: 1, color: YamColors.border),

          // Bas : Historique
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: const [
                Text(
                  'HISTORIQUE RÉCENT',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.1,
                    color: YamColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CallsScreen(app: widget.app),
          ),
        ],
      ),
    );
  }
}
