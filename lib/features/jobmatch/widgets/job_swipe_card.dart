import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/utils/relative_time.dart';
import '../jobmatch_theme.dart';
import '../model/job_feed_item.dart';

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
    // Progrès 0→1 du geste, dans chaque direction — pilote l'opacité du
    // bandeau plein-carte "JE SUIS INTÉRESSÉ"/"PASSER" (cf. maquette).
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
                  color: jobMatchLike,
                  icon: Icons.favorite_rounded,
                  label: 'JE SUIS\nINTÉRESSÉ',
                ),
              if (rejectProgress > 0)
                _buildSwipeOverlay(
                  progress: rejectProgress,
                  color: Colors.red,
                  icon: Icons.close_rounded,
                  label: 'PASSER',
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bandeau plein-carte qui se teinte progressivement pendant le
  /// glissement — cf. maquette ("JE SUIS INTÉRESSÉ" en surimpression).
  Widget _buildSwipeOverlay({
    required double progress,
    required Color color,
    required IconData icon,
    required String label,
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
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

  String? get _backgroundUrl {
    final bg = widget.job.companyBackgroundImage;
    if (bg == null || bg.isEmpty) return null;
    return bg.startsWith('http') ? bg : '${ApiEndpoints.storageUrl}/$bg';
  }

  static const _fallbackGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF262626), Color(0xFF0D0D0D)],
  );

  Widget _buildCardContent(BuildContext context) {
    final job = widget.job;
    final logoUrl = _logoUrl;
    final backgroundUrl = _backgroundUrl;

    // width/height: double.infinity — remplit tout l'espace que le Stack
    // parent (Positioned.fill, cf. JobMatchFeedPage._buildStack) lui
    // réserve réellement, plutôt que de recalculer sa propre hauteur à
    // partir de MediaQuery : un calcul ignorant totalement l'espace déjà
    // pris par l'AppBar, les boutons Passer/Aimer et le padding de la
    // pilule de nav, qui pouvait dépasser la hauteur d'écran disponible et
    // pousser ces boutons par-dessus la barre de navigation.
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo de couverture de l'entreprise si elle en a une
            // (branding activé), sinon le dégradé sombre uni d'origine —
            // sans quoi le grand espace entre le logo et le titre du
            // poste restait vide.
            if (backgroundUrl != null)
              CachedNetworkImage(
                imageUrl: backgroundUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const DecoratedBox(
                    decoration: BoxDecoration(gradient: _fallbackGradient)),
              )
            else
              const DecoratedBox(
                  decoration: BoxDecoration(gradient: _fallbackGradient)),
            // Voile sombre par-dessus la photo — indispensable pour que le
            // texte blanc (titre, entreprise, salaire...) reste lisible
            // quelle que soit la photo, plus prononcé vers le bas où se
            // concentre l'information.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0xE6000000),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 52,
                          height: 52,
                          color: Colors.white,
                          child: logoUrl != null
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CachedNetworkImage(
                                    imageUrl: logoUrl,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) =>
                                        _logoFallback(),
                                  ),
                                )
                              : _logoFallback(),
                        ),
                      ),
                      const Spacer(),
                      if (job.isSaved) ...[
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber.shade400),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: jobMatchAccent.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          '${job.score}%',
                          style: const TextStyle(
                            color: jobMatchAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Profil correspondant',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                job.companyName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                size: 15, color: jobMatchAccent),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if ((job.isRemote ? 'À distance' : job.location)
                                    ?.isNotEmpty ==
                                true)
                              job.isRemote ? 'À distance' : job.location,
                            job.contractType,
                            job.isRemote ? 'Hybride' : null,
                          ].whereType<String>().join(' · '),
                          style: const TextStyle(
                              fontSize: 12.5, color: Colors.white60),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_salaryLabel(job) != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _salaryLabel(job)!,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: jobMatchAccent,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...job.skills.take(3).map((s) => _buildChip(s)),
                            if (job.skills.isEmpty) ...[
                              if (job.contractType != null)
                                _buildChip(job.contractType!),
                              if (job.experienceRequired != null)
                                _buildChip(
                                  "${job.experienceRequired} an${job.experienceRequired! > 1 ? 's' : ''}",
                                ),
                            ],
                          ],
                        ),
                        if (job.publishedAt != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Publiée ${relativeTimeLabel(job.publishedAt!)}',
                            style: const TextStyle(
                                fontSize: 11.5, color: Colors.white38),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() {
    final name = widget.job.companyName;
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  String? _salaryLabel(JobFeedItem job) {
    if (job.salaryMin == null && job.salaryMax == null) return null;
    if (job.salaryMin != null && job.salaryMax != null) {
      return '${job.salaryMin} - ${job.salaryMax} FCFA / mois';
    }
    return '${job.salaryMin ?? job.salaryMax} FCFA / mois';
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
