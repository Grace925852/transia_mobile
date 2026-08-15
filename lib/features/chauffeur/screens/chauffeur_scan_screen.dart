import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/chauffeur/models/billet_lookup_model.dart';
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
  Map<String, dynamic>? foundColis;
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
      foundColis = null;
    });

    // 1. Vérifier si c'est un billet passager dans la liste du trajet
    final passenger = _findPassengerByQr(rawValue);

    if (!mounted) return;

    if (passenger != null) {
      setState(() {
        foundPassenger = passenger;
        isProcessing = false;
      });
      return;
    }

    // 2. Vérifier si c'est un Colis (QR Code ou numéro de suivi TRS-XXXXXX)
    try {
      final colis = await chauffeurService.getColisByNumeroSuivi(rawValue);
      if (!mounted) return;

      if (colis != null) {
        final colisTrajetId = colis['trajetId']?.toString();
        if (colisTrajetId != null &&
            colisTrajetId.isNotEmpty &&
            colisTrajetId != widget.trip.id) {
          final infoTrajet = colis['trajetInfo'] ?? 'autre car';
          setState(() {
            errorMessage =
                '⚠️ Ce colis est déjà attribué à un autre trajet ($infoTrajet). L\'embarquement dans ce car n\'est pas autorisé.';
            isProcessing = false;
          });
          return;
        }

        final statut = colis['statut']?.toString() ?? '';
        if (statut == 'EN_ATTENTE_DEPOT') {
          setState(() {
            errorMessage =
                '⚠️ Ce colis n\'a pas encore été pèsé et payé en agence. Embarquement refusé.';
            isProcessing = false;
          });
          return;
        }

        setState(() {
          foundColis = colis;
          isProcessing = false;
        });
        return;
      }
    } catch (_) {}

    // 3. Sinon, interroger le backend pour voir s'il s'agit d'un billet d'un autre trajet
    try {
      final lookup = await chauffeurService.lookupBilletByQr(
        rawValue.trim(),
      );

      if (!mounted) return;

      setState(() {
        errorMessage = _buildNotFoundMessage(lookup);
        isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'QR invalide : ce code est introuvable (ni billet passager, ni colis).';
        isProcessing = false;
      });
    }
  }

  Future<void> chargerFoundColis() async {
    final colis = foundColis;
    if (colis == null) return;

    final id = colis['id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final updated = await chauffeurService.chargerColis(
        colisId: id,
        tripId: widget.trip.id,
      );

      if (!mounted) return;

      setState(() {
        foundColis = updated;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '📦 Colis ${colis['numeroSuivi']} chargé en soute avec succès !'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement : ${e.toString()}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  String _buildNotFoundMessage(BilletLookupModel? lookup) {
    if (lookup == null) {
      return 'QR invalide : ce billet est introuvable dans le système.';
    }

    if (lookup.trajetId != null && lookup.trajetId == widget.trip.id) {
      switch (lookup.statut.toUpperCase()) {
        case 'EN_ATTENTE':
          return 'Ce billet n\'est pas encore payé — l\'embarquement n\'est pas autorisé.';
        case 'ANNULE':
          return 'Ce billet a été annulé.';
        case 'UTILISE':
          return 'Ce billet a déjà été validé pour l\'embarquement.';
        default:
          return 'Ce billet appartient à ce trajet mais n\'a pas pu être vérifié (statut : ${lookup.statut}).';
      }
    }

    final quand = _situerDansLeTemps(lookup.dateDepart, lookup.heureDepart);
    final trajetLabel = lookup.trajetInfo.trim();
    final dateLabel = _formatDate(lookup.dateDepart, lookup.heureDepart);

    final details = [
      if (trajetLabel.isNotEmpty) trajetLabel,
      if (dateLabel.isNotEmpty) dateLabel,
    ].join(', ');

    final detailsSuffix = details.isNotEmpty ? ' ($details)' : '';

    return 'Ce billet appartient à $quand$detailsSuffix — pas à ce trajet-ci.';
  }

  String _situerDansLeTemps(String date, String heure) {
    final dt = _parseTrajetDateTime(date, heure);
    if (dt == null) return 'un autre trajet';
    return dt.isBefore(DateTime.now())
        ? 'un trajet déjà passé'
        : 'un trajet à venir';
  }

  String _formatDate(String date, String heure) {
    final dt = _parseTrajetDateTime(date, heure);
    if (dt == null) return '';

    final jour = dt.day.toString().padLeft(2, '0');
    final mois = dt.month.toString().padLeft(2, '0');
    final heureStr = dt.hour.toString().padLeft(2, '0');
    final minuteStr = dt.minute.toString().padLeft(2, '0');

    return 'le $jour/$mois/${dt.year} à $heureStr:$minuteStr';
  }

  DateTime? _parseTrajetDateTime(String date, String heure) {
    if (date.trim().isEmpty) return null;

    final normalizedHeure = heure.trim().isEmpty ? '00:00:00' : heure.trim();

    try {
      return DateTime.parse('${date.trim()}T$normalizedHeure');
    } catch (_) {
      return null;
    }
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
          else if (foundColis != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Colis Fret : ${foundColis!['numeroSuivi'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                      label: 'Contenu',
                      value: foundColis!['description']?.toString() ?? '—'),
                  _InfoRow(
                      label: 'Poids réel',
                      value: foundColis!['poidsReel'] != null
                          ? '${foundColis!['poidsReel']} kg'
                          : 'Non pesé'),
                  _InfoRow(
                      label: 'Expéditeur',
                      value:
                          '${foundColis!['expediteurNom'] ?? ''} (${foundColis!['expediteurTelephone'] ?? ''})'),
                  _InfoRow(
                      label: 'Destinataire',
                      value:
                          '${foundColis!['destinataireNom'] ?? ''} (${foundColis!['destinataireTelephone'] ?? ''})'),
                  _InfoRow(
                      label: 'Agence départ',
                      value:
                          foundColis!['agenceDepartNom']?.toString() ?? '—'),
                  _InfoRow(
                      label: 'Agence arrivée',
                      value:
                          foundColis!['agenceArriveeNom']?.toString() ?? '—'),
                  _InfoRow(
                    label: 'Statut',
                    value: foundColis!['statut']?.toString() ?? 'INCONNU',
                  ),
                  const SizedBox(height: 14),
                  if (foundColis!['statut'] == 'DEPOSE_EN_AGENCE')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: chargerFoundColis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.archive),
                        label: const Text(
                          '📦 Charger en soute (Valider)',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else if (foundColis!['statut'] == 'EN_TRANSIT')
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ce colis est déjà chargé à bord de ce car (En transit).',
                              style: TextStyle(
                                  color: Color(0xFF047857),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Statut du colis : ${foundColis!['statut']}',
                      style: const TextStyle(color: Color(0xFF64748B)),
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