import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

import '../state/app_state.dart';
import '../theme.dart';

/// Portail Sanctum : le mobile ne démarre ni la signalisation ni les appels
/// avant qu'une session par téléphone ait été créée.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.app});

  final AppState app;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;
  String _fullPhone = '';

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      if (_register) {
        await widget.app.register(
          name: _name.text,
          phoneNumber: _fullPhone,
          password: _password.text,
          username: _username.text,
        );
      } else {
        await widget.app.login(phoneNumber: _fullPhone, password: _password.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: YamColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamColors.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: YamColors.surface,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: kCardRadius,
                  side: BorderSide(color: YamColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: YamColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: YamColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Yam',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: YamColors.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _register
                              ? 'Créez votre compte professionnel.'
                              : 'Connectez-vous pour accéder à votre espace.',
                          style: const TextStyle(
                            color: YamColors.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_register) ...[
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(labelText: 'Nom complet'),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _username,
                            decoration: const InputDecoration(labelText: 'Nom d’utilisateur (facultatif)'),
                          ),
                          const SizedBox(height: 12),
                        ],
                        IntlPhoneField(
                          controller: _phone,
                          decoration: const InputDecoration(labelText: 'Numéro de téléphone'),
                          invalidNumberMessage: 'Numéro de téléphone invalide',
                          initialCountryCode: 'TG',
                          pickerDialogStyle: PickerDialogStyle(
                            searchFieldInputDecoration: const InputDecoration(labelText: 'Rechercher un pays'),
                          ),
                          onChanged: (phone) {
                            _fullPhone = phone.completeNumber;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Mot de passe'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Champ requis'
                              : (v.length < 8 ? '8 caractères minimum' : null),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: YamColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _loading
                                ? 'Connexion…'
                                : (_register ? 'Créer mon compte' : 'Se connecter'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading ? null : () => setState(() => _register = !_register),
                          style: TextButton.styleFrom(
                            foregroundColor: YamColors.primary,
                          ),
                          child: Text(
                            _register ? 'J’ai déjà un compte' : 'Créer un compte',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Champ requis' : null;
}
