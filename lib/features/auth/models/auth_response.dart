class AuthResponse {
  final String id;
  final int numericId;
  final String fullName;
  final String telephone;
  final String token;
  final String type;
  final List<String> roles;

  AuthResponse({
    required this.id,
    required this.numericId,
    required this.fullName,
    required this.telephone,
    required this.token,
    required this.type,
    required this.roles,
  });

  factory AuthResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthResponse(
      id: json['id']?.toString() ??
          json['userId']?.toString() ??
          json['publicId']?.toString() ??
          '',
      numericId: _parseNumericId(
        json['numericId'],
      ),
      fullName: json['fullName']?.toString() ??
          json['name']?.toString() ??
          json['nom']?.toString() ??
          '',
      telephone:
          json['telephone']?.toString() ??
              json['username']?.toString() ??
              json['login']?.toString() ??
              '',
      token: json['token']?.toString() ??
          json['accessToken']?.toString() ??
          '',
      type: json['type']?.toString() ??
          json['tokenType']?.toString() ??
          'Bearer',
      roles: _parseRoles(
        json['roles'],
      ),
    );
  }

  static int _parseNumericId(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static List<String> _parseRoles(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (item) {
              if (item is Map) {
                return (item['name'] ??
                        item['role'] ??
                        item['authority'] ??
                        '')
                    .toString();
              }

              return item.toString();
            },
          )
          .where(
            (role) =>
                role.trim().isNotEmpty,
          )
          .toList();
    }

    if (value is Map) {
      final role = value['name'] ??
          value['role'] ??
          value['authority'];

      if (role != null &&
          role.toString().trim().isNotEmpty) {
        return [
          role.toString(),
        ];
      }
    }

    return [];
  }
}