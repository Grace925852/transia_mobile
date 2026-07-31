class ReservationRequestModel {

  final String trajetId;
  final int nombrePlace;
  final String nomResponsable;
  final List<String> nomsPassagers;
  final List<String> siegesChoisis;

  const ReservationRequestModel({
    required this.trajetId,
    required this.nombrePlace,
    required this.nomResponsable,
    required this.nomsPassagers,
    this.siegesChoisis = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      
      'trajetId': trajetId,
      'nombrePlace': nombrePlace,
      'nomResponsable': nomResponsable,
      'nomsPassagers': nomsPassagers,
      'siegesChoisis': siegesChoisis,
    };
  }
}
