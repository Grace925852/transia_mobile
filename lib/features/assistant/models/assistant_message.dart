enum AssistantMessageAuthor {
  user,
  assistant,
}

enum AssistantMessageType {
  text,
  suggestion,
  error,
}

class AssistantMessage {
  final String id;
  final String content;
  final AssistantMessageAuthor author;
  final AssistantMessageType type;
  final DateTime createdAt;
  final List<String> suggestions;

  const AssistantMessage({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.type = AssistantMessageType.text,
    this.suggestions = const [],
  });

  bool get isUser {
    return author == AssistantMessageAuthor.user;
  }

  bool get isAssistant {
    return author == AssistantMessageAuthor.assistant;
  }

  bool get hasSuggestions {
    return suggestions.isNotEmpty;
  }

  AssistantMessage copyWith({
    String? id,
    String? content,
    AssistantMessageAuthor? author,
    AssistantMessageType? type,
    DateTime? createdAt,
    List<String>? suggestions,
  }) {
    return AssistantMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  factory AssistantMessage.user({
    required String content,
  }) {
    final now = DateTime.now();

    return AssistantMessage(
      id: 'user_${now.microsecondsSinceEpoch}',
      content: content.trim(),
      author: AssistantMessageAuthor.user,
      createdAt: now,
    );
  }

  factory AssistantMessage.assistant({
    required String content,
    List<String> suggestions = const [],
    AssistantMessageType type = AssistantMessageType.text,
  }) {
    final now = DateTime.now();

    return AssistantMessage(
      id: 'assistant_${now.microsecondsSinceEpoch}',
      content: content.trim(),
      author: AssistantMessageAuthor.assistant,
      type: type,
      createdAt: now,
      suggestions: suggestions,
    );
  }

  factory AssistantMessage.error({
    required String content,
  }) {
    final now = DateTime.now();

    return AssistantMessage(
      id: 'error_${now.microsecondsSinceEpoch}',
      content: content.trim(),
      author: AssistantMessageAuthor.assistant,
      type: AssistantMessageType.error,
      createdAt: now,
    );
  }
}