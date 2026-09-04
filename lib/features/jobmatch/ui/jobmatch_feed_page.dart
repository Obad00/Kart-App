import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../shared/tour/tour_prefs.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';
import '../../../shared/widgets/auth_outline_button.dart';
import '../../profile_completion/ui/skill_editor_sheet.dart';
import '../model/job_feed_item.dart';
import '../providers/jobmatch_provider.dart';
import '../widgets/job_swipe_card.dart';
import 'jobmatch_matches_page.dart';
import '../../../shared/widgets/glass_app_bar.dart';

const _accentBlue = Color(0xFF3B82F6);

class JobMatchFeedPage extends StatefulWidget {
  const JobMatchFeedPage({super.key});

  @override
  State<JobMatchFeedPage> createState() => _JobMatchFeedPageState();
}

class _JobMatchFeedPageState extends State<JobMatchFeedPage> {
  final _dashboardTourKey = GlobalKey();

  // Petite célébration (icône + retour haptique/sonore) à chaque "like" —
  // distincte de l'overlay "C'est un match !" (ça, c'est réservé à un vrai
  // match mutuel confirmé par le serveur). Purement visuelle/immédiate,
  // ne bloque rien : elle disparaît toute seule.
  JobFeedItem? _celebrating;

  void _handleLike(JobFeedItem job, JobMatchProvider provider) {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() => _celebrating = job);
    // 1300ms ne laissait pas le temps de lire "Bravo ! 🎉" + le titre de
    // l'offre avant que ça disparaisse — remonté comme "trop rapide".
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted && _celebrating?.id == job.id) {
        setState(() => _celebrating = null);
      }
    });
    provider.swipe(job, 'like');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobMatchProvider>().loadFeed();
      _maybeStartTour();
    });
  }

  Future<void> _maybeStartTour() async {
    if (!mounted || await TourPrefs.hasSeen('jobmatch_feed')) return;

    await TourPrefs.markSeen('jobmatch_feed');
    if (!mounted) return;

    ShowCaseWidget.of(context).startShowCase([_dashboardTourKey]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobMatchProvider>();
    final colors = Theme.of(context).colorScheme;

    final glassAppBar = GlassAppBar(
      title: const Text(
        'Offres pour vous',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
      ),
      actions: [
        Showcase(
          key: _dashboardTourKey,
          title: 'Votre tableau de bord',
          description:
              'Retrouvez ici vos matchs, les offres aimées et celles passées.',
          targetShapeBorder: const CircleBorder(),
          child: IconButton(
            icon: const Icon(Icons.favorite_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JobMatchMatchesPage()),
            ),
          ),
        ),
      ],
    );

    // GlassAppBar est autonome (pas besoin d'un Scaffold.appBar) : hauteur
    // totale (statut + toolbar) réservée manuellement en haut du contenu,
    // comme sur Explorer.
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    // Pas de Scaffold ici : HomeShell en possède déjà un pour toute la
    // navigation (fond colorScheme.surface unique). GlassAppBar est posé
    // par-dessus via Positioned.
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(top: topPadding),
          // top:false : déjà réservé ci-dessus. bottom:false : la pilule de
          // nav flottante de HomeShell (+ safe area) est protégée dans
          // _buildCardStack, sinon les boutons Aimer/Rejeter finissent
          // dessous.
          child: SafeArea(
            top: false,
            bottom: false,
            child: Stack(
              children: [
                if (provider.loading)
                  const Center(child: CircularProgressIndicator())
                else if (provider.feed.isEmpty)
                  _buildEmptyState(context, colors)
                else
                  _buildCardStack(context, provider),
                if (provider.lastMatch != null)
                  _buildMatchOverlay(context, provider),
                // AnimatedSwitcher : fondu à l'apparition ET à la
                // disparition, au lieu d'un "pop"/disparition brutale quand
                // _celebrating repasse à null.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _celebrating != null
                      ? _buildLikedCelebration(_celebrating!)
                      : const SizedBox.shrink(key: ValueKey('no-celebration')),
                ),
              ],
            ),
          ),
        ),
        // SizedBox(height: topPadding) est indispensable : sans lui, ce
        // Positioned (top/left/right seuls, pas de bottom) donne à
        // GlassAppBar une hauteur non contrainte et son AppBar interne
        // plante en layout — cf. la même note dans explore_page.dart.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(height: topPadding, child: glassAppBar),
        ),
      ],
    );
  }

  Widget _buildCardStack(BuildContext context, JobMatchProvider provider) {
    final feed = provider.feed;
    final topJob = feed.first;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + BottomNavMetrics.reservedHeight,
      ),
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
                onTap: () => _handleLike(topJob, provider),
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
          onLike: () => _handleLike(job, provider),
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
              child: const Icon(Icons.work_outline_rounded,
                  size: 40, color: _accentBlue),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune offre pour le moment',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des compétences à votre profil pour recevoir des suggestions d\'offres correspondantes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const SkillEditorSheet(),
                );
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Ajouter des compétences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                // fontFamily explicite : sans lui, ce textStyle remplace le
                // DefaultTextStyle ambiant du thème (Syne) par la police
                // système par défaut — cf. même correctif sur ProfilePage.
                textStyle: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                '${match.jobTitle} · ${match.companyName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.white70),
              ),
              const SizedBox(height: 36),
              // Empilés (plutôt que côte à côte) : deux boutons "expanded"
              // dans une Row débordaient sur la plupart des téléphones
              // (chacun a une largeur minimale de 200px, largement plus que
              // ce que la moitié d'un écran standard peut offrir).
              Column(
                children: [
                  AuthPrimaryButton(
                    label: 'Voir mes matchs',
                    onTap: () {
                      provider.dismissMatch();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const JobMatchMatchesPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthOutlineButton(
                    label: 'Continuer',
                    onTap: () => provider.dismissMatch(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Petite célébration immédiate au like — pas bloquante, disparaît toute
  /// seule (contrairement à l'overlay de match, qu'il faut fermer).
  Widget _buildLikedCelebration(JobFeedItem job) {
    return IgnorePointer(
      key: ValueKey(job.id),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value.clamp(0.0, 1.3),
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration_rounded,
                    color: Colors.white, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'Bravo ! 🎉',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Vous avez aimé l'offre",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  job.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
