import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/community.dart';
import '../models/explore_user.dart';
import '../services/community_service.dart';
import '../widgets/explore_user_row.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';

/// Membres d'une communauté — ouvert en tapant sur une carte "Réseaux
/// populaires"/"à rejoindre" (Explorer), y compris avant de l'avoir
/// rejointe.
class CommunityMembersPage extends StatefulWidget {
  final int communityId;
  final String communityName;

  const CommunityMembersPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityMembersPage> createState() => _CommunityMembersPageState();
}

class _CommunityMembersPageState extends State<CommunityMembersPage> {
  final _service = CommunityService();
  Community? _community;
  List<ExploreUser> _members = [];
  bool _isLoading = true;
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
      final result = await _service.fetchMembers(widget.communityId);
      if (!mounted) return;
      setState(() {
        _community = result.community;
        _members = result.members;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger ce réseau.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = GlassAppBar(title: Text(widget.communityName));
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

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final community = _community;

    return ListView(
      padding: EdgeInsets.only(
        top: topPadding + 12,
        bottom: 24 + BottomNavMetrics.bottomInset(MediaQuery.of(context).padding.bottom),
      ),
      children: [
        if (community != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: community.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_rounded, color: community.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${community.membersCount} membre${community.membersCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      if (community.description?.isNotEmpty == true)
                        Text(
                          community.description!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    try {
                      if (community.isJoined) {
                        await _service.leave(community.id);
                      } else {
                        await _service.join(community.id);
                      }
                      _load();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Une erreur est survenue, réessayez.')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: community.isJoined
                        ? colors.onSurface.withValues(alpha: 0.6)
                        : community.color,
                    side: BorderSide(
                      color: community.isJoined
                          ? colors.onSurface.withValues(alpha: 0.15)
                          : community.color.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(community.isJoined ? 'Quitter' : 'Rejoindre'),
                ),
              ],
            ),
          ),
        if (_members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Aucun autre membre à afficher pour le moment',
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ..._members.map((member) => ExploreUserRow(user: member)),
      ],
    );
  }
}
