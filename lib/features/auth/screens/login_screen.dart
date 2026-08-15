import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/auth/models/auth_response.dart';
import 'package:transia_mobile/features/auth/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String expectedRole;
  final bool allowRegistration;

  const LoginScreen({
    super.key,
    required this.expectedRole,
    this.allowRegistration = false,
  });

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
  final TextEditingController registerEmailController = TextEditingController();
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
    registerEmailController.dispose();
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

  String get _expectedRole => widget.expectedRole
      .trim()
      .toUpperCase()
      .replaceFirst('ROLE_', '');

  bool get _isClientPortal => _expectedRole == 'CLIENT';

  String get _portalLabel {
    switch (_expectedRole) {
      case 'CHAUFFEUR':
        return 'Espace Chauffeur';
      case 'LIVREUR':
        return 'Espace Livreur';
      case 'CLIENT':
      default:
        return 'Espace Client';
    }
  }

  bool _hasRole(AuthResponse response, String role) {
    final expected = role
        .trim()
        .toUpperCase()
        .replaceFirst('ROLE_', '');

    return response.roles.any((item) {
      final normalized = item
          .trim()
          .toUpperCase()
          .replaceFirst('ROLE_', '');
      return normalized == expected;
    });
  }

  void _redirectToUserSpace(AuthResponse user) {
    if (!mounted) return;

    if (_hasRole(user, 'CHAUFFEUR')) {
      context.go(AppRoutes.chauffeur);
    } else if (_hasRole(user, 'LIVREUR')) {
      context.go(AppRoutes.livreur);
    } else {
      context.go(AppRoutes.client);
    }
  }

  Future<void> login() async {
    final telephone = loginPhoneController.text.trim();
    final password = loginPasswordController.text.trim();

    if (telephone.isEmpty || password.isEmpty) {
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
        telephone: telephone,
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

      _redirectToUserSpace(user);
    } catch (e) {
      showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> register() async {
    if (!widget.allowRegistration || !_isClientPortal) {
      showMessage('L’inscription est réservée aux comptes clients.');
      return;
    }

    final fullName = registerFullNameController.text.trim();
    final telephone = registerPhoneController.text.trim();
    final email = registerEmailController.text.trim();
    final password = registerPasswordController.text.trim();
    final confirmPassword = registerConfirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        telephone.isEmpty ||
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
        telephone: telephone,
        email: email,
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

      loginPhoneController.text = telephone;
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

    if (!widget.allowRegistration) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF172554)
              : const Color(0xFFF1F5FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _portalLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      );
    }
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
    final subtitleColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(
            fr: 'Connectez-vous à votre compte',
            en: 'Sign in to your account',
            es: 'Conéctese a su cuenta',
            ar: 'سجّل الدخول إلى حسابك',
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : () => context.push(AppRoutes.forgotPassword),
            child: Text(
              tr(
                fr: 'Mot de passe oublié ?',
                en: 'Forgot password?',
                es: '¿Olvidó su contraseña?',
                ar: 'نسيت كلمة المرور؟',
              ),
              style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
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
            fr: 'E-mail (optionnel)',
            en: 'Email (optional)',
            es: 'Correo electrónico (opcional)',
            ar: 'البريد الإلكتروني (اختياري)',
          ),
          controller: registerEmailController,
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          hintText: tr(
            fr: 'Pour récupérer votre mot de passe',
            en: 'To recover your password',
            es: 'Para recuperar su contraseña',
            ar: 'لاسترداد كلمة المرور',
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

Widget _buildLogo() {
  return Container(
    height: 128,
    width: 128,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(34),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.scale(
          scale: 0.30,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.directions_bus_rounded,
                size: 70,
                color: primaryBlue,
              );
            },
          ),
        ),
      ),
    ),
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
      resizeToAvoidBottomInset: true,
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                        child: Center(
                          child: Column(
                            children: [
                              _buildLogo(),
                              const SizedBox(height: 14),
                              const Text(
                                'Transia',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tr(
                                  fr: 'Transport intelligent pour tous',
                                  en: 'Smart transport for everyone',
                                  es: 'Transporte inteligente para todos',
                                  ar: 'نقل ذكي للجميع',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: pageBackground,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(34),
                              topRight: Radius.circular(34),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildModeSwitcher(context),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: (!widget.allowRegistration || isLoginMode)
                                    ? buildLoginForm(context)
                                    : buildRegisterForm(context),
                              ),
                              if (widget.allowRegistration)
                                const SizedBox(height: 14),
                              if (widget.allowRegistration && isLoginMode)
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
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : textColor,
                                    ),
                                  ),
                                )
                              else if (widget.allowRegistration)
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
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : textColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

