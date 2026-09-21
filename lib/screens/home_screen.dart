import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'dossier_medical_screen.dart';
import 'encaisser_screen.dart';
import 'facturer_screen.dart';
import 'ordonnance_screen.dart';

/// Accueil : solde + grille d'accès rapide.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.app});

  final AppState app;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _WalletCard(),
        const SizedBox(height: 20),
        const Text(
          'Services rapides',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: YamColors.text,
          ),
        ),
        const SizedBox(height: 12),
        _QuickAccessGrid(app: widget.app),
      ],
    );
  }
}

class _WalletCard extends StatefulWidget {
  const _WalletCard();

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  bool _isHidden = false;
  final String _balance = "0 F";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: YamColors.primary,
        borderRadius: kCardRadius,
        boxShadow: [
          BoxShadow(
            color: YamColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Solde disponible',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isHidden = !_isHidden),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _isHidden ? "•••••• F" : _balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({this.app});

  final AppState? app;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        _GridCard(
          title: 'Dossier médical',
          subtitle: 'Patients et suivis',
          icon: Icons.folder_shared_rounded,
          iconColor: YamColors.primary,
          iconBgColor: YamColors.primarySoft,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DossierMedicalScreen(app: app)),
          ),
        ),
        _GridCard(
          title: 'Encaisser',
          subtitle: 'Lien QR de paiement',
          icon: Icons.qr_code_rounded,
          iconColor: YamColors.primary,
          iconBgColor: YamColors.primarySoft,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EncaisserScreen()),
          ),
        ),
        _GridCard(
          title: 'Facturer',
          subtitle: 'Créer une facture',
          icon: Icons.receipt_long_rounded,
          iconColor: YamColors.accent,
          iconBgColor: YamColors.accentSoft,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FacturerScreen()),
          ),
        ),
        _GridCard(
          title: 'Ordonnance',
          subtitle: 'Prescription rapide',
          icon: Icons.medication_rounded,
          iconColor: YamColors.primary,
          iconBgColor: YamColors.primarySoft,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdonnanceScreen()),
          ),
        ),
      ],
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YamColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: kCardRadius,
        side: BorderSide(color: YamColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: kCardRadius,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: YamColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: YamColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
