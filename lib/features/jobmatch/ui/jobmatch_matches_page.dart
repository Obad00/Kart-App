import 'package:flutter/material.dart';
import '../model/job_feed_item.dart';
import '../services/jobmatch_service.dart';

const _accentBlue = Color(0xFF3B82F6);

class JobMatchMatchesPage extends StatefulWidget {
  const JobMatchMatchesPage({super.key});

  @override
  State<JobMatchMatchesPage> createState() => _JobMatchMatchesPageState();
}

class _JobMatchMatchesPageState extends State<JobMatchMatchesPage> {
  final _service = JobMatchService();
  List<JobMatchResult> _matches = [];
  List<LikedJobItem> _liked = [];
  JobMatchSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchMatches(),
        _service.fetchLiked(),
        _service.fetchSummary(),
      ]);
      _matches = results[0] as List<JobMatchResult>;
      _liked = results[1] as List<LikedJobItem>;
      _summary = results[2] as JobMatchSummary;
    } catch (_) {
      // silencieux : listes vides affichées par défaut
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          title: const Text('Mon tableau de bord'),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: _accentBlue,
            indicatorColor: _accentBlue,
            tabs: [
              Tab(text: 'Matchs'),
              Tab(text: 'Aimées'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_summary != null) _buildSummaryRow(colors, _summary!),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMatchesList(colors),
                        _buildLikedList(colors),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRow(ColorScheme colors, JobMatchSummary summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(child: _buildStat('Matchs', summary.matches, Colors.green, colors)),
          const SizedBox(width: 10),
          Expanded(child: _buildStat('Aimées', summary.liked, _accentBlue, colors)),
          const SizedBox(width: 10),
          Expanded(child: _buildStat('En attente', summary.pendingSuggestions, Colors.orange, colors)),
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onSurface.withValues(alpha: 0.5)),
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

  Widget _buildRow(
    ColorScheme colors, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
  }) {
    return Container(
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
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing, style: const TextStyle(fontWeight: FontWeight.w800, color: _accentBlue)),
        ],
      ),
    );
  }
}
