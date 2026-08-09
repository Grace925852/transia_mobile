class ApiConstants {
  static const String baseUrl =
      'https://transia-back-end.onrender.com';

  static const String login = '/api/v1/login';
  static const String register = '/api/v1/register';
  static const String forgotPassword = '/api/v1/forgot-password';

  static const String me = '/api/v1/me';
  static const String myPassword = '/api/v1/me/password';
  static const String myProfil = '/api/v1/profil/me';

  static const String users = '/api/v1/users';
  static const String trajets = '/api/v1/trajet';
  static const String villes = '/api/v1/ville';
  static const String agences = '/api/v1/agences';
  static const String reservations = '/api/v1/reservations';
  static const String paiements = '/api/v1/paiements';
  static const String feedback = '/api/v1/feedback';
  static const String vehicules = '/api/v1/vehicule';

  static const String colis = '/api/v1/colis';
  static const String tarifsColis = '/api/v1/colis/tarifs';
  static const String demandesCollecte = '/api/v1/colis/collecte';

  static const String chauffeurProblemes =
      '/api/v1/chauffeur-problemes';

  static const String assistantChat =
      '/api/v1/assistant/chat';
}