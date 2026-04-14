import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../../public_card/ui/public_card_page.dart';

class ContactCard extends StatefulWidget {
  final ContactModel contact;
  final VoidCallback onShare;
  final VoidCallback onEmailTap;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onShare,
    required this.onEmailTap,
  });

  @override
  ContactCardState createState() => ContactCardState();
}

class ContactCardState extends State<ContactCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // ← min : prend juste la hauteur du contenu
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Carte principale — plus de Expanded
          GestureDetector(
            onTap: () {
              if (widget.contact.cardSlug != null &&
                  widget.contact.cardSlug!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PublicCardPage(slug: widget.contact.cardSlug!),
                  ),
                );
              }
            },
            child: DefaultTextStyle.merge(
              style: const TextStyle(decoration: TextDecoration.none),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(widget.contact.fullname),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nom
                      Text(
                        widget.contact.fullname,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Job
                      if (widget.contact.job != null &&
                          widget.contact.job!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.contact.job!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Company
                      if (widget.contact.company != null &&
                          widget.contact.company!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@ ${widget.contact.company}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Boutons sociaux
                      _buildSocialButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButtons() {
    final List<Widget> buttons = [];

    // LinkedIn button
    if (_hasValidValue(widget.contact.linkedin)) {
      buttons.add(
        _buildSocialButton(
          icon: FontAwesomeIcons.linkedin,
          color: const Color(0xFF0A66C2),
          onTap: () => _launchUrl(
              _formatSocialUrl(widget.contact.linkedin!, 'linkedin')),
        ),
      );
    }

    // Twitter/X button
    if (_hasValidValue(widget.contact.twitter)) {
      buttons.add(
        _buildSocialButton(
          icon: FontAwesomeIcons.xTwitter,
          color: const Color(0xFF000000),
          onTap: () =>
              _launchUrl(_formatSocialUrl(widget.contact.twitter!, 'twitter')),
        ),
      );
    }

    // Facebook button
    if (_hasValidValue(widget.contact.facebook)) {
      buttons.add(
        _buildSocialButton(
          icon: FontAwesomeIcons.facebook,
          color: const Color(0xFF1877F2),
          onTap: () => _launchUrl(
              _formatSocialUrl(widget.contact.facebook!, 'facebook')),
        ),
      );
    }

    // Instagram button
    if (_hasValidValue(widget.contact.instagram)) {
      buttons.add(
        _buildSocialButton(
          icon: FontAwesomeIcons.instagram,
          color: const Color(0xFFE4405F),
          onTap: () => _launchUrl(
              _formatSocialUrl(widget.contact.instagram!, 'instagram')),
        ),
      );
    }

    // Website button
    if (_hasValidValue(widget.contact.website)) {
      buttons.add(
        _buildSocialButton(
          icon: FontAwesomeIcons.globe,
          color: const Color(0xFF6366F1),
          onTap: () => _launchUrl(widget.contact.website!),
        ),
      );
    }

    // Phone button (WhatsApp if available)
    if (_hasValidValue(widget.contact.phone)) {
      buttons.add(
        _buildSocialButton(
          icon: FontAwesomeIcons.whatsapp,
          color: const Color(0xFF25D366),
          onTap: () => _launchUrl(
              'https://wa.me/${widget.contact.phone!.replaceAll(RegExp(r'[^\d+]'), '')}'),
        ),
      );
    }

    // Email button
    if (_hasValidValue(widget.contact.email)) {
      buttons.add(
        _buildSocialButton(
          icon: Icons.email,
          color: const Color(0xFF2563EB),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onEmailTap();
          },
        ),
      );
    }

    // If no social buttons, show a placeholder
    if (buttons.isEmpty) {
      return const SizedBox(height: 8);
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  /// Check if a field has a valid value (not null, not empty, not "null" string)
  bool _hasValidValue(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.toLowerCase() == 'null') return false;
    return true;
  }

  String _formatSocialUrl(String value, String platform) {
    // If already a full URL, return as is
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // Remove @ if present
    final username = value.replaceFirst('@', '');

    // Format based on platform
    switch (platform) {
      case 'linkedin':
        return 'https://www.linkedin.com/in/$username';
      case 'twitter':
        return 'https://twitter.com/$username';
      case 'facebook':
        return 'https://www.facebook.com/$username';
      case 'instagram':
        return 'https://www.instagram.com/$username';
      default:
        return value;
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
