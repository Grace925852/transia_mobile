class AgenceModel {
  final String id;
  final String nom;
  final String villeId;
  final String villeNom;
  final String adresse;
  final String telephone;
  final String email;
  final double? latitude;
  final double? longitude;
  final bool statut;
  final List<String> photos;

  AgenceModel({
    required this.id,
    required this.nom,
    required this.villeId,
    required this.villeNom,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.statut,
    required this.photos,
  });

  factory AgenceModel.fromJson(Map<String, dynamic> json) {
    return AgenceModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      villeId: json['villeId']?.toString() ?? '',
      villeNom: json['villeNom']?.toString() ?? '',
      adresse: json['adresse']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      statut: json['statut'] == null ? true : json['statut'] == true,
      photos: json['photos'] is List
          ? List<String>.from(
              (json['photos'] as List).map((e) => e.toString()),
            )
          : [],
    );
  }

  bool get aCoordonnees => latitude != null && longitude != null;

  String? get lienGoogleMaps =>
      aCoordonnees ? 'https://www.google.com/maps?q=$latitude,$longitude' : null;
}
