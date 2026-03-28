import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../models/contact_model.dart';
import '../../public_card/ui/public_card_page.dart';

class ContactCard extends StatefulWidget {
  final ContactModel contact;
  final VoidCallback? onMailTap;
  final bool isSelected;
  final int index;

  const ContactCard({
    super.key,
    required this.contact,
    this.onMailTap,
    this.isSelected = false,
    this.index = 0,
  });

  @override
  State<ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<ContactCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: 50 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _generateAvatarColor(String name) {
    final hash = name.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final companyColor = context.companyColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarColor = _generateAvatarColor(widget.contact.fullname);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          if (widget.contact.cardSlug != null &&
              widget.contact.cardSlug!.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicCardPage(slug: widget.contact.cardSlug!),
              ),
            );
          }
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (widget.isSelected ? companyColor : avatarColor)
                      .withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E1E2E),
                            const Color(0xFF161622),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFFF8F9FC),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.isSelected
                        ? companyColor.withValues(alpha: 0.5)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05)),
                    width: widget.isSelected ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background decoration
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              avatarColor.withValues(alpha: 0.15),
                              avatarColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Shimmer effect line
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              (isDark ? Colors.white : avatarColor)
                                  .withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with Avatar and Actions
                          Row(
                            children: [
                              // Avatar with glow effect
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: avatarColor.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        avatarColor,
                                        avatarColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getInitials(widget.contact.fullname),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Action buttons
                              _ActionButton(
                                icon: Icons.mail_rounded,
                                color: companyColor,
                                onTap: widget.onMailTap,
                                isDark: isDark,
                              ),
                              if (widget.contact.cardSlug != null) ...[
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.credit_card_rounded,
                                  color: avatarColor,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PublicCardPage(
                                          slug: widget.contact.cardSlug!,
                                        ),
                                      ),
                                    );
                                  },
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Name
                          Text(
                            widget.contact.fullname,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Company
                          if (widget.contact.company != null &&
                              widget.contact.company!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.contact.company!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Contact info chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (widget.contact.email != null &&
                                  widget.contact.email!.isNotEmpty)
                                _InfoChip(
                                  icon: Icons.email_outlined,
                                  text: widget.contact.email!,
                                  color: companyColor,
                                  isDark: isDark,
                                ),
                              if (widget.contact.phone != null &&
                                  widget.contact.phone!.isNotEmpty)
                                _InfoChip(
                                  icon: Icons.phone_outlined,
                                  text: widget.contact.phone!,
                                  color: avatarColor,
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Selection indicator
                    if (widget.isSelected)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: companyColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: companyColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
