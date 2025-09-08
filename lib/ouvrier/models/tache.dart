class Tache {
  final int? id;
  final String? trackingId;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final bool isActiver;
  final bool isResolu;
  final String? signalementTitre;
  final String? signalementDescription;
  final String? signalementStatut;
  final String? pdfPath;
  final String? statutRapport;

  Tache({
    this.id,
    this.trackingId,
    this.dateDebut,
    this.dateFin,
    required this.isActiver,
    required this.isResolu,
    this.signalementTitre,
    this.signalementDescription,
    this.signalementStatut,
    this.pdfPath,
    this.statutRapport,
  });

  factory Tache.fromJson(Map<String, dynamic> json) {
    return Tache(
      id: json['id'],
      trackingId: json['trackingId'],
      dateDebut:
          json['dateDebut'] != null ? DateTime.parse(json['dateDebut']) : null,
      dateFin: json['dateFin'] != null ? DateTime.parse(json['dateFin']) : null,
      isActiver: json['isActiver'] ?? false,
      isResolu: json['isResolu'] ?? false,
      signalementTitre: json['signalement']?['titre'],
      signalementDescription: json['signalement']?['description'],
      signalementStatut: json['signalement']?['statut'],
      pdfPath: json['pdfPath'],
      statutRapport: json['statutRapport'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingId': trackingId,
      'dateDebut': dateDebut?.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'isActiver': isActiver,
      'isResolu': isResolu,
      'signalement': {
        'titre': signalementTitre,
        'description': signalementDescription,
        'statut': signalementStatut,
      },
      'statutRapport': statutRapport,
    };
  }

  Tache copyWith({
    int? id,
    String? trackingId,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? isActiver,
    bool? isResolu,
    String? signalementTitre,
    String? signalementDescription,
    String? signalementStatut,
    String? statutRapport,
  }) {
    return Tache(
      id: id ?? this.id,
      trackingId: trackingId ?? this.trackingId,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      isActiver: isActiver ?? this.isActiver,
      isResolu: isResolu ?? this.isResolu,
      signalementTitre: signalementTitre ?? this.signalementTitre,
      signalementDescription:
          signalementDescription ?? this.signalementDescription,
      signalementStatut: signalementStatut ?? this.signalementStatut,
      statutRapport: statutRapport ?? this.statutRapport,
    );
  }

  @override
  String toString() {
    return 'Tache(id: $id, trackingId: $trackingId, dateDebut: $dateDebut, dateFin: $dateFin, isActiver: $isActiver, isResolu: $isResolu)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tache && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Ajout d'un getter pour accéder à un objet Signalement depuis Tache
  Signalement? get signalement {
    if (signalementTitre != null ||
        signalementDescription != null ||
        signalementStatut != null) {
      return Signalement(
        id: id ?? 0,
        titre: signalementTitre ?? '',
        description: signalementDescription ?? '',
        statut: signalementStatut ?? '',
        typeService: '',
        serviceId: 0,
      );
    }
    return null;
  }
}

class EtatDeTache {
  final String statut;
  final DateTime date;
  final String commentaire;

  EtatDeTache({
    required this.statut,
    required this.date,
    required this.commentaire,
  });

  factory EtatDeTache.fromJson(Map<String, dynamic> json) {
    return EtatDeTache(
      statut: json['statut'] ?? '',
      date: DateTime.parse(json['date']),
      commentaire: json['commentaire'] ?? '',
    );
  }
}

class Signalement {
  final int id;
  final String titre;
  final String description;
  final String statut;
  final String typeService;
  final int serviceId;
  final String? commentaireService;
  final int? priorite;
  final String? latitude;
  final String? longitude;

  Signalement({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.typeService,
    required this.serviceId,
    this.commentaireService,
    this.priorite,
    this.latitude,
    this.longitude,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    return Signalement(
      id: json['id'],
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      statut: json['statut'] ?? '',
      typeService: json['typeService'] ?? '',
      serviceId: json['serviceId'],
      commentaireService: json['commentaireService'],
      priorite: json['priorite'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
