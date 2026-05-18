import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/auth/models/auth_response.dart';
import 'package:transia_mobile/features/auth/services/auth_service.dart';

class ChauffeurLoginScreen extends StatefulWidget {
  const ChauffeurLoginScreen({super.key});

  @override
  State<ChauffeurLoginScreen> createState() => _ChauffeurLoginScreenState();
}

class _ChauffeurLoginScreenState extends State<ChauffeurLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final SecureStorageService secureStorageService = SecureStorageService();

  bool obscurePassword = true;
  bool isLoading = false;

  final Color primaryBlue = const Color(0xFF3158F5);

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isChauffeur(AuthResponse response, String username) {
    final rolesUpper = response.roles.map((e) => e.toUpperCase()).toList();

    final roleIsChauffeur = rolesUpper.any(
      (role) => role == 'CHAUFFEUR' || role == 'ROLE_CHAUFFEUR',
    );

    const allowedChauffeurUsernames = [
      '92000000',
      '90005566',
    ];

    if (!allowedChauffeurUsernames.contains(username.trim())) {
      return false;
    }

    return roleIsChauffeur;
  }

  Future<void> loginChauffeur() async {
    FocusScope.of(context).unfocus();

    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showMessage('Veuillez renseigner le numéro et le mot de passe.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final apiClient = ApiClient(secureStorageService);
      final authService = AuthService(
        apiClient: apiClient,
        secureStorageService: secureStorageService,
      );

      final response = await authService.login(
        username: phone,
        password: password,
      );

      if (!_isChauffeur(response, phone)) {
        await secureStorageService.clearSession();
        _showMessage('Ce compte n’est pas autorisé dans l’espace chauffeur.');
        return;
      }

      // IMPORTANT :
      // On ne réécrit pas la session ici.
      // AuthService.login() l’a déjà enregistrée avec numericUserId.

      if (!mounted) return;
      context.go(AppRoutes.chauffeur);
    } catch (e) {
      _showMessage(
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
  }) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final hintColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF9CA3AF);
    final cardColor = theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? obscurePassword : false,
            keyboardType:
                isPassword ? TextInputType.text : TextInputType.phone,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              hintText: isPassword
                  ? 'Entrez votre mot de passe'
                  : 'Entrez votre numéro',
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: hintColor,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: hintColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 170,
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Transform.scale(
          scale: 1.1,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.directions_bus_rounded,
                size: 80,
                color: primaryBlue,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 24),
                          const Text(
                            'Transia',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Connexion chauffeur',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Identifiez-vous pour accéder à votre espace chauffeur',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.75),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildInputField(
                            context: context,
                            label: 'Numéro de téléphone',
                            controller: phoneController,
                            icon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 18),
                          _buildInputField(
                            context: context,
                            label: 'Mot de passe',
                            controller: passwordController,
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : loginChauffeur,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : const Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}