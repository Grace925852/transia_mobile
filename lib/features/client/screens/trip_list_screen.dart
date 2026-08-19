import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';
import 'package:transia_mobile/shared/widgets/vehicule_thumbnail.dart';

class TripListScreen extends StatelessWidget {
  final List<TrajetModel> trajets;
  final String villeDepart;
  final String villeArrivee;
  final String dateDepart;
  final int nombreSieges;

  const TripListScreen({
    super.key,
    required this.trajets,
    required this.villeDepart,
    required this.villeArrivee,
    required this.dateDepart,
    required this.nombreSieges,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Trajets disponibles',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$villeDepart → $villeArrivee',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Date : $dateDepart • $nombreSieges siège(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: trajets.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun trajet disponible',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                    itemCount: trajets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trajet = trajets[index];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                                VehiculeThumbnail(
                                  imageBase64: trajet.vehiculeImage,
                                  size: 44,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${trajet.villeDepart} → ${trajet.villeArrivee}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.access_time_rounded,
                              text: 'Départ : ${trajet.heureFormatee}',
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              icon: Icons.calendar_month_rounded,
                              text: 'Date : ${trajet.dateFormatee.isEmpty ? trajet.dateDepart : trajet.dateFormatee}',
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              icon: Icons.timer_outlined,
                              text: 'Durée : ${trajet.dureeEstimee}',
                            ),
                            const SizedBox(height: 6),
                            _InfoRow(
                              icon: Icons.confirmation_number_outlined,
                              text:
                                  'Immatriculation : ${trajet.vehiculeImmatriculation}',
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  trajet.prixFormate,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3158F5),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.push(
                                        AppRoutes.tripDetail,
                                        extra: trajet,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3158F5),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Voir détail',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}