
class Ouvrier {
  final String trackingId;
  final String nom;
  final String prenom;
  final String cni;
  final String dateNaissance;
  final String email;
  final int numero;
  final String adresse;
  final String role;
  final String? specialite;
  final String? serviceId;
  final String? telephone;
  final String? service;

  Ouvrier({
    required this.trackingId,
    required this.nom,
    required this.prenom,
    required this.cni,
    required this.dateNaissance,
    required this.email,
    required this.numero,
    required this.adresse,
    required this.role,
    this.specialite,
    this.serviceId,
    this.telephone,
    this.service,
  });

  factory Ouvrier.fromJson(Map<String, dynamic> json) {
    return Ouvrier(
      trackingId: json['trackingId']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      cni: json['cni'] ?? '',
      dateNaissance: json['dateNaissance'] ?? '',
      email: json['email'] ?? '',
      numero: json['numero'] ?? 0,
      adresse: json['adresse'] ?? '',
      role: json['role']?.toString() ?? '',
      specialite: json['specialite']?.toString(),
      serviceId: json['serviceId']?.toString(),
      telephone: json['telephone']?.toString(),
      service: json['service']?.toString(),
    );
  }
}
