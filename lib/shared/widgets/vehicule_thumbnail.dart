import 'package:flutter/material.dart';
import 'package:transia_mobile/shared/utils/base64_image.dart';

/// Vignette véhicule : affiche la photo du véhicule si disponible (base64),
/// sinon une icône de bus par défaut sur fond bleu.
class VehiculeThumbnail extends StatelessWidget {
  final String? imageBase64;
  final double size;
  final double borderRadius;

  const VehiculeThumbnail({
    super.key,
    required this.imageBase64,
    this.size = 44,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final image = base64ImageProvider(imageBase64);

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3158F5),
        borderRadius: BorderRadius.circular(borderRadius),
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover)
            : null,
      ),
      child: image == null
          ? Icon(
              Icons.directions_bus_filled_rounded,
              color: Colors.white,
              size: size * 0.55,
            )
          : null,
    );
  }
}
