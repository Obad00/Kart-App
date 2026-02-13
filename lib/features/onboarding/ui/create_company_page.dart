import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/logo_picker_field.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _maxUsersCtrl = TextEditingController();

  String? _logoPath;
  Color _primaryColor = const Color(0xFF2563EB);

  bool _loading = false;
  int _currentStep = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  int? _subscriptionId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _subscriptionId = args['subscriptionId'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxUsersCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
    }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _maxUsersCtrl.text.isEmpty) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }
    if (_subscriptionId == null) {
      _showError('Subscription ID manquant');
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    final companyProvider = context.read<CompanyProvider>();

    await companyProvider.createCompany(
      name: _nameCtrl.text.trim(),
      maxUsers: int.parse(_maxUsersCtrl.text.trim()),
      logo: _logoPath,
      primaryColor: _colorToHex(_primaryColor),
      subscriptionId: _subscriptionId!,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (companyProvider.error == null) {
      HapticFeedback.heavyImpact();
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showError(companyProvider.error!);
    }
  }

  void _showError(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressIndicator(),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _buildCurrentStep(),
                      ),
                    ],
                  ),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_currentStep > 0) {
                _previousStep();
              } else {
                Navigator.pushReplacementNamed(context, '/plans');
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Configurer votre entreprise',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Infos', 'Branding', 'Logo'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              if (index > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted || isActive
                        ? const Color(0xFF2563EB)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              GestureDetector(
                onTap: () {
                if (index < _currentStep) {
                  setState(() => _currentStep = index);
                }
              },

                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFF2563EB)
                            : isActive
                                ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isActive || isCompleted
                              ? const Color(0xFF2563EB)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF2563EB)
                                      : Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive || isCompleted
                            ? Colors.white
                            : Colors.grey[500],
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? const Color(0xFF2563EB)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.business_outlined,
          title: 'Informations',
          subtitle: 'Commencez par les informations de base',
        ),
        const SizedBox(height: 32),
        AuthTextField(
          label: 'Nom de votre entreprise',
          controller: _nameCtrl,
          prefixIcon: Icons.business_center_outlined,
        ),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Nombre de membres',
          controller: _maxUsersCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.people_outline,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF3B82F6), size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Le nombre de membres determine combien de cartes peuvent etre creees.',
                  style: TextStyle(
                      color: Colors.grey[300], fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.palette_outlined,
          title: 'Identite visuelle',
          subtitle: 'Personnalisez votre marque',
        ),
        const SizedBox(height: 32),
        ColorPickerField(
          label: 'Couleur principale',
          initialColor: _primaryColor,
          onColorChanged: (color) => setState(() => _primaryColor = color),
        ),
        const SizedBox(height: 24),
        _buildCardPreview(),
      ],
    );
  }

  Widget _buildCardPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apercu de votre carte',
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryColor.withValues(alpha: 0.15),
                _primaryColor.withValues(alpha: 0.05)
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: _primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: _logoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_logoPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.business,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 28)),
                      )
                    : Icon(Icons.business,
                        color: Colors.white.withValues(alpha: 0.8), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _nameCtrl.text.isEmpty
                            ? 'Votre Entreprise'
                            : _nameCtrl.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Carte digitale professionnelle',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child:
                    Icon(Icons.qr_code_rounded, color: _primaryColor, size: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.image_outlined,
          title: 'Logo',
          subtitle: 'Ajoutez votre identite visuelle',
        ),
        const SizedBox(height: 32),
        LogoPickerField(
          label: 'Telecharger votre logo',
          initialUrl: _logoPath,
          onLogoChanged: (path) => setState(() => _logoPath = path),
        ),
        const SizedBox(height: 24),
        _buildFinalPreview(),
      ],
    );
  }

  Widget _buildFinalPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.green[400], size: 20),
              const SizedBox(width: 10),
              const Text('Recapitulatif',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
              'Entreprise', _nameCtrl.text.isEmpty ? '-' : _nameCtrl.text),
          _buildSummaryRow(
              'Membres', _maxUsersCtrl.text.isEmpty ? '-' : _maxUsersCtrl.text),
          _buildSummaryRow('Couleur', _colorToHex(_primaryColor)),
          _buildSummaryRow('Logo', _logoPath != null ? 'Ajoute' : 'Non defini'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Row(
            children: [
              if (label == 'Couleur')
                Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(4))),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: GestureDetector(
                onTap: _previousStep,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Center(
                    child: Text('Precedent',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: AuthPrimaryButton(
              label: _currentStep < 2 ? 'Continuer' : 'Creer entreprise',
              loading: _loading,
              onTap: _nextStep,
              icon: _currentStep < 2 ? Icons.arrow_forward : Icons.check,
            ),
          ),
        ],
      ),
    );
  }
}
