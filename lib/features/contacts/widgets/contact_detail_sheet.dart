import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../../public_card/ui/public_card_page.dart';

class ContactDetailSheet extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onShare;
  final VoidCallback onEmailTap;

  const ContactDetailSheet({
    super.key,
    required this.contact,
    required this.onShare,
    required this.onEmailTap,
  });

  static void show(
    BuildContext context, {
    required ContactModel contact,
    required VoidCallback onShare,
    required VoidCallback onEmailTap,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactDetailSheet(
        contact: contact,
        onShare: onShare,
        onEmailTap: onEmailTap,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  bool _hasValue(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.toLowerCase() != 'null';
  }

  String _formatSocialUrl(String value, String platform) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final username = value.replaceFirst('@', '');
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const accent = Color(0xFF2563EB);

    return DraggableScrollableSheet(
      initialChildSize: 0.60,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
       child: SingleChildScrollView(
  controller: scrollController,
  child: Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
    ),
    child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with avatar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(contact.fullname),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name
                    Text(
                      contact.fullname,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Job & Company
                    if (_hasValue(contact.job) ||
                        _hasValue(contact.company)) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (_hasValue(contact.job)) contact.job!,
                          if (_hasValue(contact.company)) contact.company!,
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Quick action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_hasValue(contact.phone))
                          _buildQuickAction(
                            context,
                            icon: Icons.phone_rounded,
                            label: 'Appeler',
                            color: const Color(0xFF10B981),
                            onTap: () => _launchUrl(
                                'tel:${contact.phone!.replaceAll(RegExp(r'[^\d+]'), '')}'),
                          ),
                        if (_hasValue(contact.phone))
                          const SizedBox(width: 16),
                        if (_hasValue(contact.phone))
                          _buildQuickAction(
                            context,
                            icon: FontAwesomeIcons.whatsapp,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: () => _launchUrl(
                                'https://wa.me/${contact.phone!.replaceAll(RegExp(r'[^\d+]'), '')}'),
                          ),
                        if (_hasValue(contact.phone))
                          const SizedBox(width: 16),
                        if (_hasValue(contact.email))
                          _buildQuickAction(
                            context,
                            icon: Icons.email_rounded,
                            label: 'Email',
                            color: accent,
                            onTap: () {
                              Navigator.pop(context);
                              onEmailTap();
                            },
                          ),
                        if (_hasValue(contact.email))
                          const SizedBox(width: 16),
                        _buildQuickAction(
                          context,
                          icon: Icons.send_rounded,
                          label: 'Relancer',
                          color: const Color(0xFF8B5CF6),
                          onTap: () {
                            Navigator.pop(context);
                            onShare();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Social networks
                    if (_hasAnySocial()) ...[
                      _buildSectionTitle(context, 'Réseaux sociaux'),
                      const SizedBox(height: 10),
                      _buildSocialGrid(context),
                      const SizedBox(height: 20),
                    ],

                    // View public card button
                    if (_hasValue(contact.cardSlug)) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PublicCardPage(slug: contact.cardSlug!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.credit_card_rounded, size: 20),
                          label: const Text('Voir la carte digitale'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }

  bool _hasAnySocial() {
    return _hasValue(contact.linkedin) ||
        _hasValue(contact.twitter) ||
        _hasValue(contact.facebook) ||
        _hasValue(contact.instagram) ||
        _hasValue(contact.website);
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: icon is IconData ? Icon(icon, color: color, size: 22) : FaIcon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        letterSpacing: 1.2,
      ),
    );
  }

  // Widget _buildInfoCard(BuildContext context,
  //     {required List<Widget> children}) {
  //   final colors = Theme.of(context).colorScheme;
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: colors.onSurface.withValues(alpha: 0.03),
  //       borderRadius: BorderRadius.circular(18),
  //       border: Border.all(
  //         color: colors.onSurface.withValues(alpha: 0.06),
  //       ),
  //     ),
  //     child: Column(children: children),
  //   );
  // }

  // Widget _buildInfoTile(
  //   BuildContext context, {
  //   required IconData icon,
  //   required String label,
  //   required String value,
  //   required Color color,
  //   VoidCallback? onTap,
  //   VoidCallback? onLongPress,
  // }) {
  //   final colors = Theme.of(context).colorScheme;
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: onTap,
  //       onLongPress: onLongPress,
  //       borderRadius: BorderRadius.circular(18),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //         child: Row(
  //           children: [
  //             Container(
  //               width: 40,
  //               height: 40,
  //               decoration: BoxDecoration(
  //                 color: color.withValues(alpha: 0.1),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Icon(icon, size: 18, color: color),
  //             ),
  //             const SizedBox(width: 14),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     label,
  //                     style: TextStyle(
  //                       fontSize: 11,
  //                       fontWeight: FontWeight.w500,
  //                       color: colors.onSurface.withValues(alpha: 0.45),
  //                       letterSpacing: 0.3,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 2),
  //                   Text(
  //                     value,
  //                     style: TextStyle(
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w600,
  //                       color: colors.onSurface,
  //                     ),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             if (onTap != null)
  //               Icon(
  //                 Icons.open_in_new_rounded,
  //                 size: 16,
  //                 color: colors.onSurface.withValues(alpha: 0.25),
  //               ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildTileDivider(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Divider(
  //       height: 1,
  //       color:
  //           Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
  //     ),
  //   );
  // }

  Widget _buildSocialGrid(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final socials = <_SocialItem>[];

    if (_hasValue(contact.linkedin)) {
      socials.add(_SocialItem(
        icon: FontAwesomeIcons.linkedin,
        label: 'LinkedIn',
        color: const Color(0xFF0A66C2),
        url: _formatSocialUrl(contact.linkedin!, 'linkedin'),
      ));
    }
    if (_hasValue(contact.twitter)) {
      socials.add(_SocialItem(
        icon: FontAwesomeIcons.xTwitter,
        label: 'X / Twitter',
        color: colors.onSurface,
        url: _formatSocialUrl(contact.twitter!, 'twitter'),
      ));
    }
    if (_hasValue(contact.facebook)) {
      socials.add(_SocialItem(
        icon: FontAwesomeIcons.facebook,
        label: 'Facebook',
        color: const Color(0xFF1877F2),
        url: _formatSocialUrl(contact.facebook!, 'facebook'),
      ));
    }
    if (_hasValue(contact.instagram)) {
      socials.add(_SocialItem(
        icon: FontAwesomeIcons.instagram,
        label: 'Instagram',
        color: const Color(0xFFE4405F),
        url: _formatSocialUrl(contact.instagram!, 'instagram'),
      ));
    }
    if (_hasValue(contact.website)) {
      socials.add(_SocialItem(
        icon: FontAwesomeIcons.globe,
        label: 'Site web',
        color: const Color(0xFF6366F1),
        url: contact.website!,
      ));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: socials.map((social) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _launchUrl(social.url);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: social.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: social.color.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                social.icon is IconData ? Icon(social.icon, size: 16, color: social.color) : FaIcon(social.icon, size: 16, color: social.color),
                const SizedBox(width: 8),
                Text(
                  social.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: social.color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // void _copyToClipboard(BuildContext context, String text) {
  //   Clipboard.setData(ClipboardData(text: text));
  //   HapticFeedback.lightImpact();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Copié : $text'),
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }
}

class _SocialItem {
  final dynamic icon;
  final String label;
  final Color color;
  final String url;

  const _SocialItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.url,
  });
}
