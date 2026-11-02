import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../services/event_qr_cards_service.dart';

/// QR de l'événement en 5 modèles : aperçu, puis partage (enregistrer,
/// imprimer, envoyer) en PNG ou en PDF.
class EventQrModelsPage extends StatefulWidget {
  final int eventId;
  final String eventName;
  final EventQrCardsService? service;

  const EventQrModelsPage({super.key, required this.eventId, required this.eventName, this.service});

  @override
  State<EventQrModelsPage> createState() => _EventQrModelsPageState();
}

class _EventQrModelsPageState extends State<EventQrModelsPage> {
  late final EventQrCardsService _service = widget.service ?? EventQrCardsService();
  final Map<String, Uint8List> _previews = {};
  final Set<String> _failed = {};
  String? _busy;

  @override
  void initState() {
    super.initState();
    for (final model in EventQrCardsService.models) {
      _loadPreview(model.key);
    }
  }

  Future<void> _loadPreview(String key) async {
    try {
      final bytes = await _service.fetch(widget.eventId, key);
      if (mounted) setState(() => _previews[key] = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed.add(key));
    }
  }

  Future<void> _share(EventQrModel model, String format) async {
    setState(() => _busy = '${model.key}-$format');
    try {
      final bytes = format == 'png' && _previews[model.key] != null
          ? _previews[model.key]!
          : await _service.fetch(widget.eventId, model.key, format: format);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/qr-evenement-${model.key}.$format');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: format == 'pdf' ? 'application/pdf' : 'image/png')],
        subject: 'QR de check-in · ${widget.eventName}',
      ));
    } catch (_) {
      if (mounted) {
        FeedbackOverlay.showError(context,
            title: 'Partage impossible', subtitle: "Le QR n'a pas pu être préparé. Réessayez dans un instant.");
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appBar = GlassAppBar(title: const Text("QR de l'événement"));
    final top = appBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 32),
            children: [
              Text(
                "À imprimer ou afficher à l'accueil : scanné avec l'appareil photo, il enregistre la présence.",
                style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              for (final model in EventQrCardsService.models) _modelCard(model, colors),
            ],
          ),
          Positioned(top: 0, left: 0, right: 0, child: SizedBox(height: top, child: appBar)),
        ],
      ),
    );
  }

  Widget _modelCard(EventQrModel model, ColorScheme colors) {
    final preview = _previews[model.key];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 136,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: preview != null
                  ? Image.memory(preview, fit: BoxFit.contain)
                  : Center(
                      child: _failed.contains(model.key)
                          ? Icon(Icons.qr_code_2_rounded, color: colors.onSurface.withValues(alpha: 0.3))
                          : const CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.label,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 2),
                Text(model.hint, style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.55))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final format in ['png', 'pdf'])
                      OutlinedButton.icon(
                        onPressed: _busy == null ? () => _share(model, format) : null,
                        icon: _busy == '${model.key}-$format'
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.ios_share_rounded, size: 16),
                        label: Text(format.toUpperCase()),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
