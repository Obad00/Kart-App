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

class _PlanSelectionPageState extends State<PlanSelectionPage> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlanProvider>(context, listen: false).loadPlans();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlanProvider>(context);
    final plans = provider.plans;

    if (provider.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (plans.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: Text(
            'Aucun plan disponible',
            style: TextStyle(color: Colors.white),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              const Text(
                'Choisissez votre plan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Balayez pour comparer les offres',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: plans.length,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  itemBuilder: (_, index) {
                    final plan = plans[index];
                    final isSelected = index == _selectedIndex;
                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: isSelected ? 0 : 20),
                      child: PlanCard(
                        title: plan['name']!,
                        price: plan['price']!,
                        description: plan['description']!,
                        highlight: isSelected,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
  label: 'Continuer avec le plan ${plans[_selectedIndex]['name']}',
  loading: provider.loading,
  onTap: () async {
  final plan = plans[_selectedIndex];
  final planId = plan['id'];
  final planSlug = plan['slug'];

  // ✅ données capturées avant await

  await provider.subscribePlan(planId);

  // ✅ vérifie que le widget est toujours monté
  if (!mounted) return;

  // ✅ utilise le context dans un callback post-frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
      return;
    }

    if (planSlug == 'enterprise') {
      Navigator.pushReplacementNamed(
        context,
        '/create-company',
        arguments: {'subscriptionId': provider.currentSubscriptionId},
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
                onTap: () {
                  // Capture context localement ici aussi
                  final currentContext = context;
                  Navigator.pushReplacementNamed(currentContext, '/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
