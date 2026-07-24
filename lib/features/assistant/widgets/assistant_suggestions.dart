import 'package:flutter/material.dart';

class AssistantSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionSelected;

  const AssistantSuggestions({
    super.key,
    required this.suggestions,
    required this.onSuggestionSelected,
  });

  IconData _getIcon(String suggestion) {
    final text = suggestion.toLowerCase();

    if (text.contains('réserv') || text.contains('trajet')) {
      return Icons.directions_bus_rounded;
    }

    if (text.contains('colis') || text.contains('bagage')) {
      return Icons.inventory_2_rounded;
    }

    if (text.contains('billet') ||
        text.contains('ticket') ||
        text.contains('qr')) {
      return Icons.confirmation_number_rounded;
    }

    if (text.contains('paiement') ||
        text.contains('payer') ||
        text.contains('coûte')) {
      return Icons.account_balance_wallet_rounded;
    }

    if (text.contains('suivi')) {
      return Icons.location_on_rounded;
    }

    if (text.contains('remboursement') ||
        text.contains('annuler')) {
      return Icons.currency_exchange_rounded;
    }

    if (text.contains('historique')) {
      return Icons.history_rounded;
    }

    return Icons.chat_bubble_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
      color: isDark
          ? const Color(0xFF191D27)
          : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () {
                    onSuggestionSelected(suggestion);
                  },
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF242834)
                          : const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E6EF),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIcon(suggestion),
                          size: 17,
                          color: const Color(0xFF3158F5),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.88)
                                : const Color(0xFF303647),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}