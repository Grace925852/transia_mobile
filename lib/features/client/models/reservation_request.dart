class ReservationRequestModel {
  final int userId;
  final String trajetId;
  final int nombrePlace;
  final String nomResponsable;
  final List<String> nomsPassagers;
  final List<int> numerosSieges;

  ReservationRequestModel({
    required this.userId,
    required this.trajetId,
    required this.nombrePlace,
    required this.nomResponsable,
    required this.nomsPassagers,
    this.numerosSieges = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'trajetId': trajetId,
      'nombrePlace': nombrePlace,
      'nomResponsable': nomResponsable,
      'nomsPassagers': nomsPassagers,
      'numerosSieges': numerosSieges,
    };
  }
}