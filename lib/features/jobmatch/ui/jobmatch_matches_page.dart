import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../shared/tour/tour_prefs.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../jobmatch_theme.dart';
import '../model/job_feed_item.dart';
import '../providers/jobmatch_provider.dart';
import '../services/jobmatch_service.dart';
import 'job_detail_page.dart';

const _accentBlue = jobMatchAccent;

class JobMatchMatchesPage extends StatefulWidget {
  /// Onglet ouvert au premier affichage (0 = Matchs, 1 = Aimées, 2 =
  /// Passées, 3 = Sauvegardées) — permet par ex. au deep link
  /// `kart://jobmatch/liked` de pointer directement sur l'onglet "Aimées".
  /// Sauvegardées est en 4e position (pas insérée entre Matchs et Aimées
  /// comme sur la maquette fournie) pour ne pas décaler les index déjà
  /// utilisés par ces liens.
  final int initialTabIndex;

  const JobMatchMatchesPage({super.key, this.initialTabIndex = 0});

  @override
  State<JobMatchMatchesPage> createState() => _JobMatchMatchesPageState();
}

class _JobMatchMatchesPageState extends State<JobMatchMatchesPage>
    with SingleTickerProviderStateMixin {
  final _service = JobMatchService();
  late final TabController _tabController;
  final _tabsTourKey = GlobalKey();
  List<JobMatchResult> _matches = [];
  List<LikedJobItem> _liked = [];
  List<LikedJobItem> _rejected = [];
  // "Sauvegardées" — ajouté en 4e position plutôt qu'inséré entre Matchs et
  // Aimées (comme sur la maquette) : ça aurait décalé les index 1/2 déjà
  // utilisés par les deep links kart://jobmatch/liked et /matches.
  List<LikedJobItem> _saved = [];
  JobMatchSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  Future<void> _maybeStartTour() async {
    if (!mounted || await TourPrefs.hasSeen('jobmatch_matches')) return;

    await TourPrefs.markSeen('jobmatch_matches');
    if (!mounted) return;

    ShowCaseWidget.of(context).startShowCase([_tabsTourKey]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchMatches(),
        _service.fetchLiked(),
        _service.fetchRejected(),
        _service.fetchSummary(),
        _service.fetchSaved(),
      ]);
      _matches = results[0] as List<JobMatchResult>;
      _liked = results[1] as List<LikedJobItem>;
      _rejected = results[2] as List<LikedJobItem>;
      _summary = results[3] as JobMatchSummary;
      _saved = results[4] as List<LikedJobItem>;
    } catch (_) {
      // silencieux : listes vides affichées par défaut
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _unsave(LikedJobItem job) async {
    // Optimiste : retiré de la liste tout de suite, remis si l'appel échoue
    // — cohérent avec JobMatchProvider.toggleSave() côté fil de suggestions.
    setState(() => _saved.removeWhere((s) => s.jobId == job.jobId));
    try {
      await _service.unsaveJob(job.jobId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saved.add(job));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur, réessayez')),
      );
    }
  }

  void _openMatchDetail(JobMatchResult match) {
    showJobDetailSheet(
      context,
      title: match.jobTitle,
      companyName: match.companyName,
      companyLogo: match.companyLogo,
      location: match.location,
      isRemote: match.isRemote,
      contractType: match.contractType,
      salaryMin: match.salaryMin,
      salaryMax: match.salaryMax,
      experienceRequired: match.experienceRequired,
      description: match.description,
      publishedAt: match.publishedAt,
      skills: match.skills,
      score: match.score,
    );
  }

  void _openJobDetail(LikedJobItem job) {
    showJobDetailSheet(
      context,
      title: job.jobTitle,
      companyName: job.companyName,
      companyLogo: job.companyLogo,
      location: job.location,
      isRemote: job.isRemote,
      contractType: job.contractType,
      salaryMin: job.salaryMin,
      salaryMax: job.salaryMax,
      experienceRequired: job.experienceRequired,
      description: job.description,
      publishedAt: job.publishedAt,
      skills: job.skills,
    );
  }

  /// Retire un "j'aime" — l'offre redevient éligible au fil de suggestions,
  /// exactement comme _reconsider() pour un rejet (même endpoint générique
  /// côté backend : DELETE sur le swipe, quel que soit son type).
  Future<void> _removeLike(LikedJobItem job) async {
    try {
      await _service.unswipe(job.jobId);
      if (!mounted) return;
      setState(() => _liked.removeWhere((l) => l.jobId == job.jobId));
      // Sans ça, l'offre ne réapparaissait dans le fil de suggestions
      // (JobMatchProvider, une instance globale et durable) qu'après un
      // redémarrage complet de l'app.
      if (mounted) context.read<JobMatchProvider>().loadFeed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"J\'aime" retiré de ${job.jobTitle}')),
      );
    } catch (e) {
      // Erreur non identifiée statiquement (l'endpoint DELETE est
      // pourtant générique et identique pour un rejet ou un "j'aime") —
      // logguée en clair pour pouvoir enfin la diagnostiquer si elle se
      // reproduit.
      debugPrint('⚠️ Échec unswipe: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur, réessayez')),
      );
    }
  }

  Future<void> _reconsider(LikedJobItem job) async {
    try {
      await _service.unswipe(job.jobId);
      if (!mounted) return;
      setState(() => _rejected.removeWhere((r) => r.jobId == job.jobId));
      // Sans ça, l'offre ne réapparaissait dans le fil de suggestions
      // (JobMatchProvider, une instance globale et durable, pas recréée à
      // chaque ouverture de ce tableau de bord) qu'après un redémarrage
      // complet de l'app — ce qui donnait l'impression que "reconsidérer"
      // ne marchait pas vraiment.
      if (mounted) context.read<JobMatchProvider>().loadFeed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${job.jobTitle} est de retour dans votre fil')),
      );
    } catch (e) {
      // Erreur non identifiée statiquement (l'endpoint DELETE est
      // pourtant générique et identique pour un rejet ou un "j'aime") —
      // logguée en clair pour pouvoir enfin la diagnostiquer si elle se
      // reproduit.
      debugPrint('⚠️ Échec unswipe: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur, réessayez')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: GlassAppBar(
        title: const Text('Mon tableau de bord'),
        // Même pilule "segmented control" que l'onglet Explorer, pour une
        // apparence cohérente entre les deux pages à onglets de l'app.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Showcase(
            key: _tabsTourKey,
            title: 'Vos offres',
            description:
                'Matchs mutuels, offres aimées, et offres passées que vous pouvez reconsidérer.',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Container(
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _accentBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  splashBorderRadius: BorderRadius.circular(999),
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
                  // 11.5 plutôt que 13 : avec le 4e onglet (Sauvegardées),
                  // "Sauvées" à la taille d'origine tronquait/débordait
                  // dans la pilule à largeur égale.
                  labelStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Matchs'),
                    Tab(text: 'Aimées'),
                    Tab(text: 'Passées'),
                    Tab(text: 'Sauvées'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_summary != null) _buildSummaryRow(colors, _summary!),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMatchesList(colors),
                      _buildLikedList(colors),
                      _buildRejectedList(colors),
                      _buildSavedList(colors),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(ColorScheme colors, JobMatchSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
              child: _buildStat('Matchs', summary.matches, Colors.green, colors,
                  tabIndex: 0)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildStat('Aimées', summary.liked, _accentBlue, colors,
                  tabIndex: 1)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildStat(
                  'Passées', summary.rejected, Colors.orange, colors,
                  tabIndex: 2)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildStat(
                  'Sauvées', summary.saved, Colors.amber.shade700, colors,
                  tabIndex: 3)),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    int value,
    Color color,
    ColorScheme colors, {
    required int tabIndex,
  }) {
    return InkWell(
      // Tape la stat = bascule directement sur l'onglet correspondant, au
      // lieu de forcer à chercher le bon onglet dans le TabBar juste
      // au-dessus — sans onTap ici, cette rangée entière était purement
      // décorative.
      onTap: () => _tabController.animateTo(tabIndex),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(ColorScheme colors) {
    if (_matches.isEmpty) {
      return _buildEmpty(colors, 'Aucun match pour l\'instant');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final match = _matches[index];
        return _buildRow(
          colors,
          icon: Icons.favorite,
          iconColor: Colors.green,
          title: match.jobTitle,
          subtitle: match.companyName,
          trailing: '${match.score}%',
          onTap: () => _openMatchDetail(match),
        );
      },
    );
  }

  Widget _buildLikedList(ColorScheme colors) {
    if (_liked.isEmpty) {
      return _buildEmpty(colors, 'Aucune offre aimée pour l\'instant');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _liked.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final liked = _liked[index];
        return _buildRow(
          colors,
          icon: Icons.thumb_up_alt_rounded,
          iconColor: _accentBlue,
          title: liked.jobTitle,
          subtitle: liked.companyName,
          trailingWidget: IconButton(
            icon: const Icon(Icons.close_rounded),
            color: colors.onSurface.withValues(alpha: 0.4),
            tooltip: 'Retirer le j\'aime',
            onPressed: () => _removeLike(liked),
          ),
          onTap: () => _openJobDetail(liked),
        );
      },
    );
  }

  Widget _buildEmpty(ColorScheme colors, String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildRejectedList(ColorScheme colors) {
    if (_rejected.isEmpty) {
      return _buildEmpty(colors, 'Aucune offre passée pour l\'instant');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _rejected.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = _rejected[index];
        return _buildRow(
          colors,
          icon: Icons.close_rounded,
          iconColor: colors.onSurface.withValues(alpha: 0.4),
          title: job.jobTitle,
          subtitle: job.companyName,
          trailingWidget: TextButton(
            onPressed: () => _reconsider(job),
            child: const Text('Reconsidérer'),
          ),
          onTap: () => _openJobDetail(job),
        );
      },
    );
  }

  Widget _buildSavedList(ColorScheme colors) {
    if (_saved.isEmpty) {
      return _buildEmpty(colors, 'Aucune offre sauvegardée pour l\'instant');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _saved.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final job = _saved[index];
        return _buildRow(
          colors,
          icon: Icons.star_rounded,
          iconColor: Colors.amber.shade700,
          title: job.jobTitle,
          subtitle: job.companyName,
          trailingWidget: IconButton(
            icon: const Icon(Icons.close_rounded),
            color: colors.onSurface.withValues(alpha: 0.4),
            tooltip: 'Retirer des sauvegardes',
            onPressed: () => _unsave(job),
          ),
          onTap: () => _openJobDetail(job),
        );
      },
    );
  }

  Widget _buildRow(
    ColorScheme colors, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          if (trailingWidget != null)
            trailingWidget
          else if (trailing != null)
            Text(trailing,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: _accentBlue)),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: content,
    );
  }
}
