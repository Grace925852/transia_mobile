import 'package:transia_mobile/features/assistant/models/assistant_message.dart';

class AssistantService {
  Future<AssistantMessage> getResponse(String question) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final text = question.toLowerCase().trim();

    // Salutations
    if (_contains(text, [
      'bonjour',
      'salut',
      'bonsoir',
      'hello',
      'cc'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Bonjour 👋 Je suis TransIA, votre assistant de voyage. Comment puis-je vous aider aujourd'hui ?",
        suggestions: [
          "Réserver un trajet",
          "Demander un remboursement",
          "Voir mes réservations",
        ],
      );
    }

    // Réservation
    if (_contains(text, [
      'réserver',
      'reservation',
      'trajet',
      'voyage',
      'bus'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Pour réserver un trajet, choisissez votre ville de départ, votre destination puis sélectionnez votre trajet disponible.",
        suggestions: [
          "Comment payer ?",
          "Combien coûte un billet ?",
        ],
      );
    }

    // Paiement
    if (_contains(text, [
      'payer',
      'paiement',
      'carte',
      'argent'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Après avoir choisi votre trajet, appuyez sur « Réserver », puis suivez les étapes de paiement.",
      );
    }

    // Historique
    if (_contains(text, [
      'historique',
      'mes réservations',
      'reservation'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Vous pouvez retrouver toutes vos réservations dans l'onglet Historique.",
      );
    }

    // QR Code
    if (_contains(text, [
      'qr',
      'code',
      'ticket'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Votre billet électronique avec QR Code est disponible immédiatement après la confirmation du paiement.",
      );
    }

    // Remboursement
    if (_contains(text, [
      'remboursement',
      'annuler',
      'annulation'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Une demande de remboursement peut être effectuée jusqu'à 48 heures avant le départ.",
      );
    }

    // Bagages
    if (_contains(text, [
      'bagage',
      'valise',
      'colis'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Les bagages sont soumis aux règles de la compagnie. Vous pouvez également envoyer un colis depuis l'application.",
      );
    }

    // Merci
    if (_contains(text, [
      'merci',
      'thanks'
    ])) {
      return AssistantMessage.assistant(
        content:
            "Avec plaisir 😊 Je reste disponible si vous avez d'autres questions.",
      );
    }

    // Réponse par défaut
    return AssistantMessage.assistant(
      content:
          "Je n'ai pas encore compris votre demande. Pouvez-vous la reformuler ?",
      suggestions: [
        "Réserver un trajet",
        "Paiement",
        "Historique",
        "Remboursement",
      ],
    );
  }

  bool _contains(String text, List<String> words) {
    for (final word in words) {
      if (text.contains(word)) {
        return true;
      }
    }
    return false;
  }
}