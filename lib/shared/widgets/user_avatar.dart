import 'dart:convert';
import 'package:flutter/material.dart';

/// Avatar circulaire : affiche la photo de profil si disponible (data URL base64),
/// sinon les initiales du nom complet.
class UserAvatar extends StatelessWidget {
  final String? photoBase64;
  final String initiales;
  final double radius;
  final Color backgroundColor;
  final Color textColor;
  final double? fontSize;

  const UserAvatar({
    super.key,
    required this.photoBase64,
    required this.initiales,
    this.radius = 30,
    this.backgroundColor = const Color(0xFF3158F5),
    this.textColor = Colors.white,
    this.fontSize,
  });

  ImageProvider? _decodeImage() {
    final value = photoBase64;
    if (value == null || value.trim().isEmpty) return null;
    try {
      final base64Part = value.contains(',') ? value.split(',').last : value;
      return MemoryImage(base64Decode(base64Part));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _decodeImage();
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: image,
      child: image == null
          ? Text(
              initiales,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? radius * 0.6,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}
