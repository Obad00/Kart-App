import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/public_card_service.dart';
import '../../../shared/services/card_service.dart';
import '../widgets/lead_capture_sheet.dart';


class PublicCardPage extends StatefulWidget {
  final String slug;

  const PublicCardPage({super.key, required this.slug});

  @override
  State<PublicCardPage> createState() => _PublicCardPageState();
}

class _PublicCardPageState extends State<PublicCardPage>
    with TickerProviderStateMixin {
  final _service = PublicCardService();
  Map<String, dynamic>? card;
  bool isLoading = true;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _appearController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _load();

    // Animation flottante
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Animation d'apparition
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutBack),
    );

    _appearController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _service.fetchCard(widget.slug);
    setState(() {
      card = data;
      isLoading = false;
    });

    // Enregistrer automatiquement la vue
    _registerView();
  }

  Future<void> _registerView() async {
    try {
      await CardService.registerCardView(
        slug: widget.slug,
        source: 'qr_scan',
      );
    } catch (_) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _showContactForm() async {
    await LeadCaptureSheet.show(
      context,
      slug: widget.slug,
      ownerName: card!['fullname'] ?? 'le proprietaire',
    );
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  String _getFieldValue(String key) {
    final fields = card?['fields'];
    if (fields is Map<String, dynamic>) {
      final value = fields[key];
      if (value is String && value.isNotEmpty) return value.trim();
    }
    return '';
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Ignorer les erreurs de lancement URL.
    }
  }

  Future<void> _openPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (card == null) {
      return Scaffold(
        body: Center(child: Text('Carte non trouvée')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(card!['fullname'] ?? 'Carte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F0F23), const Color(0xFF1A1A2E)]
                : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      elevation: 20,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      color: isDark ? Colors.black : Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF3B82F6).withValues(alpha: 0.05),
                              const Color(0xFF2563EB).withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF2563EB),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(card!['fullname'] ?? ''),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Nom
                            Text(
                              card!['fullname'] ?? '',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Job
                            if (card!['job_title'] != null && card!['job_title'].isNotEmpty)
                              Text(
                                card!['job_title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 4),
                            // Company
                            if (card!['company'] != null && card!['company'].isNotEmpty)
                              Text(
                                card!['company'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white70 : const Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 16),
                            // Contact Info
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  // Phone
                                  if (card!['phone'] != null && card!['phone'].isNotEmpty)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _openPhone(card!['phone']),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.phone_outlined,
                                              size: 18,
                                              color: const Color(0xFF2563EB),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              card!['phone'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDark ? Colors.white70 : const Color(0xFF374151),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  // Email
                                  if (card!['fields'] != null && card!['fields']['email'] != null && card!['fields']['email'].isNotEmpty)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _openEmail(card!['fields']['email']),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 18,
                                              color: const Color(0xFF2563EB),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              card!['fields']['email'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: isDark ? Colors.white70 : const Color(0xFF374151),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Bouton "Restons en contact"
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showContactForm(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  elevation: 4,
                                  shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.person_add_outlined, size: 20),
                                label: const Text(
                                  'Restons en contact',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Social Links - Using FontAwesome icons like contact card
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                if (_getFieldValue('x').isNotEmpty)
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.xTwitter,
                                    color: const Color(0xFF000000),
                                    onTap: () => _openUrl(_getFieldValue('x')),
                                  ),
                                if (_getFieldValue('linkedin').isNotEmpty)
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.linkedin,
                                    color: const Color(0xFF0A66C2),
                                    onTap: () => _openUrl(_getFieldValue('linkedin')),
                                  ),
                                if (_getFieldValue('instagram').isNotEmpty)
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.instagram,
                                    color: const Color(0xFFE4405F),
                                    onTap: () => _openUrl(_getFieldValue('instagram')),
                                  ),
                                if (_getFieldValue('facebook').isNotEmpty)
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.facebook,
                                    color: const Color(0xFF1877F2),
                                    onTap: () => _openUrl(_getFieldValue('facebook')),
                                  ),
                                if (_getFieldValue('github').isNotEmpty)
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.github,
                                    color: const Color(0xFF333333),
                                    onTap: () => _openUrl(_getFieldValue('github')),
                                  ),
                                if (_getFieldValue('website').isNotEmpty)
                                  _buildSocialButton(
                                    icon: FontAwesomeIcons.globe,
                                    color: const Color(0xFF6366F1),
                                    onTap: () => _openUrl(_getFieldValue('website')),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}
