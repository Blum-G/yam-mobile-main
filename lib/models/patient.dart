class Patient {
  const Patient({
    required this.nom,
    required this.telephone,
    required this.dateNaissance,
    this.id = '',
    this.groupeSanguin = 'O+',
    this.sexe = 'Masculin',
    this.adresse = 'Lomé, Quartier Tokoin',
    this.contactUrgence = 'Paul KOFFI (+228 90 00 11 22)',
    this.allergies = const ['Pénicilline', 'Aspirine'],
    this.antecedents = const [
      'Hypertension artérielle',
      'Appendicectomie (2015)',
    ],
  });

  final String nom;
  final String telephone;
  final String dateNaissance;

  /// Identifiant lu dans la carte QR (ex: `PAT-2024-00123`).
  final String id;

  final String groupeSanguin;
  final String sexe;
  final String adresse;
  final String contactUrgence;
  final List<String> allergies;
  final List<String> antecedents;

  String get initials {
    final parts = nom.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom.substring(0, 2).toUpperCase();
  }

  /// Normalise un code patient pour la comparaison (casse et espaces ignorés).
  static String normalizeId(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  int get age {
    try {
      final parts = dateNaissance.split('/');
      if (parts.length == 3) {
        final birthYear = int.parse(parts[2]);
        final currentYear = DateTime.now().year;
        return currentYear - birthYear;
      }
    } catch (_) {}
    return 41; // Valeur de repli
  }
}
