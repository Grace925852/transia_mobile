class ReservationRequestModel {
  final int userId;
  final String trajetId;
  final int nombrePlace;
  final String nomResponsable;
  final List<String> nomsPassagers;
  final List<String> siegesChoisis;

  ReservationRequestModel({
    required this.userId,
    required this.trajetId,
    required this.nombrePlace,
    required this.nomResponsable,
    required this.nomsPassagers,
    this.siegesChoisis = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'trajetId': trajetId,
      'nombrePlace': nombrePlace,
      'nomResponsable': nomResponsable,
      'nomsPassagers': nomsPassagers,
      'siegesChoisis': siegesChoisis,
    };
  }
}