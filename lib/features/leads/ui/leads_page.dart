import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/leads_provider.dart';

/// Page affichant la liste des leads (personnes ayant scanne la carte)
class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().loadLeads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Mes contacts',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<LeadsProvider>(
            builder: (_, provider, __) {
              return IconButton(
                icon: Icon(Icons.refresh, color: colors.onSurface.withValues(alpha: 0.7)),
                onPressed:
                    provider.isLoading ? null : () => provider.refresh(),
              );
            },
          ),
        ],
      ),
      body: Consumer<LeadsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.leads.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.leads.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            color: const Color(0xFF3B82F6),
            child: Column(
              children: [
                // Stats header
                _buildStatsHeader(context, provider),

                // Liste des leads
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.leads.length,
                    itemBuilder: (context, index) {
                      final lead = provider.leads[index];
                      return _buildLeadCard(context, lead);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                color: colors.onSurface.withValues(alpha: 0.3),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun contact pour le moment',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez votre carte pour commencer a collecter des contacts',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, LeadsProvider provider) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.15),
            const Color(0xFF8B5CF6).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.visibility_outlined,
              value: '${provider.total}',
              label: 'Vues totales',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colors.onSurface.withValues(alpha: 0.1),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.person_add_outlined,
              value: '${provider.contactCount}',
              label: 'Contacts',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLeadCard(BuildContext context, Lead lead) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Format de date simple sans dependance de locale
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Determiner la premiere lettre pour l'avatar
    String avatarLetter = '?';
    if (lead.name != null && lead.name!.isNotEmpty) {
      avatarLetter = lead.name![0].toUpperCase();
    } else if (lead.email != null && lead.email!.isNotEmpty) {
      avatarLetter = lead.email![0].toUpperCase();
    } else if (lead.phone != null && lead.phone!.isNotEmpty) {
      avatarLetter = '#';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lead.hasContactInfo
              ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
              : colors.onSurface.withValues(alpha: 0.1),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: lead.hasContactInfo
                      ? const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        )
                      : null,
                  color: lead.hasContactInfo
                      ? null
                      : colors.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: TextStyle(
                      color: lead.hasContactInfo
                          ? Colors.white
                          : colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom ou identifiant
                    Text(
                      lead.name ?? lead.displayName,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildSourceBadge(source: lead.sourceLabel),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateFormat.format(lead.viewedAt),
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (lead.email != null && lead.email!.isNotEmpty)
                _buildActionButton(
                  context,
                  Icons.email_outlined,
                  () => _launchEmail(lead.email!),
                ),
              if (lead.phone != null && lead.phone!.isNotEmpty)
                _buildActionButton(
                  context,
                  Icons.phone_outlined,
                  () => _launchPhone(lead.phone!),
                ),
            ],
          ),

          // Details supplementaires - toujours afficher les infos disponibles
          const SizedBox(height: 12),
          Divider(color: colors.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 8),

          // Infos de contact
          if (lead.email != null && lead.email!.isNotEmpty)
            _buildDetailRow(context, Icons.email_outlined, lead.email!),
          if (lead.phone != null && lead.phone!.isNotEmpty)
            _buildDetailRow(context, Icons.phone_outlined, lead.phone!),

          // Infos techniques du visiteur
          if (lead.device != null && lead.device!.isNotEmpty)
            _buildDetailRow(context, Icons.phone_android_outlined, lead.device!),
          if (lead.location != null && lead.location!.isNotEmpty)
            _buildDetailRow(context, Icons.location_on_outlined, lead.location!),

          // Si aucune info, afficher un message
          if (!lead.hasContactInfo && lead.device == null && lead.location == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Aucune information disponible',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge({required String source}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        source,
        style: const TextStyle(
          color: Color(0xFF3B82F6),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, VoidCallback onTap) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: colors.onSurface.withValues(alpha: 0.7), size: 18),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String value) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurface.withValues(alpha: 0.5), size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
