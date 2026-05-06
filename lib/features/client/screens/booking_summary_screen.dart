import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/reservation_request.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';
import 'package:transia_mobile/features/client/services/reservation_service.dart';

class BookingSummaryScreen extends StatefulWidget {
  final TrajetModel trajet;
  final int nombreSieges;

  const BookingSummaryScreen({
    super.key,
    required this.trajet,
    required this.nombreSieges,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;

  bool isLoading = false;
  bool jeFaisPartieDuVoyage = true;

  String clientName = '';
  String clientUsername = '';
  int? clientNumericUserId;

  late List<TextEditingController> passengerControllers;

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    reservationService = ReservationService(apiClient: apiClient);

    passengerControllers = List.generate(
      _nombreChampsPassagers,
      (_) => TextEditingController(),
    );

    chargerInfosClient();
  }

  int get _nombreChampsPassagers {
    if (widget.nombreSieges <= 0) return 0;
    return jeFaisPartieDuVoyage
        ? (widget.nombreSieges - 1).clamp(0, 100)
        : widget.nombreSieges;
  }

  @override
  void dispose() {
    for (final controller in passengerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _rebuildPassengerControllers() {
    for (final controller in passengerControllers) {
      controller.dispose();
    }

    passengerControllers = List.generate(
      _nombreChampsPassagers,
      (_) => TextEditingController(),
    );

    setState(() {});
  }

  Future<void> chargerInfosClient() async {
    try {
      final storedName = await secureStorageService.getFullName();
      final storedUsername = await secureStorageService.getUsername();
      final storedNumericUserIdString =
          await secureStorageService.getNumericUserId();

      final storedNumericUserId =
          int.tryParse(storedNumericUserIdString ?? '');

      if (!mounted) return;

      setState(() {
        clientName = storedName ?? '';
        clientUsername = storedUsername ?? '';
        clientNumericUserId = storedNumericUserId;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  List<String> _buildPassengerNames() {
    final List<String> names = [];

    if (jeFaisPartieDuVoyage && clientName.trim().isNotEmpty) {
      names.add(clientName.trim());
    }

    for (final controller in passengerControllers) {
      final value = controller.text.trim();
      if (value.isNotEmpty) {
        names.add(value);
      }
    }

    return names;
  }

  String _buildNomResponsable(List<String> passengers) {
    if (!jeFaisPartieDuVoyage && passengers.isNotEmpty) {
      return passengers.first;
    }

    if (clientName.trim().isNotEmpty) {
      return clientName.trim();
    }

    if (passengers.isNotEmpty) {
      return passengers.first;
    }

    return 'Client';
  }

  Future<void> confirmerReservation() async {
    try {
      if (clientNumericUserId == null) {
        throw Exception(
          'Impossible de retrouver votre identifiant numérique client.',
        );
      }

      final passengers = _buildPassengerNames();

      if (passengers.length != widget.nombreSieges) {
        throw Exception(
          'Veuillez renseigner correctement les noms des passagers.',
        );
      }

      setState(() {
        isLoading = true;
      });

      final nomResponsable = _buildNomResponsable(passengers);

      final request = ReservationRequestModel(
        userId: clientNumericUserId!,
        trajetId: widget.trajet.id,
        nombrePlace: widget.nombreSieges,
        nomResponsable: nomResponsable,
        nomsPassagers: passengers,
      );

      await reservationService.createReservation(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation créée avec succès.'),
        ),
      );

      context.go(AppRoutes.reservations);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
                color:
                    highlight ? const Color(0xFF3158F5) : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final montantTotal = widget.trajet.tarif * widget.nombreSieges;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Confirmation'),
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
                  'Détails de la réservation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                _buildRow(
                  'Trajet',
                  '${widget.trajet.villeDepart} → ${widget.trajet.villeArrivee}',
                ),
                _buildRow('Date', widget.trajet.dateDepart),
                _buildRow('Heure', widget.trajet.heureFormatee),
                _buildRow('Véhicule', widget.trajet.vehiculeImmatriculation),
                _buildRow('Nombre de sièges', '${widget.nombreSieges}'),
                _buildRow('Prix unitaire', widget.trajet.prixFormate),
                _buildRow(
                  'Montant total',
                  '${montantTotal.toStringAsFixed(0)} FCFA',
                  highlight: true,
                ),
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
                  'Type de réservation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                RadioListTile<bool>(
                  value: true,
                  groupValue: jeFaisPartieDuVoyage,
                  onChanged: (value) {
                    setState(() {
                      jeFaisPartieDuVoyage = value ?? true;
                    });
                    _rebuildPassengerControllers();
                  },
                  title: const Text('Je fais partie du voyage'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue: jeFaisPartieDuVoyage,
                  onChanged: (value) {
                    setState(() {
                      jeFaisPartieDuVoyage = value ?? false;
                    });
                    _rebuildPassengerControllers();
                  },
                  title: const Text('Je réserve pour d’autres personnes'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (jeFaisPartieDuVoyage)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Le premier passager sera automatiquement : $clientName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
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
                  'Informations passagers',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                if (_nombreChampsPassagers == 0)
                  const Text(
                    'Aucun autre passager à renseigner.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  )
                else
                  ...List.generate(
                    passengerControllers.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: passengerControllers[index],
                        decoration: InputDecoration(
                          labelText: jeFaisPartieDuVoyage
                              ? 'Passager ${index + 2}'
                              : 'Passager ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : confirmerReservation,
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text('Confirmer la réservation'),
            ),
          ),
        ],
      ),
    );
  }
}