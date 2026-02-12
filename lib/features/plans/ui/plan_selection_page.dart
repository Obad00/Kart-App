import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/auth_outline_button.dart';
import '../widgets/plan_card.dart';

class PlanSelectionPage extends StatefulWidget {
  const PlanSelectionPage({super.key});

  @override
  State<PlanSelectionPage> createState() => _PlanSelectionPageState();
}

class _PlanSelectionPageState extends State<PlanSelectionPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _selectedIndex = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Couleurs d'accent pour chaque plan
  final List<Color> _planColors = [
    Colors.grey[400]!, // Free
    const Color(0xFF2563EB), // Pro (bleu)
    const Color(0xFFFFD700), // Enterprise (or)
  ];

  // Couleur secondaire pour gradient Pro
  static const Color _proSecondaryColor = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlanProvider>(context, listen: false).loadPlans();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  List<String> _getFeaturesForPlan(String? slug) {
    switch (slug) {
      case 'free':
        return [
          'Carte digitale personnelle',
          'QR code unique',
          'Partage illimité',
        ];
      case 'pro':
        return [
          'Tout de Free +',
          'Thèmes premium',
          'Statistiques avancées',
          'Highlights personnalisés',
          'Support prioritaire',
        ];
      case 'enterprise':
        return [
          'Tout de Pro +',
          'Gestion d\'équipe',
          'Licences multiples',
          'Branding entreprise',
          'Analytics d\'équipe',
          'Support dédié',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlanProvider>(context);
    final plans = provider.plans;

    if (provider.loading && plans.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (plans.isEmpty) {
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

    if (_selectedIndex >= plans.length) {
      _selectedIndex = 0;
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
                        children: List.generate(plans.length, (i) {
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
                    itemCount: plans.length,
                    onPageChanged: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    itemBuilder: (_, index) {
                      final plan = plans[index];
                      final isSelected = index == _selectedIndex;
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
                      AuthPrimaryButton(
                        label:
                            'Continuer avec ${plans[_selectedIndex]['name']}',
                        icon: Icons.arrow_forward_rounded,
                        loading: provider.loading,
                        onTap: () async {
                          final plan = plans[_selectedIndex];
                          final planId = plan['id'];
                          final planSlug = plan['slug'];

                          await provider.subscribePlan(planId);

                          if (!mounted) return;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;

                            if (provider.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.error!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (planSlug == 'enterprise') {
                              Navigator.pushReplacementNamed(
                                context,
                                '/create-company',
                                arguments: {
                                  'subscriptionId':
                                      provider.currentSubscriptionId
                                },
                              );
                            } else {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          });
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
