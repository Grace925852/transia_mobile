class ChauffeurPassengerModel {
  final String reservationId;
  final String billetId;
  final String trajetId;
  final String passagerNom;
  final String siege;
  final bool paid;
  final bool present;
  final String clientResponsable;
  final String qrCode;

  ChauffeurPassengerModel({
    required this.reservationId,
    required this.billetId,
    required this.trajetId,
    required this.passagerNom,
    required this.siege,
    required this.paid,
    required this.present,
    required this.clientResponsable,
    required this.qrCode,
  });

  factory ChauffeurPassengerModel.fromJson(Map<String, dynamic> json) {
    return ChauffeurPassengerModel(
      reservationId: json['reservationId']?.toString() ?? '',
      billetId: json['billetId']?.toString() ?? json['id']?.toString() ?? '',
      trajetId: json['trajetId']?.toString() ?? '',
      passagerNom: json['passagerNom']?.toString() ??
          json['nomPassager']?.toString() ??
          json['nom']?.toString() ??
          '',
      siege: json['siege']?.toString() ??
          json['numeroSiege']?.toString() ??
          json['seatNumber']?.toString() ??
          '-',
      paid: json['paid'] == true,
      present: json['present'] == true,
      clientResponsable: json['clientResponsable']?.toString() ?? '',
      qrCode: json['qrCode']?.toString() ?? '',
    );
  }

  ChauffeurPassengerModel copyWith({
    bool? present,
  }) {
    return ChauffeurPassengerModel(
      reservationId: reservationId,
      billetId: billetId,
      trajetId: trajetId,
      passagerNom: passagerNom,
      siege: siege,
      paid: paid,
      present: present ?? this.present,
      clientResponsable: clientResponsable,
      qrCode: qrCode,
    );
  }
}