import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/auth/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SecureStorageService secureStorageService = SecureStorageService();

  final TextEditingController loginPhoneController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();

  final TextEditingController registerFullNameController =
      TextEditingController();
  final TextEditingController registerPhoneController = TextEditingController();
  final TextEditingController registerPasswordController =
      TextEditingController();
  final TextEditingController registerConfirmPasswordController =
      TextEditingController();

  bool isLoginMode = true;
  bool obscureLoginPassword = true;
  bool obscureRegisterPassword = true;
  bool obscureRegisterConfirmPassword = true;
  bool isLoading = false;

  final Color primaryBlue = const Color(0xFF3158F5);
  final Color backgroundColor = const Color(0xFFF5F7FF);
  final Color textColor = const Color(0xFF374151);
  final Color hintColor = const Color(0xFF9CA3AF);

  @override
  void dispose() {
    loginPhoneController.dispose();
    loginPasswordController.dispose();
    registerFullNameController.dispose();
    registerPhoneController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    super.dispose();
  }

  AuthService _buildAuthService() {
    final apiClient = ApiClient(secureStorageService);
    return AuthService(
      apiClient: apiClient,
      secureStorageService: secureStorageService,
    );
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> login() async {
    final username = loginPhoneController.text.trim();
    final password = loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showMessage('Veuillez remplir tous les champs.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = _buildAuthService();

      final user = await authService.login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      showMessage('Bienvenue ${user.fullName}');
      context.go(AppRoutes.client);
    } catch (e) {
      showMessage(
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> register() async {
    final fullName = registerFullNameController.text.trim();
    final username = registerPhoneController.text.trim();
    final password = registerPasswordController.text.trim();
    final confirmPassword = registerConfirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Veuillez remplir tous les champs.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Les mots de passe ne correspondent pas.');
      return;
    }

    if (password.length < 4) {
      showMessage('Le mot de passe est trop court.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final authService = _buildAuthService();

      await authService.register(
        fullName: fullName,
        username: username,
        password: password,
      );

      if (!mounted) return;

      showMessage('Inscription réussie. Vous pouvez maintenant vous connecter.');

      setState(() {
        isLoginMode = true;
      });

      loginPhoneController.text = username;
      loginPasswordController.clear();
      registerPasswordController.clear();
      registerConfirmPasswordController.clear();
    } catch (e) {
      showMessage(
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: hintColor),
              suffixIcon: onToggleVisibility == null
                  ? null
                  : IconButton(
                      onPressed: onToggleVisibility,
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: hintColor,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isLoginMode = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isLoginMode ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Connexion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isLoginMode ? Colors.white : textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isLoginMode = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !isLoginMode ? primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Inscription',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !isLoginMode ? Colors.white : textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connectez-vous à votre compte client',
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        buildInputField(
          label: 'Numéro de téléphone',
          controller: loginPhoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          hintText: 'Entrez votre numéro',
        ),
        const SizedBox(height: 18),
        buildInputField(
          label: 'Mot de passe',
          controller: loginPasswordController,
          icon: Icons.lock_outline_rounded,
          obscureText: obscureLoginPassword,
          onToggleVisibility: () {
            setState(() {
              obscureLoginPassword = !obscureLoginPassword;
            });
          },
          hintText: 'Entrez votre mot de passe',
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : login,
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
    );
  }

  Widget buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créez votre compte client',
          style: TextStyle(
            fontSize: 14,
            color: textColor.withOpacity(0.75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        buildInputField(
          label: 'Nom complet',
          controller: registerFullNameController,
          icon: Icons.person_outline_rounded,
          hintText: 'Ex : Koffi AKAKPO',
        ),
        const SizedBox(height: 18),
        buildInputField(
          label: 'Numéro de téléphone',
          controller: registerPhoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          hintText: 'Entrez votre numéro',
        ),
        const SizedBox(height: 18),
        buildInputField(
          label: 'Mot de passe',
          controller: registerPasswordController,
          icon: Icons.lock_outline_rounded,
          obscureText: obscureRegisterPassword,
          onToggleVisibility: () {
            setState(() {
              obscureRegisterPassword = !obscureRegisterPassword;
            });
          },
          hintText: 'Créez un mot de passe',
        ),
        const SizedBox(height: 18),
        buildInputField(
          label: 'Confirmer le mot de passe',
          controller: registerConfirmPasswordController,
          icon: Icons.lock_outline_rounded,
          obscureText: obscureRegisterConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              obscureRegisterConfirmPassword =
                  !obscureRegisterConfirmPassword;
            });
          },
          hintText: 'Confirmez le mot de passe',
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : register,
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
                    'S’inscrire',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              Icons.directions_bus_rounded,
                              size: 62,
                              color: primaryBlue,
                            ),
                          ),
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
                            'Transport intelligent pour tous',
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
              flex: 6,
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
                    buildModeSwitcher(),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: isLoginMode
                          ? buildLoginForm()
                          : buildRegisterForm(),
                    ),
                    const SizedBox(height: 14),
                    if (isLoginMode)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLoginMode = false;
                          });
                        },
                        child: const Text(
                          'Vous n’avez pas de compte ? Inscrivez-vous',
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLoginMode = true;
                          });
                        },
                        child: const Text(
                          'Vous avez déjà un compte ? Connectez-vous',
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