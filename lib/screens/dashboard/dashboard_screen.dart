import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../ticket/ticket_list_screen.dart';
import '../ticket/ticket_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final stats = provider.ticketStats;
    final tickets = provider.userTickets;
    final recentTickets = tickets.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, size: 22),
            const SizedBox(width: 8),
            const Text('E-Ticketing'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: provider.toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header
              GradientHeader(
                title: user.name,
                subtitle: 'Halo,',
                role: user.role,
              ),
              const SizedBox(height: 24),

              // Stats grid
              SectionHeader(
                title: 'Statistik Tiket',
                action: 'Lihat Semua',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TicketListScreen())),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: [
                  StatCard(
                    label: 'Total Tiket',
                    count: stats['total']!,
                    color: AppTheme.primaryBlue,
                    icon: Icons.confirmation_num_rounded,
                  ),
                  StatCard(
                    label: 'Open',
                    count: stats['open']!,
                    color: const Color(0xFF3B82F6),
                    icon: Icons.fiber_new_rounded,
                  ),
                  StatCard(
                    label: 'In Progress',
                    count: stats['in_progress']!,
                    color: AppTheme.accentAmber,
                    icon: Icons.pending_actions_rounded,
                  ),
                  StatCard(
                    label: 'Resolved',
                    count: stats['resolved']!,
                    color: AppTheme.successGreen,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Pie chart
              if (stats['total']! > 0) ...[
                SectionHeader(title: 'Distribusi Status'),
                const SizedBox(height: 12),
                _buildPieChart(context, stats),
                const SizedBox(height: 24),
              ],

              // Recent tickets
              SectionHeader(
                title: 'Tiket Terbaru',
                action: 'Lihat Semua',
                onAction: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TicketListScreen())),
              ),
              const SizedBox(height: 12),
              if (recentTickets.isEmpty)
                const EmptyState(
                  message: 'Belum ada tiket',
                  icon: Icons.inbox_outlined,
                )
              else
                ...recentTickets.map((ticket) => _TicketCard(
                  ticket: ticket,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket.id)),
                  ),
                )),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, int> stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sections = <PieChartSectionData>[];
    final data = [
      ('Open', stats['open']!, const Color(0xFF3B82F6)),
      ('Progress', stats['in_progress']!, AppTheme.accentAmber),
      ('Resolved', stats['resolved']!, AppTheme.successGreen),
      ('Closed', stats['closed']!, const Color(0xFF6B7280)),
      ('Pending', stats['pending']!, AppTheme.dangerRed),
    ];
    for (final item in data) {
      if (item.$2 > 0) {
        sections.add(PieChartSectionData(
          value: item.$2.toDouble(),
          color: item.$3,
          title: '${item.$2}',
          radius: 55,
          titleStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.where((d) => d.$2 > 0).map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: d.$3, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Text(d.$1, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text('${d.$2}', style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: d.$3)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final ticket;
  final VoidCallback onTap;
  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            CategoryIcon(category: ticket.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.id,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(status: ticket.status),
          ],
        ),
      ),
    );
  }
}
