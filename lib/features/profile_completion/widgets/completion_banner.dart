import 'package:flutter/material.dart';
import '../helpers/completion_helper.dart';
import '../providers/profile_completion_provider.dart';
import '../ui/completion_checklist_page.dart';
import 'package:provider/provider.dart';

class CompletionBanner extends StatelessWidget {
  const CompletionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileCompletionProvider>();
    final result = CompletionHelper.calculate(provider.model);

    if (result.percent >= 100) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🚀 Complétez votre profil",
              style: TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),

          Text("Profil à ${result.percent.toInt()}%"),

          const SizedBox(height: 10),

          LinearProgressIndicator(value: result.percent / 100),

          const SizedBox(height: 10),

          Wrap(
            spacing: 6,
            children: result.missing.map((e) => Chip(label: Text(e))).toList(),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompletionChecklistPage(),
                ),
              );
            },
            child: const Text("Compléter"),
          )
        ],
      ),
    );
  }
}
