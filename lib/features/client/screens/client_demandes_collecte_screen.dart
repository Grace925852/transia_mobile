import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/client/models/agence_model.dart';
import 'package:transia_mobile/features/client/models/demande_collecte_model.dart';
import 'package:transia_mobile/features/client/services/agence_service.dart';
import 'package:transia_mobile/features/client/services/demande_collecte_service.dart';

class ClientDemandesCollecteScreen extends StatefulWidget {
  const ClientDemandesCollecteScreen({super.key});

  @override
  State<ClientDemandesCollecteScreen> createState() =>
      _ClientDemandesCollecteScreenState();
}

class _ClientDemandesCollecteScreenState
    extends State<ClientDemandesCollecteScreen> {
  final _storage = SecureStorageService();
  late final DemandeCollecteService _service;
  late final AgenceService _agenceService;

  bool _loading = true;
  String _error = '';
  List<DemandeCollecteModel> _demandes = [];
  List<AgenceModel> _agences = [];

  @override
  void initState() {
    super.initState();
    _service = DemandeCollecteService(apiClient: ApiClient(_storage));
    _agenceService = AgenceService(apiClient: ApiClient(_storage));
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await Future.wait([
        _service.getMesDemandes(),
        _agenceService.getAgencesActives(),
      ]);
      if (!mounted) return;
      setState(() {
        _demandes = results[0] as List<DemandeCollecteModel>;
        _agences = results[1] as List<AgenceModel>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _annuler(DemandeCollecteModel d) async {
    try {
      await _service.annulerDemande(d.id);
      _charger();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _ouvrirFormulaire() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DemandeCollecteForm(
        agences: _agences,
        service: _service,
      ),
    );
    if (created == true) _charger();
  }

  Color _statutColor(StatutCollecte s) {
    switch (s) {
      case StatutCollecte.collecte: return const Color(0xFF10B981);
      case StatutCollecte.enCours: return const Color(0xFF3158F5);
      case StatutCollecte.annule: return const Color(0xFFEF4444);
      case StatutCollecte.enAttente: return const Color(0xFFF59E0B);
    }
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
        title: const Text('Collectes à domicile',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agences.isEmpty ? null : _ouvrirFormulaire,
        backgroundColor: const Color(0xFF3158F5),
        icon: const Icon(Icons.add),
        label: const Text('Demander'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _charger, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              : _demandes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_work_outlined, size: 72, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 16),
                            const Text('Aucune demande de collecte',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                                    color: Color(0xFF374151))),
                            const SizedBox(height: 8),
                            const Text(
                              'Demandez à ce qu\'un livreur vienne récupérer votre colis à domicile.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: _demandes.length,
                        itemBuilder: (ctx, i) {
                          final d = _demandes[i];
                          final color = _statutColor(d.statut);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(d.adresseCollecte,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, fontSize: 14)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(statutCollecteLabel(d.statut),
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(d.dateHeureCollecte,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                if (d.livreurNom != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Livreur : ${d.livreurNom}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                ],
                                if (d.statut == StatutCollecte.enAttente ||
                                    d.statut == StatutCollecte.enCours) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => _annuler(d),
                                      child: const Text('Annuler',
                                          style: TextStyle(color: Color(0xFFEF4444))),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _DemandeCollecteForm extends StatefulWidget {
  final List<AgenceModel> agences;
  final DemandeCollecteService service;

  const _DemandeCollecteForm({required this.agences, required this.service});

  @override
  State<_DemandeCollecteForm> createState() => _DemandeCollecteFormState();
}

class _DemandeCollecteFormState extends State<_DemandeCollecteForm> {
  final _adresseCtrl = TextEditingController();
  String? _agenceId;
  DateTime? _dateHeure;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDateHeure() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _dateHeure = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _soumettre() async {
    if (_adresseCtrl.text.trim().isEmpty || _agenceId == null || _dateHeure == null) {
      setState(() { _error = 'Veuillez remplir tous les champs.'; });
      return;
    }

    setState(() { _submitting = true; _error = null; });

    try {
      await widget.service.creerDemande(DemandeCollecteRequest(
        adresseCollecte: _adresseCtrl.text.trim(),
        dateHeureCollecte: _dateHeure!.toIso8601String(),
        agenceId: _agenceId!,
      ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle demande de collecte',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 8),
            ],
            const Text('Adresse de collecte',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _adresseCtrl,
              decoration: InputDecoration(
                hintText: 'Quartier, rue...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Agence de départ du colis',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: DropdownButton<String>(
                value: _agenceId,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Sélectionner une agence'),
                items: widget.agences
                    .map((a) => DropdownMenuItem(
                        value: a.id, child: Text('${a.nom} (${a.villeNom})')))
                    .toList(),
                onChanged: (v) => setState(() => _agenceId = v),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Date et heure souhaitées',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _choisirDateHeure,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF6B7280)),
                    const SizedBox(width: 10),
                    Text(
                      _dateHeure == null
                          ? 'Choisir une date et une heure'
                          : '${_dateHeure!.day}/${_dateHeure!.month}/${_dateHeure!.year} à '
                            '${_dateHeure!.hour.toString().padLeft(2, '0')}:${_dateHeure!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _soumettre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3158F5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Envoyer la demande',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
