export 'package:transia_mobile/features/client/models/colis_model.dart'
    show
        TranchePoids,
        StatutColis,
        StatutPaiementColis,
        ModeRemise,
        statutColisFromJson,
        statutColisLabel,
        modeRemiseLabel,
        trancheLabel;

import 'package:transia_mobile/features/client/models/colis_model.dart';

class LivreurColisModel {
  final String id;
  final String numeroSuivi;
  final String description;
  final TranchePoids tranchePoids;
  final StatutColis statut;
  final StatutPaiementColis statutPaiement;
  final ModeRemise modeRemise;
  final String destinataireNom;
  final String destinataireTelephone;
  final String? destinataireAdresse;
  final String? agenceDepartNom;
  final String? agenceArriveeNom;
  final String? dateCreation;

  const LivreurColisModel({
    required this.id,
    required this.numeroSuivi,
    required this.description,
    required this.tranchePoids,
    required this.statut,
    required this.statutPaiement,
    required this.modeRemise,
    required this.destinataireNom,
    required this.destinataireTelephone,
    this.destinataireAdresse,
    this.agenceDepartNom,
    this.agenceArriveeNom,
    this.dateCreation,
  });

  factory LivreurColisModel.fromJson(Map<String, dynamic> json) {
    return LivreurColisModel(
      id: json['id']?.toString() ?? '',
      numeroSuivi: json['numeroSuivi']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tranchePoids: trancheFromJson(json['tranchePoids']?.toString()),
      statut: statutColisFromJson(json['statut']?.toString()),
      statutPaiement: statutPaiementFromJson(json['statutPaiement']?.toString()),
      modeRemise: modeRemiseFromJson(json['modeRemise']?.toString()),
      destinataireNom: json['destinataireNom']?.toString() ?? '',
      destinataireTelephone: json['destinataireTelephone']?.toString() ?? '',
      destinataireAdresse: json['destinataireAdresse']?.toString(),
      agenceDepartNom: json['agenceDepartNom']?.toString(),
      agenceArriveeNom: json['agenceArriveeNom']?.toString(),
      dateCreation: json['dateCreation']?.toString(),
    );
  }
}
