import 'package:go_router/go_router.dart';
import 'package:transia_mobile/features/auth/screens/login_screen.dart';
import 'package:transia_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:transia_mobile/shared/screens/edit_profile_screen.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_passenger_model.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_main_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_scan_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_trip_passengers_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_report_problem_screen.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';
import 'package:transia_mobile/features/client/models/trajet_model.dart';
import 'package:transia_mobile/features/client/screens/booking_summary_screen.dart';
import 'package:transia_mobile/features/client/screens/client_main_screen.dart';
import 'package:transia_mobile/features/client/screens/history_screen.dart';
import 'package:transia_mobile/features/client/screens/payement_screen.dart';
import 'package:transia_mobile/features/client/screens/rating_screen.dart';
import 'package:transia_mobile/features/client/screens/refund_request.dart';
import 'package:transia_mobile/features/client/screens/ticket_details_screen.dart';
import 'package:transia_mobile/features/client/screens/tracking_detail_screen.dart';
import 'package:transia_mobile/features/client/screens/trip_detail_screen.dart';
import 'package:transia_mobile/features/client/screens/trip_list_screen.dart';
import 'package:transia_mobile/features/client/screens/client_colis_list_screen.dart';
import 'package:transia_mobile/features/client/screens/client_colis_form_screen.dart';
import 'package:transia_mobile/features/client/screens/client_colis_detail_screen.dart';
import 'package:transia_mobile/features/client/models/colis_model.dart';
import 'package:transia_mobile/features/livreur/screens/livreur_main_screen.dart';
import 'package:transia_mobile/features/livreur/screens/livreur_colis_detail_screen.dart';
import 'package:transia_mobile/features/livreur/models/livreur_colis_model.dart';

class AppRoutes {
  static const String login = '/';
  static const String forgotPassword = '/forgot-password';
  static const String editProfile = '/edit-profile';
  static const String client = '/client';

  static const String chauffeur = '/chauffeur';
  static const String chauffeurPassengers = '/chauffeur/passagers';
  static const String chauffeurScan = '/chauffeur/scan';
  static const String chauffeurReportProblem = '/chauffeur/report-problem';

  static const String livreur = '/livreur';
  static const String livreurColisDetail = '/livreur/colis-detail';

  static const String tripList = '/trip-list';
  static const String tripDetail = '/trip-detail';
  static const String bookingSummary = '/booking-summary';

  static const String reservations = '/reservations';
  static const String payment = '/payment';
  static const String ticketDetails = '/ticket-details';
  static const String refundRequest = '/refund-request';
  static const String history = '/history';

  static const String trackingDetail = '/tracking-detail';
  static const String rating = '/rating';

  static const String clientColis = '/client-colis';
  static const String clientColisForm = '/client-colis/nouveau';
  static const String clientColisDetail = '/client-colis/detail';
}


const bool launchClientOnly = true;

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.client,
      builder: (context, state) => const ClientMainScreen(),
    ),
    GoRoute(
      path: AppRoutes.chauffeur,
      builder: (context, state) => const ChauffeurMainScreen(),
    ),
    GoRoute(
      path: AppRoutes.chauffeurPassengers,
      builder: (context, state) => ChauffeurTripPassengersScreen(
        trip: state.extra as ChauffeurTripModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.chauffeurScan,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ChauffeurScanScreen(
          trip: data['trip'] as ChauffeurTripModel,
          passengers: data['passengers'] as List<ChauffeurPassengerModel>,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.livreur,
      builder: (context, state) => const LivreurMainScreen(),
    ),
    GoRoute(
      path: AppRoutes.livreurColisDetail,
      builder: (context, state) => LivreurColisDetailScreen(
        colis: state.extra as LivreurColisModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.tripList,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return TripListScreen(
          trajets: data['trajets'],
          villeDepart: data['villeDepart'],
          villeArrivee: data['villeArrivee'],
          dateDepart: data['dateDepart'],
          nombreSieges: data['nombreSieges'] ?? 1,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.tripDetail,
      builder: (context, state) => TripDetailScreen(
        trajet: state.extra as TrajetModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.bookingSummary,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return BookingSummaryScreen(
          trajet: data['trajet'] as TrajetModel,
          nombreSieges: data['nombreSieges'] as int,
          selectedSeats: (data['selectedSeats'] as List<dynamic>? ?? [])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList(),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.reservations,
      builder: (context, state) => const ClientMainScreen(initialIndex: 1),
    ),
    GoRoute(
      path: AppRoutes.payment,
      builder: (context, state) => PaymentScreen(
        reservation: state.extra as ReservationModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.ticketDetails,
      builder: (context, state) => TicketDetailsScreen(
        reservation: state.extra as ReservationModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.refundRequest,
      builder: (context, state) => RefundRequestScreen(
        reservation: state.extra as ReservationModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.trackingDetail,
      builder: (context, state) => TrackingDetailScreen(
        reservation: state.extra as ReservationModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.rating,
      builder: (context, state) => RatingScreen(
        reservation: state.extra as ReservationModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.chauffeurReportProblem,
      builder: (context, state) => ChauffeurReportProblemScreen(
        trip: state.extra as ChauffeurTripModel,
      ),
    ),
    GoRoute(
      path: AppRoutes.clientColis,
      builder: (context, state) => const ClientColisListScreen(),
    ),
    GoRoute(
      path: AppRoutes.clientColisForm,
      builder: (context, state) => const ClientColisFormScreen(),
    ),
    GoRoute(
      path: AppRoutes.clientColisDetail,
      builder: (context, state) => ClientColisDetailScreen(
        colis: state.extra as ColisModel,
      ),
    ),
  ],
);
