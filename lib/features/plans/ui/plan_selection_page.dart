import 'package:flutter/material.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/auth_outline_button.dart';
import '../widgets/plan_card.dart';

class PlanSelectionPage extends StatefulWidget {
  const PlanSelectionPage({super.key});

  @override
  State<PlanSelectionPage> createState() => _PlanSelectionPageState();
}

class _PlanSelectionPageState extends State<PlanSelectionPage> {
  final PageController _pageController = PageController(
    viewportFraction: 0.88,
  );

  int _selectedIndex = 1; // Pro par défaut

  final List<Map<String, String>> _plans = [
    {
      'title': 'Gratuit',
      'price': '0 €',
      'description': 'Carte digitale, QR Code, contacts basiques',
    },
    {
      'title': 'Pro',
      'price': '9.99 € / mois',
      'description': 'Thèmes premium, export contacts, analytics',
    },
    {
      'title': 'Enterprise',
      'price': '29.99 € / mois',
      'description': 'Équipe, branding entreprise, API',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              /// HEADER
              const Text(
                'Choisissez votre plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Balayez pour comparer les offres',
                style: TextStyle(color: Colors.grey[400]),
              ),

              const SizedBox(height: 24),

              /// PLANS – SWIPE HORIZONTAL
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _plans.length,
                  onPageChanged: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final plan = _plans[index];

                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: index == _selectedIndex ? 0 : 24,
                      ),
                      child: PlanCard(
                        title: plan['title']!,
                        price: plan['price']!,
                        description: plan['description']!,
                        highlight: index == _selectedIndex,
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              /// ACTION PRINCIPALE
              AuthPrimaryButton(
                label:
                    'Continuer avec le plan ${_plans[_selectedIndex]['title']}',
                onTap: () {
                  final selectedPlan = _plans[_selectedIndex]['title'];

                  if (selectedPlan == 'Gratuit') {
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    Navigator.pushReplacementNamed(
                        context, '/create-company');
                  }
                },
              ),

              const SizedBox(height: 12),

              AuthOutlineButton(
                label: 'Choisir plus tard',
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
