import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../jobmatch/widgets/job_details_sheet.dart';
import '../models/company_job.dart';
import '../services/company_discovery_service.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Détail d'une entreprise "à découvrir" — ouvert en tapant sur sa carte
/// (Explorer). Coordonnées publiques + ses offres publiées.
class CompanyDetailPage extends StatefulWidget {
  final int companyId;
  final String companyName;

  const CompanyDetailPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  final _service = CompanyDiscoveryService();
  CompanyDetail? _detail;
  bool _isLoading = true;
  bool _isTogglingFollow = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final detail = await _service.fetchCompanyDetail(widget.companyId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Impossible de charger cette entreprise.";
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final detail = _detail;
    if (detail == null || _isTogglingFollow) return;

    HapticFeedback.selectionClick();
    setState(() => _isTogglingFollow = true);
    try {
      if (detail.isFollowing) {
        await _service.unfollow(detail.id);
      } else {
        await _service.follow(detail.id);
      }
      if (!mounted) return;
      setState(() {
        _detail = CompanyDetail(
          id: detail.id,
          name: detail.name,
          logo: detail.logo,
          industry: detail.industry,
          address: detail.address,
          website: detail.website,
          email: detail.email,
          phone: detail.phone,
          isFollowing: !detail.isFollowing,
          jobs: detail.jobs,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une erreur est survenue, réessayez.")),
      );
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  String get _logoUrl {
    final logo = _detail?.logo;
    if (logo == null || logo.isEmpty) return '';
    return logo.startsWith('http') ? logo : '${ApiEndpoints.storageUrl}/$logo';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = GlassAppBar(title: Text(widget.companyName));
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: _buildBody(colors, topPadding),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: topPadding, child: glassAppBar),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colors, double topPadding) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _detail == null) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Entreprise introuvable',
                  style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final logoUrl = _logoUrl;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 40),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 64,
                height: 64,
                color: _themeBlue.withValues(alpha: 0.1),
                child: logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _logoFallback(),
                      )
                    : _logoFallback(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.name,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  if (detail.industry?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail.industry!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isTogglingFollow ? null : _toggleFollow,
            icon: Icon(
              detail.isFollowing ? Icons.check_rounded : Icons.add_rounded,
              size: 18,
            ),
            label: Text(detail.isFollowing ? 'Suivi' : 'Suivre'),
            style: OutlinedButton.styleFrom(
              foregroundColor: detail.isFollowing
                  ? colors.onSurface.withValues(alpha: 0.6)
                  : _themeBlue,
              side: BorderSide(
                color: detail.isFollowing
                    ? colors.onSurface.withValues(alpha: 0.15)
                    : _themeBlue.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        // Seule l'adresse est affichée ici — email/téléphone/site sur
        // Company sont pour l'instant souvent juste le contact d'un admin
        // (pas une ligne dédiée "entreprise"), les montrer publiquement
        // dans Explorer donnait l'impression erronée d'exposer une
        // coordonnée personnelle.
        if (detail.address != null) ...[
          const SizedBox(height: 24),
          Text(
            'Coordonnées',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(colors, Icons.location_on_outlined, detail.address!),
        ],
        const SizedBox(height: 24),
        Text(
          detail.jobs.isEmpty
              ? 'Aucune offre publiée pour le moment'
              : 'Offres publiées (${detail.jobs.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.onSurface.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        ...detail.jobs.map((job) => _buildJobRow(colors, job, detail.name)),
      ],
    );
  }

  Widget _logoFallback() {
    return Center(
      child: Text(
        widget.companyName.isNotEmpty
            ? widget.companyName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: _themeBlue,
        ),
      ),
    );
  }

  Widget _buildInfoRow(ColorScheme colors, IconData icon, String value,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: colors.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: onTap != null ? _themeBlue : colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobRow(ColorScheme colors, CompanyJob job, String companyName) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showJobDetailsSheet(
          context,
          title: job.title,
          companyName: companyName,
          location: job.isRemote ? 'À distance' : job.location,
          description: job.description,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _themeBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline_rounded,
                    size: 16, color: _themeBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (job.isRemote) 'À distance' else job.location,
                        job.contractType,
                      ].where((e) => e != null && e.isNotEmpty).join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
