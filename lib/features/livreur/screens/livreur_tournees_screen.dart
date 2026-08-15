import 'package:flutter/material.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/livreur/models/livreur_tournee_model.dart';
import 'package:transia_mobile/features/livreur/screens/livreur_tournee_detail_screen.dart';
import 'package:transia_mobile/features/livreur/services/livreur_service.dart';

class LivreurTourneesScreen extends StatefulWidget {
  const LivreurTourneesScreen({super.key});

  @override
  State<LivreurTourneesScreen> createState() => _LivreurTourneesScreenState();
}

class _LivreurTourneesScreenState extends State<LivreurTourneesScreen> {
  late final LivreurService _service;
  final _storage = SecureStorageService();

  bool _loading = true;
  String _error = '';
  List<LivreurTourneeModel> _tournees = [];

  @override
  void initState() {
    super.initState();
    _service = LivreurService(apiClient: ApiClient(_storage));
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final list = await _service.getMesTournees();
      if (!mounted) return;
      setState(() { _tournees = list; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'TERMINEE': return const Color(0xFF10B981);
      case 'EN_COURS': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3158F5);
    }
  }

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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes Tournées',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_tournees.length} tournée(s) de collecte planifiée(s)',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _charger,
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3158F5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _charger,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _tournees.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_shipping_outlined,
                                        size: 72, color: Color(0xFFCBD5E1)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Aucune tournée assignée',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF374151)),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Vos nouvelles tournées de collecte créées par l\'agence s\'afficheront ici.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13, color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _charger,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: _tournees.length,
                                itemBuilder: (ctx, i) {
                                  final t = _tournees[i];
                                  final color = _statutColor(t.statut);
                                  final nbColis = t.demandesCollecte.length;

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              LivreurTourneeDetailScreen(tournee: t),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border(
                                            left: BorderSide(color: color, width: 4)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                                alpha: isDark ? 0.2 : 0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  Icons.alt_route_rounded,
                                                  color: color,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      t.zone != null && t.zone!.isNotEmpty
                                                          ? 'Tournée : ${t.zone}'
                                                          : 'Tournée sans nom',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w800,
                                                          fontSize: 15),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Date : ${t.dateTournee}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Color(0xFF6B7280)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  t.statut,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: color),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          const Divider(height: 1),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.inventory_2_rounded,
                                                  size: 16, color: Color(0xFF3158F5)),
                                              const SizedBox(width: 6),
                                              Text(
                                                '$nbColis colis à collecter',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF374151)),
                                              ),
                                              const Spacer(),
                                              const Text(
                                                'Voir détails',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF3158F5)),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward_ios_rounded,
                                                  size: 12, color: Color(0xFF3158F5)),
                                            ],
                                          ),
                                        ],
                                      ),
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
