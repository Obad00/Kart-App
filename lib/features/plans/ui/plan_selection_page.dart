import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../../payment/providers/payment_provider.dart';
import '../../payment/models/plan.dart' as payment_models;
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
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _selectedIndex = 0;
  bool _isJoinCompanySelected = true; // Par defaut, le premier item est "Rejoindre entreprise"

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
  List<Map<String, dynamic>> _getFilteredPlans(List<Map<String, dynamic>> plans) {
    return plans.where((plan) => plan['slug'] != 'free').toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlanProvider>(context);
    final allPlans = provider.plans;
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
                          final planId = plan['id'];
                          final planSlug = plan['slug'];
                          final planName = plan['name'] ?? '';
                          final planDescription = plan['description'] ?? '';
                          final planPrice = plan['price'] ?? 0;
                          final planBillingCycle = plan['billing_cycle'] ?? 'monthly';
                          final planFeatures = plan['features'] != null
                              ? List<String>.from(plan['features'])
                              : <String>[];

                          // Sélectionner le plan dans le PaymentProvider et rediriger vers les méthodes de paiement
                          final paymentProvider = context.read<PaymentProvider>();
                          paymentProvider.selectPlan(
                            payment_models.Plan(
                              id: planId,
                              name: planName,
                              slug: planSlug ?? '',
                              description: planDescription,
                              price: planPrice is int ? planPrice : int.tryParse(planPrice.toString()) ?? 0,
                              billingCycle: planBillingCycle,
                              features: planFeatures,
                              isActive: true,
                            ),
                          );

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
