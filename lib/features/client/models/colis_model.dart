enum StatutColis {
  enAttenteCollecte,
  prisEnCharge,
  collecteEffectuee,
  enCours,
  livre,
  annule,
}

enum ModeDepot {
  enlevementDomicile,
  depotAgence,
  creationAgence,
}

enum ModeRemise {
  livraisonDomicile,
  retraitAgence,
}

StatutColis statutColisFromJson(String? v) {
  switch (v) {
    case 'EN_ATTENTE_COLLECTE': return StatutColis.enAttenteCollecte;
    case 'PRIS_EN_CHARGE':      return StatutColis.prisEnCharge;
    case 'COLLECTE_EFFECTUEE':  return StatutColis.collecteEffectuee;
    case 'EN_COURS':            return StatutColis.enCours;
    case 'LIVRE':               return StatutColis.livre;
    case 'ANNULE':              return StatutColis.annule;
    default:                    return StatutColis.enAttenteCollecte;
  }
}

String statutColisToJson(StatutColis s) {
  switch (s) {
    case StatutColis.enAttenteCollecte: return 'EN_ATTENTE_COLLECTE';
    case StatutColis.prisEnCharge:      return 'PRIS_EN_CHARGE';
    case StatutColis.collecteEffectuee: return 'COLLECTE_EFFECTUEE';
    case StatutColis.enCours:           return 'EN_COURS';
    case StatutColis.livre:             return 'LIVRE';
    case StatutColis.annule:            return 'ANNULE';
  }
}

String statutColisLabel(StatutColis s) {
  switch (s) {
    case StatutColis.enAttenteCollecte: return 'En attente de collecte';
    case StatutColis.prisEnCharge:      return 'Pris en charge';
    case StatutColis.collecteEffectuee: return 'Collecté';
    case StatutColis.enCours:           return 'En cours de livraison';
    case StatutColis.livre:             return 'Livré';
    case StatutColis.annule:            return 'Annulé';
  }
}

ModeDepot modeDepotFromJson(String? v) {
  switch (v) {
    case 'ENLEVEMENT_DOMICILE': return ModeDepot.enlevementDomicile;
    case 'DEPOT_AGENCE':        return ModeDepot.depotAgence;
    default:                    return ModeDepot.creationAgence;
  }
}

String modeDepotToJson(ModeDepot m) {
  switch (m) {
    case ModeDepot.enlevementDomicile: return 'ENLEVEMENT_DOMICILE';
    case ModeDepot.depotAgence:        return 'DEPOT_AGENCE';
    case ModeDepot.creationAgence:     return 'CREATION_AGENCE';
  }
}

String modeDepotLabel(ModeDepot m) {
  switch (m) {
    case ModeDepot.enlevementDomicile: return 'Enlèvement à domicile';
    case ModeDepot.depotAgence:        return 'Dépôt en agence';
    case ModeDepot.creationAgence:     return 'Créé en agence';
  }
}

ModeRemise modeRemiseFromJson(String? v) {
  switch (v) {
    case 'LIVRAISON_DOMICILE': return ModeRemise.livraisonDomicile;
    default:                   return ModeRemise.retraitAgence;
  }
}

String modeRemiseToJson(ModeRemise m) {
  switch (m) {
    case ModeRemise.livraisonDomicile: return 'LIVRAISON_DOMICILE';
    case ModeRemise.retraitAgence:     return 'RETRAIT_AGENCE';
  }
}

String modeRemiseLabel(ModeRemise m) {
  switch (m) {
    case ModeRemise.livraisonDomicile: return 'Livraison à domicile';
    case ModeRemise.retraitAgence:     return 'Retrait en agence';
  }
}

class ColisModel {
  final String id;
  final String numeroSuivi;
  final String nomDestinataire;
  final String adresseDestinataire;
  final String telephoneDestinataire;
  final double poids;
  final double longueur;
  final double largeur;
  final double hauteur;
  final StatutColis statut;
  final ModeDepot modeDepot;
  final ModeRemise modeRemise;
  final String? adresseCollecte;
  final String? remarques;
  final String? dateCreation;
  final String? villeDepartNom;
  final String? villeArriveeNom;
  final String? expediteurId;
  final String? livreurId;

  const ColisModel({
    required this.id,
    required this.numeroSuivi,
    required this.nomDestinataire,
    required this.adresseDestinataire,
    required this.telephoneDestinataire,
    required this.poids,
    required this.longueur,
    required this.largeur,
    required this.hauteur,
    required this.statut,
    required this.modeDepot,
    required this.modeRemise,
    this.adresseCollecte,
    this.remarques,
    this.dateCreation,
    this.villeDepartNom,
    this.villeArriveeNom,
    this.expediteurId,
    this.livreurId,
  });

  factory ColisModel.fromJson(Map<String, dynamic> json) {
    return ColisModel(
      id: json['id']?.toString() ?? '',
      numeroSuivi: json['numeroSuivi']?.toString() ?? '',
      nomDestinataire: json['nomDestinataire']?.toString() ?? '',
      adresseDestinataire: json['adresseDestinataire']?.toString() ?? '',
      telephoneDestinataire: json['telephoneDestinataire']?.toString() ?? '',
      poids: (json['poids'] as num?)?.toDouble() ?? 0,
      longueur: (json['longueur'] as num?)?.toDouble() ?? 0,
      largeur: (json['largeur'] as num?)?.toDouble() ?? 0,
      hauteur: (json['hauteur'] as num?)?.toDouble() ?? 0,
      statut: statutColisFromJson(json['statut']?.toString()),
      modeDepot: modeDepotFromJson(json['modeDepot']?.toString()),
      modeRemise: modeRemiseFromJson(json['modeRemise']?.toString()),
      adresseCollecte: json['adresseCollecte']?.toString(),
      remarques: json['remarques']?.toString(),
      dateCreation: json['dateCreation']?.toString(),
      villeDepartNom: json['villeDepartNom']?.toString(),
      villeArriveeNom: json['villeArriveeNom']?.toString(),
      expediteurId: json['expediteurId']?.toString(),
      livreurId: json['livreurId']?.toString(),
    );
  }
}

class ColisRequest {
  final String? expediteurId;
  final String nomDestinataire;
  final String adresseDestinataire;
  final String telephoneDestinataire;
  final double poids;
  final double longueur;
  final double largeur;
  final double hauteur;
  final ModeDepot modeDepot;
  final ModeRemise modeRemise;
  final String? adresseCollecte;
  final String? remarques;
  final String? villeDepartId;
  final String? villeArriveeId;

  const ColisRequest({
    this.expediteurId,
    required this.nomDestinataire,
    required this.adresseDestinataire,
    required this.telephoneDestinataire,
    required this.poids,
    required this.longueur,
    required this.largeur,
    required this.hauteur,
    required this.modeDepot,
    required this.modeRemise,
    this.adresseCollecte,
    this.remarques,
    this.villeDepartId,
    this.villeArriveeId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (expediteurId != null && expediteurId!.isNotEmpty) 'expediteurId': expediteurId,
      'nomDestinataire': nomDestinataire,
      'adresseDestinataire': adresseDestinataire,
      'telephoneDestinataire': telephoneDestinataire,
      'poids': poids,
      'longueur': longueur,
      'largeur': largeur,
      'hauteur': hauteur,
      'modeDepot': modeDepotToJson(modeDepot),
      'modeRemise': modeRemiseToJson(modeRemise),
      if (adresseCollecte != null) 'adresseCollecte': adresseCollecte,
      if (remarques != null) 'remarques': remarques,
      if (villeDepartId != null) 'villeDepartId': villeDepartId,
      if (villeArriveeId != null) 'villeArriveeId': villeArriveeId,
    };
  }
}
