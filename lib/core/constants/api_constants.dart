class ApiConstants {
  /*
   * Téléphone Android physique connecté par USB.
   * Avant de lancer Flutter :
   *
   * adb reverse tcp:8181 tcp:8181
   */
  static const String baseUrl = 'http://127.0.0.1:8181';
  //  static const String baseUrl = 'http://192.168.0.172:8181';

   //static const String baseUrl = 'http://192.168.1.103:8181';

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








/**
class ApiConstants {
  // 'localhost' ne fonctionne que pour Flutter Web/l'émulateur Android (qui pointent
  // vers la machine hôte) : sur un téléphone physique, 'localhost' désigne le téléphone
  // lui-même. Il faut l'IP locale (Wi-Fi) de la machine qui fait tourner le backend, et
  // le téléphone doit être sur le même réseau Wi-Fi. À remettre à jour si cette IP change.
  // static const String baseUrl = 'http://192.168.0.172:8181';
 // static const String baseUrl = 'http://10.0.2.2:8181';

   // static const String baseUrl = 'http://192.168.1.103:8181';
    static const String baseUrl = 'http://127.0.0.1:8181';
  // baseUrl: '/api/v1',

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
  static const String chauffeurProblemes = '/api/v1/chauffeur-problemes';
}
 */