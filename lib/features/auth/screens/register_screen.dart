import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/auth/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final Color primaryBlue = const Color(0xFF3158F5);
  final Color backgroundColor = const Color(0xFFF5F7FF);
  final Color textColor = const Color(0xFF374151);

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final AuthService authService;

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    authService = AuthService(
      apiClient: apiClient,
      secureStorageService: secureStorageService,
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    telephoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final fullName = fullNameController.text.trim();
    final telephone = telephoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        telephone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Veuillez remplir tous les champs.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.register(
        fullName: fullName,
        telephone: telephone,
        email: email,
        password: password,
      );

      if (!mounted) return;

      showMessage('Compte créé avec succès. Connectez-vous.');
      context.pop();
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          children: [
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Text(
                'Créer un compte',
                style: TextStyle(
                  color: textColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                'Inscrivez-vous pour réserver vos voyages',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.60),
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 26),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Nom complet'),
                  const SizedBox(height: 7),
                  _AuthField(
                    controller: fullNameController,
                    hintText: 'Ex : Koffi AKAKPO',
                    icon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 15),

                  _label('Numéro de téléphone'),
                  const SizedBox(height: 7),
                  _AuthField(
                    controller: telephoneController,
                    hintText: 'Ex : 90000000',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 15),

                  _label('E-mail (optionnel)'),
                  const SizedBox(height: 7),
                  _AuthField(
                    controller: emailController,
                    hintText: 'Pour récupérer votre mot de passe',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 15),

                  _label('Mot de passe'),
                  const SizedBox(height: 7),
                  _AuthField(
                    controller: passwordController,
                    hintText: 'Créer un mot de passe',
                    icon: Icons.lock_outline_rounded,
                    obscureText: !isPasswordVisible,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  _label('Confirmer le mot de passe'),
                  const SizedBox(height: 7),
                  _AuthField(
                    controller: confirmPasswordController,
                    hintText: 'Confirmer le mot de passe',
                    icon: Icons.lock_outline_rounded,
                    obscureText: !isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible =
                              !isConfirmPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                              'Créer mon compte',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Déjà un compte ?',
                  style: TextStyle(
                    color: textColor.withOpacity(0.70),
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Se connecter',
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: textColor.withOpacity(0.78),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _AuthField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF9CA3AF),
            size: 22,
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}