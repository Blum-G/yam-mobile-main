import 'package:flutter/material.dart';

import '../services/call_service.dart';
import '../services/signaling_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'calls_screen.dart';
import 'contacts_screen.dart';
import 'home_screen.dart';
import 'in_call_screen.dart';
import 'incoming_call_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.app});
  final AppState app;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // S'abonner aux changements d'AppState
    widget.app.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    // Se désabonner impérativement
    widget.app.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    // Ne mettre à jour que si le widget est toujours monté
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final call = app.call;
    final showIncoming = call.phase == CallPhase.incoming;
    final showActive = call.phase == CallPhase.calling || call.phase == CallPhase.inCall;

    return Scaffold(
      backgroundColor: YamColors.pageBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _Header(app: app),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      HomeScreen(app: app),
                      ContactsScreen(app: app),
                      CallsScreen(app: app),
                    ],
                  ),
                ),
              ],
            ),
            if (showIncoming)
              Positioned.fill(
                key: const ValueKey('incoming_call_overlay'),
                child: IncomingCallScreen(
                  key: const ValueKey('incoming_call_screen'),
                  app: app,
                  onAccept: () => call.accept(),
                  onRefuse: () => call.refuse(),
                ),
              ),
            if (showActive)
              Positioned.fill(
                key: const ValueKey('active_call_overlay'),
                child: InCallScreen(
                  key: const ValueKey('in_call_screen'),
                  app: app,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 66,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'Appels',
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final (label, dotColor) = switch (app.status) {
      ConnStatus.connected => ('Connecté', YamColors.accent),
      ConnStatus.connecting => ('Connexion…', YamColors.muted),
      ConnStatus.disconnected => ('Déconnecté', YamColors.danger),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      child: Row(
        children: [
          const Text('Yam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: YamColors.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: YamColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: YamColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 12, color: YamColors.muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Adresse du serveur',
            onPressed: () => _editServer(context),
            icon: const Icon(Icons.settings_outlined, color: YamColors.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _editServer(BuildContext context) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final ctrl = TextEditingController(text: app.serverUrl);
          return AlertDialog(
            title: const Text('Adresse du serveur'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'http://yam.mdkrlabs.dev',
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
                  final newUrl = ctrl.text.trim();
                  ctrl.dispose();
                  Navigator.pop(ctx, newUrl.isNotEmpty ? newUrl : null);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );

    if (!context.mounted) return;
    if (result is String && result.isNotEmpty) {
      await app.updateServerUrl(result);
    }
  }
}