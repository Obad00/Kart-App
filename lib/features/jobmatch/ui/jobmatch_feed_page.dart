import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/auth_outline_button.dart';
import '../../profile_completion/ui/skill_editor_sheet.dart';
import '../providers/jobmatch_provider.dart';
import '../widgets/job_swipe_card.dart';
import 'jobmatch_matches_page.dart';

const _accentBlue = Color(0xFF3B82F6);

class JobMatchFeedPage extends StatefulWidget {
  const JobMatchFeedPage({super.key});

  @override
  State<JobMatchFeedPage> createState() => _JobMatchFeedPageState();
}

class _JobMatchFeedPageState extends State<JobMatchFeedPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobMatchProvider>().loadFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobMatchProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Offres pour vous',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobMatchMatchesPage()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (provider.loading)
            const Center(child: CircularProgressIndicator())
          else if (provider.feed.isEmpty)
            _buildEmptyState(context, colors)
          else
            _buildCardStack(context, provider),

          if (provider.lastMatch != null) _buildMatchOverlay(context, provider),
        ],
      ),
    );
  }

  Widget _buildCardStack(BuildContext context, JobMatchProvider provider) {
    final feed = provider.feed;
    final topJob = feed.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          Expanded(child: _buildStack(provider, feed)),
          const SizedBox(height: 20),
          // Boutons explicites en complément du glissement — plus simple à
          // utiliser à la souris/trackpad (Flutter Web) qu'un seuil de drag.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.close_rounded,
                color: Colors.red,
                onTap: () => provider.swipe(topJob, 'reject'),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.favorite_rounded,
                color: Colors.green,
                onTap: () => provider.swipe(topJob, 'like'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _buildStack(JobMatchProvider provider, List feed) {
    return Stack(
      alignment: Alignment.center,
      children: feed.take(3).toList().reversed.map((job) {
        final isTop = job.id == feed.first.id;

        if (!isTop) {
          return IgnorePointer(
            child: Opacity(
              opacity: 0.5,
              child: JobSwipeCard(job: job, onLike: () {}, onReject: () {}),
            ),
          );
        }

        return JobSwipeCard(
          key: ValueKey(job.id),
          job: job,
          onLike: () => provider.swipe(job, 'like'),
          onReject: () => provider.swipe(job, 'reject'),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accentBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_outline_rounded, size: 40, color: _accentBlue),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune offre pour le moment',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des compétences à votre profil pour recevoir des suggestions d\'offres correspondantes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Ajouter des compétences',
              expanded: false,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const SkillEditorSheet(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchOverlay(BuildContext context, JobMatchProvider provider) {
    final match = provider.lastMatch!;

    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite_rounded, color: _accentBlue, size: 56),
              const SizedBox(height: 20),
              const Text(
                "C'est un match !",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                '${match.jobTitle} · ${match.companyName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthOutlineButton(
                    label: 'Continuer',
                    expanded: false,
                    onTap: () => provider.dismissMatch(),
                  ),
                  const SizedBox(width: 14),
                  AuthPrimaryButton(
                    label: 'Voir mes matchs',
                    expanded: false,
                    onTap: () {
                      provider.dismissMatch();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const JobMatchMatchesPage()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
