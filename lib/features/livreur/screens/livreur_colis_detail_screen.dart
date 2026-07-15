import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/livreur/models/livreur_colis_model.dart';
import 'package:transia_mobile/features/livreur/services/livreur_service.dart';

class LivreurColisDetailScreen extends StatefulWidget {
  final LivreurColisModel colis;

  const LivreurColisDetailScreen({super.key, required this.colis});

  @override
  State<LivreurColisDetailScreen> createState() =>
      _LivreurColisDetailScreenState();
}

class _LivreurColisDetailScreenState extends State<LivreurColisDetailScreen> {
  late LivreurColisModel _colis;
  late final LivreurService _service;
  final _storage = SecureStorageService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _colis = widget.colis;
    _service = LivreurService(apiClient: ApiClient(_storage));
  }

  Color get _couleurStatut {
    switch (_colis.statut) {
      case StatutColis.livre:             return const Color(0xFF10B981);
      case StatutColis.enCours:           return const Color(0xFF3158F5);
      case StatutColis.collecteEffectuee: return const Color(0xFF8B5CF6);
      case StatutColis.prisEnCharge:      return const Color(0xFF6366F1);
      case StatutColis.annule:            return const Color(0xFFEF4444);
      default:                            return const Color(0xFFF59E0B);
    }
  }

  Future<void> _changerStatut(StatutColis nouveauStatut) async {
    setState(() => _loading = true);
    try {
      await _service.mettreAJourStatut(_colis.id, nouveauStatut);
      if (!mounted) return;
      setState(() {
        _colis = LivreurColisModel(
          id: _colis.id,
          numeroSuivi: _colis.numeroSuivi,
          nomDestinataire: _colis.nomDestinataire,
          adresseDestinataire: _colis.adresseDestinataire,
          telephoneDestinataire: _colis.telephoneDestinataire,
          poids: _colis.poids,
          statut: nouveauStatut,
          modeRemise: _colis.modeRemise,
          villeDepartNom: _colis.villeDepartNom,
          villeArriveeNom: _colis.villeArriveeNom,
          remarques: _colis.remarques,
          dateCreation: _colis.dateCreation,
          livreurId: _colis.livreurId,
        );
      });
      _snack('Statut mis à jour : ${statutColisLabel(nouveauStatut)}');
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  List<(StatutColis, String, IconData)> get _actionsDisponibles {
    switch (_colis.statut) {
      case StatutColis.prisEnCharge:
        return [(StatutColis.collecteEffectuee, 'Marquer collecté', Icons.check_circle_outline)];
      case StatutColis.collecteEffectuee:
        return [(StatutColis.enCours, 'Démarrer livraison', Icons.local_shipping_rounded)];
      case StatutColis.enCours:
        return [
          (StatutColis.livre, 'Marquer livré', Icons.task_alt_rounded),
        ];
      default:
        return [];
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
        title: Text(
          _colis.numeroSuivi.isNotEmpty ? _colis.numeroSuivi : 'Détail',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
              fontFamily: 'monospace'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Statut
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _couleurStatut,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statut',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(statutColisLabel(_colis.statut),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Actions
          if (_actionsDisponibles.isNotEmpty)
            _Card(
              title: 'Actions',
              icon: Icons.touch_app_rounded,
              isDark: isDark,
              children: _actionsDisponibles.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _changerStatut(action.$1),
                      icon: _loading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Icon(action.$3, size: 18),
                      label: Text(action.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3158F5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          // Destinataire
          _Card(
            title: 'Destinataire',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            children: [
              _InfoRow(label: 'Nom', value: _colis.nomDestinataire),
              _InfoRow(label: 'Adresse', value: _colis.adresseDestinataire),
              _InfoRow(label: 'Téléphone', value: _colis.telephoneDestinataire),
              _InfoRow(label: 'Mode remise', value: modeRemiseLabel(_colis.modeRemise)),
            ],
          ),
          const SizedBox(height: 12),
          // Trajet
          if (_colis.villeDepartNom != null)
            _Card(
              title: 'Trajet',
              icon: Icons.route_rounded,
              isDark: isDark,
              children: [
                _InfoRow(label: 'Départ', value: _colis.villeDepartNom ?? '—'),
                _InfoRow(label: 'Arrivée', value: _colis.villeArriveeNom ?? '—'),
                _InfoRow(label: 'Poids', value: '${_colis.poids} kg'),
              ],
            ),
          if (_colis.remarques != null && _colis.remarques!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              title: 'Remarques',
              icon: Icons.notes_rounded,
              isDark: isDark,
              children: [
                Text(_colis.remarques!,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF6B7280))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;

  const _Card({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF3158F5)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }
}
