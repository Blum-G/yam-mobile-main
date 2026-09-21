import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../theme.dart';

class _Acte {
  _Acte({
    required this.code,
    required this.libelle,
    required this.prix,
    this.checked = false,
  });

  final String code;
  final String libelle;
  final int prix;
  bool checked;
}

class FacturerScreen extends StatefulWidget {
  const FacturerScreen({super.key});

  @override
  State<FacturerScreen> createState() => _FacturerScreenState();
}

class _FacturerScreenState extends State<FacturerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  final List<_Acte> _actes = [
    _Acte(code: 'C001', libelle: 'Consultation générale', prix: 5000, checked: true),
    _Acte(code: 'C002', libelle: 'Pansement simple', prix: 3000),
    _Acte(code: 'C003', libelle: 'Injection IM / IV', prix: 2500, checked: true),
    _Acte(code: 'C004', libelle: 'Soins infirmiers', prix: 2000),
    _Acte(code: 'C005', libelle: 'Visite à domicile', prix: 10000),
    _Acte(code: 'C006', libelle: 'Certificat médical', prix: 2500),
  ];

  int get _total =>
      _actes.where((a) => a.checked).fold(0, (sum, a) => sum + a.prix);

  String _formatPrix(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  void _validerFacture() {
    if (_formKey.currentState!.validate()) {
      final selectedActes = _actes.where((a) => a.checked).toList();
      if (selectedActes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner au moins un acte.'),
            backgroundColor: YamColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final phone = _phoneController.text.trim();
      debugPrint('Facture validée pour $phone — Total: $_total FCFA');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Facture enregistrée (${selectedActes.length} acte(s) — ${_formatPrix(_total)})',
          ),
          backgroundColor: YamColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Créer une Facture',
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Numéro du patient
                      const Text(
                        'Numéro du patient',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: YamColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: IntlPhoneField(
                              controller: _phoneController,
                              initialCountryCode: 'TG',
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: YamColors.text,
                              ),
                              invalidNumberMessage:
                                  'Numéro de téléphone invalide',
                              decoration: InputDecoration(
                                hintText: 'Ex: 90 00 00 00',
                                filled: true,
                                fillColor: YamColors.surface,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: kFieldRadius,
                                  borderSide:
                                      const BorderSide(color: YamColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: kFieldRadius,
                                  borderSide:
                                      const BorderSide(color: YamColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: kFieldRadius,
                                  borderSide: const BorderSide(
                                    color: YamColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: YamColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: kFieldRadius,
                              side: const BorderSide(color: YamColors.border),
                            ),
                            child: InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Accès aux contacts'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius: kFieldRadius,
                              child: Container(
                                width: 52,
                                height: 52,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.contact_phone_outlined,
                                  color: YamColors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section Actes disponibles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Actes disponibles',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: YamColors.text,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: YamColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_actes.where((a) => a.checked).length} sélectionné(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: YamColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Liste des actes
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _actes.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final acte = _actes[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: YamColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: acte.checked
                                    ? YamColors.primary
                                    : YamColors.border,
                                width: acte.checked ? 1.5 : 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  acte.checked = !acte.checked;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: acte.checked,
                                        activeColor: YamColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        side: const BorderSide(
                                          color: YamColors.muted,
                                          width: 1.5,
                                        ),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            acte.checked = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            acte.libelle,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: YamColors.text,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Code : ${acte.code}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: YamColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatPrix(acte.prix),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: acte.checked
                                            ? YamColors.primary
                                            : YamColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Bloc Total
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: YamColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: YamColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Montant Total',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: YamColors.text,
                              ),
                            ),
                            Text(
                              _formatPrix(_total),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: YamColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pied de page : Bouton d'action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: YamColors.surface,
                border: Border(
                  top: BorderSide(
                    color: YamColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _validerFacture,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YamColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: kButtonRadius,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Valider la facture'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
