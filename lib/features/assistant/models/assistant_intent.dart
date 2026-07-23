enum AssistantIntent {
  unknown,
  greeting,
  help,
  booking,
  parcel,
  ticket,
  payment,
  tracking,
  refund,
  reservations,
  history,
  profile,
  thanks,
  goodbye,
}

extension AssistantIntentExtension on AssistantIntent {
  String get label {
    switch (this) {
      case AssistantIntent.unknown:
        return 'Demande inconnue';

      case AssistantIntent.greeting:
        return 'Salutation';

      case AssistantIntent.help:
        return 'Aide';

      case AssistantIntent.booking:
        return 'Réservation';

      case AssistantIntent.parcel:
        return 'Envoi de colis';

      case AssistantIntent.ticket:
        return 'Billet';

      case AssistantIntent.payment:
        return 'Paiement';

      case AssistantIntent.tracking:
        return 'Suivi';

      case AssistantIntent.refund:
        return 'Remboursement';

      case AssistantIntent.reservations:
        return 'Mes réservations';

      case AssistantIntent.history:
        return 'Historique';

      case AssistantIntent.profile:
        return 'Profil';

      case AssistantIntent.thanks:
        return 'Remerciement';

      case AssistantIntent.goodbye:
        return 'Au revoir';
    }
  }

  bool get isNavigationIntent {
    switch (this) {
      case AssistantIntent.booking:
      case AssistantIntent.parcel:
      case AssistantIntent.ticket:
      case AssistantIntent.payment:
      case AssistantIntent.tracking:
      case AssistantIntent.refund:
      case AssistantIntent.reservations:
      case AssistantIntent.history:
      case AssistantIntent.profile:
        return true;

      case AssistantIntent.unknown:
      case AssistantIntent.greeting:
      case AssistantIntent.help:
      case AssistantIntent.thanks:
      case AssistantIntent.goodbye:
        return false;
    }
  }
}