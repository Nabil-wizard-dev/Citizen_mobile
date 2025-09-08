class User {
  final String? trackingId;
  final String nom;
  final String prenom;
  final String cni;
  final String dateNaissance;
  final String email;
  final int numero;
  final String adresse;
  final String role;
  final String? photoProfil;

  User({
    this.trackingId,
    required this.nom,
    required this.prenom,
    required this.cni,
    required this.dateNaissance,
    required this.email,
    required this.numero,
    required this.adresse,
    required this.role,
    this.photoProfil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    dynamic role = json['role'] ?? json['roles'] ?? json['authorities'] ?? '';
    if (role is List && role.isNotEmpty) {
      role = role.first;
    }

    // Gérer le cas où on a seulement les données d'authentification
    if (json['token'] != null) {
      return User(
        trackingId: json['trackingId'],
        nom: json['nom'] ?? 'Utilisateur',
        prenom: json['prenom'] ?? '',
        cni: json['cni'] ?? '',
        dateNaissance: json['dateNaissance'] ?? '',
        email: json['email'] ?? '',
        numero: json['numero'] ?? 0,
        adresse: json['adresse'] ?? '',
        role: role.toString().toUpperCase(),
        photoProfil: json['photoProfil'],
      );
    }

    return User(
      trackingId: json['trackingId'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      cni: json['cni'] ?? '',
      dateNaissance: json['dateNaissance'] ?? '',
      email: json['email'] ?? '',
      numero: json['numero'] ?? 0,
      adresse: json['adresse'] ?? '',
      role: role.toString().toUpperCase(),
      photoProfil: json['photoProfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackingId': trackingId,
      'nom': nom,
      'prenom': prenom,
      'cni': cni,
      'dateNaissance': dateNaissance,
      'email': email,
      'numero': numero,
      'adresse': adresse,
      'role': role,
      'photoProfil': photoProfil,
    };
  }

  String get fullName => '$prenom $nom';

  @override
  String toString() {
    return 'User(trackingId: $trackingId, nom: $nom, prenom: $prenom, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.trackingId == trackingId;
  }

  @override
  int get hashCode => trackingId.hashCode;
}

// Enum pour les rôles utilisateur
enum UtilisateurRole {
  ADMINISTRATEUR,
  AUTORITE_LOCALE,
  OUVRIER,
  CITOYEN,
  SERVICE_HYGIENE,
  SERVICE_MUNICIPAL,
}

// Extension pour convertir les enums en String
extension UtilisateurRoleExtension on UtilisateurRole {
  String get value {
    switch (this) {
      case UtilisateurRole.ADMINISTRATEUR:
        return 'ADMINISTRATEUR';
      case UtilisateurRole.AUTORITE_LOCALE:
        return 'AUTORITE_LOCALE';
      case UtilisateurRole.OUVRIER:
        return 'OUVRIER';
      case UtilisateurRole.CITOYEN:
        return 'CITOYEN';
      case UtilisateurRole.SERVICE_HYGIENE:
        return 'SERVICE_HYGIENE';
      case UtilisateurRole.SERVICE_MUNICIPAL:
        return 'SERVICE_MUNICIPAL';
    }
  }

  String get displayName {
    switch (this) {
      case UtilisateurRole.ADMINISTRATEUR:
        return 'Administrateur';
      case UtilisateurRole.AUTORITE_LOCALE:
        return 'Autorité Locale';
      case UtilisateurRole.OUVRIER:
        return 'Ouvrier';
      case UtilisateurRole.CITOYEN:
        return 'Citoyen';
      case UtilisateurRole.SERVICE_HYGIENE:
        return 'Service d\'Hygiène';
      case UtilisateurRole.SERVICE_MUNICIPAL:
        return 'Service Municipal';
    }
  }
}
