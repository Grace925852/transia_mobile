class AuthResponse {
  final String id;
  final String fullName;
  final String telephone;
  final String token;
  final String type;
  final List<String> roles;

  AuthResponse({
    required this.id,
    required this.fullName,
    required this.telephone,
    required this.token,
    required this.type,
    required this.roles,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      id: json['id']?.toString() ??
          json['userId']?.toString() ??
          json['publicId']?.toString() ??
          '',
      fullName: json['fullName']?.toString() ??
          json['name']?.toString() ??
          json['nom']?.toString() ??
          '',
      telephone: json['telephone']?.toString() ??
          json['login']?.toString() ??
          '',
      token: json['token']?.toString() ??
          json['accessToken']?.toString() ??
          '',
      type: json['type']?.toString() ??
          json['tokenType']?.toString() ??
          'Bearer',
      roles: json['roles'] is List
          ? List<String>.from(json['roles'].map((e) => e.toString()))
          : [],
    );
  }
}
