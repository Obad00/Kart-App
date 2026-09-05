import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/utils/relative_time.dart';
import '../model/job_feed_item.dart';
import 'job_details_sheet.dart';

const _accentBlue = Color(0xFF3B82F6);
const _accentGreen = Color(0xFF16A34A);

class JobSwipeCard extends StatefulWidget {
  final JobFeedItem job;
  final VoidCallback onLike;
  final VoidCallback onReject;

  const JobSwipeCard({
    super.key,
    required this.job,
    required this.onLike,
    required this.onReject,
  });

  @override
  State<JobSwipeCard> createState() => _JobSwipeCardState();
}

class _JobSwipeCardState extends State<JobSwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  late AnimationController _controller;
  Animation<Offset>? _animation;

  static const double _swipeThreshold = 120;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_animation != null) {
          setState(() => _dragOffset = _animation!.value);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragOffset.dx.abs() > _swipeThreshold) {
      _flyAway(isLike: _dragOffset.dx > 0);
    } else {
      _animateTo(Offset.zero);
    }
  }

  void _flyAway({required bool isLike}) {
    final endOffset = Offset(isLike ? 700 : -700, _dragOffset.dy);
    _animateTo(endOffset, onComplete: () {
      if (isLike) {
        widget.onLike();
      } else {
        widget.onReject();
      }
    });
  }

  void _animateTo(Offset target, {VoidCallback? onComplete}) {
    _animation = Tween<Offset>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward(from: 0).whenComplete(() {
      if (onComplete != null) onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final angle = (_dragOffset.dx / 300).clamp(-0.4, 0.4);
    // Progrès 0→1 du geste, dans chaque direction — pilote à la fois
    // l'opacité du bandeau plein-carte ("J'aime"/"Passer", cf. maquette
    // JobMatch fournie) et une légère mise à l'échelle pour le feedback.
    final likeProgress = (_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);
    final rejectProgress = (-_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            children: [
              _buildCardContent(context),
              if (likeProgress > 0)
                _buildSwipeOverlay(
                  progress: likeProgress,
                  color: _accentGreen,
                  icon: Icons.favorite_rounded,
                  label: 'INTÉRESSÉ',
                  alignment: Alignment.topLeft,
                ),
              if (rejectProgress > 0)
                _buildSwipeOverlay(
                  progress: rejectProgress,
                  color: Colors.red,
                  icon: Icons.close_rounded,
                  label: 'PASSER',
                  alignment: Alignment.topRight,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bandeau plein-carte qui se teinte progressivement pendant le
  /// glissement — remplace les anciens tampons "OUI"/"NON" en coin par un
  /// retour plus visible, dans l'esprit de la maquette fournie ("JE SUIS
  /// INTÉRESSÉ" en surimpression pendant le glissement).
  Widget _buildSwipeOverlay({
    required double progress,
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: progress * 0.92,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: color.withValues(alpha: 0.94),
            ),
            child: Align(
              alignment: alignment == Alignment.topLeft
                  ? Alignment.center
                  : Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? get _logoUrl {
    final logo = widget.job.companyLogo;
    if (logo == null || logo.isEmpty) return null;
    return logo.startsWith('http') ? logo : '${ApiEndpoints.storageUrl}/$logo';
  }

  Widget _buildCardContent(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final job = widget.job;
    final logoUrl = _logoUrl;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: _accentBlue.withValues(alpha: 0.1),
                      child: logoUrl != null
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  _logoFallback(),
                            )
                          : _logoFallback(),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            size: 14, color: _accentBlue),
                        const SizedBox(width: 4),
                        Text(
                          '${job.score}% correspondant',
                          style: const TextStyle(
                            color: _accentBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              // Pas de SingleChildScrollView ici : le GestureDetector du
              // glissement (onPanUpdate/onPanEnd) capte déjà tout
              // mouvement vertical, il entrerait en conflit avec un
              // défilement interne. maxLines sur chaque texte + Wrap sur
              // les chips gardent ce contenu dans un gabarit prévisible.
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      job.companyName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _accentBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if ((job.isRemote ? 'À distance' : job.location)
                            ?.isNotEmpty ==
                        true)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14,
                              color: colors.onSurface.withValues(alpha: 0.45)),
                          const SizedBox(width: 4),
                          Text(
                            job.isRemote ? 'À distance' : job.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    if (_salaryLabel(job) != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _salaryLabel(job)!,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _accentGreen,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (job.contractType != null)
                          _buildChip(job.contractType!, colors),
                        if (job.isRemote) _buildChip('Remote', colors),
                        if (job.experienceRequired != null)
                          _buildChip(
                            "${job.experienceRequired} an${job.experienceRequired! > 1 ? 's' : ''} d'expérience",
                            colors,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (job.publishedAt != null)
                      Text(
                        'Publié ${relativeTimeLabel(job.publishedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    if ((job.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _showDetails(context),
                          icon:
                              const Icon(Icons.info_outline_rounded, size: 18),
                          label: const Text('Voir les détails'),
                          style: TextButton.styleFrom(
                            foregroundColor: _accentBlue,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() {
    return const Center(
      child: Icon(Icons.business_rounded, color: _accentBlue, size: 26),
    );
  }

  void _showDetails(BuildContext context) {
    final job = widget.job;
    showJobDetailsSheet(
      context,
      title: job.title,
      companyName: job.companyName,
      location: job.location,
      description: job.description,
    );
  }

  String? _salaryLabel(JobFeedItem job) {
    if (job.salaryMin == null && job.salaryMax == null) return null;
    if (job.salaryMin != null && job.salaryMax != null) {
      return '${job.salaryMin} - ${job.salaryMax} FCFA';
    }
    return '${job.salaryMin ?? job.salaryMax} FCFA';
  }

  Widget _buildChip(String label, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
