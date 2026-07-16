import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/colis_model.dart';
import 'package:transia_mobile/features/client/models/ville_model.dart';
import 'package:transia_mobile/features/client/services/colis_service.dart';
import 'package:transia_mobile/features/client/services/ville_service.dart';

class ClientColisFormScreen extends StatefulWidget {
  const ClientColisFormScreen({super.key});

  @override
  State<ClientColisFormScreen> createState() => _ClientColisFormScreenState();
}

class _ClientColisFormScreenState extends State<ClientColisFormScreen> {
  final _storage = SecureStorageService();
  late final ColisService _colisService;
  late final VilleService _villeService;

  final _nomDestCtrl = TextEditingController();
  final _adresseDestCtrl = TextEditingController();
  final _telDestCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _longueurCtrl = TextEditingController(text: '0');
  final _largeurCtrl = TextEditingController(text: '0');
  final _hauteurCtrl = TextEditingController(text: '0');
  final _remarquesCtrl = TextEditingController();
  final _adresseCollecteCtrl = TextEditingController();

  ModeDepot _modeDepot = ModeDepot.depotAgence;
  ModeRemise _modeRemise = ModeRemise.retraitAgence;

  List<VilleModel> _villes = [];
  String? _villeDepartId;
  String? _villeArriveeId;

  bool _loading = false;
  bool _loadingVilles = true;

  @override
  void initState() {
    super.initState();
    _colisService = ColisService(apiClient: ApiClient(_storage));
    _villeService = VilleService(apiClient: ApiClient(_storage));
    _chargerVilles();
  }

  @override
  void dispose() {
    _nomDestCtrl.dispose();
    _adresseDestCtrl.dispose();
    _telDestCtrl.dispose();
    _poidsCtrl.dispose();
    _longueurCtrl.dispose();
    _largeurCtrl.dispose();
    _hauteurCtrl.dispose();
    _remarquesCtrl.dispose();
    _adresseCollecteCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerVilles() async {
    try {
      final villes = await _villeService.getVilles();
      if (!mounted) return;
      setState(() { _villes = villes; _loadingVilles = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingVilles = false; });
    }
  }

  Future<void> _soumettre() async {
    if (_nomDestCtrl.text.trim().isEmpty ||
        _adresseDestCtrl.text.trim().isEmpty ||
        _telDestCtrl.text.trim().isEmpty ||
        _poidsCtrl.text.trim().isEmpty) {
      _snack('Veuillez remplir tous les champs obligatoires.');
      return;
    }

    if (_modeDepot == ModeDepot.enlevementDomicile &&
        _adresseCollecteCtrl.text.trim().isEmpty) {
      _snack("Veuillez saisir l'adresse d'enlèvement.");
      return;
    }

    setState(() { _loading = true; });

    try {
      final expediteurId = await _storage.getUserId();
      final request = ColisRequest(
        expediteurId: expediteurId,
        nomDestinataire: _nomDestCtrl.text.trim(),
        adresseDestinataire: _adresseDestCtrl.text.trim(),
        telephoneDestinataire: _telDestCtrl.text.trim(),
        poids: double.tryParse(_poidsCtrl.text.trim()) ?? 0,
        longueur: double.tryParse(_longueurCtrl.text.trim()) ?? 0,
        largeur: double.tryParse(_largeurCtrl.text.trim()) ?? 0,
        hauteur: double.tryParse(_hauteurCtrl.text.trim()) ?? 0,
        modeDepot: _modeDepot,
        modeRemise: _modeRemise,
        adresseCollecte: _modeDepot == ModeDepot.enlevementDomicile
            ? _adresseCollecteCtrl.text.trim()
            : null,
        remarques: _remarquesCtrl.text.trim().isNotEmpty
            ? _remarquesCtrl.text.trim()
            : null,
        villeDepartId: _villeDepartId,
        villeArriveeId: _villeArriveeId,
      );

      await _colisService.creerColis(request);

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
      body: _loadingVilles
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _Section(
                  title: 'Destinataire',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _Field(label: 'Nom complet *', controller: _nomDestCtrl,
                        hint: 'Ex : Koffi Akakpo'),
                    _Field(label: 'Adresse *', controller: _adresseDestCtrl,
                        hint: 'Adresse de livraison'),
                    _Field(label: 'Téléphone *', controller: _telDestCtrl,
                        hint: 'Ex : 90000000',
                        type: TextInputType.phone),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Trajet',
                  icon: Icons.route_rounded,
                  children: [
                    _DropdownField(
                      label: 'Ville de départ',
                      value: _villeDepartId,
                      items: _villes
                          .map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text('${v.nomVille} (${v.region})')))
                          .toList(),
                      onChanged: (v) => setState(() => _villeDepartId = v),
                    ),
                    _DropdownField(
                      label: "Ville d'arrivée",
                      value: _villeArriveeId,
                      items: _villes
                          .where((v) => v.id != _villeDepartId)
                          .map((v) => DropdownMenuItem(
                              value: v.id,
                              child: Text('${v.nomVille} (${v.region})')))
                          .toList(),
                      onChanged: (v) => setState(() => _villeArriveeId = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Dimensions & Poids',
                  icon: Icons.straighten_rounded,
                  children: [
                    _Field(label: 'Poids (kg) *', controller: _poidsCtrl,
                        hint: 'Ex : 2.5',
                        type: TextInputType.numberWithOptions(decimal: true)),
                    Row(
                      children: [
                        Expanded(child: _Field(label: 'Longueur (cm)',
                            controller: _longueurCtrl, hint: '0',
                            type: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: _Field(label: 'Largeur (cm)',
                            controller: _largeurCtrl, hint: '0',
                            type: TextInputType.number)),
                        const SizedBox(width: 8),
                        Expanded(child: _Field(label: 'Hauteur (cm)',
                            controller: _hauteurCtrl, hint: '0',
                            type: TextInputType.number)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Mode de collecte',
                  icon: Icons.local_shipping_outlined,
                  children: [
                    _RadioGroup<ModeDepot>(
                      value: _modeDepot,
                      options: const [
                        (ModeDepot.depotAgence, 'Dépôt en agence'),
                        (ModeDepot.enlevementDomicile, 'Enlèvement à domicile'),
                      ],
                      onChanged: (v) => setState(() => _modeDepot = v),
                    ),
                    if (_modeDepot == ModeDepot.enlevementDomicile)
                      _Field(
                        label: "Adresse d'enlèvement *",
                        controller: _adresseCollecteCtrl,
                        hint: 'Adresse où le colis sera récupéré',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Mode de livraison',
                  icon: Icons.hail_rounded,
                  children: [
                    _RadioGroup<ModeRemise>(
                      value: _modeRemise,
                      options: const [
                        (ModeRemise.retraitAgence, 'Retrait en agence'),
                        (ModeRemise.livraisonDomicile, 'Livraison à domicile'),
                      ],
                      onChanged: (v) => setState(() => _modeRemise = v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Remarques',
                  icon: Icons.notes_rounded,
                  children: [
                    _Field(label: 'Remarques (optionnel)',
                        controller: _remarquesCtrl,
                        hint: 'Ex : Fragile, ne pas retourner',
                        maxLines: 3),
                  ],
                ),
                const SizedBox(height: 24),
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
                Text(opt.$2,
                    style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
