import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transia_mobile/app/routes.dart';
import 'package:transia_mobile/core/network/api_client.dart';
import 'package:transia_mobile/core/network/self_service.dart';
import 'package:transia_mobile/core/storage/secure_storage_service.dart';
import 'package:transia_mobile/features/livreur/models/livreur_colis_model.dart';
import 'package:transia_mobile/features/livreur/services/livreur_service.dart';
import 'package:transia_mobile/shared/widgets/user_avatar.dart';

class LivreurProfileScreen extends StatefulWidget {
  const LivreurProfileScreen({super.key});

  @override
  State<LivreurProfileScreen> createState() =>
      _LivreurProfileScreenState();
}

class _LivreurProfileScreenState
    extends State<LivreurProfileScreen> {
  final SecureStorageService _storage =
      SecureStorageService();

  late final LivreurService _service;
  late final SelfService _selfService;

  bool _loading = true;
  String _fullName = 'Livreur';
  String _username = '';
  String? _photoBase64;

  List<LivreurColisModel> _tous = [];

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(_storage);

    _service = LivreurService(
      apiClient: apiClient,
    );

    _selfService = SelfService(
      apiClient: apiClient,
    );

    _charger();
  }

  Future<void> _charger() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final name = await _storage.getFullName();
      final phone = await _storage.getTelephone();

      final list = await _service.getMesLivraisons();
      final profil = await _selfService.getMyProfil();

      if (!mounted) return;

      setState(() {
        final cleanName = name?.trim() ?? '';
        final cleanPhone = phone?.trim() ?? '';

        _fullName =
            cleanName.isNotEmpty ? cleanName : 'Livreur';

        _username = cleanPhone;
        _photoBase64 = profil?.photoProfil;
        _tous = list;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _storage.clearSession();

    if (!mounted) return;

    context.go(AppRoutes.livreurLogin);
  }

  String get _initiales {
    final cleanName = _fullName.trim();

    if (cleanName.isEmpty || cleanName == 'Livreur') {
      return 'LV';
    }

    final parts = cleanName.split(
      RegExp(r'\s+'),
    );

    if (parts.isEmpty) {
      return 'LV';
    }

    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first[0].toUpperCase()
          : 'LV';
    }

    return '${parts.first[0]}${parts[1][0]}'
        .toUpperCase();
  }

  int get _livres {
    return _tous
        .where(
          (colis) =>
              colis.statut == StatutColis.livre,
        )
        .length;
  }

  int get _enCours {
    return _tous
        .where(
          (colis) =>
              colis.statut ==
              StatutColis.enCoursLivraison,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _charger,
          color: const Color(0xFF3158F5),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              40,
            ),
            children: [
              const Text(
                'Profil livreur',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    UserAvatar(
                      photoBase64: _photoBase64,
                      initiales: _initiales,
                      radius: 36,
                      fontSize: 24,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _username,
                      style: const TextStyle(
                        fontSize: 14,
                        color:
                            Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF3158F5,
                        ).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'LIVREUR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xFF3158F5),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_loading)
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        value: '${_tous.length}',
                        label: 'Total',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        value: '$_livres',
                        label: 'Livrés',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        value: '$_enCours',
                        label: 'En cours',
                      ),
                    ),
                  ],
                )
              else
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3158F5),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.editProfile,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Modifier mon profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _loading ? null : _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF4444),
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3158F5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
