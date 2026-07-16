import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/network/self_service.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/shared/widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color primaryBlue = const Color(0xFF3158F5);

  late final SelfService selfService;
  final SecureStorageService storage = SecureStorageService();

  final fullNameController = TextEditingController();
  final telephoneController = TextEditingController();
  final emailController = TextEditingController();
  final adresseController = TextEditingController();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool profilExistant = false;
  String? photoBase64;
  bool isUploadingPhoto = false;

  bool isLoadingInfos = false;
  bool isLoadingProfil = false;
  bool isLoadingPassword = false;
  bool isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    selfService = SelfService(apiClient: ApiClient(storage));
    _charger();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    telephoneController.dispose();
    emailController.dispose();
    adresseController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final me = await selfService.getMe();
      fullNameController.text = me.fullName;
      telephoneController.text = me.telephone;
      emailController.text = me.email ?? '';

      final profil = await selfService.getMyProfil();
      if (profil != null) {
        profilExistant = true;
        adresseController.text = profil.adresse ?? '';
        photoBase64 = profil.photoProfil;
      }
    } catch (e) {
      if (mounted) _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoadingInitial = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _initiales {
    final parts = fullNameController.text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Future<void> _choisirPhoto() async {
    try {
      final picker = ImagePicker();
      final fichier = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (fichier == null) return;

      final bytes = await fichier.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      setState(() {
        photoBase64 = base64Image;
        isUploadingPhoto = true;
      });

      await selfService.saveMyProfil(
        photoProfil: base64Image,
        adresse: adresseController.text.trim(),
        existant: profilExistant,
      );
      profilExistant = true;
      if (mounted) _showMessage('Photo de profil mise à jour.');
    } catch (e) {
      if (mounted) _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isUploadingPhoto = false);
    }
  }

  Future<void> _enregistrerInfos() async {
    if (fullNameController.text.trim().isEmpty || telephoneController.text.trim().isEmpty) {
      _showMessage('Le nom complet et le téléphone sont obligatoires.');
      return;
    }

    setState(() => isLoadingInfos = true);
    try {
      await selfService.updateMe(
        fullName: fullNameController.text.trim(),
        telephone: telephoneController.text.trim(),
        email: emailController.text.trim(),
      );
      await storage.updateProfileCache(
        fullName: fullNameController.text.trim(),
        telephone: telephoneController.text.trim(),
      );
      if (mounted) _showMessage('Vos informations ont été mises à jour.');
    } catch (e) {
      if (mounted) _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoadingInfos = false);
    }
  }

  Future<void> _enregistrerProfil() async {
    setState(() => isLoadingProfil = true);
    try {
      await selfService.saveMyProfil(
        adresse: adresseController.text.trim(),
        existant: profilExistant,
      );
      profilExistant = true;
      if (mounted) _showMessage('Votre adresse a été mise à jour.');
    } catch (e) {
      if (mounted) _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoadingProfil = false);
    }
  }

  Future<void> _changerMotDePasse() async {
    if (currentPasswordController.text.isEmpty || newPasswordController.text.isEmpty) {
      _showMessage('Veuillez remplir tous les champs.');
      return;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      _showMessage('Les nouveaux mots de passe ne correspondent pas.');
      return;
    }

    setState(() => isLoadingPassword = true);
    try {
      await selfService.changePassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      if (mounted) _showMessage('Votre mot de passe a été modifié.');
    } catch (e) {
      if (mounted) _showMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoadingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Center(child: _avatarEditable()),
                const SizedBox(height: 20),
                _sectionAccordion(
                  title: 'Informations',
                  icon: Icons.badge_outlined,
                  initiallyExpanded: true,
                  children: [
                    _field('Nom complet', fullNameController),
                    const SizedBox(height: 12),
                    _field('Téléphone', telephoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _field('E-mail (optionnel)', emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _submitButton('Enregistrer', isLoadingInfos, _enregistrerInfos),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionAccordion(
                  title: 'Adresse',
                  icon: Icons.location_on_outlined,
                  children: [
                    _field('Adresse', adresseController),
                    const SizedBox(height: 16),
                    _submitButton('Enregistrer', isLoadingProfil, _enregistrerProfil),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionAccordion(
                  title: 'Mot de passe',
                  icon: Icons.lock_outline_rounded,
                  children: [
                    _field('Mot de passe actuel', currentPasswordController, obscure: true),
                    const SizedBox(height: 12),
                    _field('Nouveau mot de passe', newPasswordController, obscure: true),
                    const SizedBox(height: 12),
                    _field('Confirmer le nouveau mot de passe', confirmPasswordController, obscure: true),
                    const SizedBox(height: 16),
                    _submitButton('Changer le mot de passe', isLoadingPassword, _changerMotDePasse),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _avatarEditable() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(
          photoBase64: photoBase64,
          initiales: _initiales,
          radius: 48,
          backgroundColor: primaryBlue,
          fontSize: 28,
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: GestureDetector(
            onTap: isUploadingPhoto ? null : _choisirPhoto,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isUploadingPhoto
                  ? const SizedBox(
                      height: 16, width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionAccordion({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon, color: primaryBlue),
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          children: children,
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _submitButton(String label, bool loading, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
