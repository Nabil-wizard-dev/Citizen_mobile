class Signalement {
  final String? trackingId;
  final String titre;
  final String code;
  final String description;
  final String statut;
  final String typeService;
  final int serviceId;
  final String? utilisateurCreateur;
  final List<String>? fichiers;
  final List<String>? fichiersPaths;
  final String? commentaireService;
  final int? priorite;
  final String? latitude;
  final String? longitude;
  final String? ouvrierUuid;
  final String? traiteurUuid;

  Signalement({
    this.trackingId,
    required this.titre,
    required this.code,
    required this.description,
    required this.statut,
    required this.typeService,
    required this.serviceId,
    this.utilisateurCreateur,
    this.fichiers,
    this.fichiersPaths,
    this.commentaireService,
    this.priorite,
    this.latitude,
    this.longitude,
    this.ouvrierUuid,
    this.traiteurUuid,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    return Signalement(
      trackingId: json['trackingId'],
      titre: json['titre'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      statut: json['statut'] ?? '',
      typeService: json['typeService'] ?? '',
      serviceId: json['serviceId'] ?? 1,
      utilisateurCreateur: json['utilisateurCreateur'],
      fichiers:
          json['fichiers'] != null ? List<String>.from(json['fichiers']) : null,
      fichiersPaths:
          json['fichiersPaths'] != null
              ? List<String>.from(json['fichiersPaths'])
              : null,
      commentaireService: json['commentaireService'],
      priorite: json['priorite'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      ouvrierUuid: json['ouvrierUuid'],
      traiteurUuid: json['traiteurUuid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trackingId': trackingId,
      'titre': titre,
      'code': code,
      'description': description,
      'statut': statut,
      'typeService': typeService,
      'serviceId': serviceId,
      'utilisateurCreateur': utilisateurCreateur,
      'fichiers': fichiers,
      'fichiersPaths': fichiersPaths,
      'commentaireService': commentaireService,
      'priorite': priorite,
      'latitude': latitude,
      'longitude': longitude,
      'ouvrierUuid': ouvrierUuid,
      'traiteurUuid': traiteurUuid,
    };
  }

  Signalement copyWith({
    String? trackingId,
    String? titre,
    String? code,
    String? description,
    String? statut,
    String? typeService,
    int? serviceId,
    String? utilisateurCreateur,
    List<String>? fichiers,
    List<String>? fichiersPaths,
    String? commentaireService,
    int? priorite,
    String? latitude,
    String? longitude,
    String? ouvrierUuid,
    String? traiteurUuid,
  }) {
    return Signalement(
      trackingId: trackingId ?? this.trackingId,
      titre: titre ?? this.titre,
      code: code ?? this.code,
      description: description ?? this.description,
      statut: statut ?? this.statut,
      typeService: typeService ?? this.typeService,
      serviceId: serviceId ?? this.serviceId,
      utilisateurCreateur: utilisateurCreateur ?? this.utilisateurCreateur,
      fichiers: fichiers ?? this.fichiers,
      fichiersPaths: fichiersPaths ?? this.fichiersPaths,
      commentaireService: commentaireService ?? this.commentaireService,
      priorite: priorite ?? this.priorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ouvrierUuid: ouvrierUuid ?? this.ouvrierUuid,
      traiteurUuid: traiteurUuid ?? this.traiteurUuid,
    );
  }

  @override
  String toString() {
    return 'Signalement(trackingId: $trackingId, titre: $titre, code: $code, description: $description, statut: $statut, typeService: $typeService, serviceId: $serviceId, priorite: $priorite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Signalement && other.trackingId == trackingId;
  }

  @override
  int get hashCode => trackingId.hashCode;
}

// Enums pour les types de service et statuts
enum TypeService { SERVICE_HYGIENE, SERVICE_MUNICIPAL }

enum StatutSignalement { EN_ATTENTE, EN_COURS, TRAITE, REJETE, ARCHIVE }

// Extension pour convertir les enums en String
extension TypeServiceExtension on TypeService {
  String get value {
    switch (this) {
      case TypeService.SERVICE_HYGIENE:
        return 'SERVICE_HYGIENE';
      case TypeService.SERVICE_MUNICIPAL:
        return 'SERVICE_MUNICIPAL';
    }
  }

  String get displayName {
    switch (this) {
      case TypeService.SERVICE_HYGIENE:
        return 'Service d\'Hygiène';
      case TypeService.SERVICE_MUNICIPAL:
        return 'Service Municipal';
    }
  }
}

extension StatutSignalementExtension on StatutSignalement {
  String get value {
    switch (this) {
      case StatutSignalement.EN_ATTENTE:
        return 'EN_ATTENTE';
      case StatutSignalement.EN_COURS:
        return 'EN_COURS';
      case StatutSignalement.TRAITE:
        return 'TRAITE';
      case StatutSignalement.REJETE:
        return 'REJETE';
      case StatutSignalement.ARCHIVE:
        return 'ARCHIVE';
    }
  }

  String get displayName {
    switch (this) {
      case StatutSignalement.EN_ATTENTE:
        return 'En Attente';
      case StatutSignalement.EN_COURS:
        return 'En Cours';
      case StatutSignalement.TRAITE:
        return 'Traité';
      case StatutSignalement.REJETE:
        return 'Rejeté';
      case StatutSignalement.ARCHIVE:
        return 'Archivé';
    }
  }

  String get color {
    switch (this) {
      case StatutSignalement.EN_ATTENTE:
        return '#FFA500'; // Orange
      case StatutSignalement.EN_COURS:
        return '#007BFF'; // Bleu
      case StatutSignalement.TRAITE:
        return '#28A745'; // Vert
      case StatutSignalement.REJETE:
        return '#DC3545'; // Rouge
      case StatutSignalement.ARCHIVE:
        return '#6C757D'; // Gris
    }
  }
}
