import 'package:flutter/material.dart';

class AssistantInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isEnabled;

  const AssistantInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191D27) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE8EBF1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 50,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF242834)
                      : const Color(0xFFF3F5F9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFE3E7EF),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: isEnabled,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (isEnabled) {
                      onSend();
                    }
                  },
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF202532),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Posez votre question...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.42)
                          : const Color(0xFF9299A8),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Material(
              color: isEnabled
                  ? const Color(0xFF3158F5)
                  : const Color(0xFF9CA3AF),
              shape: const CircleBorder(),
              elevation: isEnabled ? 3 : 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isEnabled ? onSend : null,
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}