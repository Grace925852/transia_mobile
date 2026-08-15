import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/colis_model.dart';
import 'package:transia_mobile/features/client/services/colis_service.dart';

class ClientColisListScreen extends StatefulWidget {
  const ClientColisListScreen({super.key});

  @override
  State<ClientColisListScreen> createState() => _ClientColisListScreenState();
}

class _ClientColisListScreenState extends State<ClientColisListScreen> {
  late final ColisService _service;
  final _storage = SecureStorageService();

  bool _loading = true;
  String _error = '';
  List<ColisModel> _colis = [];

  @override
  void initState() {
    super.initState();
    _service = ColisService(apiClient: ApiClient(_storage));
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final list = await _service.getMesColis();
      if (!mounted) return;
      setState(() { _colis = list; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Color _statutColor(StatutColis s) {
    switch (s) {
      case StatutColis.livre:             return const Color(0xFF10B981);
      case StatutColis.enCoursLivraison:  return const Color(0xFF3158F5);
      case StatutColis.enTransit:         return const Color(0xFF3158F5);
      case StatutColis.arriveEnAgence:    return const Color(0xFF8B5CF6);
      case StatutColis.deposeEnAgence:    return const Color(0xFF6366F1);
      case StatutColis.retourne:
      case StatutColis.perdu:
      case StatutColis.annule:            return const Color(0xFFEF4444);
      case StatutColis.enAttenteCollecte:
      case StatutColis.enAttenteDepot:    return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes Colis',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          '${_colis.length} envoi(s)',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push(AppRoutes.clientColisForm);
                      _charger();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Envoyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3158F5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? _ErrorView(message: _error, onRetry: _charger)
                      : _colis.isEmpty
                          ? _EmptyView(onEnvoyer: () async {
                              await context.push(AppRoutes.clientColisForm);
                              _charger();
                            })
                          : RefreshIndicator(
                              onRefresh: _charger,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: _colis.length,
                                itemBuilder: (ctx, i) {
                                  final c = _colis[i];
                                  return _ColisCard(
                                    colis: c,
                                    statutColor: _statutColor(c.statut),
                                    onTap: () => context.push(
                                      AppRoutes.clientColisDetail,
                                      extra: c,
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

class _ColisCard extends StatelessWidget {
  final ColisModel colis;
  final Color statutColor;
  final VoidCallback onTap;

  const _ColisCard({
    required this.colis,
    required this.statutColor,
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
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3158F5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Color(0xFF3158F5), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        colis.numeroSuivi.isNotEmpty ? colis.numeroSuivi : '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14,
                            fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pour: ${colis.destinataireNom}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statutColisLabel(colis.statut),
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: statutColor),
                  ),
                ),
              ],
            ),
            if (colis.livreurNom != null && colis.livreurNom!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Livreur assigné : ${colis.livreurNom}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (colis.agenceDepartNom != null || colis.agenceArriveeNom != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF3158F5)),
                  const SizedBox(width: 6),
                  Text(colis.agenceDepartNom ?? '?',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 12, color: Color(0xFF9CA3AF)),
                  ),
                  const Icon(Icons.location_on, size: 8, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Text(colis.agenceArriveeNom ?? '?',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const Spacer(),
                  Text(trancheLabel(colis.tranchePoids),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF374151))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onEnvoyer;
  const _EmptyView({required this.onEnvoyer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 72, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('Aucun colis envoyé',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
            const SizedBox(height: 8),
            const Text('Envoyez votre premier colis facilement.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onEnvoyer,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Envoyer un colis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3158F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
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
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
