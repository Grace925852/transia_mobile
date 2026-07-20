import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:transia_mobile/features/client/models/agence_model.dart';
import 'package:transia_mobile/shared/utils/base64_image.dart';

class AgenceDetailScreen extends StatefulWidget {
  final AgenceModel agence;

  const AgenceDetailScreen({super.key, required this.agence});

  @override
  State<AgenceDetailScreen> createState() => _AgenceDetailScreenState();
}

class _AgenceDetailScreenState extends State<AgenceDetailScreen> {
  final PageController _pageController = PageController();
  int _photoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _appeler() async {
    final numero = widget.agence.telephone.trim();
    if (numero.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      _afficherErreur('Impossible de lancer l\'appel.');
    }
  }

  Future<void> _ouvrirItineraire() async {
    final lien = widget.agence.lienGoogleMaps;
    if (lien == null) return;
    final uri = Uri.parse(lien);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _afficherErreur('Impossible d\'ouvrir la carte.');
    }
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.agence;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF);
    const primaryBlue = Color(0xFF3158F5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
              ),
              _buildCarousel(a, primaryBlue),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.nom,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (a.villeNom.isNotEmpty)
                      Text(a.villeNom, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.call_rounded,
                            label: 'Appeler',
                            color: primaryBlue,
                            onTap: a.telephone.isNotEmpty ? _appeler : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.directions_rounded,
                            label: 'Itinéraire',
                            color: const Color(0xFF10B981),
                            onTap: a.aCoordonnees ? _ouvrirItineraire : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _InfoTile(icon: Icons.location_on_outlined, label: 'Adresse', value: a.adresse.isNotEmpty ? a.adresse : '—'),
                    _InfoTile(icon: Icons.phone_outlined, label: 'Téléphone', value: a.telephone.isNotEmpty ? a.telephone : '—'),
                    if (a.email.isNotEmpty)
                      _InfoTile(icon: Icons.email_outlined, label: 'Email', value: a.email),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(AgenceModel a, Color primaryColor) {
    if (a.photos.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.store_rounded, color: primaryColor, size: 56),
      );
    }

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _pageController,
                itemCount: a.photos.length,
                onPageChanged: (i) => setState(() => _photoIndex = i),
                itemBuilder: (ctx, i) {
                  final image = base64ImageProvider(a.photos[i]);
                  if (image == null) {
                    return Container(color: primaryColor.withValues(alpha: 0.1));
                  }
                  return Image(image: image, fit: BoxFit.cover, width: double.infinity);
                },
              ),
            ),
          ),
          if (a.photos.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(a.photos.length, (i) {
                  final active = i == _photoIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: active ? 1 : 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: disabled ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: disabled ? color.withValues(alpha: 0.4) : color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: disabled ? color.withValues(alpha: 0.4) : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
