import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../config/auth_config.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/auth_outline_button.dart';
import '../widgets/plan_card.dart';
import '../widgets/join_company_card.dart';

class PlanSelectionPage extends StatefulWidget {
  const PlanSelectionPage({super.key});

  @override
  State<PlanSelectionPage> createState() => _PlanSelectionPageState();
}

class _PlanSelectionPageState extends State<PlanSelectionPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _selectedIndex = 0;
  bool _isJoinCompanySelected =
      true; // Par defaut, le premier item est "Rejoindre entreprise"
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Couleurs d'accent pour chaque plan (sans Free)
  final List<Color> _planColors = [
    const Color(0xFF10B981), // Rejoindre entreprise (vert)
    const Color(0xFF2563EB), // Pro (bleu)
    const Color(0xFFFFD700), // Enterprise (or)
  ];

  // Couleur secondaire pour gradient Pro
  static const Color _proSecondaryColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlanProvider>(context, listen: false);
      provider.loadPlans();
      provider.loadPendingPlanSlug();
      _refreshUserAfterReturn();
      _animController.forward();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUserAfterReturn();
    }
  }

  Future<void> _refreshUserAfterReturn() async {
    final provider = context.read<PlanProvider>();
    if (provider.pendingPlanSlug != null &&
        provider.pendingPlanSlug!.isNotEmpty) {
      await context.read<AuthProvider>().loadMe();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  List<String> _getFeaturesForPlan(String? slug) {
    switch (slug) {
      case 'pro':
        return [
          'Carte digitale personnelle',
          'QR code unique',
          'Partage illimite',
          'Themes premium',
          'Statistiques avancees',
          'Support prioritaire',
        ];
      case 'enterprise':
        return [
          'Tout de Pro +',
          'Gestion d\'equipe',
          'Licences multiples',
          'Branding entreprise',
          'Analytics d\'equipe',
          'Support dedie',
        ];
      default:
        return [];
    }
  }

  // Filtrer les plans pour enlever le plan Free
  List<Map<String, dynamic>> _getFilteredPlans(
      List<Map<String, dynamic>> plans) {
    return plans.where((plan) => plan['slug'] != 'free').toList();
  }

  Future<void> _activateFreePlan(String planSlug) async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<PlanProvider>();
      await provider.setPendingPlanSlug(planSlug);
      final response = await provider.activateFreePlan(planSlug);

      if (!mounted) return;

      if (response == null) {
        throw Exception('activation_failed');
      }

      final statusCode = response.statusCode;
      final data = response.data;
      final requiresVerification = data['requires_email_verification'] == true;
      final is2xx = statusCode >= 200 && statusCode < 300;
      final isExplicitSuccess = data['success'] == true;

      debugPrint('🧭 Plan activation status=$statusCode data=$data');

      if (requiresVerification) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Un email de validation vous a été envoyé. Vérifiez votre boîte mail puis revenez continuer.',
            ),
          ),
        );
        return;
      }

      if (statusCode == 200 ||
          statusCode == 201 ||
          (is2xx && isExplicitSuccess)) {
        await context.read<AuthProvider>().loadMe();
        await provider.setPendingPlanSlug(null);

        final successMessage = planSlug == 'pro'
            ? 'Votre plan Pro a été activé avec succès. Vous pouvez vous connecter directement.'
            : 'Votre plan Enterprise a été activé avec succès.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );

        if (!mounted) return;

        if (planSlug == 'enterprise') {
          final subscription = data['subscription'];
          int? subscriptionId;
          if (subscription is Map<String, dynamic>) {
            final rawId = subscription['id'];
            if (rawId is int) {
              subscriptionId = rawId;
            } else if (rawId != null) {
              subscriptionId = int.tryParse(rawId.toString());
            }
          }

          Navigator.pushReplacementNamed(
            context,
            '/company/create',
            arguments: {
              'planSlug': planSlug,
              if (subscriptionId != null) 'subscriptionId': subscriptionId,
            },
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      final backendMessage = data['message']?.toString();
      final normalizedMessage = backendMessage?.toLowerCase() ?? '';
      final alreadyActive = normalizedMessage.contains('déjà un plan actif') ||
          normalizedMessage.contains('deja un plan actif');

      if (statusCode == 422 && alreadyActive) {
        final targetPlan = provider.plans.firstWhere(
          (p) => (p['slug']?.toString() ?? '') == planSlug,
          orElse: () => <String, dynamic>{},
        );

        final rawPlanId = targetPlan['id'];
        int? planId;
        if (rawPlanId is int) {
          planId = rawPlanId;
        } else if (rawPlanId != null) {
          planId = int.tryParse(rawPlanId.toString());
        }

        if (planId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                backendMessage ??
                    'Une erreur est survenue. Veuillez réessayer.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final switchedSubscriptionId = await provider.subscribePlan(planId);
        if (!mounted) return;

        if (switchedSubscriptionId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.error ??
                    backendMessage ??
                    'Une erreur est survenue. Veuillez réessayer.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await context.read<AuthProvider>().loadMe();
        await provider.setPendingPlanSlug(null);

        final successMessage = planSlug == 'pro'
            ? 'Votre plan Pro a été activé avec succès. Vous pouvez vous connecter directement.'
            : 'Votre plan Enterprise a été activé avec succès.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );

        if (!mounted) return;

        if (planSlug == 'enterprise') {
          Navigator.pushReplacementNamed(
            context,
            '/company/create',
            arguments: {
              'planSlug': planSlug,
              'subscriptionId': switchedSubscriptionId,
            },
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      if (backendMessage != null && backendMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(backendMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      throw Exception('activation_failed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlanProvider>(context);
    final allPlans = provider.plans;
    final pendingPlanSlug = provider.pendingPlanSlug;
    // Filtrer pour enlever le plan Free
    final plans = _getFilteredPlans(allPlans);
    // Total des items = 1 (rejoindre entreprise) + plans payants
    final totalItems = plans.length + 1;

    if (provider.loading && allPlans.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (allPlans.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.grey[600],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun plan disponible',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedIndex >= totalItems) {
      _selectedIndex = 0;
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Choisissez votre plan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Balayez pour découvrir les offres',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Page indicator dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(totalItems, (i) {
                          final isSelected = i == _selectedIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isSelected ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _planColors[i % _planColors.length]
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            _planColors[i % _planColors.length]
                                                .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Plans carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalItems,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                        _isJoinCompanySelected = index == 0;
                      });
                    },
                    itemBuilder: (_, index) {
                      final isSelected = index == _selectedIndex;

                      // Premier item = Rejoindre une entreprise
                      if (index == 0) {
                        return AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: isSelected ? 0 : 24,
                          ),
                          child: JoinCompanyCard(
                            highlight: isSelected,
                            accentColor: _planColors[0],
                          ),
                        );
                      }

                      // Les autres items = plans payants
                      final planIndex = index - 1;
                      final plan = plans[planIndex];
                      final slug = plan['slug'] as String?;

                      return AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: isSelected ? 0 : 24,
                        ),
                        child: PlanCard(
                          title: plan['name'] ?? '',
                          price: plan['price'] ?? '',
                          description: plan['description'] ?? '',
                          features: _getFeaturesForPlan(slug),
                          highlight: isSelected,
                          isPopular: slug == 'pro',
                          accentColor: _planColors[index % _planColors.length],
                          secondaryColor:
                              slug == 'pro' ? _proSecondaryColor : null,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      if (pendingPlanSlug != null &&
                          pendingPlanSlug.isNotEmpty) ...[
                        AuthOutlineButton(
                          label:
                              'Reprendre ${pendingPlanSlug == 'pro' ? 'Pro' : 'Enterprise'}',
                          icon: Icons.refresh_rounded,
                          onTap: () => _activateFreePlan(pendingPlanSlug),
                        ),
                        const SizedBox(height: 12),
                      ],
                      AuthPrimaryButton(
                        label: _isJoinCompanySelected || _selectedIndex == 0
                            ? 'Rejoindre une entreprise'
                            : 'Continuer avec ${plans.isNotEmpty && _selectedIndex > 0 && _selectedIndex - 1 < plans.length ? plans[_selectedIndex - 1]['name'] : 'ce plan'}',
                        icon: _isJoinCompanySelected || _selectedIndex == 0
                            ? Icons.business_rounded
                            : Icons.arrow_forward_rounded,
                        loading: provider.loading,
                        onTap: () async {
                          if (_isJoinCompanySelected || _selectedIndex == 0) {
                            // Rediriger vers la page pour rejoindre une entreprise
                            Navigator.pushReplacementNamed(
                              context,
                              '/join-company',
                            );
                            return;
                          }

                          final planIndex = _selectedIndex - 1;
                          if (planIndex < 0 || planIndex >= plans.length) {
                            return;
                          }
                          final plan = plans[planIndex];
                          final planSlug = (plan['slug'] as String?) ?? '';
                          if (planSlug.isEmpty) {
                            return;
                          }

                          if (!AuthConfig.enablePayments) {
                            await _activateFreePlan(planSlug);
                            return;
                          }

                          if (!mounted) return;
                          Navigator.pushNamed(context, '/payment/methods');
                        },
                      ),
                      const SizedBox(height: 12),
                      AuthOutlineButton(
                        label: 'Choisir plus tard',
                        icon: Icons.schedule_rounded,
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
