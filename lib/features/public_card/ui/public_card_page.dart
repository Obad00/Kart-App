import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:dio/dio.dart';
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

  final List<String> exampleMessages = [
    "Ravi de vous rencontrer ! 🤝",
    "Merci pour cet échange enrichissant",
    "Restons en contact 📲",
    "Au plaisir de collaborer ensemble",
  ];

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

  // =============================
  // WORKFLOWS RELANCE & EMAIL
  // =============================

  void _showSnackBar({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _shareContact({
    required String slug,
    required String message,
    required String ownerName,
    required void Function(bool value) setLoading,
  }) async {
    if (slug.isEmpty) {
      _showSnackBar(
        title: 'Carte introuvable',
        subtitle: 'Cette carte n\'a pas de slug associé.',
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
      return;
    }

    setLoading(true);

    try {
      // await ContactsProvider().shareContact(slug: slug, message: message.trim().isNotEmpty ? message.trim() : null);
      
      // Simuler l'appel API (remplacer par votre vraie logique)
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      
      _showSnackBar(
        title: 'Envoyé',
        subtitle: 'Votre carte a été envoyée à $ownerName',
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      );
    } on DioException catch (e) {
      String errorMessage = 'Échec de l\'envoi';

      if (e.response?.statusCode == 500) {
        errorMessage = 'Erreur du serveur. Veuillez réessayer plus tard.';
      } else if (e.response?.statusCode == 422) {
        errorMessage = 'Données invalides.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Carte introuvable';
      } else if (e.response?.data is Map) {
        final message = e.response?.data['message'];
        if (message != null) {
          errorMessage = message.toString();
        }
      }

      _showSnackBar(
        title: 'Erreur d\'envoi',
        subtitle: errorMessage,
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
    } catch (e) {
      _showSnackBar(
        title: 'Erreur',
        subtitle: 'Une erreur inattendue s\'est produite',
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) setLoading(false);
    }
  }

  void _openShareContactPopup() {
    final ownerName = card?['fullname']?.toString() ?? 'le propriétaire';
    final email = _getFieldValue('email');
    final phone = _getFieldValue('phone').isNotEmpty
        ? _getFieldValue('phone')
        : _getFieldValue('telephone').isNotEmpty
            ? _getFieldValue('telephone')
            : _getFieldValue('mobile');
    
    final messageController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Relancer le contact',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Renvoyer votre carte',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Contact Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.person_rounded, 'Nom', ownerName),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.email_rounded, 'Email', email),
                          ],
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.phone_rounded, 'Téléphone', phone),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Optional message
                    Text(
                      "Message personnalisé (optionnel)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: messageController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: "Ajoutez un message personnel...",
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    await _shareContact(
                                      slug: widget.slug,
                                      message: messageController.text.trim(),
                                      ownerName: ownerName,
                                      setLoading: (value) =>
                                          setDialogState(() => isLoading = value),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded,
                                          size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Envoyer',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
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
    );
  }

  void _openEmailPopup(String contactEmail) {
    final messageController = TextEditingController();
    final selectedExampleNotifier = ValueNotifier<String?>(null);
    bool isSending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> sendEmail() async {
            final content = messageController.text.trim();

            if (content.isEmpty) {
              _showSnackBar(
                title: 'Attention',
                subtitle: 'Le message ne peut pas être vide',
                icon: Icons.warning_rounded,
                iconColor: Colors.orange,
              );
              return;
            }

            setDialogState(() => isSending = true);

            try {
              // await ContactsProvider().sendMessage(...)
              
              // Simuler l'envoi
              await Future.delayed(const Duration(seconds: 1));

              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();

              if (!mounted) return;
              _showSnackBar(
                title: 'Message envoyé',
                subtitle: 'Votre message a été envoyé avec succès',
                icon: Icons.check_circle_rounded,
                iconColor: Colors.green,
              );

              messageController.clear();
            } catch (e) {
              if (!mounted) return;
              _showSnackBar(
                title: 'Erreur',
                subtitle: 'Une erreur est survenue lors de l\'envoi',
                icon: Icons.error_rounded,
                iconColor: Colors.red,
              );
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isSending = false);
              }
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                  const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF3B82F6),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Envoyer un message',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isSending
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Message Field
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: messageController,
                          maxLines: 5,
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: "Écrivez votre message...",
                            hintStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Examples Section
                      Text(
                        "Suggestions",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...exampleMessages.map((msg) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: selectedExampleNotifier,
                          builder: (context, selected, _) {
                            final isSelected = selected == msg;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    selectedExampleNotifier.value = msg;
                                    messageController.text = msg;
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.1)
                                          : Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF3B82F6)
                                                .withValues(alpha: 0.3)
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.08),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? const Color(0xFF3B82F6)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                          ),
                                          child: isSelected
                                              ? Center(
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFF3B82F6),
                                                    ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            msg,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? const Color(0xFF3B82F6)
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isSending
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Annuler',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isSending ? null : sendEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send_rounded,
                                            size: 18, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Envoyer',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon,
            size: 18, color: const Color(0xFF3B82F6).withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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

  String _getFirstName() {
    final fullName = card?['fullname']?.toString().trim() ?? '';
    if (fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  String _getFieldValue(String key) {
    final rawFields = card?['fields'];
    if (rawFields == null) return '';

    if (rawFields is Map<String, dynamic>) {
      final value = rawFields[key];
      if (value is String && value.isNotEmpty) return value.trim();
      if (value != null && value.toString().isNotEmpty) {
        return value.toString().trim();
      }
      return '';
    }

    if (rawFields is Map) {
      final value = rawFields[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString().trim();
      }
      return '';
    }

    debugPrint(
        '_getFieldValue($key) fields is not a Map: ${rawFields.runtimeType}');
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

  Future<void> _openEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openPhone(String phone) async {
    if (phone.isEmpty) return;
    final sanitizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: sanitizedPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final email = _getFieldValue('email');
    final phone = _getFieldValue('phone').isNotEmpty
        ? _getFieldValue('phone')
        : _getFieldValue('telephone').isNotEmpty
            ? _getFieldValue('telephone')
            : _getFieldValue('mobile');
    final location = _getFieldValue('location');
    final firstName = _getFirstName();
    final skills = _skillsList();
    final experiences = _getExperiences();
    final educations = _getEducations();
    final socialProfiles = _socialProfiles();
    final portraitUrl = card?['avatar_url']?.toString() ?? '';
    final fullName = card?['fullname']?.toString() ?? '';
    final jobTitle = card?['job_title']?.toString() ?? '';
    final company = card?['company']?.toString() ?? '';

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(
              isDark ? Colors.white : const Color(0xFF2563EB),
            ),
          ),
        ),
      );
    }

    if (card == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            'Carte non trouvée',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(
                          isDark: isDark,
                          fullName: fullName,
                          jobTitle: jobTitle,
                          company: company,
                          location: location,
                          email: email,
                          phone: phone,
                          avatarUrl: portraitUrl,
                        ),
                        _buildSectionDivider(),
                        _buildCallToActions(
                          email: email,
                          firstName: firstName,
                        ),
                        const SizedBox(height: 18),
                        _buildSecondaryActions(
                          socialProfiles: socialProfiles,
                        ),
                        if (socialProfiles.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildSocialNetworks(socialProfiles),
                        ],
                        if (_getFieldValue('bio').isNotEmpty) ...[
                          _buildSectionDivider(),
                          _buildAbout(isDark),
                        ],
                        if (skills.isNotEmpty) ...[
                          _buildSectionDivider(),
                          _buildSkills(isDark, skills),
                        ],
                        _buildSectionDivider(),
                        _buildExperienceTimeline(isDark, experiences),
                        _buildSectionDivider(),
                        _buildEducation(isDark, educations),
                        const SizedBox(height: 12),
                      ],
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

  Widget _buildHero({
    required bool isDark,
    required String fullName,
    required String jobTitle,
    required String company,
    required String location,
    required String email,
    required String phone,
    required String avatarUrl,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final chipBackground =
        isDark ? const Color(0xFF111827) : const Color(0xFFF0FDF4);
    final chipBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFDCFCE7);
    final avatarBackground =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final avatarTextColor =
        isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: titleColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipBorder),
          ),
          child: Text(
            'OUVERT AUX OPPORTUNITÉS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF2563EB) : const Color(0xFF166534),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ROLE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              jobTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMPANY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (location.isNotEmpty ||
                      email.isNotEmpty ||
                      phone.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (email.isNotEmpty || phone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (email.isNotEmpty)
                            _buildInlineContactChip(
                              icon: Icons.email_outlined,
                              label: email,
                              onTap: () => _openEmail(email),
                              titleColor: titleColor,
                              borderColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE5E7EB),
                            ),
                          if (phone.isNotEmpty)
                            _buildInlineContactChip(
                              icon: Icons.phone_outlined,
                              label: phone,
                              onTap: () => _openPhone(phone),
                              titleColor: titleColor,
                              borderColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE5E7EB),
                            ),
                        ],
                      ),
                      // ✅ NOUVEAU BOUTON RELANCER AJOUTÉ ICI
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openShareContactPopup,
                          icon: const Icon(Icons.send_outlined, size: 18),
                          label: const Text(
                            'Relancer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE5E7EB),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: avatarBackground,
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(
                      _getInitials(fullName),
                      style: TextStyle(
                        color: avatarTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineContactChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color titleColor,
    required Color borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallToActions({
    required String email,
    required String firstName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            if (email.isNotEmpty) {
              _openEmailPopup(email); // ✅ Ouvre la popup d'envoi de message
            } else {
              _showContactForm();
            }
          },
          icon: const Icon(Icons.mail_outline, size: 18),
          label: Text(
            'Contacter${firstName.isNotEmpty ? ' $firstName' : ''}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions({
    required List<Map<String, dynamic>> socialProfiles,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final foregroundColor = isDark ? Colors.white : const Color(0xFF111827);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showContactForm,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text(
              'Partager',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showFollowOptions(socialProfiles),
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Follow',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialNetworks(List<Map<String, dynamic>> socialProfiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réseaux sociaux',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: socialProfiles.map((profile) {
            return OutlinedButton.icon(
              onPressed: () => _openUrl(profile['value'] as String),
              icon: Icon(
                profile['icon'] as IconData,
                color: profile['iconColor'] as Color,
                size: 16,
              ),
              label: Text(
                profile['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: titleColor,
                side: BorderSide(color: borderColor),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showFollowOptions(List<Map<String, dynamic>> profiles) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final titleColor = isDark ? Colors.white : const Color(0xFF111827);
        final subtitleColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
        final dividerColor =
            isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6);
        final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          color: backgroundColor,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewPadding.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suivre sur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                if (profiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Aucun réseau social disponible.',
                      style: TextStyle(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                  )
                else
                  ...profiles.map((profile) {
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: (profile['bgColor'] as Color)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                profile['icon'] as IconData,
                                color: profile['iconColor'] as Color,
                                size: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            profile['label'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          subtitle: Text(
                            profile['value'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                          ),
                          onTap: () => _openUrl(profile['value'] as String),
                        ),
                        if (profiles.indexOf(profile) != profiles.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: dividerColor,
                          ),
                      ],
                    );
                  }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbout(bool isDark) {
    final bio = _getFieldValue('bio');
    if (bio.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A propos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          bio,
          style: TextStyle(
            fontSize: 14,
            height: 1.7,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildSkills(bool isDark, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compétences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceTimeline(bool isDark, List<dynamic> experiences) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final textColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final iconColor =
        isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_outline, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              'Experience',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (experiences.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Aucune expérience',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ] else ...[
          Column(
            children: experiences.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value as Map? ?? {};
              final title = item['title']?.toString() ?? '';
              final company = item['company']?.toString() ?? '';
              final startDate = item['start_date']?.toString() ?? '';
              final endDate = item['end_date']?.toString() ?? '';
              final description = item['description']?.toString() ?? '';
              final isLast = index == experiences.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Column(
                        children: [
                          if (index != 0)
                            Container(
                              width: 1,
                              height: 18,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF3F4F6),
                            ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 1,
                              height: 60,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF3F4F6),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          if (company.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            endDate.isNotEmpty
                                ? '$startDate — $endDate'
                                : '$startDate — Present',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEducation(bool isDark, List<dynamic> educations) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final textColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final accentColor =
        isDark ? const Color(0xFF2563EB) : const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_outlined, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'Education',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (educations.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Aucune éducation',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ] else ...[
          Column(
            children: educations.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value as Map? ?? {};
              final degree = item['degree']?.toString() ?? '';
              final school = item['school']?.toString() ?? '';
              final field = item['field']?.toString() ?? '';
              final startYear = item['start_year']?.toString() ?? '';
              final endYear = item['end_year']?.toString() ?? '';
              final isLast = index == educations.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      degree,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      school,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (field.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              field,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (field.isNotEmpty) const SizedBox(width: 10),
                        Text(
                          '$startYear — $endYear',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
      ),
    );
  }

  List<String> _skillsList() {
    return _getFieldValue('skills')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _socialProfiles() {
    final profiles = <Map<String, dynamic>>[];

    if (_getFieldValue('linkedin').isNotEmpty) {
      profiles.add({
        'label': 'LinkedIn',
        'icon': FontAwesome.linkedin_brand,
        'value': _getFieldValue('linkedin'),
        'bgColor': const Color(0xFFE8F0FE),
        'iconColor': const Color(0xFF0A66C2),
      });
    }
    if (_getFieldValue('x').isNotEmpty) {
      profiles.add({
        'label': 'X',
        'icon': FontAwesome.x_twitter_brand,
        'value': _getFieldValue('x'),
        'bgColor': const Color(0xFFF3F4F6),
        'iconColor': const Color(0xFF000000),
      });
    }
    if (_getFieldValue('instagram').isNotEmpty) {
      profiles.add({
        'label': 'Instagram',
        'icon': FontAwesome.instagram_brand,
        'value': _getFieldValue('instagram'),
        'bgColor': const Color(0xFFFCE7F3),
        'iconColor': const Color(0xFFE4405F),
      });
    }
    if (_getFieldValue('facebook').isNotEmpty) {
      profiles.add({
        'label': 'Facebook',
        'icon': FontAwesome.facebook_brand,
        'value': _getFieldValue('facebook'),
        'bgColor': const Color(0xFFEAF2FF),
        'iconColor': const Color(0xFF1877F2),
      });
    }
    if (_getFieldValue('github').isNotEmpty) {
      profiles.add({
        'label': 'GitHub',
        'icon': FontAwesome.github_brand,
        'value': _getFieldValue('github'),
        'bgColor': const Color(0xFFF3F4F6),
        'iconColor': const Color(0xFF111827),
      });
    }
    if (_getFieldValue('website').isNotEmpty) {
      profiles.add({
        'label': 'Website',
        'icon': FontAwesome.globe_solid,
        'value': _getFieldValue('website'),
        'bgColor': const Color(0xFFEFF6FF),
        'iconColor': const Color(0xFF2563EB),
      });
    }

    final phone = _getFieldValue('phone');
    final ownerName = card?['fullname']?.toString() ?? '';

    if (phone.isNotEmpty) {
      final formattedPhone = phone.replaceAll(RegExp(r'\D'), '');

      profiles.add({
        'label': 'WhatsApp',
        'icon': FontAwesome.whatsapp_brand,
        'value': 'https://wa.me/$formattedPhone?text=Bonjour%20$ownerName',
        'bgColor': const Color(0xFFE7FCEB),
        'iconColor': const Color(0xFF25D366),
      });
    }

    return profiles;
  }

  List<dynamic> _getExperiences() {
    final experiences = card?['experiences'];
    if (experiences is List) return experiences;
    return [];
  }

  List<dynamic> _getEducations() {
    final educations = card?['educations'];
    if (educations is List) return educations;
    return [];
  }
}