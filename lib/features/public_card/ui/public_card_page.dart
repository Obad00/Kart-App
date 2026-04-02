import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _openLeadCaptureSheet() {
    final ownerName = card?['fullname'] ?? 'ce contact';
    LeadCaptureSheet.show(
      context,
      slug: widget.slug,
      ownerName: ownerName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : Stack(
              children: [
                Center(
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
                Positioned(
                  top: 50,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(ThemeData theme, bool isLightMode) {
    final cardColor = isLightMode ? Colors.white : Colors.grey[900]!;
    final borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.1);
    final shadowColor = Colors.black.withValues(alpha: 0.3);
    final textColor = theme.colorScheme.onSurface;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge KART
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'KART',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nom
          Text(
            card?['fullname'] ?? '',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if ((card?['job_title'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card?['job_title'] ?? '',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if ((card?['company'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card?['company'] ?? '',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),

          if ((card?['fields'] ?? {}).isNotEmpty)
            ..._buildFields(card?['fields'], textColor),

          const SizedBox(height: 24),

          // Bouton pour partager ses coordonnees


// Nouvelle méthode pour ouvrir la popup de partage/contact (logique similaire à la liste)
        ],
      ),
    );
  }

  List<Widget> _buildFields(Map<String, dynamic>? fields, Color textColor) {
    final List<Widget> widgets = [];

    if (fields == null) return widgets;

    if (fields.containsKey('email')) {
      widgets.add(_buildFieldRow(Icons.email_outlined, fields['email'], textColor));
    }

    if (fields.containsKey('phone')) {
      widgets.add(_buildFieldRow(Icons.phone_outlined, fields['phone'], textColor));
    }

    if (fields.containsKey('linkedin')) {
      widgets.add(_buildLinkedInIcon(fields['linkedin'], textColor));
    }

    return widgets;
  }

  Widget _buildFieldRow(IconData icon, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedInIcon(String url, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: const FaIcon(
          FontAwesomeIcons.linkedin,
          size: 18,
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }
}
