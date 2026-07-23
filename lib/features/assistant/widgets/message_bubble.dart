import 'package:flutter/material.dart';
import 'package:transia_mobile/features/assistant/models/assistant_message.dart';

class MessageBubble extends StatelessWidget {
  final AssistantMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.isUser;
    final isError = message.type == AssistantMessageType.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xFFE74C3C)
                    : const Color(0xFF3158F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.smart_toy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF3158F5)
                    : isError
                        ? const Color(0xFFFFECEA)
                        : isDark
                            ? const Color(0xFF222632)
                            : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 18 : 5),
                  topRight: Radius.circular(isUser ? 5 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isError
                            ? const Color(0xFFFFC7C2)
                            : isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFE9ECF2),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.10 : 0.035,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  height: 1.4,
                  fontSize: 14.2,
                  fontWeight: FontWeight.w500,
                  color: isUser
                      ? Colors.white
                      : isError
                          ? const Color(0xFFB42318)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.92)
                              : const Color(0xFF222735),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}