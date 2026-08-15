import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';

class ProfessionalSpaceScreen extends StatelessWidget {
  const ProfessionalSpaceScreen({super.key});

  static const Color primaryBlue = Color(0xFF3158F5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.welcome),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Espace professionnel',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Container(
                height: 100,
                width: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.directions_bus_rounded,
                      size: 55,
                      color: primaryBlue,
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Bienvenue',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Sélectionnez votre profil professionnel.',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),

              const SizedBox(height: 36),

              _ProfessionalCard(
                icon: Icons.directions_bus_rounded,
                title: 'Chauffeur',
                subtitle: 'Accéder à votre espace chauffeur',
                onTap: () {
                  context.go(AppRoutes.chauffeurLogin);
                },
              ),

              const SizedBox(height: 18),

              _ProfessionalCard(
                icon: Icons.local_shipping_outlined,
                title: 'Livreur',
                subtitle: 'Accéder à votre espace livreur',
                onTap: () {
                  context.go(AppRoutes.livreurLogin);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfessionalCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: ProfessionalSpaceScreen.primaryBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}