class ChauffeurTripModel {
  final String id;
  final String villeDepart;
  final String villeArrivee;
  final String dateDepart;
  final String heureDepart;
  final String vehiculeImmatriculation;
  final double tarif;
  final String statut;
  final Map<String, dynamic> rawData;

  ChauffeurTripModel({
    required this.id,
    required this.villeDepart,
    required this.villeArrivee,
    required this.dateDepart,
    required this.heureDepart,
    required this.vehiculeImmatriculation,
    required this.tarif,
    required this.statut,
    required this.rawData,
  });

  factory ChauffeurTripModel.fromJson(Map<String, dynamic> json) {
    final dynamic villeDepartData = json['villeDepart'] ?? json['villeDepartDto'];
    final dynamic villeArriveeData =
        json['villeArrivee'] ?? json['villeArriveeDto'];
    final dynamic vehiculeData = json['vehicule'] ?? json['vehiculeDto'];

    final villeDepart =
        (villeDepartData is Map
                ? (villeDepartData['nomVille'] ??
                    villeDepartData['name'] ??
                    villeDepartData['libelle'])
                : (json['villeDepartNom'] ?? json['nomVilleDepart']))
            ?.toString() ??
            '';

    final villeArrivee =
        (villeArriveeData is Map
                ? (villeArriveeData['nomVille'] ??
                    villeArriveeData['name'] ??
                    villeArriveeData['libelle'])
                : (json['villeArriveeNom'] ?? json['nomVilleArrivee']))
            ?.toString() ??
            '';

    final vehiculeImmatriculation =
        (vehiculeData is Map
                ? (vehiculeData['immatriculation'] ??
                    vehiculeData['matricule'] ??
                    vehiculeData['plaque'])
                : (json['vehiculeImmatriculation'] ?? json['immatriculation']))
            ?.toString() ??
            '';

    return ChauffeurTripModel(
      id: (json['id'] ?? '').toString(),
      villeDepart: villeDepart,
      villeArrivee: villeArrivee,
      dateDepart: (json['dateDepart'] ?? json['date'] ?? '').toString(),
      heureDepart: (json['heureDepart'] ?? json['heure'] ?? '').toString(),
      vehiculeImmatriculation: vehiculeImmatriculation,
      tarif: double.tryParse((json['tarif'] ?? json['prix'] ?? 0).toString()) ?? 0,
      statut: (json['statut'] ?? '').toString(),
      rawData: json,
    );
  }

  String get trajetLabel => '$villeDepart → $villeArrivee';

  String get heureFormatee {
    if (heureDepart.length >= 5) return heureDepart.substring(0, 5);
    return heureDepart;
  }

  String get tarifFormate => '${tarif.toStringAsFixed(0)} FCFA';
}