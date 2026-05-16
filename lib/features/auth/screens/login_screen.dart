import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
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

  AppPreferencesController get prefs => AppPreferencesController.instance;

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

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
      showMessage(
        tr(
          fr: 'Veuillez remplir tous les champs.',
          en: 'Please fill in all fields.',
          es: 'Por favor complete todos los campos.',
          ar: 'يرجى ملء جميع الحقول.',
        ),
      );
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

      showMessage(
        tr(
          fr: 'Bienvenue ${user.fullName}',
          en: 'Welcome ${user.fullName}',
          es: 'Bienvenido ${user.fullName}',
          ar: 'مرحبًا ${user.fullName}',
        ),
      );
      context.go(AppRoutes.client);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception: ', ''));
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
      showMessage(
        tr(
          fr: 'Veuillez remplir tous les champs.',
          en: 'Please fill in all fields.',
          es: 'Por favor complete todos los campos.',
          ar: 'يرجى ملء جميع الحقول.',
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        tr(
          fr: 'Les mots de passe ne correspondent pas.',
          en: 'Passwords do not match.',
          es: 'Las contraseñas no coinciden.',
          ar: 'كلمتا المرور غير متطابقتين.',
        ),
      );
      return;
    }

    if (password.length < 4) {
      showMessage(
        tr(
          fr: 'Le mot de passe est trop court.',
          en: 'The password is too short.',
          es: 'La contraseña es demasiado corta.',
          ar: 'كلمة المرور قصيرة جدًا.',
        ),
      );
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

      showMessage(
        tr(
          fr: 'Inscription réussie. Vous pouvez maintenant vous connecter.',
          en: 'Registration successful. You can now sign in.',
          es: 'Registro exitoso. Ahora puede iniciar sesión.',
          ar: 'تم التسجيل بنجاح. يمكنك الآن تسجيل الدخول.',
        ),
      );

      setState(() {
        isLoginMode = true;
      });

      loginPhoneController.text = username;
      loginPasswordController.clear();
      registerPasswordController.clear();
      registerConfirmPasswordController.clear();
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget buildInputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? hintText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final hintColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF9CA3AF);

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
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(color: textColor),
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

  Widget buildModeSwitcher(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172554) : const Color(0xFFF1F5FF),
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
                  tr(
                    fr: 'Connexion',
                    en: 'Sign in',
                    es: 'Conexión',
                    ar: 'تسجيل الدخول',
                  ),
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
                  tr(
                    fr: 'Inscription',
                    en: 'Register',
                    es: 'Registro',
                    ar: 'إنشاء حساب',
                  ),
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

  Widget buildLoginForm(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final subtitleColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(
            fr: 'Connectez-vous à votre compte client',
            en: 'Sign in to your client account',
            es: 'Conéctese a su cuenta de cliente',
            ar: 'سجّل الدخول إلى حساب العميل الخاص بك',
          ),
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        buildInputField(
          context: context,
          label: tr(
            fr: 'Numéro de téléphone',
            en: 'Phone number',
            es: 'Número de teléfono',
            ar: 'رقم الهاتف',
          ),
          controller: loginPhoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          hintText: tr(
            fr: 'Entrez votre numéro',
            en: 'Enter your number',
            es: 'Ingrese su número',
            ar: 'أدخل رقمك',
          ),
        ),
        const SizedBox(height: 18),
        buildInputField(
          context: context,
          label: tr(
            fr: 'Mot de passe',
            en: 'Password',
            es: 'Contraseña',
            ar: 'كلمة المرور',
          ),
          controller: loginPasswordController,
          icon: Icons.lock_outline_rounded,
          obscureText: obscureLoginPassword,
          onToggleVisibility: () {
            setState(() {
              obscureLoginPassword = !obscureLoginPassword;
            });
          },
          hintText: tr(
            fr: 'Entrez votre mot de passe',
            en: 'Enter your password',
            es: 'Ingrese su contraseña',
            ar: 'أدخل كلمة المرور',
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : login,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    tr(
                      fr: 'Se connecter',
                      en: 'Sign in',
                      es: 'Iniciar sesión',
                      ar: 'تسجيل الدخول',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget buildRegisterForm(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(
            fr: 'Créez votre compte client',
            en: 'Create your client account',
            es: 'Cree su cuenta de cliente',
            ar: 'أنشئ حساب العميل الخاص بك',
          ),
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        buildInputField(
          context: context,
          label: tr(
            fr: 'Nom complet',
            en: 'Full name',
            es: 'Nombre completo',
            ar: 'الاسم الكامل',
          ),
          controller: registerFullNameController,
          icon: Icons.person_outline_rounded,
          hintText: tr(
            fr: 'Ex : Koffi AKAKPO',
            en: 'Ex: Koffi AKAKPO',
            es: 'Ej: Koffi AKAKPO',
            ar: 'مثال: Koffi AKAKPO',
          ),
        ),
        const SizedBox(height: 18),
        buildInputField(
          context: context,
          label: tr(
            fr: 'Numéro de téléphone',
            en: 'Phone number',
            es: 'Número de teléfono',
            ar: 'رقم الهاتف',
          ),
          controller: registerPhoneController,
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          hintText: tr(
            fr: 'Entrez votre numéro',
            en: 'Enter your number',
            es: 'Ingrese su número',
            ar: 'أدخل رقمك',
          ),
        ),
        const SizedBox(height: 18),
        buildInputField(
          context: context,
          label: tr(
            fr: 'Mot de passe',
            en: 'Password',
            es: 'Contraseña',
            ar: 'كلمة المرور',
          ),
          controller: registerPasswordController,
          icon: Icons.lock_outline_rounded,
          obscureText: obscureRegisterPassword,
          onToggleVisibility: () {
            setState(() {
              obscureRegisterPassword = !obscureRegisterPassword;
            });
          },
          hintText: tr(
            fr: 'Créez un mot de passe',
            en: 'Create a password',
            es: 'Cree una contraseña',
            ar: 'أنشئ كلمة مرور',
          ),
        ),
        const SizedBox(height: 18),
        buildInputField(
          context: context,
          label: tr(
            fr: 'Confirmer le mot de passe',
            en: 'Confirm password',
            es: 'Confirmar contraseña',
            ar: 'تأكيد كلمة المرور',
          ),
          controller: registerConfirmPasswordController,
          icon: Icons.lock_outline_rounded,
          obscureText: obscureRegisterConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              obscureRegisterConfirmPassword =
                  !obscureRegisterConfirmPassword;
            });
          },
          hintText: tr(
            fr: 'Confirmez le mot de passe',
            en: 'Confirm password',
            es: 'Confirme la contraseña',
            ar: 'أكد كلمة المرور',
          ),
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : register,
            child: isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    tr(
                      fr: 'S’inscrire',
                      en: 'Register',
                      es: 'Registrarse',
                      ar: 'إنشاء حساب',
                    ),
                    style: const TextStyle(
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
    final theme = Theme.of(context);
    final pageBackground = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final isDark = theme.brightness == Brightness.dark;

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
                            tr(
                              fr: 'Transport intelligent pour tous',
                              en: 'Smart transport for everyone',
                              es: 'Transporte inteligente para todos',
                              ar: 'نقل ذكي للجميع',
                            ),
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
                  color: pageBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(34),
                    topRight: Radius.circular(34),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                  children: [
                    buildModeSwitcher(context),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: isLoginMode
                          ? buildLoginForm(context)
                          : buildRegisterForm(context),
                    ),
                    const SizedBox(height: 14),
                    if (isLoginMode)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLoginMode = false;
                          });
                        },
                        child: Text(
                          tr(
                            fr: 'Vous n’avez pas de compte ? Inscrivez-vous',
                            en: 'Don’t have an account? Sign up',
                            es: '¿No tiene cuenta? Regístrese',
                            ar: 'ليس لديك حساب؟ أنشئ حسابًا',
                          ),
                          style: TextStyle(color: isDark ? Colors.white70 : textColor),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLoginMode = true;
                          });
                        },
                        child: Text(
                          tr(
                            fr: 'Vous avez déjà un compte ? Connectez-vous',
                            en: 'Already have an account? Sign in',
                            es: '¿Ya tiene cuenta? Inicie sesión',
                            ar: 'لديك حساب بالفعل؟ سجّل الدخول',
                          ),
                          style: TextStyle(color: isDark ? Colors.white70 : textColor),
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