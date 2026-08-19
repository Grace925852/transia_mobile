class ReservationModel {
  final String id;
  final String? reference;
  final String? userId;
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
    this.reference,
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

    // Le backend enrichit désormais la réservation avec le trajet complet (villes, véhicule, tarif) :
    // on l'utilise en priorité, avec repli sur un trajetData fourni séparément pour compatibilité.
    final Map<String, dynamic>? effectiveTrajetData =
        json['trajet'] is Map
            ? Map<String, dynamic>.from(json['trajet'] as Map)
            : trajetData;

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

    // userId est l'UUID (publicId) du titulaire renvoyé par le backend, pas un identifiant numérique.
    final String? parsedUserId = (userData is Map
            ? (userData['id'] ?? userData['userId'] ?? userData['publicId'])
            : (json['userId'] ?? json['clientId'] ?? json['utilisateurId']))
        ?.toString();

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
                (effectiveTrajetData != null ? effectiveTrajetData['id'] : null))
            ?.toString() ??
        '';

    final dynamic villeDepartData =
        effectiveTrajetData?['villeDepart'] ?? effectiveTrajetData?['villeDepartDto'];
    final dynamic villeArriveeData =
        effectiveTrajetData?['villeArrivee'] ?? effectiveTrajetData?['villeArriveeDto'];
    final dynamic vehiculeData =
        effectiveTrajetData?['vehicule'] ?? effectiveTrajetData?['vehiculeDto'];

    final String parsedVilleDepart =
        (villeDepartData is Map
                    ? (villeDepartData['nomVille'] ??
                        villeDepartData['name'] ??
                        villeDepartData['libelle'])
                    : (effectiveTrajetData?['villeDepartNom'] ??
                        effectiveTrajetData?['nomVilleDepart']))
                ?.toString() ??
            json['villeDepart']?.toString() ??
            '';

    final String parsedVilleArrivee =
        (villeArriveeData is Map
                    ? (villeArriveeData['nomVille'] ??
                        villeArriveeData['name'] ??
                        villeArriveeData['libelle'])
                    : (effectiveTrajetData?['villeArriveeNom'] ??
                        effectiveTrajetData?['nomVilleArrivee']))
                ?.toString() ??
            json['villeArrivee']?.toString() ??
            '';

    final String parsedDateDepart =
        (effectiveTrajetData?['dateDepart'] ?? effectiveTrajetData?['date'] ?? json['dateDepart'])
            ?.toString() ??
        '';

    final String parsedHeureDepart =
        (effectiveTrajetData?['heureDepart'] ??
                effectiveTrajetData?['heure'] ??
                json['heureDepart'])
            ?.toString() ??
        '';

    final String parsedVehicule =
        (vehiculeData is Map
                    ? (vehiculeData['immatriculation'] ??
                        vehiculeData['matricule'] ??
                        vehiculeData['plaque'])
                    : (effectiveTrajetData?['vehiculeImmatriculation'] ??
                        effectiveTrajetData?['immatriculation']))
                ?.toString() ??
            json['vehiculeImmatriculation']?.toString() ??
            '';

    final String parsedStatut =
        (json['statut'] ?? json['status'] ?? 'EN_ATTENTE').toString();

    final double parsedPrixUnitaire =
        double.tryParse(
          (effectiveTrajetData?['tarif'] ?? effectiveTrajetData?['prix'] ?? json['tarif'] ?? 0)
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

    final String? parsedRef = (json['reference'] ?? json['referenceMetier'])?.toString();

    return ReservationModel(
      id: (json['id'] ?? '').toString(),
      reference: parsedRef,
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

  String get displayReference {
    if (reference != null && reference!.trim().isNotEmpty) {
      return reference!.trim();
    }
    if (id.length >= 8) {
      return 'RES-${id.substring(0, 8).toUpperCase()}';
    }
    return id;
  }

  String get prixFormate => '${montantTotal.toStringAsFixed(0)} FCFA';
  String get prixUnitaireFormate => '${prixUnitaire.toStringAsFixed(0)} FCFA';
  String get trajetLabel => '$villeDepart → $villeArrivee';

  String get heureFormatee {
    if (heureDepart.length >= 5) return heureDepart.substring(0, 5);
    return heureDepart;
  }

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

  String get statutUpper => statut.trim().toUpperCase();

  bool get isPaidOrValidated {
    final status = statutUpper;
    return status.contains('CONFIRME') ||
        status.contains('VALIDE') ||
        status.contains('PAYE') ||
        status.contains('PAYÉ');
  }

  bool get isCancelled {
    final status = statutUpper;
    return status.contains('ANNULE');
  }

  bool get isRefundRequested {
    final status = statutUpper;
    return status.contains('REMBOURSEMENT_DEMANDE') ||
        status.contains('DEMANDE_REMBOURSEMENT') ||
        status.contains('REMBOURSEMENT_EN_COURS');
  }

  bool get isRefunded {
    final status = statutUpper;
    return status.contains('REMBOURSE') || status.contains('REMBOURSÉ');
  }

  bool get isClosedForReservations {
    return isCancelled || isRefunded;
  }

  bool get isPast {
    final departure = departureDateOnly;
    if (departure == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return departure.isBefore(today);
  }

  bool get isUpcoming => !isPast;

  bool get shouldShowInActiveReservations =>
      isUpcoming && !isClosedForReservations;

  bool get shouldShowInHistory =>
      !isClosedForReservations && isPast && isPaidOrValidated;

  bool get isRefundEligible {
    final departure = departureDateTime;
    if (departure == null) return false;

    final limit = departure.subtract(const Duration(hours: 24));
    return DateTime.now().isBefore(limit);
  }

  String get refundEligibilityMessage {
    if (isRefundEligible) {
      return 'Remboursement encore possible.';
    }
    return 'Le remboursement n’est autorisé qu’avant les 24 heures précédant le départ.';
  }
}