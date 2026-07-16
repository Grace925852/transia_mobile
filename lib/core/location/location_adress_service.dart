import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class LocationAddressService {
  LocationAddressService._();

  static final LocationAddressService instance =
      LocationAddressService._();

  final Geocoding _geocoding = Geocoding();

  final Map<String, String> _cache = {};

  Future<String> getReadableAddress({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey =
        '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';

    final cachedAddress = _cache[cacheKey];

    if (cachedAddress != null && cachedAddress.trim().isNotEmpty) {
      return cachedAddress;
    }

    try {
      final List<Placemark> placemarks =
          await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return 'Position non identifiée';
      }

      final Placemark placemark = placemarks.first;
      final String address = _buildAddress(placemark);

      _cache[cacheKey] = address;

      return address;
    } catch (error) {
      debugPrint('ERREUR GÉOCODAGE INVERSÉ : $error');
      return 'Position non identifiée';
    }
  }

  String _buildAddress(Placemark placemark) {
    final String quartier = _firstNotEmpty([
      placemark.subLocality,
      placemark.street,
      placemark.thoroughfare,
      placemark.subAdministrativeArea,
    ]);

    final String ville = _firstNotEmpty([
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ]);

    final String region =
        placemark.administrativeArea?.trim() ?? '';

    final String pays =
        placemark.country?.trim() ?? '';

    final List<String> parts = [];

    _addUniquePart(parts, quartier);
    _addUniquePart(parts, ville);

    if (parts.isEmpty) {
      _addUniquePart(parts, region);
    }

    if (parts.isEmpty) {
      _addUniquePart(parts, pays);
    }

    if (parts.isEmpty) {
      return 'Position non identifiée';
    }

    return parts.join(', ');
  }

  String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      final cleaned = value?.trim() ?? '';

      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    return '';
  }

  void _addUniquePart(
    List<String> parts,
    String value,
  ) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return;
    }

    final alreadyExists = parts.any(
      (item) =>
          item.toLowerCase() == cleaned.toLowerCase(),
    );

    if (!alreadyExists) {
      parts.add(cleaned);
    }
  }

  void clearCache() {
    _cache.clear();
  }
}