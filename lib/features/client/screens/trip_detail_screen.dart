import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';

class TripDetailScreen extends StatefulWidget {
  final TrajetModel trajet;

  const TripDetailScreen({
    super.key,
    required this.trajet,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int nombreSieges = 1;

  @override
  Widget build(BuildContext context) {
    final trajet = widget.trajet;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Détail du trajet'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Résumé du voyage',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                _TripRow(label: 'Départ', value: trajet.villeDepart),
                _TripRow(label: 'Destination', value: trajet.villeArrivee),
                _TripRow(label: 'Date', value: trajet.dateDepart),
                _TripRow(label: 'Heure', value: trajet.heureFormatee),
                _TripRow(label: 'Durée estimée', value: trajet.dureeEstimee),
                _TripRow(
                  label: 'Véhicule',
                  value: trajet.vehiculeImmatriculation,
                ),
                _TripRow(label: 'Statut', value: trajet.statut),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarification',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                _TripRow(
                  label: 'Prix unitaire',
                  value: trajet.prixFormate,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Nombre de sièges',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: nombreSieges > 1
                          ? () {
                              setState(() {
                                nombreSieges--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$nombreSieges',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          nombreSieges++;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _TripRow(
                  label: 'Montant total',
                  value:
                      '${(trajet.tarif * nombreSieges).toStringAsFixed(0)} FCFA',
                  highlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  AppRoutes.bookingSummary,
                  extra: {
                    'trajet': trajet,
                    'nombreSieges': nombreSieges,
                  },
                );
              },
              child: const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _TripRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlighted
                    ? const Color(0xFF3158F5)
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}