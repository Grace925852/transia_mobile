import 'package:flutter/material.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';

class TrackingDetailScreen extends StatefulWidget {
  final ReservationModel reservation;

  const TrackingDetailScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  double latitude = 6.1375;
  double longitude = 1.2123;
  String chauffeurNom = 'Chauffeur';
  bool isLoading = false;

  AppPreferencesController get prefs => AppPreferencesController.instance;

  String tr({
    required String fr,
    required String en,
    required String es,
    required String ar,
  }) {
    return prefs.tr(fr: fr, en: en, es: es, ar: ar);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Suivi GPS',
            en: 'GPS tracking',
            es: 'Seguimiento GPS',
            ar: 'تتبع GPS',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reservation.trajetLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.reservation.dateDepart} • ${widget.reservation.heureFormatee}',
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${tr(fr: 'Chauffeur', en: 'Driver', es: 'Conductor', ar: 'السائق')} : $chauffeurNom',
                  style: TextStyle(
                    fontSize: 14,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 360,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      tr(
                        fr: 'Carte GPS à brancher ici',
                        en: 'GPS map to connect here',
                        es: 'Mapa GPS para conectar aquí',
                        ar: 'خريطة GPS تُربط هنا',
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: mutedColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              '${tr(fr: 'Position actuelle', en: 'Current position', es: 'Posición actual', ar: 'الموقع الحالي')} : $latitude , $longitude',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}