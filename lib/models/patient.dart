class Patient {
  const Patient({
    required this.nom,
    required this.telephone,
    required this.dateNaissance,
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
