import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_passenger_model.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/services/chauffeur_service.dart';

class ChauffeurScanScreen extends StatefulWidget {
  final ChauffeurTripModel trip;
  final List<ChauffeurPassengerModel> passengers;

  const ChauffeurScanScreen({
    super.key,
    required this.trip,
    required this.passengers,
  });

  @override
  State<ChauffeurScanScreen> createState() => _ChauffeurScanScreenState();
}

class _ChauffeurScanScreenState extends State<ChauffeurScanScreen> {
  final MobileScannerController scannerController = MobileScannerController();

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ChauffeurService chauffeurService;

  bool isProcessing = false;
  ChauffeurPassengerModel? foundPassenger;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    chauffeurService = ChauffeurService(apiClient: apiClient);
  }

  ChauffeurPassengerModel? _findPassengerByQr(String rawValue) {
    for (final passenger in widget.passengers) {
      if (passenger.qrCode.trim().isNotEmpty &&
          passenger.qrCode.trim() == rawValue.trim()) {
        return passenger;
      }
    }

    for (final passenger in widget.passengers) {
      if (passenger.billetId.trim() == rawValue.trim()) {
        return passenger;
      }
    }

    return null;
  }

  Future<void> handleScan(String rawValue) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
      foundPassenger = null;
    });

    final passenger = _findPassengerByQr(rawValue);

    if (!mounted) return;

    if (passenger == null) {
      setState(() {
        errorMessage = 'QR invalide ou billet introuvable pour ce trajet.';
        isProcessing = false;
      });
      return;
    }

    setState(() {
      foundPassenger = passenger;
      isProcessing = false;
    });
  }

  Future<void> markPresent() async {
    final passenger = foundPassenger;
    if (passenger == null) return;

    if (passenger.present) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce passager est déjà marqué présent.')),
      );
      return;
    }

    await chauffeurService.markPassengerPresent(
      tripId: widget.trip.id,
      billetId: passenger.billetId,
    );

    if (!mounted) return;
    Navigator.pop(context, passenger.billetId);
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passenger = foundPassenger;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Scan QR'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.trip.trajetLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.trip.dateDepart} • ${widget.trip.heureFormatee}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 300,
              child: MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;

                  final raw = barcodes.first.rawValue;
                  if (raw == null || raw.trim().isEmpty) return;

                  handleScan(raw);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isProcessing)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFBE123C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (passenger != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Billet vérifié',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'Passager', value: passenger.passagerNom),
                  _InfoRow(label: 'Siège', value: passenger.siege),
                  _InfoRow(label: 'Billet', value: passenger.billetId),
                  _InfoRow(label: 'Réservation', value: passenger.reservationId),
                  _InfoRow(label: 'Trajet', value: widget.trip.trajetLabel),
                  _InfoRow(
                    label: 'Présence',
                    value: passenger.present ? 'Déjà présent' : 'Non marqué',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: markPresent,
                      child: Text(
                        passenger.present ? 'Déjà présent' : 'Client présent',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Scannez un QR code pour vérifier le billet.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}