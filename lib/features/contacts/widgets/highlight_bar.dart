import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/highlight_provider.dart';
import '../models/highlight_model.dart';

class HighlightBar extends StatelessWidget {
  const HighlightBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HighlightProvider>();

    if (provider.isLoading) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: provider.highlights.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          if (index == 0) return const _AddHighlightButton();

          final highlight = provider.highlights[index - 1];
          return _HighlightItem(highlight: highlight);
        },
      ),
    );
  }
}

class _HighlightItem extends StatelessWidget {
  final HighlightModel highlight;

  const _HighlightItem({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HighlightProvider>();

    return GestureDetector(
onTap: () => provider.toggleHighlight(highlight),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: highlight.isActive
                  ? const LinearGradient(
                      colors: [Color(0xFFE1306C), Color(0xFFF77737)],
                    )
                  : null,
              border: Border.all(
                color: highlight.isActive
                    ? Colors.transparent
                    : Colors.white24,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF121212),
              ),
              alignment: Alignment.center,
              child: Text(
                highlight.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              highlight.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddHighlightButton extends StatelessWidget {
  const _AddHighlightButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCreateHighlightModal(context),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text('Nouveau', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

void _openCreateHighlightModal(BuildContext context) {
  final controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nouveau highlight',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: controller,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: 'Ex: Salon Dakar 2026',
                filled: true,
                fillColor: Colors.white.withAlpha(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
               onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;

                  // ✅ capturer AVANT l'await
                  final provider = context.read<HighlightProvider>();
                  final navigator = Navigator.of(context);

                  await provider.createHighlight(name);

                  if (navigator.mounted) {
                    navigator.pop();
                  }
                },
                child: const Text('Créer'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
