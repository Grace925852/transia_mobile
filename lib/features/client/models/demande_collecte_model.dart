enum StatutCollecte {
  enAttente,
  enCours,
  collecte,
  annule,
}

StatutCollecte statutCollecteFromJson(String? v) {
  switch (v) {
    case 'EN_COURS': return StatutCollecte.enCours;
    case 'COLLECTE': return StatutCollecte.collecte;
    case 'ANNULE': return StatutCollecte.annule;
    default: return StatutCollecte.enAttente;
  }
}

String statutCollecteLabel(StatutCollecte s) {
  switch (s) {
    case StatutCollecte.enAttente: return 'En attente';
    case StatutCollecte.enCours: return 'Livreur assigné';
    case StatutCollecte.collecte: return 'Collectée';
    case StatutCollecte.annule: return 'Annulée';
  }
}

class DemandeCollecteModel {
  final String id;
  final String adresseCollecte;
  final double? latitude;
  final double? longitude;
  final String dateHeureCollecte;
  final StatutCollecte statut;
  final String? agenceNom;
  final String? livreurNom;
  final String? colisId;
  final String? colisNumeroSuivi;

  const DemandeCollecteModel({
    required this.id,
    required this.adresseCollecte,
    this.latitude,
    this.longitude,
    required this.dateHeureCollecte,
    required this.statut,
    this.agenceNom,
    this.livreurNom,
    this.colisId,
    this.colisNumeroSuivi,
  });

  factory DemandeCollecteModel.fromJson(Map<String, dynamic> json) {
    return DemandeCollecteModel(
      id: json['id']?.toString() ?? '',
      adresseCollecte: json['adresseCollecte']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dateHeureCollecte: json['dateHeureCollecte']?.toString() ?? '',
      statut: statutCollecteFromJson(json['statut']?.toString()),
      agenceNom: json['agenceNom']?.toString(),
      livreurNom: json['livreurNom']?.toString(),
      colisId: json['colisId']?.toString(),
      colisNumeroSuivi: json['colisNumeroSuivi']?.toString(),
    );
  }
}

class DemandeCollecteRequest {
  final String adresseCollecte;
  final double? latitude;
  final double? longitude;
  final String dateHeureCollecte;
  final String agenceId;

  const DemandeCollecteRequest({
    required this.adresseCollecte,
    this.latitude,
    this.longitude,
    required this.dateHeureCollecte,
    required this.agenceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'adresseCollecte': adresseCollecte,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'dateHeureCollecte': dateHeureCollecte,
      'agenceId': agenceId,
    };
  }
}
