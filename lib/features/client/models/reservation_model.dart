class ReservationModel {
  final String id;
  final int userId;
  final String clientNom;
  final String trajetId;
  final String villeDepart;
  final String villeArrivee;
  final String dateDepart;
  final String heureDepart;
  final String vehiculeImmatriculation;
  final int nombrePlace;
  final String statut;
  final double montantTotal;
  final double prixUnitaire;
  final int nombreBillets;
  final Map<String, dynamic> rawData;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.clientNom,
    required this.trajetId,
    required this.villeDepart,
    required this.villeArrivee,
    required this.dateDepart,
    required this.heureDepart,
    required this.vehiculeImmatriculation,
    required this.nombrePlace,
    required this.statut,
    required this.montantTotal,
    required this.prixUnitaire,
    required this.nombreBillets,
    required this.rawData,
  });

  factory ReservationModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? trajetData,
  }) {
    final dynamic userData =
        json['user'] ?? json['users'] ?? json['client'] ?? json['utilisateur'];

    final dynamic billetsData =
        json['billets'] ??
        json['tickets'] ??
        json['billetEntities'] ??
        json['reservationBillets'];

    final int parsedNombrePlace =
        int.tryParse(
          (json['nombrePlace'] ?? json['nombrePlaces'] ?? 0).toString(),
        ) ??
        0;

    final int safeNombrePlace = parsedNombrePlace > 0 ? parsedNombrePlace : 1;

    final int parsedUserId =
        int.tryParse(
          (userData is Map
                      ? (userData['id'] ??
                          userData['userId'] ??
                          userData['numericId'])
                      : (json['userId'] ??
                          json['clientId'] ??
                          json['utilisateurId']))
                  ?.toString() ??
              '0',
        ) ??
        0;

    final String parsedClientNom =
        (json['nomResponsable'] ??
                json['clientNom'] ??
                (userData is Map
                    ? (userData['fullName'] ??
                        userData['nom'] ??
                        userData['clientNom'] ??
                        userData['username'])
                    : json['fullName']))
            ?.toString() ??
        '';

    final String parsedTrajetId =
        (json['trajetId'] ??
                json['trajet_id'] ??
                (trajetData != null ? trajetData['id'] : null))
            ?.toString() ??
        '';

    final dynamic villeDepartData =
        trajetData?['villeDepart'] ?? trajetData?['villeDepartDto'];
    final dynamic villeArriveeData =
        trajetData?['villeArrivee'] ?? trajetData?['villeArriveeDto'];
    final dynamic vehiculeData =
        trajetData?['vehicule'] ?? trajetData?['vehiculeDto'];

    final String parsedVilleDepart =
        (villeDepartData is Map
                    ? (villeDepartData['nomVille'] ??
                        villeDepartData['name'] ??
                        villeDepartData['libelle'])
                    : (trajetData?['villeDepartNom'] ??
                        trajetData?['nomVilleDepart']))
                ?.toString() ??
            json['villeDepart']?.toString() ??
            '';

    final String parsedVilleArrivee =
        (villeArriveeData is Map
                    ? (villeArriveeData['nomVille'] ??
                        villeArriveeData['name'] ??
                        villeArriveeData['libelle'])
                    : (trajetData?['villeArriveeNom'] ??
                        trajetData?['nomVilleArrivee']))
                ?.toString() ??
            json['villeArrivee']?.toString() ??
            '';

    final String parsedDateDepart =
        (trajetData?['dateDepart'] ?? trajetData?['date'] ?? json['dateDepart'])
            ?.toString() ??
        '';

    final String parsedHeureDepart =
        (trajetData?['heureDepart'] ??
                trajetData?['heure'] ??
                json['heureDepart'])
            ?.toString() ??
        '';

    final String parsedVehicule =
        (vehiculeData is Map
                    ? (vehiculeData['immatriculation'] ??
                        vehiculeData['matricule'] ??
                        vehiculeData['plaque'])
                    : (trajetData?['vehiculeImmatriculation'] ??
                        trajetData?['immatriculation']))
                ?.toString() ??
            json['vehiculeImmatriculation']?.toString() ??
            '';

    final String parsedStatut =
        (json['statut'] ?? json['status'] ?? 'EN_ATTENTE').toString();

    final double parsedPrixUnitaire =
        double.tryParse(
          (trajetData?['tarif'] ?? trajetData?['prix'] ?? json['tarif'] ?? 0)
              .toString(),
        ) ??
        0;

    double parsedMontant =
        double.tryParse(
          (json['montantTotal'] ?? json['totalAmount'] ?? 0).toString(),
        ) ??
        0;

    if (parsedMontant <= 0 && parsedPrixUnitaire > 0) {
      parsedMontant = parsedPrixUnitaire * safeNombrePlace;
    }

    final int parsedBilletsCount =
        billetsData is List ? billetsData.length : safeNombrePlace;

    return ReservationModel(
      id: (json['id'] ?? '').toString(),
      userId: parsedUserId,
      clientNom: parsedClientNom,
      trajetId: parsedTrajetId,
      villeDepart: parsedVilleDepart,
      villeArrivee: parsedVilleArrivee,
      dateDepart: parsedDateDepart,
      heureDepart: parsedHeureDepart,
      vehiculeImmatriculation: parsedVehicule,
      nombrePlace: safeNombrePlace,
      statut: parsedStatut,
      montantTotal: parsedMontant,
      prixUnitaire: parsedPrixUnitaire,
      nombreBillets: parsedBilletsCount,
      rawData: json,
    );
  }

  String get prixFormate => '${montantTotal.toStringAsFixed(0)} FCFA';
  String get prixUnitaireFormate => '${prixUnitaire.toStringAsFixed(0)} FCFA';

  String get heureFormatee {
    if (heureDepart.length >= 5) return heureDepart.substring(0, 5);
    return heureDepart;
  }

  String get trajetLabel => '$villeDepart → $villeArrivee';

  DateTime? get departureDateTime {
    try {
      if (dateDepart.trim().isEmpty) return null;
      final timePart =
          heureFormatee.trim().isEmpty ? '00:00' : heureFormatee.trim();
      return DateTime.parse('$dateDepart $timePart:00');
    } catch (_) {
      return null;
    }
  }

  DateTime? get departureDateOnly {
    try {
      if (dateDepart.trim().isEmpty) return null;
      final d = DateTime.parse(dateDepart.trim());
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  bool get isPaidOrValidated {
    final status = statut.toUpperCase();
    return status.contains('CONFIRME') ||
        status.contains('VALIDE') ||
        status.contains('PAYE') ||
        status.contains('PAYÉ');
  }

  bool get isPast {
    final departure = departureDateOnly;
    if (departure == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return departure.isBefore(today);
  }

  bool get isUpcoming => !isPast;
  bool get shouldShowInActiveReservations => isUpcoming;
  bool get shouldShowInHistory => isPast && isPaidOrValidated;

  bool get isRefundEligible {
    final departure = departureDateTime;
    if (departure == null) return false;

    final limit = departure.subtract(const Duration(days: 2));
    return DateTime.now().isBefore(limit);
  }

  String get refundEligibilityMessage {
    if (isRefundEligible) {
      return 'Remboursement encore possible.';
    }
    return 'Le remboursement n’est autorisé qu’au moins 2 jours avant le départ.';
  }
}