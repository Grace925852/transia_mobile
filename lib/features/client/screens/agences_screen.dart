import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/agence_model.dart';
import 'package:transia_mobile/features/client/services/agence_service.dart';
import 'package:transia_mobile/shared/utils/base64_image.dart';

class AgencesScreen extends StatefulWidget {
  const AgencesScreen({super.key});

  @override
  State<AgencesScreen> createState() => _AgencesScreenState();
}

class _AgencesScreenState extends State<AgencesScreen> {
  late final AgenceService _service;

  bool _loading = true;
  String _error = '';
  List<AgenceModel> _agences = [];
  List<AgenceModel> _agencesAffichees = [];
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _service = AgenceService(apiClient: ApiClient(SecureStorageService()));
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final list = await _service.getAgencesActives();
      if (!mounted) return;
      setState(() {
        _agences = list;
        _appliquerFiltre();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appliquerFiltre() {
    final terme = _recherche.trim().toLowerCase();
    _agencesAffichees = terme.isEmpty
        ? _agences
        : _agences
            .where((a) =>
                a.nom.toLowerCase().contains(terme) ||
                a.villeNom.toLowerCase().contains(terme))
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF);
    const primaryBlue = Color(0xFF3158F5);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nos Agences',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          '${_agencesAffichees.length} point(s) de service',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) {
                    setState(() {
                      _recherche = v;
                      _appliquerFiltre();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par nom ou ville...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? _ErrorView(message: _error, onRetry: _charger)
                      : _agencesAffichees.isEmpty
                          ? const _EmptyView()
                          : RefreshIndicator(
                              onRefresh: _charger,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: _agencesAffichees.length,
                                itemBuilder: (ctx, i) {
                                  final a = _agencesAffichees[i];
                                  return _AgenceCard(
                                    agence: a,
                                    primaryColor: primaryBlue,
                                    onTap: () => context.push(
                                      AppRoutes.clientAgenceDetail,
                                      extra: a,
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgenceCard extends StatelessWidget {
  final AgenceModel agence;
  final Color primaryColor;
  final VoidCallback onTap;

  const _AgenceCard({
    required this.agence,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildThumbnail(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agence.nom,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          agence.villeNom.isNotEmpty ? agence.villeNom : agence.adresse,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final image = agence.photos.isNotEmpty
        ? base64ImageProvider(agence.photos.first)
        : null;

    if (image == null) return _placeholder(primaryColor);

    return Image(
      image: image,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(primaryColor),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      width: 64,
      height: 64,
      color: color.withValues(alpha: 0.1),
      child: Icon(Icons.store_rounded, color: color, size: 28),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 72, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('Aucune agence disponible',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
