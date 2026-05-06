class VilleModel {
  final String id;
  final String nomVille;
  final String region;

  VilleModel({
    required this.id,
    required this.nomVille,
    required this.region,
  });

  factory VilleModel.fromJson(Map<String, dynamic> json) {
    return VilleModel(
      id: json['id']?.toString() ?? '',
      nomVille: json['nomVille']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
    );
  }
}