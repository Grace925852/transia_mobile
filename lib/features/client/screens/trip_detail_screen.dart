import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';
import 'package:transia_mobile/features/client/services/reservation_service.dart';

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
  bool demanderSelectionSiege = false;
  bool isLoadingSeats = false;

  final Set<int> selectedSeats = {};
  final Set<int> occupiedSeats = {};

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;

  int get totalSeats {
    final backendSeats = widget.trajet.capacite;
    if (backendSeats <= 0) return 30;
    return backendSeats;
  }

  int get availableSeatsCount {
    final available = totalSeats - occupiedSeats.length;
    return available < 0 ? 0 : available;
  }

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    reservationService = ReservationService(apiClient: apiClient);
    _loadOccupiedSeats();
  }

  Set<int> _extractSeatsFromDynamicList(dynamic data) {
    final Set<int> result = {};

    if (data is List) {
      for (final item in data) {
        if (item is int) {
          result.add(item);
        } else if (item is String) {
          final parsed = int.tryParse(item.trim());
          if (parsed != null) result.add(parsed);
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final seatValue = map['numeroSiege'] ??
              map['numero_siege'] ??
              map['seatNumber'] ??
              map['siege'];

          if (seatValue is int) {
            result.add(seatValue);
          } else if (seatValue is String) {
            final parsed = int.tryParse(seatValue.trim());
            if (parsed != null) result.add(parsed);
          }
        }
      }
    }

    return result;
  }

  Future<void> _loadOccupiedSeats() async {
    setState(() {
      isLoadingSeats = true;
    });

    try {
      final reservations = await reservationService.getReservations();
      final Set<int> freshOccupiedSeats = {};

      for (final reservation in reservations) {
        if (reservation.trajetId != widget.trajet.id) continue;

        final raw = reservation.rawData;
        freshOccupiedSeats.addAll(_extractSeatsFromDynamicList(raw['billets']));
        freshOccupiedSeats.addAll(_extractSeatsFromDynamicList(raw['tickets']));
        freshOccupiedSeats
            .addAll(_extractSeatsFromDynamicList(raw['billetEntities']));
        freshOccupiedSeats
            .addAll(_extractSeatsFromDynamicList(raw['reservationBillets']));
        freshOccupiedSeats
            .addAll(_extractSeatsFromDynamicList(raw['selectedSeats']));
        freshOccupiedSeats
            .addAll(_extractSeatsFromDynamicList(raw['numerosSieges']));
        freshOccupiedSeats
            .addAll(_extractSeatsFromDynamicList(raw['seatNumbers']));
      }

      if (!mounted) return;

      setState(() {
        occupiedSeats
          ..clear()
          ..addAll(freshOccupiedSeats);

        selectedSeats.removeWhere((seat) => occupiedSeats.contains(seat));

        if (availableSeatsCount > 0 && nombreSieges > availableSeatsCount) {
          nombreSieges = availableSeatsCount;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSeats = false;
        });
      }
    }
  }

  void _onSeatSelectionChoice(bool value) async {
    setState(() {
      demanderSelectionSiege = value;
    });

    if (value) {
      await _loadOccupiedSeats();
    } else {
      setState(() {
        selectedSeats.clear();
      });
    }
  }

  void _toggleSeat(int seatNumber) {
    if (occupiedSeats.contains(seatNumber)) return;

    if (selectedSeats.contains(seatNumber)) {
      setState(() {
        selectedSeats.remove(seatNumber);
      });
      return;
    }

    if (selectedSeats.length >= nombreSieges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vous devez sélectionner exactement $nombreSieges siège(s).',
          ),
        ),
      );
      return;
    }

    setState(() {
      selectedSeats.add(seatNumber);
    });
  }

  void _incrementSeats() {
    if (availableSeatsCount <= 0) return;
    if (nombreSieges >= availableSeatsCount) return;

    setState(() {
      nombreSieges++;
      if (selectedSeats.length > nombreSieges) {
        final kept = selectedSeats.take(nombreSieges).toSet();
        selectedSeats
          ..clear()
          ..addAll(kept);
      }
    });
  }

  void _decrementSeats() {
    if (nombreSieges <= 1) return;

    setState(() {
      nombreSieges--;
      if (selectedSeats.length > nombreSieges) {
        final kept = selectedSeats.take(nombreSieges).toSet();
        selectedSeats
          ..clear()
          ..addAll(kept);
      }
    });
  }

  Future<void> _continuer() async {
    await _loadOccupiedSeats();

    final collision =
        selectedSeats.any((seat) => occupiedSeats.contains(seat));

    if (collision) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Un ou plusieurs sièges viennent d’être pris. Veuillez rechoisir.',
          ),
        ),
      );
      return;
    }

    if (demanderSelectionSiege && selectedSeats.length != nombreSieges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner exactement $nombreSieges siège(s).',
          ),
        ),
      );
      return;
    }

    context.push(
      AppRoutes.bookingSummary,
      extra: {
        'trajet': widget.trajet,
        'nombreSieges': nombreSieges,
        'selectedSeats': selectedSeats.toList()..sort(),
      },
    );
  }

  Widget _buildRow(String label, String value, {bool highlight = false}) {
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
                color: highlight
                    ? const Color(0xFF3158F5)
                    : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choix du siège',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Voulez-vous sélectionner votre siège ?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  value: true,
                  groupValue: demanderSelectionSiege,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Oui'),
                  onChanged: (_) => _onSeatSelectionChoice(true),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  value: false,
                  groupValue: demanderSelectionSiege,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Non'),
                  onChanged: (_) => _onSeatSelectionChoice(false),
                ),
              ),
            ],
          ),
          if (demanderSelectionSiege) ...[
            const SizedBox(height: 8),
            Text(
              'Choisissez exactement $nombreSieges siège(s). Les sièges gris sont déjà pris.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Disponibles : $availableSeatsCount / $totalSeats',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            if (isLoadingSeats)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(totalSeats, (index) {
                  final seatNumber = index + 1;
                  final isOccupied = occupiedSeats.contains(seatNumber);
                  final isSelected = selectedSeats.contains(seatNumber);

                  Color backgroundColor;
                  Color textColor;
                  Color borderColor;

                  if (isOccupied) {
                    backgroundColor = const Color(0xFFE5E7EB);
                    textColor = const Color(0xFF9CA3AF);
                    borderColor = const Color(0xFFD1D5DB);
                  } else if (isSelected) {
                    backgroundColor = const Color(0xFF3158F5);
                    textColor = Colors.white;
                    borderColor = const Color(0xFF3158F5);
                  } else {
                    backgroundColor = const Color(0xFFEAF0FF);
                    textColor = const Color(0xFF3158F5);
                    borderColor = const Color(0xFF3158F5);
                  }

                  return GestureDetector(
                    onTap: () => _toggleSeat(seatNumber),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Center(
                        child: Text(
                          '$seatNumber',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnés : ${selectedSeats.length}/$nombreSieges',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (selectedSeats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Siège(s) choisi(s) : ${(selectedSeats.toList()..sort()).join(', ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trajet = widget.trajet;
    final total = trajet.tarif * nombreSieges;

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
                _buildRow('Départ', trajet.villeDepart),
                _buildRow('Destination', trajet.villeArrivee),
                _buildRow('Date', trajet.dateDepart),
                _buildRow('Heure', trajet.heureFormatee),
                _buildRow('Durée estimée', trajet.dureeEstimee),
                _buildRow('Véhicule', trajet.vehiculeImmatriculation),
                _buildRow('Statut', trajet.statut),
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
                _buildRow('Prix unitaire', trajet.prixFormate),
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
                      onPressed: nombreSieges > 1 ? _decrementSeats : null,
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
                      onPressed: nombreSieges < availableSeatsCount
                          ? _incrementSeats
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Maximum disponible pour ce trajet : $availableSeatsCount siège(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRow(
                  'Montant total',
                  '${total.toStringAsFixed(0)} FCFA',
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSeatSelectionSection(),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _continuer,
              child: const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }
}