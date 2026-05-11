import 'package:go_router/go_router.dart';
import 'package:transia_mobile/features/auth/screens/login_screen.dart';
import 'package:transia_mobile/features/chauffeur/models/chauffeur_trip_model.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_login_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_main_screen.dart';
import 'package:transia_mobile/features/chauffeur/screens/chauffeur_trip_passengers_screen.dart';
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

class AppRoutes {
  static const String login = '/login';
  static const String client = '/client';

  static const String chauffeurLogin = '/chauffeur-login';
  static const String chauffeur = '/chauffeur';
  static const String chauffeurPassengers = '/chauffeur/passagers';

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
}

const bool launchClientOnly = true;

final GoRouter appRouter = GoRouter(
  initialLocation:
      launchClientOnly ? AppRoutes.login : AppRoutes.chauffeurLogin,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.client,
      builder: (context, state) => const ClientMainScreen(),
    ),
    GoRoute(
      path: AppRoutes.chauffeurLogin,
      builder: (context, state) => const ChauffeurLoginScreen(),
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
  ],
);