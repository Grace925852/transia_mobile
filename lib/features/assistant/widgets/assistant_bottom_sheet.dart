import 'package:flutter/material.dart';
import 'package:transia_mobile/features/assistant/models/assistant_message.dart';
import 'package:transia_mobile/features/assistant/services/assistant_service.dart';
import 'package:transia_mobile/features/assistant/widgets/assistant_header.dart';
import 'package:transia_mobile/features/assistant/widgets/assistant_input.dart';
import 'package:transia_mobile/features/assistant/widgets/assistant_suggestions.dart';
import 'package:transia_mobile/features/assistant/widgets/message_bubble.dart';

class AssistantBottomSheet extends StatefulWidget {
  const AssistantBottomSheet({
    super.key,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (context) {
        return const AssistantBottomSheet();
      },
    );
  }

  @override
  State<AssistantBottomSheet> createState() =>
      _AssistantBottomSheetState();
}

class _AssistantBottomSheetState
    extends State<AssistantBottomSheet> {
  final AssistantService _assistantService = AssistantService();

  final TextEditingController _messageController =
      TextEditingController();

  final FocusNode _messageFocusNode = FocusNode();

  final ScrollController _scrollController =
      ScrollController();

  final List<AssistantMessage> _messages = [];

  List<String> _suggestions = [
    'Réserver un trajet',
    'Voir mes réservations',
    'Envoyer un colis',
    'Paiement',
    'Voir mon billet',
    'Remboursement',
  ];

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    _messages.add(
      AssistantMessage.assistant(
        content:
            'Bonjour 👋\nComment puis-je vous aider aujourd’hui ?',
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _closeAssistant() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop();
  }

  Future<void> _sendMessage({
    String? predefinedMessage,
  }) async {
    if (_isTyping) {
      return;
    }

    final text =
        (predefinedMessage ?? _messageController.text).trim();

    if (text.isEmpty) {
      return;
    }

    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(
        AssistantMessage.user(
          content: text,
        ),
      );

      _suggestions = [];
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response =
          await _assistantService.getResponse(text);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(response);
        _suggestions = response.suggestions;
        _isTyping = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          AssistantMessage.error(
            content:
                'Une erreur est survenue. Veuillez réessayer.',
          ),
        );

        _suggestions = [
          'Réserver un trajet',
          'Paiement',
          'Remboursement',
        ];

        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _onSuggestionSelected(String suggestion) {
    _sendMessage(
      predefinedMessage: suggestion,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        top: mediaQuery.size.height * 0.15,
        bottom: mediaQuery.viewInsets.bottom,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151821)
                : const Color(0xFFF9FAFC),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.34 : 0.16,
                ),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              AssistantHeader(
                isTyping: _isTyping,
                onClose: _closeAssistant,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFE8EBF1),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    18,
                  ),
                  itemCount:
                      _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping &&
                        index == _messages.length) {
                      return const _TypingIndicator();
                    }

                    return MessageBubble(
                      message: _messages[index],
                    );
                  },
                ),
              ),
              AssistantSuggestions(
                suggestions: _suggestions,
                onSuggestionSelected:
                    _onSuggestionSelected,
              ),
              AssistantInput(
                controller: _messageController,
                focusNode: _messageFocusNode,
                onSend: _sendMessage,
                isEnabled: !_isTyping,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: const BoxDecoration(
              color: Color(0xFF3158F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Container(
            height: 43,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF222632)
                  : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE9ECF2),
              ),
            ),
            child: const Center(
              child: _AnimatedDots(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() =>
      _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final activeIndex =
            (_controller.value * 3).floor() % 3;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final isActive = index == activeIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 8 : 6,
              height: isActive ? 8 : 6,
              decoration: BoxDecoration(
                color: const Color(0xFF3158F5).withValues(
                  alpha: isActive ? 1 : 0.35,
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}