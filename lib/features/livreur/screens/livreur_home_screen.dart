import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/network/self_service.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/livreur/models/livreur_colis_model.dart';
import 'package:transia_mobile/features/livreur/services/livreur_service.dart';
import 'package:transia_mobile/shared/widgets/user_avatar.dart';

class LivreurHomeScreen extends StatefulWidget {
  const LivreurHomeScreen({super.key});

  @override
  State<LivreurHomeScreen> createState() => _LivreurHomeScreenState();
}

class _LivreurHomeScreenState extends State<LivreurHomeScreen> {
  late final LivreurService _service;
  late final SelfService _selfService;
  final _storage = SecureStorageService();

  bool _loading = true;
  String _fullName = 'Livreur';
  String? _photoBase64;
  List<LivreurColisModel> _tous = [];

  @override
  void initState() {
    super.initState();
    _service = LivreurService(apiClient: ApiClient(_storage));
    _selfService = SelfService(apiClient: ApiClient(_storage));
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final name = await _storage.getFullName();
      final list = await _service.getMesLivraisons();
      final profil = await _selfService.getMyProfil();
      if (!mounted) return;
      setState(() {
        _fullName = (name?.isNotEmpty == true) ? name! : 'Livreur';
        _photoBase64 = profil?.photoProfil;
        _tous = list;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _aLivrer => _tous.where((c) =>
      c.statut != StatutColis.livre && c.statut != StatutColis.annule).length;

  int get _enCours => _tous.where((c) => c.statut == StatutColis.enCoursLivraison).length;

  int get _livresAujourdhui {
    final today = DateTime.now();
    return _tous.where((c) {
      if (c.statut != StatutColis.livre) return false;
      final d = DateTime.tryParse(c.dateCreation ?? '');
      if (d == null) return false;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
  }

  List<LivreurColisModel> get _urgents => _tous
      .where((c) => c.statut == StatutColis.enCoursLivraison || c.statut == StatutColis.arriveEnAgence)
      .take(5)
      .toList();

  String get _initiales {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'LV';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          color: const Color(0xFF3158F5),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              // Bannière
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3158F5), Color(0xFF1d4ed8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    UserAvatar(
                      photoBase64: _photoBase64,
                      initiales: _initiales,
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      fontSize: 18,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bonjour 👋',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(_fullName,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w800,
                                  fontSize: 18)),
                          const Text('Espace Livreur',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _charger,
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // KPIs
              const Text('Tableau de bord',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B), letterSpacing: 0.5)),
              const SizedBox(height: 10),
              if (_loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Color(0xFF3158F5)),
                ))
              else ...[
                Row(
                  children: [
                    Expanded(child: _KpiCard(
                        value: '$_aLivrer',
                        label: 'À livrer',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF3158F5))),
                    const SizedBox(width: 12),
                    Expanded(child: _KpiCard(
                        value: '$_enCours',
                        label: 'En cours',
                        icon: Icons.local_shipping_rounded,
                        color: const Color(0xFFF59E0B))),
                    const SizedBox(width: 12),
                    Expanded(child: _KpiCard(
                        value: '$_livresAujourdhui',
                        label: "Livrés auj.",
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF3158F5))),
                  ],
                ),
                const SizedBox(height: 20),
                if (_urgents.isNotEmpty) ...[
                  const Text('Livraisons en cours',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  ..._urgents.map((c) => _MiniColisCard(
                        colis: c,
                        onTap: () => context.push(
                            AppRoutes.livreurColisDetail, extra: c),
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MiniColisCard extends StatelessWidget {
  final LivreurColisModel colis;
  final VoidCallback onTap;

  const _MiniColisCard({required this.colis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: Color(0xFF3158F5), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(colis.destinataireNom,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(colis.destinataireAdresse ?? colis.destinataireTelephone,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
