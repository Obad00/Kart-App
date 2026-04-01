import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/services/card_service.dart';

/// Canal de partage disponible
enum ShareChannel {
  whatsapp,
  email,
  sms,
  linkedin,
  copy,
  other,
}

/// Bottom sheet pour le partage intelligent de la carte
class ShareBottomSheet extends StatefulWidget {
  final String shareUrl;
  final String userName;
  final String? jobTitle;
  final String? company;

  const ShareBottomSheet({
    super.key,
    required this.shareUrl,
    required this.userName,
    this.jobTitle,
    this.company,
  });

  /// Affiche le bottom sheet et retourne le canal utilisé (ou null si annulé)
  static Future<ShareChannel?> show(
    BuildContext context, {
    required String shareUrl,
    required String userName,
    String? jobTitle,
    String? company,
  }) {
    return showModalBottomSheet<ShareChannel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        shareUrl: shareUrl,
        userName: userName,
        jobTitle: jobTitle,
        company: company,
      ),
    );
  }

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  ShareChannel? _selectedChannel;

  @override
  void initState() {
    super.initState();
    _messageController.text = _defaultMessage;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _defaultMessage {
    final buffer = StringBuffer();
    buffer.write('Bonjour ! Voici ma carte de visite digitale.');
    if (widget.jobTitle != null || widget.company != null) {
      buffer.write('\n\n');
      buffer.write(widget.userName);
      if (widget.jobTitle != null) {
        buffer.write(' - ${widget.jobTitle}');
      }
      if (widget.company != null) {
        buffer.write(' @ ${widget.company}');
      }
    }
    buffer.write('\n\n${widget.shareUrl}');
    return buffer.toString();
  }

  void _updateMessageForChannel(ShareChannel channel) {
    setState(() {
      _selectedChannel = channel;
    });

    // Adapter le message selon le canal
    switch (channel) {
      case ShareChannel.whatsapp:
      case ShareChannel.sms:
        _messageController.text = _defaultMessage;
        break;
      case ShareChannel.email:
        _messageController.text =
            'Bonjour,\n\nJe vous partage ma carte de visite digitale.\n\n'
            '${widget.userName}'
            '${widget.jobTitle != null ? '\n${widget.jobTitle}' : ''}'
            '${widget.company != null ? '\n${widget.company}' : ''}'
            '\n\nLien : ${widget.shareUrl}'
            '\n\nCordialement';
        break;
      case ShareChannel.linkedin:
        _messageController.text =
            'Connectons-nous ! Voici ma carte de visite digitale : ${widget.shareUrl}';
        break;
      case ShareChannel.copy:
      case ShareChannel.other:
        _messageController.text = _defaultMessage;
        break;
    }
  }

  Future<void> _shareViaChannel(ShareChannel channel) async {
    setState(() => _isLoading = true);

    try {
      final message = _messageController.text;
      bool shared = false;

      switch (channel) {
        case ShareChannel.whatsapp:
          shared = await _shareWhatsApp(message);
          break;
        case ShareChannel.email:
          shared = await _shareEmail(message);
          break;
        case ShareChannel.sms:
          shared = await _shareSms(message);
          break;
        case ShareChannel.linkedin:
          shared = await _shareLinkedIn();
          break;
        case ShareChannel.copy:
          shared = await _copyToClipboard();
          break;
        case ShareChannel.other:
          shared = await _shareOther(message);
          break;
      }

      if (shared) {
        // Logger le partage côté backend (non bloquant)
        CardService.logShare(
          channel: channel.name,
          message: message,
        );

        if (mounted) {
          Navigator.of(context).pop(channel);
        }
      }
    } catch (e, stack) {
      debugPrint('Erreur lors du partage via canal $channel : $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _shareWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('whatsapp://send?text=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    } else {
      // Fallback vers web WhatsApp
      final webUri = Uri.parse('https://wa.me/?text=$encoded');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    }
  }

  Future<bool> _shareEmail(String message) async {
    final subject = Uri.encodeComponent('Ma carte de visite - ${widget.userName}');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('mailto:?subject=$subject&body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  Future<bool> _shareSms(String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:?body=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  Future<bool> _shareLinkedIn() async {
    final encoded = Uri.encodeComponent(widget.shareUrl);
    final uri = Uri.parse(
      'https://www.linkedin.com/sharing/share-offsite/?url=$encoded',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return true;
  }

  Future<bool> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.shareUrl));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Lien copie dans le presse-papier'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    return true;
  }

  Future<bool> _shareOther(String message) async {
    await SharePlus.instance.share(ShareParams(text: message));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                'Partager ma carte',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez comment partager votre carte',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Canaux de partage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildChannelButton(
                    ShareChannel.whatsapp,
                    FontAwesomeIcons.whatsapp,
                    'WhatsApp',
                    const Color(0xFF25D366),
                  ),
                  _buildChannelButton(
                    ShareChannel.email,
                    Icons.email_outlined,
                    'Email',
                    const Color(0xFF3B82F6),
                  ),
                  _buildChannelButton(
                    ShareChannel.sms,
                    Icons.sms_outlined,
                    'SMS',
                    const Color(0xFF8B5CF6),
                  ),
                  _buildChannelButton(
                    ShareChannel.linkedin,
                    FontAwesomeIcons.linkedin,
                    'LinkedIn',
                    const Color(0xFF0A66C2),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Zone de message personnalise
              if (_selectedChannel != null &&
                  _selectedChannel != ShareChannel.copy) ...[
                Text(
                  'Message',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton envoyer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : () => _shareViaChannel(_selectedChannel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getChannelColor(_selectedChannel!),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Envoyer via ${_getChannelName(_selectedChannel!)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Actions rapides
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      Icons.copy_outlined,
                      'Copier le lien',
                      () => _shareViaChannel(ShareChannel.copy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      Icons.more_horiz,
                      'Autres apps',
                      () => _shareViaChannel(ShareChannel.other),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelButton(
    ShareChannel channel,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSelected = _selectedChannel == channel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final defaultTextColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () => _updateMessageForChannel(channel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : colors.onSurface.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : defaultTextColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : defaultTextColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChannelColor(ShareChannel channel) {
    switch (channel) {
      case ShareChannel.whatsapp:
        return const Color(0xFF25D366);
      case ShareChannel.email:
        return const Color(0xFF3B82F6);
      case ShareChannel.sms:
        return const Color(0xFF8B5CF6);
      case ShareChannel.linkedin:
        return const Color(0xFF0A66C2);
      case ShareChannel.copy:
      case ShareChannel.other:
        return const Color(0xFF6B7280);
    }
  }

  String _getChannelName(ShareChannel channel) {
    switch (channel) {
      case ShareChannel.whatsapp:
        return 'WhatsApp';
      case ShareChannel.email:
        return 'Email';
      case ShareChannel.sms:
        return 'SMS';
      case ShareChannel.linkedin:
        return 'LinkedIn';
      case ShareChannel.copy:
        return 'Copier';
      case ShareChannel.other:
        return 'Autre';
    }
  }
}
