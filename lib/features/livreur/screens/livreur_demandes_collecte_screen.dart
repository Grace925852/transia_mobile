import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/demande_collecte_model.dart';
import 'package:transia_mobile/features/livreur/services/livreur_service.dart';

class LivreurDemandesCollecteScreen extends StatefulWidget {
  const LivreurDemandesCollecteScreen({super.key});

  @override
  State<LivreurDemandesCollecteScreen> createState() =>
      _LivreurDemandesCollecteScreenState();
}

class _LivreurDemandesCollecteScreenState
    extends State<LivreurDemandesCollecteScreen> {
  late final LivreurService _service;
  final _storage = SecureStorageService();

  bool _loading = true;
  String _error = '';
  List<DemandeCollecteModel> _demandes = [];

  @override
  void initState() {
    super.initState();
    _service = LivreurService(apiClient: ApiClient(_storage));
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final list = await _service.getMesDemandesCollecte();
      if (!mounted) return;
      setState(() { _demandes = list; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Color _statutColor(StatutCollecte s) {
    switch (s) {
      case StatutCollecte.collecte: return const Color(0xFF10B981);
      case StatutCollecte.enCours: return const Color(0xFF3158F5);
      case StatutCollecte.annule: return const Color(0xFFEF4444);
      case StatutCollecte.enAttente: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3158F5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Collectes à effectuer',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
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
                        TextButton(onPressed: _charger, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _demandes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_work_outlined, size: 72, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 16),
                            const Text('Aucune collecte assignée',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                    color: Color(0xFF374151))),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _demandes.length,
                        itemBuilder: (ctx, i) {
                          final d = _demandes[i];
                          final color = _statutColor(d.statut);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border(left: BorderSide(color: color, width: 4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(d.adresseCollecte,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 14)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(statutCollecteLabel(d.statut),
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(d.dateHeureCollecte,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                if (d.agenceNom != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Agence : ${d.agenceNom}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
