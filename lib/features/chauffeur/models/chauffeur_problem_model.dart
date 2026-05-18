class ChauffeurProblemModel {
  final String id;
  final String trajetId;
  final String chauffeurId;
  final String typeProbleme;
  final String description;
  final String statut;
  final String createdAt;

  ChauffeurProblemModel({
    required this.id,
    required this.trajetId,
    required this.chauffeurId,
    required this.typeProbleme,
    required this.description,
    required this.statut,
    required this.createdAt,
  });

  factory ChauffeurProblemModel.fromJson(Map<String, dynamic> json) {
    return ChauffeurProblemModel(
      id: json['id']?.toString() ?? '',
      trajetId: json['trajetId']?.toString() ?? '',
      chauffeurId: json['chauffeurId']?.toString() ?? '',
      typeProbleme: json['typeProbleme']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      statut: json['statut']?.toString() ?? 'EN_ATTENTE',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trajetId': trajetId,
      'chauffeurId': chauffeurId,
      'typeProbleme': typeProbleme,
      'description': description,
      'statut': statut,
      'createdAt': createdAt,
    };
  }
}