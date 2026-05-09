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
  final List<int> selectedSeats;

  const BookingSummaryScreen({
    super.key,
    required this.trajet,
    required this.nombreSieges,
    this.selectedSeats = const [],
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final Color primaryBlue = const Color(0xFF3158F5);

  bool isLoading = false;
  bool clientFaitPartieDuVoyage = true;
  bool saisirNomsPassagers = false;

  String clientNom = '';
  int? clientUserId;

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;

  final TextEditingController delegueController = TextEditingController();
  final List<TextEditingController> passagerControllers = [];

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    reservationService = ReservationService(apiClient: apiClient);

    chargerSessionClient();
    genererChampsPassagers();
  }

  @override
  void dispose() {
    delegueController.dispose();
    for (final controller in passagerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> chargerSessionClient() async {
    final storedName = await secureStorageService.getFullName();
    final storedUserId = await secureStorageService.getNumericUserId();

    if (!mounted) return;

    setState(() {
      clientNom = storedName ?? '';
      clientUserId = int.tryParse(storedUserId ?? '');
    });
  }

  int get nombreChampsPassagers {
    return widget.nombreSieges > 1 ? widget.nombreSieges - 1 : 0;
  }

  double get total => widget.trajet.tarif * widget.nombreSieges;

  void genererChampsPassagers() {
    for (final controller in passagerControllers) {
      controller.dispose();
    }
    passagerControllers.clear();

    for (int i = 0; i < nombreChampsPassagers; i++) {
      passagerControllers.add(TextEditingController());
    }

    if (mounted) {
      setState(() {});
    }
  }

  void changerModeReservation(bool value) {
    setState(() {
      clientFaitPartieDuVoyage = value;
    });
    genererChampsPassagers();
  }

  String get nomResponsable {
    if (clientFaitPartieDuVoyage) {
      return clientNom.trim();
    }
    return delegueController.text.trim();
  }

  List<String> _buildNomsPassagers() {
    final responsable = nomResponsable;
    final List<String> passagers = [];

    if (saisirNomsPassagers) {
      for (int i = 0; i < passagerControllers.length; i++) {
        final typed = passagerControllers[i].text.trim();
        if (typed.isNotEmpty) {
          passagers.add(typed);
        } else {
          passagers.add('Invité N${i + 1} de $responsable');
        }
      }
    } else {
      for (int i = 0; i < nombreChampsPassagers; i++) {
        passagers.add('Invité N${i + 1} de $responsable');
      }
    }

    return passagers;
  }

  Future<void> confirmerReservation() async {
    if (clientUserId == null) {
      afficherMessage('Utilisateur introuvable.');
      return;
    }

    if (!clientFaitPartieDuVoyage &&
        delegueController.text.trim().isEmpty) {
      afficherMessage('Veuillez saisir le nom du responsable.');
      return;
    }

    if (widget.selectedSeats.isNotEmpty &&
        widget.selectedSeats.length != widget.nombreSieges) {
      afficherMessage(
        'Le nombre de sièges choisis ne correspond pas au nombre de places.',
      );
      return;
    }

    final request = ReservationRequestModel(
      userId: clientUserId!,
      trajetId: widget.trajet.id,
      nombrePlace: widget.nombreSieges,
      nomResponsable: nomResponsable,
      nomsPassagers: _buildNomsPassagers(),
      numerosSieges: widget.selectedSeats,
    );

    setState(() {
      isLoading = true;
    });

    try {
      await reservationService.createReservation(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation créée avec succès.'),
        ),
      );

      context.go(AppRoutes.reservations);
    } catch (e) {
      afficherMessage(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void afficherMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: const Text(
          'Confirmation',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails de la réservation',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                _SummaryRow(
                  label: 'Trajet',
                  value: '${widget.trajet.villeDepart} → ${widget.trajet.villeArrivee}',
                ),
                _SummaryRow(label: 'Date', value: widget.trajet.dateDepart),
                _SummaryRow(label: 'Heure', value: widget.trajet.heureFormatee),
                _SummaryRow(
                  label: 'Véhicule',
                  value: widget.trajet.vehiculeImmatriculation,
                ),
                _SummaryRow(
                  label: 'Nombre de sièges',
                  value: '${widget.nombreSieges}',
                ),
                _SummaryRow(
                  label: 'Sièges choisis',
                  value: widget.selectedSeats.isEmpty
                      ? 'Aucun'
                      : widget.selectedSeats.join(', '),
                ),
                _SummaryRow(
                  label: 'Prix unitaire',
                  value: widget.trajet.prixFormate,
                ),
                _SummaryRow(
                  label: 'Montant total',
                  value: '${total.toStringAsFixed(0)} FCFA',
                  highlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type de réservation',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 14),
                RadioListTile<bool>(
                  value: true,
                  groupValue: clientFaitPartieDuVoyage,
                  onChanged: (value) {
                    if (value != null) {
                      changerModeReservation(value);
                    }
                  },
                  title: const Text('Je fais partie du voyage'),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue: clientFaitPartieDuVoyage,
                  onChanged: (value) {
                    if (value != null) {
                      changerModeReservation(value);
                    }
                  },
                  title: const Text('Je réserve pour d’autres personnes'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (clientFaitPartieDuVoyage && clientNom.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Le responsable sera automatiquement : $clientNom',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations passagers',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 14),
                if (!clientFaitPartieDuVoyage) ...[
                  const Text(
                    'Nom du responsable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InputField(
                    controller: delegueController,
                    hintText: 'Ex : Koffi AKAKPO',
                  ),
                  const SizedBox(height: 16),
                ],
                SwitchListTile(
                  value: saisirNomsPassagers,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Voulez-vous saisir les autres noms ?'),
                  onChanged: (value) {
                    setState(() {
                      saisirNomsPassagers = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (nombreChampsPassagers == 0)
                  const Text(
                    'Aucun autre passager à renseigner.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  )
                else if (!saisirNomsPassagers)
                  const Text(
                    'Les autres noms seront générés automatiquement.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  )
                else
                  ...List.generate(
                    passagerControllers.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passager ${index + 2}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: passagerControllers[index],
                            hintText: 'Nom complet',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: isLoading ? null : confirmerReservation,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : const Text(
                      'Confirmer la réservation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _SummaryRow({
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
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _InputField({
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E5EC),
        ),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}