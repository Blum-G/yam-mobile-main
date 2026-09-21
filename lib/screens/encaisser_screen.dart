import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../theme.dart';

class EncaisserScreen extends StatefulWidget {
  const EncaisserScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<EncaisserScreen> createState() => _EncaisserScreenState();
}

class _EncaisserScreenState extends State<EncaisserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _generateQrCode() {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      final amount = _amountController.text.trim();
      final reason = _reasonController.text.trim();

      debugPrint('Génération QR : $phone, $amount FCFA, $reason');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Génération du lien de paiement en cours...'),
          backgroundColor: YamColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.showAppBar) ...[
              const SizedBox(height: 4),
              const Text(
                'Encaisser',
                style: TextStyle(
                  color: YamColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
            ],
            // Sous-titre
            const Text(
              'Générez un QR de paiement direct pour le patient.',
              style: TextStyle(
                fontSize: 14,
                color: YamColors.muted,
              ),
            ),
            const SizedBox(height: 20),

            // Champ: Numéro du patient
            const Text(
              'Numéro du patient',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: YamColors.text,
              ),
            ),
            const SizedBox(height: 8),
            IntlPhoneField(
              controller: _phoneController,
              initialCountryCode: 'TG',
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: YamColors.text,
              ),
              invalidNumberMessage: 'Numéro de téléphone invalide',
              decoration: InputDecoration(
                hintText: 'Ex: 90 00 00 00',
                filled: true,
                fillColor: YamColors.surface,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide: const BorderSide(color: YamColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide: const BorderSide(color: YamColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide:
                      const BorderSide(color: YamColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Champ: Montant à encaisser
            const Text(
              'Montant à encaisser',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: YamColors.text,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: YamColors.primary,
              ),
              decoration: InputDecoration(
                suffixText: 'FCFA',
                suffixStyle: const TextStyle(
                  color: YamColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                hintText: '0',
                filled: true,
                fillColor: YamColors.surface,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide: const BorderSide(color: YamColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide: const BorderSide(color: YamColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide:
                      const BorderSide(color: YamColors.primary, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                if (double.tryParse(value) == null) {
                  return 'Montant invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ: Motif (optionnel)
            const Text(
              'Motif (optionnel)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: YamColors.text,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              keyboardType: TextInputType.multiline,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ex: Consultation, bilan ou acte médical...',
                filled: true,
                fillColor: YamColors.surface,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide: const BorderSide(color: YamColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide: const BorderSide(color: YamColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: kFieldRadius,
                  borderSide:
                      const BorderSide(color: YamColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Bouton générer
            FilledButton(
              onPressed: _generateQrCode,
              style: FilledButton.styleFrom(
                backgroundColor: YamColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: kButtonRadius,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Générer le QR de paiement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      return _buildForm();
    }

    return Scaffold(
      backgroundColor: YamColors.pageBg,
      appBar: AppBar(
        backgroundColor: YamColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: YamColors.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Encaisser',
          style: TextStyle(
            color: YamColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: YamColors.border,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: _buildForm(),
      ),
    );
  }
}
