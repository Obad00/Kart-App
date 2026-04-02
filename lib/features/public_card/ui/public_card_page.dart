import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/public_card_service.dart';
import '../../../shared/services/card_service.dart';

class PublicCardPage extends StatefulWidget {
  final String slug;

  const PublicCardPage({super.key, required this.slug});

  @override
  State<PublicCardPage> createState() => _PublicCardPageState();
}

class _PublicCardPageState extends State<PublicCardPage>
    with SingleTickerProviderStateMixin {
  final _service = PublicCardService();
  Map<String, dynamic>? card;
  bool isLoading = true;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _load();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _service.fetchCard(widget.slug);
    setState(() {
      card = data;
      isLoading = false;
    });

    // Enregistrer automatiquement la vue (sans coordonnees)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFF3B82F6),
                ),
              )
            : Stack(
                children: [
                  // Carte centrée verticalement et horizontalement
                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: AnimatedBuilder(
                        animation: _floatAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: child,
                          );
                        },
                        child: _buildCard(theme, isLightMode),
                      ),
                    ),
                  ),

                  // Bouton retour par dessus
                  Positioned(
                    top: 16,
                    left: 8,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: theme.colorScheme.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCard(ThemeData theme, bool isLightMode) {
    final media = MediaQuery.of(context);
    final double cardWidth = (media.size.width * 0.92).clamp(280.0, 500.0);
    final textColor = theme.colorScheme.onSurface;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Fond avec dégradé
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isLightMode
                      ? [Colors.white, const Color(0xFFF8FAFF)]
                      : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
                ),
              ),
            ),

            // Cercle décoratif top-right
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      const Color(0xFF3B82F6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Cercle décoratif bottom-left
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge KART avec style pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ).createShader(bounds),
                          child: const Text(
                            'KART',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Avatar initiales
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(card?['fullname'] ?? ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nom
                  Text(
                    card?['fullname'] ?? '',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if ((card?['job_title'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      card?['job_title'] ?? '',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  if ((card?['company'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        card?['company'] ?? '',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Divider stylisé
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          textColor.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if ((card?['fields'] ?? {}).isNotEmpty)
                    ..._buildFields(card?['fields'], textColor, cardData: card),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ajoute aussi cette méthode helper dans la classe :
  String _getInitials(String fullname) {
    final parts = fullname.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  List<Widget> _buildFields(Map<String, dynamic>? fields, Color textColor,
      {Map<String, dynamic>? cardData}) {
    final List<Widget> widgets = [];

    if (fields == null) {
      return widgets;
    }

    if (fields.containsKey('email')) {
      widgets.add(
          _buildFieldRow(Icons.email_outlined, fields['email'], textColor));
    }

    // Téléphone : chercher dans fields D'ABORD, sinon fallback sur card['phone'] racine
    final phone = fields['phone'] ?? fields['téléphone'] ?? cardData?['phone'];
    if (phone != null && phone.toString().isNotEmpty) {
      widgets.add(
        _buildFieldRow(Icons.phone_outlined, phone.toString(), textColor),
      );
    }

    // debugPrint('🔗 LinkedIn raw value: ${fields['linkedin']}');
    final linkedinRaw = fields['linkedin'] ?? fields['LinkedIn'];
    final linkedin = linkedinRaw?.toString().trim();
    if (linkedin != null && linkedin.isNotEmpty) {
      widgets.add(
        GestureDetector(
          onTap: () async {
            try {
              final uri = Uri.parse(linkedin);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            } catch (_) {}
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A66C2).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.linkedin,
                      size: 16,
                      color: Color(0xFF0A66C2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'LinkedIn',
                  style: TextStyle(
                    color: const Color(0xFF0A66C2).withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFieldRow(IconData icon, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3B82F6),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.75),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
