import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../onboarding/providers/company_provider.dart';

/// Écran consultatif "Mon entreprise" : aucune action de création, d'invitation
/// ou de gestion de licence — uniquement de la lecture.
class CompanyInfoPage extends StatefulWidget {
  const CompanyInfoPage({super.key});

  @override
  State<CompanyInfoPage> createState() => _CompanyInfoPageState();
}

class _CompanyInfoPageState extends State<CompanyInfoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CompanyProvider>();
      provider.loadMyCompany();
      final user = context.read<AuthProvider>().user;
      if (user?.isCompanyOwnerOrAdmin == true) {
        provider.loadMembers();
      }
    });
  }

  String? _logoUrl(Map<String, dynamic>? company) {
    final logo = company?['logo'] as String?;
    if (logo == null || logo.isEmpty) return null;
    if (logo.startsWith('http://') || logo.startsWith('https://')) {
      return logo;
    }
    return '${ApiEndpoints.storageUrl}/$logo';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final companyProvider = context.watch<CompanyProvider>();
    final company = companyProvider.myCompany;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text('Mon entreprise'),
      ),
      body: SafeArea(
        child: companyProvider.isLoadingCompany && company == null
            ? const Center(child: CircularProgressIndicator())
            : company == null
                ? Center(
                    child: Text(
                      companyProvider.error ?? 'Aucune information disponible',
                      style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        children: [
                          if (_logoUrl(company) != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _logoUrl(company)!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.business_rounded,
                                  size: 40,
                                  color: colors.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ] else
                            Icon(
                              Icons.business_rounded,
                              size: 40,
                              color: colors.onSurface.withValues(alpha: 0.4),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              (company['name'] as String?) ?? '',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _InfoSection(
                        colors: colors,
                        rows: [
                          if ((company['address'] as String?)?.isNotEmpty == true)
                            _InfoRowData(Icons.location_on_outlined, 'Adresse', company['address']),
                          if ((company['website'] as String?)?.isNotEmpty == true)
                            _InfoRowData(Icons.language_outlined, 'Site web', company['website']),
                          if ((company['industry'] as String?)?.isNotEmpty == true)
                            _InfoRowData(Icons.category_outlined, 'Secteur', company['industry']),
                        ],
                      ),
                      if (user?.isCompanyOwnerOrAdmin == true) ...[
                        const SizedBox(height: 32),
                        Text(
                          'Équipe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (companyProvider.members.isEmpty)
                          Text(
                            'Aucun membre pour le moment',
                            style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
                          )
                        else
                          ...companyProvider.members.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.onSurface.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colors.onSurface.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${m['firstname'] ?? ''} ${m['lastname'] ?? ''}'.trim(),
                                            style: TextStyle(
                                              color: colors.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            m['email']?.toString() ?? '',
                                            style: TextStyle(
                                              color: colors.onSurface.withValues(alpha: 0.5),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (m['is_active'] == false)
                                      Text(
                                        'Inactif',
                                        style: TextStyle(color: Colors.red[400], fontSize: 12),
                                      )
                                    else
                                      Text(
                                        m['company_role'] == 'admin'
                                            ? 'Admin'
                                            : m['company_role'] == 'owner'
                                                ? 'Propriétaire'
                                                : 'Membre',
                                        style: TextStyle(
                                          color: colors.onSurface.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'La gestion de votre équipe se fait depuis votre espace web.',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  _InfoRowData(this.icon, this.label, dynamic value) : value = value?.toString() ?? '';
}

class _InfoSection extends StatelessWidget {
  final ColorScheme colors;
  final List<_InfoRowData> rows;

  const _InfoSection({required this.colors, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 24, color: colors.onSurface.withValues(alpha: 0.08)),
            Row(
              children: [
                Icon(rows[i].icon, size: 18, color: colors.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rows[i].label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rows[i].value,
                        style: TextStyle(fontSize: 14, color: colors.onSurface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
