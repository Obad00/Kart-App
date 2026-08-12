import 'package:flutter/material.dart';
import '../model/job_feed_item.dart';
import 'job_details_sheet.dart';

const _accentBlue = Color(0xFF3B82F6);

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
    final likeOpacity = (_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);
    final rejectOpacity = (-_dragOffset.dx / _swipeThreshold).clamp(0.0, 1.0);

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
              Positioned(
                top: 28,
                right: 24,
                child: Opacity(
                  opacity: likeOpacity,
                  child: _buildStamp('OUI', Colors.green),
                ),
              ),
              Positioned(
                top: 28,
                left: 24,
                child: Opacity(
                  opacity: rejectOpacity,
                  child: _buildStamp('NON', Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStamp(String label, Color color) {
    return Transform.rotate(
      angle: label == 'OUI' ? -0.3 : 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final job = widget.job;

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.62,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(Icons.business_rounded, color: _accentBlue, size: 26),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${job.score}%',
                  style: const TextStyle(
                    color: _accentBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            job.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [job.companyName, job.location]
                .where((v) => (v ?? '').isNotEmpty)
                .join(' · '),
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          if (_salaryLabel(job) != null) ...[
            Text(
              _salaryLabel(job)!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
          ],
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
          if ((job.description ?? '').isNotEmpty) ...[
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showDetails(context),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Voir les détails'),
                style: TextButton.styleFrom(foregroundColor: _accentBlue),
              ),
            ),
          ],
        ],
      ),
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
