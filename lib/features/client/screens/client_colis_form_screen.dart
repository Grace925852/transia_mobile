import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/agence_model.dart';
import 'package:transia_mobile/features/client/models/colis_model.dart';
import 'package:transia_mobile/features/client/services/agence_service.dart';
import 'package:transia_mobile/features/client/services/colis_service.dart';

class ClientColisFormScreen extends StatefulWidget {
  const ClientColisFormScreen({super.key});

  @override
  State<ClientColisFormScreen> createState() => _ClientColisFormScreenState();
}

class _ClientColisFormScreenState extends State<ClientColisFormScreen> {
  final _storage = SecureStorageService();
  late final ColisService _colisService;
  late final AgenceService _agenceService;

  final _descriptionCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _nomDestCtrl = TextEditingController();
  final _telDestCtrl = TextEditingController();
  final _adresseDestCtrl = TextEditingController();
  final _adresseCollecteCtrl = TextEditingController();

  double? _latitudeCollecte;
  double? _longitudeCollecte;
  bool _loadingGps = false;

  String _expediteurNom = '';
  String _expediteurTelephone = '';

  TranchePoids _tranchePoids = TranchePoids.moinsDe1kg;
  ModeRemise _modeRemise = ModeRemise.retraitAgence;
  bool _collecteDomicile = false;

  List<AgenceModel> _agences = [];
  String? _agenceDepartId;
  String? _agenceArriveeId;

  bool _loading = false;
  bool _loadingAgences = true;

  EstimationPrixModel? _estimation;
  String? _estimationError;
  bool _estimating = false;

  @override
  void initState() {
    super.initState();
    _colisService = ColisService(apiClient: ApiClient(_storage));
    _agenceService = AgenceService(apiClient: ApiClient(_storage));
    _init();
  }

  Future<void> _init() async {
    _expediteurNom = await _storage.getFullName() ?? '';
    _expediteurTelephone = await _storage.getTelephone() ?? '';

    try {
      final agences = await _agenceService.getAgencesActives();
      if (!mounted) return;
      setState(() { _agences = agences; _loadingAgences = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingAgences = false; });
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _dimensionsCtrl.dispose();
    _nomDestCtrl.dispose();
    _telDestCtrl.dispose();
    _adresseDestCtrl.dispose();
    _adresseCollecteCtrl.dispose();
    super.dispose();
  }

  Future<void> _capturerPositionGPS() async {
    setState(() { _loadingGps = true; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack('Veuillez activer la géolocalisation de votre téléphone.');
        setState(() { _loadingGps = false; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snack('Permission de localisation refusée.');
          setState(() { _loadingGps = false; });
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;

      setState(() {
        _latitudeCollecte = pos.latitude;
        _longitudeCollecte = pos.longitude;
        _loadingGps = false;
      });

      if (_adresseCollecteCtrl.text.trim().isEmpty) {
        _adresseCollecteCtrl.text = 'Position GPS : ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }

      _snack('📍 Position GPS capturée avec succès !');
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingGps = false; });
      _snack('Erreur lors de la détection GPS.');
    }
  }

  Future<void> _recalculerEstimation() async {
    setState(() { _estimation = null; _estimationError = null; });

    final depart = _agences.where((a) => a.id == _agenceDepartId).toList();
    final arrivee = _agences.where((a) => a.id == _agenceArriveeId).toList();
    if (depart.isEmpty || arrivee.isEmpty) return;

    setState(() { _estimating = true; });

    try {
      final estimation = await _colisService.estimerPrix(
        villeDepartId: depart.first.villeId,
        villeArriveeId: arrivee.first.villeId,
        tranche: _tranchePoids,
        modeRemise: _modeRemise,
        collecteDomicile: _collecteDomicile,
      );
      if (!mounted) return;
      setState(() { _estimation = estimation; _estimating = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _estimating = false;
        _estimationError = 'Aucun tarif configuré pour ce trajet et cette tranche de poids.';
      });
    }
  }

  Future<void> _soumettre() async {
    if (_descriptionCtrl.text.trim().isEmpty ||
        _nomDestCtrl.text.trim().isEmpty ||
        _telDestCtrl.text.trim().isEmpty) {
      _snack('Veuillez remplir tous les champs obligatoires.');
      return;
    }

    if (_agenceDepartId == null || _agenceArriveeId == null) {
      _snack('Veuillez sélectionner les agences de départ et d\'arrivée.');
      return;
    }

    if (_agenceDepartId == _agenceArriveeId) {
      _snack('L\'agence de départ et l\'agence d\'arrivée doivent être différentes.');
      return;
    }

    if (_modeRemise == ModeRemise.livraisonDomicile &&
        _adresseDestCtrl.text.trim().isEmpty) {
      _snack('Veuillez saisir l\'adresse de livraison.');
      return;
    }

    if (_collecteDomicile &&
        _adresseCollecteCtrl.text.trim().isEmpty &&
        _latitudeCollecte == null) {
      _snack('Veuillez fournir une adresse ou capturer votre position GPS pour la collecte à domicile.');
      return;
    }

    setState(() { _loading = true; });

    try {
      final request = ColisRequest(
        description: _descriptionCtrl.text.trim(),
        tranchePoids: _tranchePoids,
        dimensions: _dimensionsCtrl.text.trim().isNotEmpty
            ? _dimensionsCtrl.text.trim()
            : null,
        modeRemise: _modeRemise,
        expediteurNom: _expediteurNom,
        expediteurTelephone: _expediteurTelephone,
        destinataireNom: _nomDestCtrl.text.trim(),
        destinataireTelephone: _telDestCtrl.text.trim(),
        destinataireAdresse: _modeRemise == ModeRemise.livraisonDomicile
            ? _adresseDestCtrl.text.trim()
            : null,
        agenceDepartId: _agenceDepartId!,
        agenceArriveeId: _agenceArriveeId!,
        collecteDomicile: _collecteDomicile,
        adresseCollecte: _collecteDomicile ? _adresseCollecteCtrl.text.trim() : null,
        latitudeCollecte: _collecteDomicile ? _latitudeCollecte : null,
        longitudeCollecte: _collecteDomicile ? _longitudeCollecte : null,
      );

      await _colisService.enregistrerColis(request);

      if (!mounted) return;
      _snack('Colis enregistré avec succès !');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3158F5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Envoyer un colis',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loadingAgences
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _Section(
                  title: 'Trajet',
                  icon: Icons.route_rounded,
                  children: [
                    _DropdownField(
                      label: 'Agence de départ',
                      value: _agenceDepartId,
                      items: _agences
                          .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text('${a.nom} (${a.villeNom})')))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _agenceDepartId = v;
                          if (_agenceArriveeId == v) _agenceArriveeId = null;
                        });
                        _recalculerEstimation();
                      },
                    ),
                    _DropdownField(
                      label: "Agence d'arrivée",
                      value: _agenceArriveeId,
                      // Les agences restent toutes dans la liste (juste désactivée si == départ)
                      // : les retirer ferait planter DropdownButton si la valeur sélectionnée
                      // n'existe plus dans les items (assertion Flutter "exactly one item").
                      items: _agences
                          .map((a) => DropdownMenuItem(
                              value: a.id,
                              enabled: a.id != _agenceDepartId,
                              child: Text(
                                a.id == _agenceDepartId
                                    ? '${a.nom} (${a.villeNom}) — déjà choisie au départ'
                                    : '${a.nom} (${a.villeNom})',
                                style: a.id == _agenceDepartId
                                    ? const TextStyle(color: Color(0xFF9CA3AF))
                                    : null,
                              )))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _agenceArriveeId = v);
                        _recalculerEstimation();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Destinataire',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _Field(label: 'Nom complet *', controller: _nomDestCtrl,
                        hint: 'Ex : Koffi Akakpo'),
                    _Field(label: 'Téléphone *', controller: _telDestCtrl,
                        hint: 'Ex : 90000000',
                        type: TextInputType.phone),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Colis',
                  icon: Icons.straighten_rounded,
                  children: [
                    _Field(label: 'Description *', controller: _descriptionCtrl,
                        hint: 'Ex : Vêtements, documents...'),
                    _Field(label: 'Dimensions (optionnel)',
                        controller: _dimensionsCtrl,
                        hint: 'Ex : 30x20x15 cm'),
                    _DropdownField<TranchePoids>(
                      label: 'Tranche de poids',
                      value: _tranchePoids,
                      items: TranchePoids.values
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(trancheLabel(t))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _tranchePoids = v ?? _tranchePoids);
                        _recalculerEstimation();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Mode de remise',
                  icon: Icons.hail_rounded,
                  children: [
                    _RadioGroup<ModeRemise>(
                      value: _modeRemise,
                      options: const [
                        (ModeRemise.retraitAgence, 'Retrait en agence'),
                        (ModeRemise.livraisonDomicile, 'Livraison à domicile'),
                      ],
                      onChanged: (v) {
                        setState(() => _modeRemise = v);
                        _recalculerEstimation();
                      },
                    ),
                    if (_modeRemise == ModeRemise.livraisonDomicile)
                      _Field(
                        label: 'Adresse de livraison *',
                        controller: _adresseDestCtrl,
                        hint: 'Quartier, rue...',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Mode de dépôt du colis',
                  icon: Icons.unarchive_rounded,
                  children: [
                    _RadioGroup<bool>(
                      value: _collecteDomicile,
                      options: const [
                        (false, '🏢 Dépôt en agence (Je l\'apporte moi-même)'),
                        (true, '🏠 Collecte à domicile (Un livreur passe chez moi)'),
                      ],
                      onChanged: (v) {
                        setState(() => _collecteDomicile = v);
                        _recalculerEstimation();
                      },
                    ),
                    if (_collecteDomicile) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _loadingGps ? null : _capturerPositionGPS,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _loadingGps
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location_rounded, size: 20),
                          label: Text(
                            _latitudeCollecte != null
                                ? '📍 GPS capturé (${_latitudeCollecte!.toStringAsFixed(4)}, ${_longitudeCollecte!.toStringAsFixed(4)})'
                                : '📍 Capturer ma position GPS actuelle',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Field(
                        label: 'Adresse de ramassage / Repères *',
                        controller: _adresseCollecteCtrl,
                        hint:
                            'Ex: Quartier Hedzranawoe, Rue 124, près de la pharmacie',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (_estimating)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_estimation != null) _EstimationCard(estimation: _estimation!),
                if (_estimationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_estimationError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _soumettre,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3158F5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Enregistrer l\'envoi',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EstimationCard extends StatelessWidget {
  final EstimationPrixModel estimation;
  const _EstimationCard({required this.estimation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF0FDF4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Prix expédition', estimation.prixExpedition),
          if (estimation.fraisCollecte > 0) _row('Frais de collecte', estimation.fraisCollecte),
          if (estimation.fraisLivraison > 0) _row('Frais de livraison', estimation.fraisLivraison),
          const Divider(height: 20),
          _row('Total estimé', estimation.totalEstime, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF374151))),
          Text('${value.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF3158F5)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType type;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.type = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.45), fontSize: 13),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF3158F5), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? const Color(0xFF374151);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final fillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(color: textColor, fontSize: 14),
              hint: Text('Sélectionner',
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.45), fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioGroup<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _RadioGroup({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color
        ?? const Color(0xFF374151);

    return Column(
      children: options.map((opt) {
        final selected = opt.$1 == value;
        return GestureDetector(
          onTap: () => onChanged(opt.$1),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF3158F5)
                          : const Color(0xFF9CA3AF),
                      width: selected ? 5 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    opt.$2,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _CheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color
        ?? const Color(0xFF374151);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: const Color(0xFF3158F5),
            onChanged: (v) => onChanged(v ?? false),
          ),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 14, color: textColor)),
          ),
        ],
      ),
    );
  }
}
