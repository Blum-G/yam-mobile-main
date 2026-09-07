import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.app});

  final AppState app;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _targetCtrl = TextEditingController();

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: widget.app.deviceId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Identifiant copié'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _call({bool video = false}) async {
    FocusScope.of(context).unfocus();
    try {
      final users = await widget.app.searchUsers(_targetCtrl.text);
      if (users.isEmpty) throw Exception('Aucun utilisateur trouvé.');
      final user = users.first;
      await widget.app.call.startOutgoing(
        user['id'].toString(),
        targetName: user['name']?.toString() ?? user['phone_number']?.toString(),
        video: video,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'appel : $e")),
      );
    }
  }

  // Dialogue "Modifier mon nom" – version robuste
  void _editName() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final ctrl = TextEditingController(text: widget.app.userName);
          return AlertDialog(
            title: const Text('Modifier mon nom'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ex: Smartphone Dam, Bureau...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ctrl.dispose();
                  Navigator.pop(ctx, null);
                },
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  final newName = ctrl.text.trim();
                  ctrl.dispose();
                  Navigator.pop(ctx, newName.isNotEmpty ? newName : null);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted) return;
    if (result is String && result.isNotEmpty) {
      await widget.app.updateUserName(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionLabel('MON IDENTIFIANT'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _copyId,
          borderRadius: kFieldRadius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: YamColors.surface,
              borderRadius: kFieldRadius,
              border: Border.all(color: YamColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.deviceId.isEmpty ? '…' : app.deviceId,
                        style: mono(size: 15, color: YamColors.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nom affiché : ${app.userName}',
                        style: const TextStyle(fontSize: 12, color: YamColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Modifier mon nom',
                  icon: const Icon(Icons.edit_outlined, size: 18, color: YamColors.muted),
                  onPressed: _editName,
                ),
                const Icon(Icons.copy, size: 18, color: YamColors.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionLabel('APPEL PONCTUEL'),
        const SizedBox(height: 8),
        TextField(
          controller: _targetCtrl,
          style: mono(size: 15, color: YamColors.text),
          decoration: InputDecoration(
            hintText: 'Téléphone, nom ou nom d’utilisateur',
            hintStyle: mono(size: 15),
            filled: true,
            fillColor: YamColors.surface,
            border: OutlineInputBorder(borderRadius: kFieldRadius),
            enabledBorder: OutlineInputBorder(
              borderRadius: kFieldRadius,
              borderSide: const BorderSide(color: YamColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: YamColors.text,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: kFieldRadius),
                  ),
                  onPressed: () => _call(video: false),
                  icon: const Icon(Icons.call, size: 20),
                  label: const Text('Appeler', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: YamColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: kFieldRadius),
                  ),
                  onPressed: () => _call(video: true),
                  icon: const Icon(Icons.videocam, size: 20),
                  label: const Text('Vidéo', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        color: YamColors.muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}