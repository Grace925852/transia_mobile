import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/settings/app_preferences_controller.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/feedback_request.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/services/feedback_service.dart';

class RatingScreen extends StatefulWidget {
  final ReservationModel reservation;

  const RatingScreen({
    super.key,
    required this.reservation,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int note = 0;
  bool isSubmitting = false;
  final TextEditingController commentaireController = TextEditingController();

  late final SecureStorageService secureStorageService;
  late final ApiClient apiClient;
  late final FeedbackService feedbackService;

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
  void initState() {
    super.initState();
    secureStorageService = SecureStorageService();
    apiClient = ApiClient(secureStorageService);
    feedbackService = FeedbackService(apiClient: apiClient);
  }

  @override
  void dispose() {
    commentaireController.dispose();
    super.dispose();
  }

  Widget buildStar(BuildContext context, int index) {
    return IconButton(
      onPressed: isSubmitting
          ? null
          : () {
              setState(() {
                note = index;
              });
            },
      icon: Icon(
        index <= note ? Icons.star_rounded : Icons.star_outline_rounded,
        color: const Color(0xFFF59E0B),
        size: 34,
      ),
    );
  }

  Future<void> envoyerAvis() async {
    if (note <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Veuillez choisir une note.',
              en: 'Please choose a rating.',
              es: 'Por favor elija una calificación.',
              ar: 'يرجى اختيار تقييم.',
            ),
          ),
        ),
      );
      return;
    }

    final trajetId = widget.reservation.trajetId.trim();
    final creerPar = widget.reservation.clientNom.trim();

    if (trajetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Trajet introuvable pour cet avis.',
              en: 'Trip not found for this feedback.',
              es: 'Trayecto no encontrado para esta opinión.',
              ar: 'تعذر العثور على الرحلة لهذا التقييم.',
            ),
          ),
        ),
      );
      return;
    }

    if (creerPar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Nom du client introuvable.',
              en: 'Client name not found.',
              es: 'Nombre del cliente no encontrado.',
              ar: 'تعذر العثور على اسم العميل.',
            ),
          ),
        ),
      );
      return;
    }

    final request = FeedbackRequest(
      noteValeur: note,
      commentaireTexte: commentaireController.text.trim(),
      trajetId: trajetId,
      creerPar: creerPar,
    );

    setState(() {
      isSubmitting = true;
    });

    try {
      await feedbackService.submitFeedback(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              fr: 'Avis enregistré avec succès.',
              en: 'Feedback saved successfully.',
              es: 'Opinión registrada con éxito.',
              ar: 'تم حفظ التقييم بنجاح.',
            ),
          ),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        theme.textTheme.titleLarge?.color ?? const Color(0xFF374151);
    final mutedColor =
        theme.textTheme.bodyMedium?.color ?? const Color(0xFF6B7280);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tr(
            fr: 'Noter le trajet',
            en: 'Rate the trip',
            es: 'Calificar el trayecto',
            ar: 'تقييم الرحلة',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 18),
                Text(
                  tr(
                    fr: 'Choisissez une note',
                    en: 'Choose a rating',
                    es: 'Elija una calificación',
                    ar: 'اختر تقييمًا',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => buildStar(context, index + 1),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  tr(
                    fr: 'Voulez-vous laisser un commentaire ?',
                    en: 'Would you like to leave a comment?',
                    es: '¿Desea dejar un comentario?',
                    ar: 'هل تريد ترك تعليق؟',
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentaireController,
                  maxLines: 5,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: tr(
                      fr: 'Votre commentaire...',
                      en: 'Your comment...',
                      es: 'Su comentario...',
                      ar: 'تعليقك...',
                    ),
                    hintStyle: TextStyle(
                      color: mutedColor,
                    ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF111827) : const Color(0xFFF7F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF3158F5),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: (note == 0 || isSubmitting) ? null : envoyerAvis,
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.3,
                      ),
                    )
                  : Text(
                      tr(
                        fr: 'Envoyer',
                        en: 'Send',
                        es: 'Enviar',
                        ar: 'إرسال',
                      ),
                      style: const TextStyle(
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