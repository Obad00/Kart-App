import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../shared/tour/tour_prefs.dart';
import '../model/job_feed_item.dart';
import '../services/jobmatch_service.dart';
import '../widgets/job_details_sheet.dart';

const _accentBlue = Color(0xFF3B82F6);

class JobMatchMatchesPage extends StatefulWidget {
  /// Onglet ouvert au premier affichage (0 = Matchs, 1 = Aimées, 2 =
  /// Passées) — permet par ex. au deep link `kart://jobmatch/liked` de
  /// pointer directement sur l'onglet "Aimées".
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
  JobMatchSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
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
      ]);
      _matches = results[0] as List<JobMatchResult>;
      _liked = results[1] as List<LikedJobItem>;
      _rejected = results[2] as List<LikedJobItem>;
      _summary = results[3] as JobMatchSummary;
    } catch (_) {
      // silencieux : listes vides affichées par défaut
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _reconsider(LikedJobItem job) async {
    try {
      await _service.unswipe(job.jobId);
      if (!mounted) return;
      setState(() => _rejected.removeWhere((r) => r.jobId == job.jobId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${job.jobTitle} est de retour dans votre fil')),
      );
    } catch (_) {
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
      appBar: AppBar(
        title: const Text('Mon tableau de bord'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Showcase(
            key: _tabsTourKey,
            title: 'Vos offres',
            description:
                'Matchs mutuels, offres aimées, et offres passées que vous pouvez reconsidérer.',
            child: TabBar(
              controller: _tabController,
              labelColor: _accentBlue,
              indicatorColor: _accentBlue,
              tabs: const [
                Tab(text: 'Matchs'),
                Tab(text: 'Aimées'),
                Tab(text: 'Passées'),
              ],
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
              child:
                  _buildStat('Matchs', summary.matches, Colors.green, colors)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildStat('Aimées', summary.liked, _accentBlue, colors)),
          const SizedBox(width: 10),
          Expanded(
              child: _buildStat(
                  'Passées', summary.rejected, Colors.orange, colors)),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color, ColorScheme colors) {
    return Container(
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
          onTap: () => showJobDetailsSheet(
            context,
            title: match.jobTitle,
            companyName: match.companyName,
            location: match.location,
            description: match.description,
          ),
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
          trailing: null,
          onTap: () => showJobDetailsSheet(
            context,
            title: liked.jobTitle,
            companyName: liked.companyName,
            location: liked.location,
            description: liked.description,
          ),
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
