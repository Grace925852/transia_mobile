import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void sendCode() {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre numéro de téléphone.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code de réinitialisation envoyé.'),
      ),
    );
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
            'Recevez un code pour récupérer votre compte',
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
              Icons.lock_reset_rounded,
              color: primaryBlue,
              size: 54,
            ),
          ),

          const SizedBox(height: 24),

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
            'Entrez votre numéro de téléphone. Nous vous enverrons un code de vérification.',
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
              onPressed: sendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Envoyer le code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

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