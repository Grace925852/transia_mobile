import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/features/client/models/colis_model.dart';

class ClientColisDetailScreen extends StatelessWidget {
  final ColisModel colis;

  const ClientColisDetailScreen({super.key, required this.colis});

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
          colis.numeroSuivi.isNotEmpty ? colis.numeroSuivi : 'Détail du colis',
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
          // Statut card
          _StatutCard(statut: colis.statut),
          const SizedBox(height: 12),
          // Trajet
          if (colis.agenceDepartNom != null || colis.agenceArriveeNom != null)
            _InfoCard(
              title: 'Trajet',
              icon: Icons.route_rounded,
              children: [
                _Row(
                  label: 'Agence départ',
                  value: colis.agenceDepartNom ?? '—',
                  icon: Icons.circle,
                  iconColor: const Color(0xFF3158F5),
                ),
                _Row(
                  label: 'Agence arrivée',
                  value: colis.agenceArriveeNom ?? '—',
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF10B981),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // Destinataire
          _InfoCard(
            title: 'Destinataire',
            icon: Icons.person_outline_rounded,
            children: [
              _Row(label: 'Nom', value: colis.destinataireNom),
              _Row(label: 'Téléphone', value: colis.destinataireTelephone),
              if (colis.destinataireAdresse != null)
                _Row(label: 'Adresse', value: colis.destinataireAdresse!),
            ],
          ),
          const SizedBox(height: 12),
          // Colis
          _InfoCard(
            title: 'Informations colis',
            icon: Icons.inventory_2_outlined,
            children: [
              _Row(label: 'Description', value: colis.description),
              _Row(label: 'Tranche de poids', value: trancheLabel(colis.tranchePoids)),
              if (colis.poidsReel != null)
                _Row(label: 'Poids réel', value: '${colis.poidsReel} kg'),
              if (colis.dimensions != null && colis.dimensions!.isNotEmpty)
                _Row(label: 'Dimensions', value: colis.dimensions!),
              _Row(label: 'Mode de remise', value: modeRemiseLabel(colis.modeRemise)),
            ],
          ),
          const SizedBox(height: 12),
          // Tarification
          _InfoCard(
            title: 'Tarification',
            icon: Icons.payments_outlined,
            children: [
              if (colis.prixEstime != null)
                _Row(label: 'Prix estimé', value: '${colis.prixEstime!.toStringAsFixed(0)} FCFA'),
              if (colis.prixFinal != null)
                _Row(label: 'Prix final', value: '${colis.prixFinal!.toStringAsFixed(0)} FCFA'),
              _Row(label: 'Paiement', value: statutPaiementLabel(colis.statutPaiement)),
            ],
          ),
          if (colis.dateCreation != null) ...[
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Suivi',
              icon: Icons.history_rounded,
              children: [
                _Row(label: 'Date de création', value: colis.dateCreation!),
                if (colis.dateLivraison != null)
                  _Row(label: 'Date de livraison', value: colis.dateLivraison!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatutCard extends StatelessWidget {
  final StatutColis statut;
  const _StatutCard({required this.statut});

  Color get _color {
    switch (statut) {
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statut actuel',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  statutColisLabel(statut),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF3158F5)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _Row({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: iconColor ?? const Color(0xFF9CA3AF)),
            const SizedBox(width: 6),
          ],
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
