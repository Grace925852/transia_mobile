import 'package:flutter/material.dart';

enum AssistantSuggestionType {
  message,
  action,
  navigation,
  date,
  destination,
  passengerCount,
}

class AssistantSuggestion {
  final String id;
  final String label;
  final IconData icon;
  final AssistantSuggestionType type;

  /// Texte qui sera envoyé dans la conversation lorsque
  /// l’utilisateur touche la suggestion.
  final String? message;

  /// Identifiant d’action utilisé plus tard par le moteur d’actions.
  ///
  /// Exemples :
  /// - open_bookings
  /// - open_parcels
  /// - open_tracking
  /// - search_trips
  final String? actionId;

  /// Données complémentaires utilisées par une suggestion.
  ///
  /// Exemple :
  /// {
  ///   'places': 2,
  /// }
  final Map<String, dynamic> data;

  const AssistantSuggestion({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
    this.message,
    this.actionId,
    this.data = const {},
  });

  factory AssistantSuggestion.message({
    required String id,
    required String label,
    required IconData icon,
    String? message,
    Map<String, dynamic> data = const {},
  }) {
    return AssistantSuggestion(
      id: id,
      label: label,
      icon: icon,
      type: AssistantSuggestionType.message,
      message: message ?? label,
      data: data,
    );
  }

  factory AssistantSuggestion.navigation({
    required String id,
    required String label,
    required IconData icon,
    required String actionId,
    String? message,
    Map<String, dynamic> data = const {},
  }) {
    return AssistantSuggestion(
      id: id,
      label: label,
      icon: icon,
      type: AssistantSuggestionType.navigation,
      message: message,
      actionId: actionId,
      data: data,
    );
  }

  factory AssistantSuggestion.action({
    required String id,
    required String label,
    required IconData icon,
    required String actionId,
    String? message,
    Map<String, dynamic> data = const {},
  }) {
    return AssistantSuggestion(
      id: id,
      label: label,
      icon: icon,
      type: AssistantSuggestionType.action,
      message: message,
      actionId: actionId,
      data: data,
    );
  }

  factory AssistantSuggestion.date({
    required String id,
    required String label,
    required String value,
    IconData icon = Icons.calendar_month_rounded,
  }) {
    return AssistantSuggestion(
      id: id,
      label: label,
      icon: icon,
      type: AssistantSuggestionType.date,
      message: label,
      data: {
        'date': value,
      },
    );
  }

  factory AssistantSuggestion.destination({
    required String id,
    required String label,
    required String destination,
    IconData icon = Icons.location_on_rounded,
  }) {
    return AssistantSuggestion(
      id: id,
      label: label,
      icon: icon,
      type: AssistantSuggestionType.destination,
      message: destination,
      data: {
        'destination': destination,
      },
    );
  }

  factory AssistantSuggestion.passengerCount({
    required int count,
    String? label,
    IconData? icon,
  }) {
    return AssistantSuggestion(
      id: 'passenger_count_$count',
      label: label ?? '$count place${count > 1 ? 's' : ''}',
      icon: icon ??
          (count == 1
              ? Icons.person_rounded
              : Icons.groups_rounded),
      type: AssistantSuggestionType.passengerCount,
      message: '$count place${count > 1 ? 's' : ''}',
      data: {
        'passengerCount': count,
      },
    );
  }

  AssistantSuggestion copyWith({
    String? id,
    String? label,
    IconData? icon,
    AssistantSuggestionType? type,
    String? message,
    String? actionId,
    Map<String, dynamic>? data,
  }) {
    return AssistantSuggestion(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      message: message ?? this.message,
      actionId: actionId ?? this.actionId,
      data: data ?? this.data,
    );
  }
}