import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:transia_mobile/core/constants/api_constants.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/demande_collecte_model.dart';
import 'package:transia_mobile/features/livreur/models/livreur_tournee_model.dart';
import 'package:transia_mobile/features/livreur/services/livreur_service.dart';

class LivreurTourneeDetailScreen extends StatefulWidget {
  final LivreurTourneeModel tournee;

  const LivreurTourneeDetailScreen({super.key, required this.tournee});

  @override
  State<LivreurTourneeDetailScreen> createState() =>
      _LivreurTourneeDetailScreenState();
}

class _LivreurTourneeDetailScreenState
    extends State<LivreurTourneeDetailScreen> {
  Future<void> _validerEnlevement(DemandeCollecteModel d) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le ramassage'),
        content: Text('Voulez-vous marquer le colis chez "${d.adresseCollecte}" comme ramassé ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Oui, Ramassé', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final storage = SecureStorageService();
      final service = LivreurService(apiClient: ApiClient(storage));
      await service.apiClient.dio.put('${ApiConstants.demandesCollecte}/${d.id}/collecter');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ramassage validé avec succès ! Colis déposé en agence.')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  Future<void> _ouvrirNavigationGps(String adresse, double? lat, double? lng) async {
    final Uri url;
    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      final query = Uri.encodeComponent(adresse);
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'application de carte.')),
      );
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
    final t = widget.tournee;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3158F5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Tournée : ${t.zone ?? 'Zone non définie'}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'en-tête de la Tournée
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3158F5), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3158F5).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.zone != null && t.zone!.isNotEmpty
                              ? 'Tournée Zone : ${t.zone}'
                              : 'Tournée de collecte',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.statut,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('Date : ${t.dateTournee}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.inventory_2_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('${t.demandesCollecte.length} colis à ramasser',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            const Text(
              'Colis & Clients à collecter dans cette tournée',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3),
            ),
            const SizedBox(height: 12),

            if (t.demandesCollecte.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun colis associé à cette tournée pour l\'instant.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: t.demandesCollecte.length,
                itemBuilder: (ctx, i) {
                  final d = t.demandesCollecte[i];
                  final badgeColor = _statutColor(d.statut);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border(left: BorderSide(color: badgeColor, width: 4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ligne du client & Statut
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3158F5).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Color(0xFF3158F5), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.colisNumeroSuivi != null && d.colisNumeroSuivi!.isNotEmpty
                                        ? 'Colis ${d.colisNumeroSuivi}'
                                        : 'Demande #${d.id.substring(0, 8)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                  Text(
                                    'Adresse : ${d.adresseCollecte}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF6B7280)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statutCollecteLabel(d.statut),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Boutons d'action : GPS + Validation d'enlèvement
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _ouvrirNavigationGps(
                                    d.adresseCollecte, d.latitude, d.longitude),
                                icon: const Icon(Icons.navigation_rounded,
                                    color: Colors.white, size: 16),
                                label: const Text('📍 GPS',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                ),
                              ),
                            ),
                            if (d.statut != StatutCollecte.collecte) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _validerEnlevement(d),
                                  icon: const Icon(Icons.check_circle_outline_rounded,
                                      color: Colors.white, size: 16),
                                  label: const Text('📦 Ramassé',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3158F5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
