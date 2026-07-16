class ClientGpsPositionModel {
  final int? id;
  final double latitude;
  final double longitude;
  final double? vitesse;
  final double? precisionGps;
  final double? altitude;
  final DateTime? dateHeure;
  final int? suiviTrajetId;

  const ClientGpsPositionModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.vitesse,
    required this.precisionGps,
    required this.altitude,
    required this.dateHeure,
    required this.suiviTrajetId,
  });

  factory ClientGpsPositionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ClientGpsPositionModel(
      id: int.tryParse(
        json['id']?.toString() ?? '',
      ),
      latitude: double.tryParse(
            json['latitude']?.toString() ?? '',
          ) ??
          0,
      longitude: double.tryParse(
            json['longitude']?.toString() ?? '',
          ) ??
          0,
      vitesse: double.tryParse(
        json['vitesse']?.toString() ?? '',
      ),
      precisionGps: double.tryParse(
        json['precisionGps']?.toString() ?? '',
      ),
      altitude: double.tryParse(
        json['altitude']?.toString() ?? '',
      ),
      dateHeure: _parseDate(
        json['dateHeure'],
      ),
      suiviTrajetId: int.tryParse(
        json['suiviTrajetId']?.toString() ?? '',
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String get vitesseFormatee {
    if (vitesse == null) {
      return '-';
    }

    return '${vitesse!.toStringAsFixed(1)} km/h';
  }
}

class ClientTripTrackingModel {
  final int id;
  final String statut;
  final String trajetId;

  final String villeDepart;
  final String villeArrivee;

  final String chauffeurNom;
  final int? chauffeurId;

  final String vehicule;
  final String immatriculation;

  final String dateDepart;
  final String heureDepart;

  final DateTime? dateDemarrage;
  final DateTime? dateFin;
  final DateTime? derniereMiseAJour;

  final String message;
  final ClientGpsPositionModel? dernierePosition;

  const ClientTripTrackingModel({
    required this.id,
    required this.statut,
    required this.trajetId,
    required this.villeDepart,
    required this.villeArrivee,
    required this.chauffeurNom,
    required this.chauffeurId,
    required this.vehicule,
    required this.immatriculation,
    required this.dateDepart,
    required this.heureDepart,
    required this.dateDemarrage,
    required this.dateFin,
    required this.derniereMiseAJour,
    required this.message,
    required this.dernierePosition,
  });

  factory ClientTripTrackingModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final positionData = json['dernierePosition'];

    return ClientTripTrackingModel(
      id: int.tryParse(
            json['id']?.toString() ?? '',
          ) ??
          0,
      statut: (json['statut'] ?? 'PROGRAMME')
          .toString(),
      trajetId: (json['trajetId'] ?? '').toString(),
      villeDepart:
          (json['villeDepart'] ?? '').toString(),
      villeArrivee:
          (json['villeArrivee'] ?? '').toString(),
      chauffeurNom:
          (json['chauffeurNom'] ?? '').toString(),
      chauffeurId: int.tryParse(
        json['chauffeurId']?.toString() ?? '',
      ),
      vehicule: (json['vehicule'] ?? '').toString(),
      immatriculation:
          (json['immatriculation'] ?? '').toString(),
      dateDepart:
          (json['dateDepart'] ?? '').toString(),
      heureDepart:
          (json['heureDepart'] ?? '').toString(),
      dateDemarrage: _parseDate(
        json['dateDemarrage'],
      ),
      dateFin: _parseDate(
        json['dateFin'],
      ),
      derniereMiseAJour: _parseDate(
        json['derniereMiseAJour'],
      ),
      message: (json['message'] ?? '').toString(),
      dernierePosition: positionData is Map
          ? ClientGpsPositionModel.fromJson(
              Map<String, dynamic>.from(positionData),
            )
          : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String get statutNormalise =>
      statut.trim().toUpperCase();

  bool get isProgramme =>
      statutNormalise == 'PROGRAMME';

  bool get isEnCours =>
      statutNormalise == 'EN_COURS';

  bool get isPause =>
      statutNormalise == 'PAUSE';

  bool get isTermine =>
      statutNormalise == 'TERMINE';

  bool get isAnnule =>
      statutNormalise == 'ANNULE';

  String get statutLabel {
    switch (statutNormalise) {
      case 'EN_COURS':
        return 'Trajet en cours';

      case 'PAUSE':
        return 'Trajet en pause';

      case 'TERMINE':
        return 'Trajet terminé';

      case 'ANNULE':
        return 'Trajet annulé';

      default:
        return 'Départ non encore effectué';
    }
  }

  String get derniereMiseAJourFormatee {
    final date = derniereMiseAJour;

    if (date == null) {
      return '-';
    }

    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final annee = date.year;

    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$jour/$mois/$annee à $heure:$minute';
  }

  String get dateDemarrageFormatee {
    final date = dateDemarrage;

    if (date == null) {
      return '-';
    }

    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$heure:$minute';
  }
}