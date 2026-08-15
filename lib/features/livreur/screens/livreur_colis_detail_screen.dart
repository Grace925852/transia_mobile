import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
      case StatutColis.livre:            return const Color(0xFF10B981);
      case StatutColis.enCoursLivraison: return const Color(0xFF3158F5);
      case StatutColis.enTransit:        return const Color(0xFF3158F5);
      case StatutColis.arriveEnAgence:   return const Color(0xFF8B5CF6);
      case StatutColis.deposeEnAgence:   return const Color(0xFF6366F1);
      case StatutColis.retourne:
      case StatutColis.perdu:
      case StatutColis.annule:           return const Color(0xFFEF4444);
      case StatutColis.enAttenteCollecte:
      case StatutColis.enAttenteDepot:   return const Color(0xFFF59E0B);
    }
  }

  Future<void> _confirmerLivraison() async {
    setState(() => _loading = true);
    try {
      final updated = await _service.confirmerLivraison(_colis.id);
      if (!mounted) return;
      setState(() => _colis = updated);
      _snack('Livraison confirmée !');
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

  Future<void> _ouvrirGoogleMaps(String adresse) async {
    final query = Uri.encodeComponent(adresse);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _snack('Impossible d\'ouvrir Google Maps');
    }
  }

  bool get _peutConfirmerLivraison =>
      _colis.statut == StatutColis.enCoursLivraison;

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
          // Action
          if (_peutConfirmerLivraison)
            _Card(
              title: 'Action',
              icon: Icons.touch_app_rounded,
              isDark: isDark,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _confirmerLivraison,
                    icon: _loading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.task_alt_rounded, size: 18),
                    label: const Text('Marquer livré',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3158F5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // Destinataire
          _Card(
            title: 'Destinataire',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            children: [
              _InfoRow(label: 'Nom', value: _colis.destinataireNom),
              _InfoRow(label: 'Téléphone', value: _colis.destinataireTelephone),
              if (_colis.destinataireAdresse != null)
                _InfoRow(label: 'Adresse', value: _colis.destinataireAdresse!),
              _InfoRow(label: 'Mode remise', value: modeRemiseLabel(_colis.modeRemise)),
              if (_colis.destinataireAdresse != null && _colis.destinataireAdresse!.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _ouvrirGoogleMaps(_colis.destinataireAdresse!),
                    icon: const Icon(Icons.map_rounded, color: Color(0xFF3158F5), size: 18),
                    label: const Text('Voir sur Google Maps', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3158F5))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3158F5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Trajet
          if (_colis.agenceDepartNom != null)
            _Card(
              title: 'Trajet',
              icon: Icons.route_rounded,
              isDark: isDark,
              children: [
                _InfoRow(label: 'Agence départ', value: _colis.agenceDepartNom ?? '—'),
                _InfoRow(label: 'Agence arrivée', value: _colis.agenceArriveeNom ?? '—'),
                _InfoRow(label: 'Tranche', value: trancheLabel(_colis.tranchePoids)),
              ],
            ),
          const SizedBox(height: 12),
          _Card(
            title: 'Colis',
            icon: Icons.notes_rounded,
            isDark: isDark,
            children: [
              _InfoRow(label: 'Description', value: _colis.description),
            ],
          ),
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
