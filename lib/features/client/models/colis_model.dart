enum TranchePoids {
  moinsDe1kg,
  de1a5kg,
  de5a10kg,
  de10a20kg,
  plusDe20kg,
}

enum StatutColis {
  enAttenteDepot,
  deposeEnAgence,
  enTransit,
  arriveEnAgence,
  enCoursLivraison,
  livre,
  retourne,
  perdu,
  annule,
}

enum StatutPaiementColis {
  enAttente,
  partiellementPaye,
  paye,
}

enum ModeRemise {
  livraisonDomicile,
  retraitAgence,
}

TranchePoids trancheFromJson(String? v) {
  switch (v) {
    case 'MOINS_DE_1KG': return TranchePoids.moinsDe1kg;
    case 'DE_1_A_5KG': return TranchePoids.de1a5kg;
    case 'DE_5_A_10KG': return TranchePoids.de5a10kg;
    case 'DE_10_A_20KG': return TranchePoids.de10a20kg;
    case 'PLUS_DE_20KG': return TranchePoids.plusDe20kg;
    default: return TranchePoids.moinsDe1kg;
  }
}

String trancheToJson(TranchePoids t) {
  switch (t) {
    case TranchePoids.moinsDe1kg: return 'MOINS_DE_1KG';
    case TranchePoids.de1a5kg: return 'DE_1_A_5KG';
    case TranchePoids.de5a10kg: return 'DE_5_A_10KG';
    case TranchePoids.de10a20kg: return 'DE_10_A_20KG';
    case TranchePoids.plusDe20kg: return 'PLUS_DE_20KG';
  }
}

String trancheLabel(TranchePoids t) {
  switch (t) {
    case TranchePoids.moinsDe1kg: return 'Moins de 1 kg';
    case TranchePoids.de1a5kg: return '1 à 5 kg';
    case TranchePoids.de5a10kg: return '5 à 10 kg';
    case TranchePoids.de10a20kg: return '10 à 20 kg';
    case TranchePoids.plusDe20kg: return 'Plus de 20 kg';
  }
}

StatutColis statutColisFromJson(String? v) {
  switch (v) {
    case 'EN_ATTENTE_DEPOT': return StatutColis.enAttenteDepot;
    case 'DEPOSE_EN_AGENCE': return StatutColis.deposeEnAgence;
    case 'EN_TRANSIT': return StatutColis.enTransit;
    case 'ARRIVE_EN_AGENCE': return StatutColis.arriveEnAgence;
    case 'EN_COURS_LIVRAISON': return StatutColis.enCoursLivraison;
    case 'LIVRE': return StatutColis.livre;
    case 'RETOURNE': return StatutColis.retourne;
    case 'PERDU': return StatutColis.perdu;
    case 'ANNULE': return StatutColis.annule;
    default: return StatutColis.enAttenteDepot;
  }
}

String statutColisLabel(StatutColis s) {
  switch (s) {
    case StatutColis.enAttenteDepot: return 'En attente de dépôt';
    case StatutColis.deposeEnAgence: return 'Déposé en agence';
    case StatutColis.enTransit: return 'En transit';
    case StatutColis.arriveEnAgence: return 'Arrivé en agence';
    case StatutColis.enCoursLivraison: return 'En cours de livraison';
    case StatutColis.livre: return 'Livré';
    case StatutColis.retourne: return 'Retourné';
    case StatutColis.perdu: return 'Perdu';
    case StatutColis.annule: return 'Annulé';
  }
}

StatutPaiementColis statutPaiementFromJson(String? v) {
  switch (v) {
    case 'PARTIELLEMENT_PAYE': return StatutPaiementColis.partiellementPaye;
    case 'PAYE': return StatutPaiementColis.paye;
    default: return StatutPaiementColis.enAttente;
  }
}

String statutPaiementLabel(StatutPaiementColis s) {
  switch (s) {
    case StatutPaiementColis.enAttente: return 'Non payé';
    case StatutPaiementColis.partiellementPaye: return 'Partiellement payé';
    case StatutPaiementColis.paye: return 'Payé';
  }
}

ModeRemise modeRemiseFromJson(String? v) {
  switch (v) {
    case 'LIVRAISON_DOMICILE': return ModeRemise.livraisonDomicile;
    default: return ModeRemise.retraitAgence;
  }
}

String modeRemiseToJson(ModeRemise m) {
  switch (m) {
    case ModeRemise.livraisonDomicile: return 'LIVRAISON_DOMICILE';
    case ModeRemise.retraitAgence: return 'RETRAIT_AGENCE';
  }
}

String modeRemiseLabel(ModeRemise m) {
  switch (m) {
    case ModeRemise.livraisonDomicile: return 'Livraison à domicile';
    case ModeRemise.retraitAgence: return 'Retrait en agence';
  }
}

class ColisModel {
  final String id;
  final String numeroSuivi;
  final String description;
  final TranchePoids tranchePoids;
  final double? poidsReel;
  final String? dimensions;
  final StatutColis statut;
  final StatutPaiementColis statutPaiement;
  final ModeRemise modeRemise;
  final String expediteurNom;
  final String expediteurTelephone;
  final String destinataireNom;
  final String destinataireTelephone;
  final String? destinataireAdresse;
  final double? prixEstime;
  final double? prixFinal;
  final double fraisCollecte;
  final double fraisLivraison;
  final String? dateCreation;
  final String? dateLivraison;
  final String? agenceDepartNom;
  final String? agenceArriveeNom;
  final String? qrCode;

  const ColisModel({
    required this.id,
    required this.numeroSuivi,
    required this.description,
    required this.tranchePoids,
    this.poidsReel,
    this.dimensions,
    required this.statut,
    required this.statutPaiement,
    required this.modeRemise,
    required this.expediteurNom,
    required this.expediteurTelephone,
    required this.destinataireNom,
    required this.destinataireTelephone,
    this.destinataireAdresse,
    this.prixEstime,
    this.prixFinal,
    this.fraisCollecte = 0,
    this.fraisLivraison = 0,
    this.dateCreation,
    this.dateLivraison,
    this.agenceDepartNom,
    this.agenceArriveeNom,
    this.qrCode,
  });

  factory ColisModel.fromJson(Map<String, dynamic> json) {
    return ColisModel(
      id: json['id']?.toString() ?? '',
      numeroSuivi: json['numeroSuivi']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tranchePoids: trancheFromJson(json['tranchePoids']?.toString()),
      poidsReel: (json['poidsReel'] as num?)?.toDouble(),
      dimensions: json['dimensions']?.toString(),
      statut: statutColisFromJson(json['statut']?.toString()),
      statutPaiement: statutPaiementFromJson(json['statutPaiement']?.toString()),
      modeRemise: modeRemiseFromJson(json['modeRemise']?.toString()),
      expediteurNom: json['expediteurNom']?.toString() ?? '',
      expediteurTelephone: json['expediteurTelephone']?.toString() ?? '',
      destinataireNom: json['destinataireNom']?.toString() ?? '',
      destinataireTelephone: json['destinataireTelephone']?.toString() ?? '',
      destinataireAdresse: json['destinataireAdresse']?.toString(),
      prixEstime: (json['prixEstime'] as num?)?.toDouble(),
      prixFinal: (json['prixFinal'] as num?)?.toDouble(),
      fraisCollecte: (json['fraisCollecte'] as num?)?.toDouble() ?? 0,
      fraisLivraison: (json['fraisLivraison'] as num?)?.toDouble() ?? 0,
      dateCreation: json['dateCreation']?.toString(),
      dateLivraison: json['dateLivraison']?.toString(),
      agenceDepartNom: json['agenceDepartNom']?.toString(),
      agenceArriveeNom: json['agenceArriveeNom']?.toString(),
      qrCode: json['qrCode']?.toString(),
    );
  }
}

class ColisRequest {
  final String description;
  final TranchePoids tranchePoids;
  final String? dimensions;
  final ModeRemise modeRemise;
  final String expediteurNom;
  final String expediteurTelephone;
  final String destinataireNom;
  final String destinataireTelephone;
  final String? destinataireAdresse;
  final String agenceDepartId;
  final String agenceArriveeId;
  final bool collecteDomicile;

  const ColisRequest({
    required this.description,
    required this.tranchePoids,
    this.dimensions,
    required this.modeRemise,
    required this.expediteurNom,
    required this.expediteurTelephone,
    required this.destinataireNom,
    required this.destinataireTelephone,
    this.destinataireAdresse,
    required this.agenceDepartId,
    required this.agenceArriveeId,
    this.collecteDomicile = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'tranchePoids': trancheToJson(tranchePoids),
      if (dimensions != null) 'dimensions': dimensions,
      'modeRemise': modeRemiseToJson(modeRemise),
      'expediteurNom': expediteurNom,
      'expediteurTelephone': expediteurTelephone,
      'destinataireNom': destinataireNom,
      'destinataireTelephone': destinataireTelephone,
      if (destinataireAdresse != null) 'destinataireAdresse': destinataireAdresse,
      'agenceDepartId': agenceDepartId,
      'agenceArriveeId': agenceArriveeId,
      'collecteDomicile': collecteDomicile,
    };
  }
}

class EstimationPrixModel {
  final double prixExpedition;
  final double fraisCollecte;
  final double fraisLivraison;
  final double totalEstime;

  const EstimationPrixModel({
    required this.prixExpedition,
    required this.fraisCollecte,
    required this.fraisLivraison,
    required this.totalEstime,
  });

  factory EstimationPrixModel.fromJson(Map<String, dynamic> json) {
    return EstimationPrixModel(
      prixExpedition: (json['prixExpedition'] as num?)?.toDouble() ?? 0,
      fraisCollecte: (json['fraisCollecte'] as num?)?.toDouble() ?? 0,
      fraisLivraison: (json['fraisLivraison'] as num?)?.toDouble() ?? 0,
      totalEstime: (json['totalEstime'] as num?)?.toDouble() ?? 0,
    );
  }
}
