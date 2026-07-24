import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
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
  final Set<String> occupiedSeats = {};

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;

  AppPreferencesController get prefs => AppPreferencesController.instance;

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

  int get totalSeats {
    final backendSeats = widget.trajet.capacite;
    if (backendSeats <= 0) return 30;
    return backendSeats;
  }

  int get availableSeatsCount {
    final available = totalSeats - occupiedSeats.length;
    return available < 0 ? 0 : available;
  }

  bool get isTripFull => availableSeatsCount <= 0;

  @override
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    reservationService = ReservationService(apiClient: apiClient);
    _loadOccupiedSeats();
  }

  Future<void> _loadOccupiedSeats() async {
    setState(() {
      isLoadingSeats = true;
    });

    try {
      // Endpoint dédié et scopé par trajet, plutôt que de charger toutes les réservations de la
      // plateforme (qui de toute façon n'est plus accessible à un client) et filtrer en local.
      final freshOccupiedSeats =
          await reservationService.getOccupiedSeats(widget.trajet.id);

      if (!mounted) return;

      setState(() {
        occupiedSeats
          ..clear()
          ..addAll(freshOccupiedSeats);

        selectedSeats.removeWhere(
          (seat) => occupiedSeats.contains(seat.toString()),
        );

        if (availableSeatsCount > 0 && nombreSieges > availableSeatsCount) {
          nombreSieges = availableSeatsCount;
        }

        if (availableSeatsCount == 0) {
          nombreSieges = 1;
          selectedSeats.clear();
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
    if (occupiedSeats.contains(seatNumber.toString())) return;

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
            tr(
              fr: 'Vous devez sélectionner exactement $nombreSieges siège(s).',
              en: 'You must select exactly $nombreSieges seat(s).',
              es: 'Debe seleccionar exactamente $nombreSieges asiento(s).',
              ar: 'يجب اختيار $nombreSieges مقعدًا بالضبط.',
            ),
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

  List<int> _generateRandomAvailableSeats(int count) {
    final List<int> freeSeats = List.generate(totalSeats, (index) => index + 1)
        .where((seat) => !occupiedSeats.contains(seat.toString()))
        .toList();

    if (freeSeats.length < count) {
      return [];
    }

    freeSeats.shuffle(Random());
    final generated = freeSeats.take(count).toList()..sort();
    return generated;
  }

  Future<void> _continuer() async {
    await _loadOccupiedSeats();

    if (availableSeatsCount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Ce trajet est complet.',
              en: 'This trip is full.',
              es: 'Este trayecto está completo.',
              ar: 'هذه الرحلة مكتملة.',
            ),
          ),
        ),
      );
      return;
    }

    if (nombreSieges > availableSeatsCount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Il ne reste que $availableSeatsCount siège(s) disponible(s).',
              en: 'Only $availableSeatsCount seat(s) remain available.',
              es: 'Solo quedan $availableSeatsCount asiento(s) disponibles.',
              ar: 'لم يتبق سوى $availableSeatsCount مقعدًا متاحًا.',
            ),
          ),
        ),
      );
      return;
    }

    List<int> finalSeats;

    if (demanderSelectionSiege) {
      final collision = selectedSeats.any(
        (seat) => occupiedSeats.contains(seat.toString()),
      );

      if (collision) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                fr: 'Un ou plusieurs sièges viennent d’être pris. Veuillez rechoisir.',
                en: 'One or more seats were just taken. Please choose again.',
                es: 'Uno o más asientos acaban de ocuparse. Elija de nuevo.',
                ar: 'تم حجز مقعد أو أكثر للتو. يرجى الاختيار مرة أخرى.',
              ),
            ),
          ),
        );
        return;
      }

      if (selectedSeats.length != nombreSieges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                fr: 'Veuillez sélectionner exactement $nombreSieges siège(s).',
                en: 'Please select exactly $nombreSieges seat(s).',
                es: 'Seleccione exactamente $nombreSieges asiento(s).',
                ar: 'يرجى اختيار $nombreSieges مقعدًا بالضبط.',
              ),
            ),
          ),
        );
        return;
      }

      finalSeats = selectedSeats.toList()..sort();
    } else {
      finalSeats = _generateRandomAvailableSeats(nombreSieges);

      if (finalSeats.length != nombreSieges) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                fr: 'Impossible d’attribuer automatiquement des sièges disponibles.',
                en: 'Unable to assign available seats automatically.',
                es: 'No se pueden asignar automáticamente los asientos disponibles.',
                ar: 'تعذر تعيين المقاعد المتاحة تلقائيًا.',
              ),
            ),
          ),
        );
        return;
      }
    }

    context.push(
      AppRoutes.bookingSummary,
      extra: {
        'trajet': widget.trajet,
        'nombreSieges': nombreSieges,
        'selectedSeats': finalSeats,
      },
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {bool highlight = false}) {
    final theme = Theme.of(context);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);
    final normalTextColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: mutedColor,
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
                    : normalTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTripBanner(BuildContext context) {
    if (!isTripFull) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.block_rounded,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr(
                fr: 'Ce trajet est complet. Il ne peut plus être réservé.',
                en: 'This trip is full. It can no longer be booked.',
                es: 'Este trayecto está completo. Ya no se puede reservar.',
                ar: 'هذه الرحلة ممتلئة ولا يمكن حجزها بعد الآن.',
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatSelectionSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(
              fr: 'Choix du siège',
              en: 'Seat selection',
              es: 'Elección de asiento',
              ar: 'اختيار المقعد',
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr(
              fr: 'Voulez-vous sélectionner votre siège ?',
              en: 'Do you want to select your seat?',
              es: '¿Desea seleccionar su asiento?',
              ar: 'هل تريد اختيار مقعدك؟',
            ),
            style: TextStyle(
              fontSize: 16,
              color: mutedColor,
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
                  title: Text(
                    tr(fr: 'Oui', en: 'Yes', es: 'Sí', ar: 'نعم'),
                  ),
                  onChanged: isTripFull ? null : (_) => _onSeatSelectionChoice(true),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  value: false,
                  groupValue: demanderSelectionSiege,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr(fr: 'Non', en: 'No', es: 'No', ar: 'لا'),
                  ),
                  onChanged: isTripFull ? null : (_) => _onSeatSelectionChoice(false),
                ),
              ),
            ],
          ),
          if (!demanderSelectionSiege && !isTripFull)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                tr(
                  fr: 'Si vous ne choisissez pas vos sièges, ils vous seront attribués automatiquement.',
                  en: 'If you do not choose your seats, they will be assigned automatically.',
                  es: 'Si no elige sus asientos, se asignarán automáticamente.',
                  ar: 'إذا لم تختر مقاعدك، فسيتم تعيينها تلقائيًا.',
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: mutedColor,
                ),
              ),
            ),
          if (demanderSelectionSiege) ...[
            const SizedBox(height: 8),
            Text(
              tr(
                fr: 'Choisissez exactement $nombreSieges siège(s). Les sièges gris sont déjà pris.',
                en: 'Choose exactly $nombreSieges seat(s). Gray seats are already taken.',
                es: 'Elija exactamente $nombreSieges asiento(s). Los asientos grises ya están ocupados.',
                ar: 'اختر $nombreSieges مقعدًا بالضبط. المقاعد الرمادية محجوزة بالفعل.',
              ),
              style: TextStyle(
                fontSize: 13,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(
                fr: 'Disponibles : $availableSeatsCount / $totalSeats',
                en: 'Available: $availableSeatsCount / $totalSeats',
                es: 'Disponibles: $availableSeatsCount / $totalSeats',
                ar: 'المتاح: $availableSeatsCount / $totalSeats',
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: titleColor,
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
                  final isOccupied =
                      occupiedSeats.contains(seatNumber.toString());
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
                    backgroundColor = isDark
                        ? const Color(0xFF172554)
                        : const Color(0xFFEAF0FF);
                    textColor = const Color(0xFF3158F5);
                    borderColor = const Color(0xFF3158F5);
                  }

                  return GestureDetector(
                    onTap: isTripFull ? null : () => _toggleSeat(seatNumber),
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
              tr(
                fr: 'Sélectionnés : ${selectedSeats.length}/$nombreSieges',
                en: 'Selected: ${selectedSeats.length}/$nombreSieges',
                es: 'Seleccionados: ${selectedSeats.length}/$nombreSieges',
                ar: 'المختارة: ${selectedSeats.length}/$nombreSieges',
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            if (selectedSeats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  tr(
                    fr: 'Siège(s) choisi(s) : ${(selectedSeats.toList()..sort()).join(', ')}',
                    en: 'Chosen seat(s): ${(selectedSeats.toList()..sort()).join(', ')}',
                    es: 'Asiento(s) elegido(s): ${(selectedSeats.toList()..sort()).join(', ')}',
                    ar: 'المقاعد المختارة: ${(selectedSeats.toList()..sort()).join(', ')}',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
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
    final theme = Theme.of(context);
    final trajet = widget.trajet;
    final total = trajet.tarif * nombreSieges;
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Détail du trajet',
            en: 'Trip details',
            es: 'Detalle del trayecto',
            ar: 'تفاصيل الرحلة',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _buildFullTripBanner(context),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    fr: 'Résumé du voyage',
                    en: 'Trip summary',
                    es: 'Resumen del viaje',
                    ar: 'ملخص الرحلة',
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                _buildRow(
                  context,
                  tr(fr: 'Départ', en: 'Departure', es: 'Salida', ar: 'الانطلاق'),
                  trajet.villeDepart,
                ),
                _buildRow(
                  context,
                  tr(fr: 'Destination', en: 'Destination', es: 'Destino', ar: 'الوجهة'),
                  trajet.villeArrivee,
                ),
                _buildRow(
                  context,
                  tr(fr: 'Date', en: 'Date', es: 'Fecha', ar: 'التاريخ'),
                  trajet.dateDepart,
                ),
                _buildRow(
                  context,
                  tr(fr: 'Heure', en: 'Time', es: 'Hora', ar: 'الوقت'),
                  trajet.heureFormatee,
                ),
                _buildRow(
                  context,
                  tr(
                    fr: 'Durée estimée',
                    en: 'Estimated duration',
                    es: 'Duración estimada',
                    ar: 'المدة التقديرية',
                  ),
                  trajet.dureeEstimee,
                ),
                _buildRow(
                  context,
                  tr(fr: 'Véhicule', en: 'Vehicle', es: 'Vehículo', ar: 'المركبة'),
                  trajet.vehiculeImmatriculation,
                ),
                _buildRow(
                  context,
                  tr(fr: 'Statut', en: 'Status', es: 'Estado', ar: 'الحالة'),
                  trajet.statut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    fr: 'Tarification',
                    en: 'Pricing',
                    es: 'Tarificación',
                    ar: 'التسعير',
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                _buildRow(
                  context,
                  tr(
                    fr: 'Prix unitaire',
                    en: 'Unit price',
                    es: 'Precio unitario',
                    ar: 'سعر الوحدة',
                  ),
                  trajet.prixFormate,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      tr(
                        fr: 'Nombre de sièges',
                        en: 'Number of seats',
                        es: 'Número de asientos',
                        ar: 'عدد المقاعد',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: mutedColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed:
                          !isTripFull && nombreSieges > 1 ? _decrementSeats : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$nombreSieges',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    IconButton(
                      onPressed: !isTripFull && nombreSieges < availableSeatsCount
                          ? _incrementSeats
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    fr: 'Maximum disponible pour ce trajet : $availableSeatsCount siège(s)',
                    en: 'Maximum available for this trip: $availableSeatsCount seat(s)',
                    es: 'Máximo disponible para este trayecto: $availableSeatsCount asiento(s)',
                    ar: 'الحد الأقصى المتاح لهذه الرحلة: $availableSeatsCount مقعدًا',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRow(
                  context,
                  tr(
                    fr: 'Montant total',
                    en: 'Total amount',
                    es: 'Monto total',
                    ar: 'المبلغ الإجمالي',
                  ),
                  '${total.toStringAsFixed(0)} FCFA',
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSeatSelectionSection(context),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isTripFull ? null : _continuer,
              child: Text(
                isTripFull
                    ? tr(
                        fr: 'Trajet complet',
                        en: 'Trip full',
                        es: 'Trayecto completo',
                        ar: 'الرحلة ممتلئة',
                      )
                    : tr(
                        fr: 'Continuer',
                        en: 'Continue',
                        es: 'Continuar',
                        ar: 'متابعة',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}