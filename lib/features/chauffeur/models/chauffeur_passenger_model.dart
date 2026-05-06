class ChauffeurPassengerModel {
  final String reservationId;
  final String trajetId;
  final String responsable;
  final String nomPassager;
  final String statut;
  final String qrCode;

  ChauffeurPassengerModel({
    required this.reservationId,
    required this.trajetId,
    required this.responsable,
    required this.nomPassager,
    required this.statut,
    required this.qrCode,
  });

  factory ChauffeurPassengerModel.fromReservationAndTicket({
    required Map<String, dynamic> reservation,
    required Map<String, dynamic> ticket,
  }) {
    return ChauffeurPassengerModel(
      reservationId: (reservation['id'] ?? '').toString(),
      trajetId: (reservation['trajetId'] ?? '').toString(),
      responsable: (reservation['nomResponsable'] ?? '').toString(),
      nomPassager: (ticket['nomPassager'] ?? '').toString(),
      statut: (ticket['statut'] ?? reservation['statut'] ?? '').toString(),
      qrCode: (ticket['qrCode'] ?? '').toString(),
    );
  }
}