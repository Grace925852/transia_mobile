import 'package:transia_mobile/features/client/models/demande_collecte_model.dart';

class LivreurTourneeModel {
  final String id;
  final String dateTournee;
  final String? zone;
  final String statut;
  final List<DemandeCollecteModel> demandesCollecte;

  const LivreurTourneeModel({
    required this.id,
    required this.dateTournee,
    this.zone,
    required this.statut,
    this.demandesCollecte = const [],
  });

  factory LivreurTourneeModel.fromJson(Map<String, dynamic> json) {
    var demandes = <DemandeCollecteModel>[];
    if (json['demandesCollecte'] is List) {
      demandes = (json['demandesCollecte'] as List)
          .whereType<Map<String, dynamic>>()
          .map(DemandeCollecteModel.fromJson)
          .toList();
    }
    return LivreurTourneeModel(
      id: json['id']?.toString() ?? '',
      dateTournee: json['dateTournee']?.toString() ?? '',
      zone: json['zone']?.toString(),
      statut: json['statut']?.toString() ?? 'PLANIFIEE',
      demandesCollecte: demandes,
    );
  }
}
