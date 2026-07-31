import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
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
  State<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  final Color primaryBlue = const Color(0xFF3158F5);

  bool isLoading = false;
  bool clientFaitPartieDuVoyage = true;
  bool saisirNomsPassagers = false;

  String clientNom = '';

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final ReservationService reservationService;

  final TextEditingController delegueController =
      TextEditingController();

  final List<TextEditingController> passagerControllers = [];

  AppPreferencesController get prefs =>
      AppPreferencesController.instance;

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(
      fr: fr,
      en: en,
      es: es,
      ar: ar,
    );
  }

  @override
  void initState() {
    super.initState();

    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);

    reservationService = ReservationService(
      apiClient: apiClient,
    );

    _genererChampsPassagers();
    _chargerSessionClient();
  }

  @override
  void dispose() {
    delegueController.dispose();

    for (final controller in passagerControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _chargerSessionClient() async {
    final storedName =
        (await secureStorageService.getFullName() ?? '').trim();

    debugPrint(
      'BOOKING SESSION => fullName=$storedName',
    );

    if (!mounted) return;

    setState(() {
      clientNom = storedName;
    });
  }

  Future<String> _reloadClientNom() async {
    final storedName =
        (await secureStorageService.getFullName() ?? '').trim();

    if (mounted) {
      setState(() {
        clientNom = storedName;
      });
    }

    return storedName;
  }

  int get _nombreAutresPassagers {
    if (widget.nombreSieges > 1) {
      return widget.nombreSieges - 1;
    }

    return 0;
  }

  double get _montantTotal {
    return widget.trajet.tarif * widget.nombreSieges;
  }

  String get _nomResponsable {
    if (clientFaitPartieDuVoyage) {
      return clientNom.trim();
    }

    return delegueController.text.trim();
  }

  void _genererChampsPassagers() {
    for (final controller in passagerControllers) {
      controller.dispose();
    }

    passagerControllers.clear();

    for (int i = 0; i < _nombreAutresPassagers; i++) {
      passagerControllers.add(
        TextEditingController(),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _changerModeReservation(bool value) {
    setState(() {
      clientFaitPartieDuVoyage = value;
    });

    _genererChampsPassagers();
  }

  List<String> _buildNomsPassagers() {
    final responsable = _nomResponsable;
    final List<String> passagers = [];

    if (saisirNomsPassagers) {
      for (int i = 0; i < passagerControllers.length; i++) {
        final typed =
            passagerControllers[i].text.trim();

        if (typed.isNotEmpty) {
          passagers.add(typed);
        } else {
          passagers.add(
            'Invité N${i + 1} de $responsable',
          );
        }
      }
    } else {
      for (int i = 0; i < _nombreAutresPassagers; i++) {
        passagers.add(
          'Invité N${i + 1} de $responsable',
        );
      }
    }

    return passagers;
  }

  Future<void> _confirmerReservation() async {
    await _reloadClientNom();

    if (!clientFaitPartieDuVoyage &&
        delegueController.text.trim().isEmpty) {
      _afficherMessage(
        tr(
          fr: 'Veuillez saisir le nom du responsable.',
          en: 'Please enter the responsible person name.',
          es:
              'Por favor ingrese el nombre del responsable.',
          ar: 'يرجى إدخال اسم المسؤول.',
        ),
      );

      return;
    }

    if (clientFaitPartieDuVoyage &&
        clientNom.trim().isEmpty) {
      _afficherMessage(
        tr(
          fr:
              'Nom du client introuvable. Reconnectez-vous puis réessayez.',
          en:
              'Client name not found. Please sign in again and retry.',
          es:
              'Nombre del cliente no encontrado. Inicie sesión nuevamente e inténtelo otra vez.',
          ar:
              'تعذر العثور على اسم العميل. سجّل الدخول مرة أخرى ثم أعد المحاولة.',
        ),
      );

      return;
    }

    if (widget.selectedSeats.isNotEmpty &&
        widget.selectedSeats.length !=
            widget.nombreSieges) {
      _afficherMessage(
        tr(
          fr:
              'Le nombre de sièges choisis doit correspondre au nombre de places.',
          en:
              'The number of selected seats must match the number of seats.',
          es:
              'La cantidad de asientos elegidos debe coincidir con la cantidad de plazas.',
          ar:
              'يجب أن يطابق عدد المقاعد المختارة عدد الأماكن.',
        ),
      );

      return;
    }

    final request = ReservationRequestModel(
      trajetId: widget.trajet.id,
      nombrePlace: widget.nombreSieges,
      nomResponsable: _nomResponsable,
      nomsPassagers: _buildNomsPassagers(),
      siegesChoisis: widget.selectedSeats
          .map(
            (seat) => seat.toString(),
          )
          .toList(),
    );

    debugPrint(
      'RESERVATION REQUEST => ${request.toJson()}',
    );

    setState(() {
      isLoading = true;
    });

    try {
      await reservationService.createReservation(
        request,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Réservation créée avec succès.',
              en:
                  'Reservation created successfully.',
              es: 'Reserva creada con éxito.',
              ar: 'تم إنشاء الحجز بنجاح.',
            ),
          ),
        ),
      );

      context.go(AppRoutes.reservations);
    } catch (e) {
      if (!mounted) return;

      _afficherMessage(
        e.toString().replaceAll(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _afficherMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final seatsLabel = widget.selectedSeats.isEmpty
        ? tr(
            fr: 'Aucun',
            en: 'None',
            es: 'Ninguno',
            ar: 'لا يوجد',
          )
        : (widget.selectedSeats.toList()..sort()).join(', ');

    final titleColor =
        theme.textTheme.titleLarge?.color ??
            const Color(0xFF374151);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Confirmation',
            en: 'Confirmation',
            es: 'Confirmación',
            ar: 'التأكيد',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    fr:
                        'Détails de la réservation',
                    en: 'Reservation details',
                    es:
                        'Detalles de la reserva',
                    ar: 'تفاصيل الحجز',
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 18),
                _SummaryRow(
                  label: tr(
                    fr: 'Trajet',
                    en: 'Trip',
                    es: 'Trayecto',
                    ar: 'الرحلة',
                  ),
                  value:
                      '${widget.trajet.villeDepart} → ${widget.trajet.villeArrivee}',
                ),
                _SummaryRow(
                  label: tr(
                    fr: 'Date',
                    en: 'Date',
                    es: 'Fecha',
                    ar: 'التاريخ',
                  ),
                  value: widget.trajet.dateDepart,
                ),
                _SummaryRow(
                  label: tr(
                    fr: 'Heure',
                    en: 'Time',
                    es: 'Hora',
                    ar: 'الوقت',
                  ),
                  value:
                      widget.trajet.heureFormatee,
                ),
                _SummaryRow(
                  label: tr(
                    fr: 'Véhicule',
                    en: 'Vehicle',
                    es: 'Vehículo',
                    ar: 'المركبة',
                  ),
                  value: widget
                      .trajet
                      .vehiculeImmatriculation,
                ),
                _SummaryRow(
                  label: tr(
                    fr: 'Nombre de sièges',
                    en: 'Number of seats',
                    es: 'Número de asientos',
                    ar: 'عدد المقاعد',
                  ),
                  value:
                      '${widget.nombreSieges}',
                ),
                _SummaryRow(
                  label: tr(
                    fr: 'Sièges choisis',
                    en: 'Selected seats',
                    es: 'Asientos elegidos',
                    ar: 'المقاعد المختارة',
                  ),
                  value: seatsLabel,
                ),
                _SummaryRow(
                  label: tr(
                    fr: 'Prix unitaire',
                    en: 'Unit price',
                    es: 'Precio unitario',
                    ar: 'سعر الوحدة',
                  ),
                  value:
                      widget.trajet.prixFormate,
                ),
                _SummaryRow(
                  label: tr(
                    fr: 'Montant total',
                    en: 'Total amount',
                    es: 'Monto total',
                    ar: 'المبلغ الإجمالي',
                  ),
                  value:
                      '${_montantTotal.toStringAsFixed(0)} FCFA',
                  highlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    fr: 'Type de réservation',
                    en: 'Reservation type',
                    es: 'Tipo de reserva',
                    ar: 'نوع الحجز',
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 14),
                RadioListTile<bool>(
                  value: true,
                  groupValue:
                      clientFaitPartieDuVoyage,
                  onChanged: (value) {
                    if (value != null) {
                      _changerModeReservation(
                        value,
                      );
                    }
                  },
                  title: Text(
                    tr(
                      fr:
                          'Je fais partie du voyage',
                      en:
                          'I am part of the trip',
                      es:
                          'Formo parte del viaje',
                      ar: 'أنا جزء من الرحلة',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<bool>(
                  value: false,
                  groupValue:
                      clientFaitPartieDuVoyage,
                  onChanged: (value) {
                    if (value != null) {
                      _changerModeReservation(
                        value,
                      );
                    }
                  },
                  title: Text(
                    tr(
                      fr:
                          'Je réserve pour d’autres personnes',
                      en:
                          'I book for other people',
                      es:
                          'Reservo para otras personas',
                      ar:
                          'أحجز لأشخاص آخرين',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (clientFaitPartieDuVoyage &&
                    clientNom.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      fr:
                          'Le responsable sera automatiquement : $clientNom',
                      en:
                          'The responsible person will automatically be: $clientNom',
                      es:
                          'La persona responsable será automáticamente: $clientNom',
                      ar:
                          'سيكون المسؤول تلقائيًا: $clientNom',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme
                          .textTheme
                          .bodyMedium
                          ?.color,
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    fr:
                        'Informations passagers',
                    en:
                        'Passenger information',
                    es:
                        'Información de pasajeros',
                    ar:
                        'معلومات المسافرين',
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 14),
                if (!clientFaitPartieDuVoyage) ...[
                  Text(
                    tr(
                      fr:
                          'Nom du responsable',
                      en:
                          'Responsible person name',
                      es:
                          'Nombre del responsable',
                      ar: 'اسم المسؤول',
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      color: theme
                          .textTheme
                          .bodyLarge
                          ?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InputField(
                    controller:
                        delegueController,
                    hintText: tr(
                      fr:
                          'Ex : Koffi AKAKPO',
                      en:
                          'Ex: Koffi AKAKPO',
                      es:
                          'Ej: Koffi AKAKPO',
                      ar:
                          'مثال: Koffi AKAKPO',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SwitchListTile(
                  value:
                      saisirNomsPassagers,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tr(
                      fr:
                          'Voulez-vous saisir les autres noms ?',
                      en:
                          'Do you want to enter the other names?',
                      es:
                          '¿Desea ingresar los otros nombres?',
                      ar:
                          'هل تريد إدخال الأسماء الأخرى؟',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      saisirNomsPassagers =
                          value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (_nombreAutresPassagers == 0)
                  Text(
                    tr(
                      fr:
                          'Aucun autre passager à renseigner.',
                      en:
                          'No other passenger to fill in.',
                      es:
                          'No hay otros pasajeros que completar.',
                      ar:
                          'لا يوجد مسافرون آخرون لإدخالهم.',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme
                          .textTheme
                          .bodyMedium
                          ?.color,
                    ),
                  )
                else if (!saisirNomsPassagers)
                  Text(
                    tr(
                      fr:
                          'Les autres noms seront générés automatiquement.',
                      en:
                          'The other names will be generated automatically.',
                      es:
                          'Los otros nombres se generarán automáticamente.',
                      ar:
                          'سيتم إنشاء الأسماء الأخرى تلقائيًا.',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: theme
                          .textTheme
                          .bodyMedium
                          ?.color,
                    ),
                  )
                else
                  ...List.generate(
                    passagerControllers.length,
                    (index) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            '${tr(
                              fr: 'Passager',
                              en: 'Passenger',
                              es: 'Pasajero',
                              ar: 'المسافر',
                            )} ${index + 2}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w600,
                              color: theme
                                  .textTheme
                                  .bodyLarge
                                  ?.color,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          _InputField(
                            controller:
                                passagerControllers[
                                    index],
                            hintText: tr(
                              fr: 'Nom complet',
                              en: 'Full name',
                              es:
                                  'Nombre completo',
                              ar:
                                  'الاسم الكامل',
                            ),
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
              onPressed: isLoading
                  ? null
                  : _confirmerReservation,
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      tr(
                        fr:
                            'Confirmer la réservation',
                        en:
                            'Confirm reservation',
                        es:
                            'Confirmar reserva',
                        ar:
                            'تأكيد الحجز',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
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
    final theme = Theme.of(context);

    final mutedColor =
        theme.textTheme.bodyMedium?.color ??
            const Color(0xFF6B7280);

    final normalTextColor =
        theme.textTheme.bodyLarge?.color ??
            const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlighted
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: highlighted
                    ? const Color(0xFF3158F5)
                    : normalTextColor,
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
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111827)
            : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E5EC),
        ),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color:
              theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          hintStyle: TextStyle(
            color:
                theme.textTheme.bodyMedium?.color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}