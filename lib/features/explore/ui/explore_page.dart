import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../models/connection_request_item.dart';
import '../models/explore_user.dart';
import '../providers/explore_provider.dart';
import '../services/explore_service.dart';
import '../widgets/connect_action_button.dart';
import '../../public_card/ui/public_card_page.dart';

const _themeBlue = Color(0xFF3B82F6);

/// "Explorer" — annuaire des utilisateurs KART avec une carte publique
/// active. Envoyer une demande de mise en relation notifie l'autre
/// personne par mail (avec des liens Accepter/Refuser, sans connexion
/// requise) ; si elle accepte, un contact se crée automatiquement des deux
/// côtés. L'onglet "Mes demandes" permet aussi de répondre directement
/// dans l'app.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with SingleTickerProviderStateMixin {
  late final ExploreProvider _provider;
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _provider = ExploreProvider(ExploreService());
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1 && _provider.myRequests.isEmpty) {
        _provider.loadMyRequests();
      }
    });
    _provider.loadUsers();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _provider.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _provider.loadUsers(search: value.trim());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explorer'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: _themeBlue,
            indicatorColor: _themeBlue,
            tabs: const [
              Tab(text: 'Découvrir'),
              Tab(text: 'Mes demandes'),
            ],
          ),
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                _buildMyRequestsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSearchBar(
            controller: _searchController,
            hintText: 'Rechercher par nom, poste, entreprise...',
            onChanged: _onSearchChanged,
          ),
        ),
        Consumer<ExploreProvider>(
          builder: (context, provider, _) => _buildJobTitleFilterRow(provider),
        ),
        Expanded(
          child: Consumer<ExploreProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.loadUsers(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.users.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_outlined,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun profil à découvrir pour le moment',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: provider.users.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= provider.users.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _ExploreUserRow(user: provider.users[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Chips de filtre par poste — même design que le filtre par highlight
  /// dans Contacts, pour repérer plus vite un profil précis.
  Widget _buildJobTitleFilterRow(ExploreProvider provider) {
    if (provider.jobTitles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: provider.jobTitles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final active = provider.jobTitleFilter.isEmpty;
            return _FilterChip(
              label: 'Tous postes',
              active: active,
              onTap: () => provider.setJobTitleFilter(''),
            );
          }

          final jobTitle = provider.jobTitles[index - 1];
          final active = provider.jobTitleFilter == jobTitle;
          return _FilterChip(
            label: jobTitle,
            active: active,
            onTap: () => provider.setJobTitleFilter(active ? '' : jobTitle),
          );
        },
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _StatusChip(
                label: 'Toutes',
                status: 'all',
              ),
              const SizedBox(width: 8),
              _StatusChip(label: 'En attente', status: 'pending'),
              const SizedBox(width: 8),
              _StatusChip(label: 'Acceptées', status: 'accepted'),
              const SizedBox(width: 8),
              _StatusChip(label: 'Refusées', status: 'declined'),
            ],
          ),
        ),
        Expanded(
          child: Consumer<ExploreProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingMyRequests) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.myRequests.isEmpty) {
                return Center(
                  child: Text(
                    'Aucune demande pour l\'instant',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                itemCount: provider.myRequests.length,
                itemBuilder: (context, index) =>
                    _MyRequestRow(item: provider.myRequests[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: active ? Colors.white : colors.onSurface.withValues(alpha: 0.7),
      ),
      selectedColor: _themeBlue,
      backgroundColor: colors.onSurface.withValues(alpha: 0.06),
      side: BorderSide.none,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String status;

  const _StatusChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final active = provider.myRequestsStatusFilter == status;
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        context.read<ExploreProvider>().loadMyRequests(status: status);
      },
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: active ? Colors.white : colors.onSurface.withValues(alpha: 0.7),
      ),
      selectedColor: _themeBlue,
      backgroundColor: colors.onSurface.withValues(alpha: 0.06),
      side: BorderSide.none,
    );
  }
}

class _MyRequestRow extends StatelessWidget {
  final ConnectionRequestItem item;

  const _MyRequestRow({required this.item});

  Color _statusColor() {
    switch (item.status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel() {
    switch (item.status) {
      case 'accepted':
        return 'Acceptée';
      case 'declined':
        return 'Refusée';
      default:
        return 'En attente';
    }
  }

  /// Sans afficher l'erreur retournée par le provider, un échec réseau/
  /// serveur sur Accepter/Refuser ne montrait strictement rien à
  /// l'utilisateur — d'où l'impression que "rien ne se passe".
  Future<void> _respond(BuildContext context, String action) async {
    final error = await context.read<ExploreProvider>().respondFromMyRequests(item.id, action);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = item.otherUser;
    final isPendingReceived = item.status == 'pending' && item.direction == RequestDirection.received;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(
              item.direction == RequestDirection.sent
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded,
              size: 16,
              color: colors.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((user.jobTitle ?? user.company ?? '').isNotEmpty)
                    Text(
                      [user.jobTitle, user.company].where((v) => (v ?? '').isNotEmpty).join(' · '),
                      style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.55)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isPendingReceived)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleActionButton(
                    icon: Icons.close_rounded,
                    color: Colors.red,
                    onTap: () => _respond(context, 'decline'),
                  ),
                  const SizedBox(width: 8),
                  _CircleActionButton(
                    icon: Icons.check_rounded,
                    color: Colors.green,
                    onTap: () => _respond(context, 'accept'),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExploreUserRow extends StatelessWidget {
  final ExploreUser user;

  const _ExploreUserRow({required this.user});

  String? get _avatarUrl {
    final avatar = user.avatar;
    if (avatar == null || avatar.isEmpty) return null;
    return avatar.startsWith('http') ? avatar : '${ApiEndpoints.storageUrl}/$avatar';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '';
  }

  void _openCard(BuildContext context) {
    final slug = user.cardSlug;
    if (slug == null || slug.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicCardPage(slug: slug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatarUrl = _avatarUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openCard(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: avatarUrl == null
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(avatarUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          _initials(user.name),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((user.jobTitle ?? user.company ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [user.jobTitle, user.company]
                            .where((v) => (v ?? '').isNotEmpty)
                            .join(' · '),
                        style: TextStyle(
                            fontSize: 12.5, color: colors.onSurface.withValues(alpha: 0.55)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConnectActionButton(
                userId: user.id,
                userName: user.name,
                initialStatus: user.connectionStatus,
                initialRequestId: user.connectionRequestId,
                onResolved: () => context.read<ExploreProvider>().removeUserLocally(user.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Petit bouton rond (✓/✕) pour accepter/refuser une demande reçue
/// directement dans la liste, sans passer par le mail.
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
