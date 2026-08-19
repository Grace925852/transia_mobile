class TrajetModel {
  final String id;
  final String villeDepart;
  final String villeArrivee;
  final String? agenceDepartNom;
  final String? agenceDepartAdresse;
  final String? agenceArriveeNom;
  final String? agenceArriveeAdresse;
  final String vehiculeImmatriculation;
  final String? vehiculeImage;
  final double distance;
  final String dureeEstimee;
  final double tarif;
  final String dateDepart;
  final String heureDepart;
  final String statut;
  final int capacite;

  TrajetModel({
    required this.id,
    required this.villeDepart,
    required this.villeArrivee,
    this.agenceDepartNom,
    this.agenceDepartAdresse,
    this.agenceArriveeNom,
    this.agenceArriveeAdresse,
    required this.vehiculeImmatriculation,
    required this.vehiculeImage,
    required this.distance,
    required this.dureeEstimee,
    required this.tarif,
    required this.dateDepart,
    required this.heureDepart,
    required this.statut,
    required this.capacite,
  });

  factory TrajetModel.fromJson(Map<String, dynamic> json) {
    final villeDepartData = json['villeDepart'];
    final villeArriveeData = json['villeArrivee'];
    final vehiculeData = json['vehicule'];
    final agenceDepartData = json['agenceDepart'];
    final agenceArriveeData = json['agenceArrivee'];

    int parsedCapacite = 0;

    if (vehiculeData is Map) {
      parsedCapacite =
          int.tryParse(vehiculeData['capacite']?.toString() ?? '0') ?? 0;
    }

    if (parsedCapacite <= 0) {
      parsedCapacite = int.tryParse(json['capacite']?.toString() ?? '0') ?? 0;
    }

    if (parsedCapacite <= 0) {
      parsedCapacite =
          int.tryParse(json['nombrePlaces']?.toString() ?? '0') ?? 0;
    }

    String? parsedAgenceDepartNom;
    String? parsedAgenceDepartAdresse;
    if (agenceDepartData is Map) {
      parsedAgenceDepartNom = agenceDepartData['nom']?.toString();
      parsedAgenceDepartAdresse = agenceDepartData['adresse']?.toString();
    }
    parsedAgenceDepartNom ??= json['agenceDepartNom']?.toString() ?? json['agenceNom']?.toString();
    parsedAgenceDepartAdresse ??= json['agenceDepartAdresse']?.toString();

    String? parsedAgenceArriveeNom;
    String? parsedAgenceArriveeAdresse;
    if (agenceArriveeData is Map) {
      parsedAgenceArriveeNom = agenceArriveeData['nom']?.toString();
      parsedAgenceArriveeAdresse = agenceArriveeData['adresse']?.toString();
    }
    parsedAgenceArriveeNom ??= json['agenceArriveeNom']?.toString();
    parsedAgenceArriveeAdresse ??= json['agenceArriveeAdresse']?.toString();

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
      agenceDepartNom: parsedAgenceDepartNom,
      agenceDepartAdresse: parsedAgenceDepartAdresse,
      agenceArriveeNom: parsedAgenceArriveeNom,
      agenceArriveeAdresse: parsedAgenceArriveeAdresse,
      vehiculeImmatriculation: vehiculeData is Map
          ? vehiculeData['immatriculation']?.toString() ?? ''
          : json['vehiculeImmatriculation']?.toString() ??
              json['immatriculation']?.toString() ??
              '',
      vehiculeImage: vehiculeData is Map
          ? vehiculeData['image']?.toString()
          : json['vehiculeImage']?.toString(),
      distance: double.tryParse(json['distance']?.toString() ?? '0') ?? 0,
      dureeEstimee: json['dureeEstimee']?.toString() ?? '',
      tarif: double.tryParse(json['tarif']?.toString() ?? '0') ?? 0,
      dateDepart: json['dateDepart']?.toString() ?? '',
      heureDepart: json['heureDepart']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      capacite: parsedCapacite,
    );
  }

  bool get aPhotoVehicule =>
      vehiculeImage != null && vehiculeImage!.trim().isNotEmpty;

  String get prixFormate {
    return '${tarif.toStringAsFixed(0)} FCFA';
  }

  String get heureFormatee {
    if (heureDepart.length >= 5) {
      return heureDepart.substring(0, 5);
    }
    return heureDepart;
  }

  String get dateFormatee {
    if (dateDepart.trim().isEmpty) return '';
    try {
      if (dateDepart.contains('-')) {
        final parts = dateDepart.split('-');
        if (parts.length == 3) {
          final year = parts[0].length == 4 ? parts[0].substring(2) : parts[0];
          return '${parts[2]}/${parts[1]}/$year';
        }
      }
    } catch (_) {}
    return dateDepart;
  }

  String get dateHeureFormatee {
    final h = heureFormatee;
    final d = dateFormatee;
    if (d.isNotEmpty && h.isNotEmpty) {
      return '$d à $h';
    } else if (d.isNotEmpty) {
      return d;
    }
    return h;
  }
}