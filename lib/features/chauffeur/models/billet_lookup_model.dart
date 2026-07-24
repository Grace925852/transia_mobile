class BilletLookupModel {
  final String? trajetId;
  final String statut;
  final String trajetInfo;
  final String dateDepart;
  final String heureDepart;

  BilletLookupModel({
    required this.trajetId,
    required this.statut,
    required this.trajetInfo,
    required this.dateDepart,
    required this.heureDepart,
  });

  factory BilletLookupModel.fromJson(Map<String, dynamic> json) {
    return BilletLookupModel(
      trajetId: json['trajetId']?.toString(),
      statut: json['statut']?.toString() ?? '',
      trajetInfo: json['trajetInfo']?.toString() ?? '',
      dateDepart: json['dateDepart']?.toString() ?? '',
      heureDepart: json['heureDepart']?.toString() ?? '',
    );
  }
}
