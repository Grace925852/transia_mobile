class TrajetModel {
  final String id;
  final String villeDepart;
  final String villeArrivee;
  final String vehiculeImmatriculation;
  final double distance;
  final String dureeEstimee;
  final double tarif;
  final String dateDepart;
  final String heureDepart;
  final String statut;

  TrajetModel({
    required this.id,
    required this.villeDepart,
    required this.villeArrivee,
    required this.vehiculeImmatriculation,
    required this.distance,
    required this.dureeEstimee,
    required this.tarif,
    required this.dateDepart,
    required this.heureDepart,
    required this.statut,
  });

  factory TrajetModel.fromJson(Map<String, dynamic> json) {
    final villeDepartData = json['villeDepart'];
    final villeArriveeData = json['villeArrivee'];
    final vehiculeData = json['vehicule'];

    return TrajetModel(
      id: json['id']?.toString() ?? '',

      villeDepart: villeDepartData is Map
          ? villeDepartData['nomVille']?.toString() ?? ''
          : json['villeDepartNom']?.toString() ??
              json['nomVilleDepart']?.toString() ??
              '',

      villeArrivee: villeArriveeData is Map
          ? villeArriveeData['nomVille']?.toString() ?? ''
          : json['villeArriveeNom']?.toString() ??
              json['nomVilleArrivee']?.toString() ??
              '',

      vehiculeImmatriculation: vehiculeData is Map
          ? vehiculeData['immatriculation']?.toString() ?? ''
          : json['vehiculeImmatriculation']?.toString() ??
              json['immatriculation']?.toString() ??
              '',

      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0,
      dureeEstimee: json['dureeEstimee']?.toString() ?? '',
      tarif: double.tryParse(json['tarif']?.toString() ?? '0') ?? 0,
      dateDepart: json['dateDepart']?.toString() ?? '',
      heureDepart: json['heureDepart']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
    );
  }

  String get prixFormate {
    return '${tarif.toStringAsFixed(0)} FCFA';
  }

  String get heureFormatee {
    if (heureDepart.length >= 5) {
      return heureDepart.substring(0, 5);
    }
    return heureDepart;
  }
}