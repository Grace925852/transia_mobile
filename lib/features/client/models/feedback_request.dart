class FeedbackRequest {
  final int noteValeur;
  final String commentaireTexte;
  final String trajetId;
  final String creerPar;

  FeedbackRequest({
    required this.noteValeur,
    required this.commentaireTexte,
    required this.trajetId,
    required this.creerPar,
  });

  Map<String, dynamic> toJson() {
    return {
      'noteValeur': noteValeur,
      'commentaireTexte': commentaireTexte,
      'trajetId': trajetId,
      'creerPar': creerPar,
    };
  }
}