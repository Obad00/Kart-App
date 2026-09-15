import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_app_bar.dart';
import '../models/company_event_summary.dart';
import '../services/company_community_service.dart';
import 'company_event_participants_page.dart';

const _themeBlue = Color(0xFF3B82F6);

/// "Voir tout" de la section "Ma communauté" d'Explorer — la liste
/// complète des événements de l'entreprise, plus les employés qui lui sont
/// rattachés ("toute personne rattachée à cette entreprise", cf. demande
/// produit). Même charpente Scaffold+GlassAppBar que CompanyDetailPage.
class CompanyEventsListPage extends StatefulWidget {
  const CompanyEventsListPage({super.key});

  @override
  State<CompanyEventsListPage> createState() => _CompanyEventsListPageState();
}

class _CompanyEventsListPageState extends State<CompanyEventsListPage> {
  final _service = CompanyCommunityService();
  List<CompanyEventSummary> _events = [];
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    // Chargés indépendamment : un compte owner/admin sans le plan
    // enterprise peut voir ses événements sans jamais avoir accès à
    // /company/employees (403 silencieux, section employés juste omise).
    final events = await _service.fetchEvents().catchError((_) => <CompanyEventSummary>[]);
    final employees =
        await _service.fetchEmployees().catchError((_) => <Map<String, dynamic>>[]);

    if (!mounted) return;
    setState(() {
      _events = events;
      _employees = employees;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = const GlassAppBar(title: Text('Ma communauté'));
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: _isLoading
                ? Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : _buildBody(colors, topPadding),
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
    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 32),
      children: [
        Text(
          'Événements',
          style: TextStyle(
              fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: colors.onSurface),
        ),
        const SizedBox(height: 10),
        if (_events.isEmpty)
          Text('Aucun événement créé pour le moment.',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)))
        else
          ..._events.map((event) => _EventRow(
                event: event,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyEventParticipantsPage(
                      eventId: event.id,
                      eventName: event.name,
                    ),
                  ),
                ),
              )),
        if (_employees.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            'Employés',
            style: TextStyle(
                fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w800, color: colors.onSurface),
          ),
          const SizedBox(height: 10),
          ..._employees.map((e) => _EmployeeRow(employee: e)),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  final CompanyEventSummary event;
  final VoidCallback onTap;

  const _EventRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.participantsCount} inscrit${event.participantsCount > 1 ? 's' : ''}'
                      '${event.hasEnded ? ' · Terminé' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurface.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: colors.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _EmployeeRow({required this.employee});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name =
        '${employee['firstname'] ?? ''} ${employee['lastname'] ?? ''}'.trim();
    final role = employee['company_role'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _themeBlue.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontFamily: 'Syne', fontWeight: FontWeight.w800, color: _themeBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? (employee['email'] ?? '') : name,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (role != null)
            Text(
              role == 'owner' ? 'Propriétaire' : role == 'admin' ? 'Admin' : role,
              style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }
}
