import 'package:flutter/material.dart';
import 'package:transia_mobile/features/client/models/reservation_model.dart';

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
  final TextEditingController commentaireController = TextEditingController();

  @override
  void dispose() {
    commentaireController.dispose();
    super.dispose();
  }

  Widget buildStar(int index) {
    return IconButton(
      onPressed: () {
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

  void envoyerAvis() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avis enregistré.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Noter le trajet'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reservation.trajetLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Choisissez une note',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => buildStar(index + 1)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Voulez-vous laisser un commentaire ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentaireController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Votre commentaire...',
                    filled: true,
                    fillColor: const Color(0xFFF7F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
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
              onPressed: note == 0 ? null : envoyerAvis,
              child: const Text('Envoyer'),
            ),
          ),
        ],
      ),
    );
  }
}