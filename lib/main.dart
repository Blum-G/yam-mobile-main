import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/in_call_screen.dart';
import 'screens/incoming_call_screen.dart';
import 'services/call_service.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState();
  // Chargement synchrone de la session locale avant le 1er rendu UI pour éviter le flash de l'écran de connexion.
  await app.init();
  runApp(YamApp(app: app));
}

class YamApp extends StatelessWidget {
  const YamApp({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yam',
      debugShowCheckedModeBanner: false,
      theme: YamTheme.lightTheme,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final call = app.call;
            final showIncoming = call.phase == CallPhase.incoming;
            final showActive =
                call.phase == CallPhase.calling || call.phase == CallPhase.inCall;

            return Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  ?child,
                  if (showIncoming)
                    Positioned.fill(
                      key: const ValueKey('incoming_call_overlay_global'),
                      child: Material(
                        type: MaterialType.transparency,
                        child: IncomingCallScreen(
                          key: const ValueKey('incoming_call_screen_global'),
                          app: app,
                          onAccept: () => call.accept(),
                          onRefuse: () => call.refuse(),
                        ),
                      ),
                    ),
                  if (showActive)
                    Positioned.fill(
                      key: const ValueKey('active_call_overlay_global'),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InCallScreen(
                          key: const ValueKey('in_call_screen_global'),
                          app: app,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      home: ListenableBuilder(
        listenable: app,
        builder: (context, _) => app.isAuthenticated
            ? HomeShell(app: app)
            : AuthScreen(app: app),
      ),
    );
  }
}
