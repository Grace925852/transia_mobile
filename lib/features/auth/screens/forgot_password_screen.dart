import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/auth/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final Color primaryBlue = const Color(0xFF3158F5);
  final Color backgroundColor = const Color(0xFFF5F7FF);
  final Color textColor = const Color(0xFF374151);

  final TextEditingController phoneController = TextEditingController();

  late final AuthService authService;
  bool isLoading = false;
  bool demandeEnvoyee = false;

  @override
  void initState() {
    super.initState();
    final storage = SecureStorageService();
    authService = AuthService(
      apiClient: ApiClient(storage),
      secureStorageService: storage,
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    final telephone = phoneController.text.trim();
    if (telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre numéro de téléphone.'),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.forgotPassword(telephone: telephone);
      if (!mounted) return;
      setState(() => demandeEnvoyee = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(),
            Transform.translate(
              offset: const Offset(0, -38),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 230,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryBlue,
            const Color(0xFF1F3EDB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Mot de passe oublié',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Récupérez l\'accès à votre compte',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 92,
            width: 92,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              demandeEnvoyee ? Icons.mark_email_read_rounded : Icons.lock_reset_rounded,
              color: primaryBlue,
              size: 54,
            ),
          ),

          const SizedBox(height: 24),

          if (!demandeEnvoyee) ...[
            Text(
              'Récupération du compte',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 27,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Entrez votre numéro de téléphone. Si un e-mail est associé à votre compte, un lien de réinitialisation vous y sera envoyé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.62),
                fontSize: 17,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Numéro de téléphone',
                style: TextStyle(
                  fontSize: 18,
                  color: textColor.withOpacity(0.78),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Container(
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                enabled: !isLoading,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF111827),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ex : 90 00 00 00',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF9CA3AF),
                    size: 26,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 66,
              child: ElevatedButton(
                onPressed: isLoading ? null : sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.6,
                        ),
                      )
                    : const Text(
                        'Envoyer la demande',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ] else ...[
            Text(
              'Demande envoyée',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 27,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Si un e-mail est associé à ce numéro, un lien de réinitialisation vient de vous être envoyé. '
              'Sinon, contactez une agence pour réinitialiser votre mot de passe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.62),
                fontSize: 17,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 18),

          TextButton(
            onPressed: () {
              context.pop();
            },
            child: Text(
              'Retour à la connexion',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
