import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/livreur/models/livreur_colis_model.dart';
import 'package:transia_mobile/features/livreur/services/livreur_service.dart';

class LivreurColisListScreen extends StatefulWidget {
  const LivreurColisListScreen({super.key});

  @override
  State<LivreurColisListScreen> createState() => _LivreurColisListScreenState();
}

class _LivreurColisListScreenState extends State<LivreurColisListScreen>
    with SingleTickerProviderStateMixin {
  late final LivreurService _service;
  final _storage = SecureStorageService();
  late final TabController _tabs;

  bool _loading = true;
  String _error = '';
  List<LivreurColisModel> _tous = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _service = LivreurService(apiClient: ApiClient(_storage));
    _charger();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final list = await _service.getMesLivraisons();
      if (!mounted) return;
      setState(() { _tous = list; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  List<LivreurColisModel> get _aLivrer => _tous.where((c) =>
      c.statut != StatutColis.livre &&
      c.statut != StatutColis.annule &&
      c.statut != StatutColis.retourne &&
      c.statut != StatutColis.perdu).toList();

  List<LivreurColisModel> get _historique => _tous.where((c) =>
      c.statut == StatutColis.livre ||
      c.statut == StatutColis.annule ||
      c.statut == StatutColis.retourne ||
      c.statut == StatutColis.perdu).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mes Livraisons',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800,
                                color: theme.textTheme.bodyLarge?.color)),
                        const SizedBox(height: 4),
                        Text('${_tous.length} colis au total',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.livreurDemandesCollecte),
                    icon: const Icon(Icons.home_work_outlined),
                    tooltip: 'Collectes à effectuer',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF3158F5).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF3158F5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: const Color(0xFF3158F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF6B7280),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'À livrer (${_aLivrer.length})'),
                  Tab(text: 'Historique (${_historique.length})'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFF3158F5)))
                  : _error.isNotEmpty
                      ? _ErrorView(message: _error, onRetry: _charger)
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _ColisListView(
                              items: _aLivrer,
                              emptyMessage: 'Aucun colis à livrer',
                              onRefresh: _charger,
                              onTap: (c) async {
                                await context.push(
                                    AppRoutes.livreurColisDetail, extra: c);
                                _charger();
                              },
                            ),
                            _ColisListView(
                              items: _historique,
                              emptyMessage: 'Aucun historique',
                              onRefresh: _charger,
                              onTap: (c) => context.push(
                                  AppRoutes.livreurColisDetail, extra: c),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColisListView extends StatelessWidget {
  final List<LivreurColisModel> items;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<LivreurColisModel> onTap;

  const _ColisListView({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
    required this.onTap,
  });

  Color _color(StatutColis s) {
    switch (s) {
      case StatutColis.livre:            return const Color(0xFF10B981);
      case StatutColis.enCoursLivraison: return const Color(0xFF3158F5);
      case StatutColis.enTransit:        return const Color(0xFF3158F5);
      case StatutColis.arriveEnAgence:   return const Color(0xFF8B5CF6);
      case StatutColis.deposeEnAgence:   return const Color(0xFF6366F1);
      case StatutColis.retourne:
      case StatutColis.perdu:
      case StatutColis.annule:           return const Color(0xFFEF4444);
      case StatutColis.enAttenteDepot:   return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF3158F5),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final c = items[i];
          final color = _color(c.statut);
          return GestureDetector(
            onTap: () => onTap(c),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.numeroSuivi.isNotEmpty ? c.numeroSuivi : '—',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13,
                              fontFamily: 'monospace'),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statutColisLabel(c.statut),
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Pour : ${c.destinataireNom}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                  if (c.destinataireAdresse != null) ...[
                    const SizedBox(height: 2),
                    Text(c.destinataireAdresse!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (c.agenceArriveeNom != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          size: 12, color: Color(0xFF3158F5)),
                      const SizedBox(width: 4),
                      Text(c.agenceArriveeNom!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF3158F5),
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Icon(Icons.scale_rounded,
                          size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(trancheLabel(c.tranchePoids),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    ]),
                  ],
                ],
              ),
            ),
          );
        },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
