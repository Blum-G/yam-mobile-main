import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'patient_details_screen.dart';

class DossierMedicalScreen extends StatefulWidget {
  const DossierMedicalScreen({super.key, this.showAppBar = true, this.app});

  final bool showAppBar;
  final AppState? app;

  @override
  State<DossierMedicalScreen> createState() => _DossierMedicalScreenState();
}

class _DossierMedicalScreenState extends State<DossierMedicalScreen> {
  int _tabIndex = 0; // 0 = Rechercher, 1 = Scanner carte
  final _searchController = TextEditingController();

  // Données mockées
  final List<Patient> _allPatients = const [
    Patient(
      nom: 'Jean KOFFI',
      telephone: '+228 90 12 34 56',
      dateNaissance: '12/05/1985',
    ),
    Patient(
      nom: 'Amina ABALO',
      telephone: '+228 91 23 45 67',
      dateNaissance: '03/11/1992',
    ),
    Patient(
      nom: 'Kofi AGBEKO',
      telephone: '+228 99 87 65 43',
      dateNaissance: '27/08/1978',
    ),
    Patient(
      nom: 'Essi MENSAH',
      telephone: '+228 93 45 67 89',
      dateNaissance: '15/02/2001',
    ),
  ];

  List<Patient> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allPatients;
    return _allPatients.where((p) {
      return p.nom.toLowerCase().contains(query) ||
          p.telephone.replaceAll(' ', '').contains(query.replaceAll(' ', ''));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showAppBar) ...[
            const SizedBox(height: 8),
            const Text(
              'Dossier médical',
              style: TextStyle(
                color: YamColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 8),
          ],

          // ── Sélecteur d'onglets ──
          _buildTabSelector(),

          const SizedBox(height: 16),

          // ── Contenu selon l'onglet ──
          if (_tabIndex == 0) ...[
            // Barre de recherche
            _buildSearchBar(),
            const SizedBox(height: 20),

            // Titre de section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Patients récents',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: YamColors.text,
                  ),
                ),
                Text(
                  '${_filteredPatients.length} patient(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: YamColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Liste des patients
            Expanded(
              child: _filteredPatients.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 44,
                            color: YamColors.muted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Aucun patient trouvé',
                            style: TextStyle(
                              color: YamColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredPatients.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _PatientCard(
                          patient: _filteredPatients[index],
                          app: widget.app,
                        );
                      },
                    ),
            ),
          ] else ...[
            // Scanner carte
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: YamColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 56,
                          color: YamColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Scanner une carte patient',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: YamColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Positionnez la carte QR du patient devant la caméra pour ouvrir son dossier médical.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: YamColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ouverture du scanner de carte...'),
                              backgroundColor: YamColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Ouvrir la caméra'),
                        style: FilledButton.styleFrom(
                          backgroundColor: YamColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: kButtonRadius,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showAppBar) {
      return _buildContent();
    }

    return Scaffold(
      backgroundColor: YamColors.pageBg,
      appBar: AppBar(
        backgroundColor: YamColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Dossier médical',
          style: TextStyle(
            color: YamColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: YamColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  /// Sélecteur d'onglets arrondi
  Widget _buildTabSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: YamColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YamColors.border),
      ),
      child: Row(
        children: [
          _buildTabButton('Rechercher', Icons.search_rounded, 0),
          const SizedBox(width: 6),
          _buildTabButton('Scanner carte', Icons.qr_code_scanner_rounded, 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: isActive ? YamColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: YamColors.border.withValues(alpha: 0.5), width: 1)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: isActive ? YamColors.primary : YamColors.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? YamColors.primary : YamColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Barre de recherche
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded, color: YamColors.muted),
        hintText: 'Rechercher par nom ou téléphone...',
        filled: true,
        fillColor: YamColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: YamColors.primary, width: 2),
        ),
      ),
    );
  }
}

/// Carte patient
class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.patient, this.app});

  final Patient patient;
  final AppState? app;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YamColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: kCardRadius,
        side: BorderSide(color: YamColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailsScreen(patient: patient, app: app),
            ),
          );
        },
        borderRadius: kCardRadius,
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar initiales
              CircleAvatar(
                radius: 22,
                backgroundColor: YamColors.primarySoft,
                child: Text(
                  patient.initials,
                  style: const TextStyle(
                    color: YamColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Infos patient
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: YamColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      patient.telephone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: YamColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Né le ${patient.dateNaissance}',
                      style: TextStyle(
                        fontSize: 12,
                        color: YamColors.muted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: YamColors.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
