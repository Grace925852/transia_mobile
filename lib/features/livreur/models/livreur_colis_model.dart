import 'package:transia_mobile/features/client/models/colis_model.dart';

export 'package:transia_mobile/features/client/models/colis_model.dart'
    show
        StatutColis,
        ModeDepot,
        ModeRemise,
        statutColisFromJson,
        statutColisToJson,
        statutColisLabel,
        modeDepotLabel,
        modeRemiseLabel;

class LivreurColisModel {
  final String id;
  final String numeroSuivi;
  final String nomDestinataire;
  final String adresseDestinataire;
  final String telephoneDestinataire;
  final double poids;
  final StatutColis statut;
  final ModeRemise modeRemise;
  final String? villeDepartNom;
  final String? villeArriveeNom;
  final String? remarques;
  final String? dateCreation;
  final String? livreurId;

  const LivreurColisModel({
    required this.id,
    required this.numeroSuivi,
    required this.nomDestinataire,
    required this.adresseDestinataire,
    required this.telephoneDestinataire,
    required this.poids,
    required this.statut,
    required this.modeRemise,
    this.villeDepartNom,
    this.villeArriveeNom,
    this.remarques,
    this.dateCreation,
    this.livreurId,
  });

  factory LivreurColisModel.fromJson(Map<String, dynamic> json) {
    return LivreurColisModel(
      id: json['id']?.toString() ?? '',
      numeroSuivi: json['numeroSuivi']?.toString() ?? '',
      nomDestinataire: json['nomDestinataire']?.toString() ?? '',
      adresseDestinataire: json['adresseDestinataire']?.toString() ?? '',
      telephoneDestinataire: json['telephoneDestinataire']?.toString() ?? '',
      poids: (json['poids'] as num?)?.toDouble() ?? 0,
      statut: statutColisFromJson(json['statut']?.toString()),
      modeRemise: modeRemiseFromJson(json['modeRemise']?.toString()),
      villeDepartNom: json['villeDepartNom']?.toString(),
      villeArriveeNom: json['villeArriveeNom']?.toString(),
      remarques: json['remarques']?.toString(),
      dateCreation: json['dateCreation']?.toString(),
      livreurId: json['livreurId']?.toString(),
    );
  }

  ColisModel toColisModel() {
    return ColisModel(
      id: id,
      numeroSuivi: numeroSuivi,
      nomDestinataire: nomDestinataire,
      adresseDestinataire: adresseDestinataire,
      telephoneDestinataire: telephoneDestinataire,
      poids: poids,
      longueur: 0,
      largeur: 0,
      hauteur: 0,
      statut: statut,
      modeDepot: ModeDepot.depotAgence,
      modeRemise: modeRemise,
      remarques: remarques,
      dateCreation: dateCreation,
      villeDepartNom: villeDepartNom,
      villeArriveeNom: villeArriveeNom,
      livreurId: livreurId,
    );
  }
}
