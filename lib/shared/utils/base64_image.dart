import 'dart:convert';
import 'package:flutter/material.dart';

/// Décode une chaîne base64 (data URL "data:image/...;base64,..." ou base64 brut)
/// en ImageProvider affichable. Retourne null si la chaîne est vide ou invalide.
ImageProvider? base64ImageProvider(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    final base64Part = value.contains(',') ? value.split(',').last : value;
    return MemoryImage(base64Decode(base64Part));
  } catch (_) {
    return null;
  }
}
