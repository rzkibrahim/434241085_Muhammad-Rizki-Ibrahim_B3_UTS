import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../ticket/ticket_detail_screen.dart';

class HelpdeskScreen extends StatefulWidget {
  const HelpdeskScreen({super.key});

  @override
  State<HelpdeskScreen> createState() => _HelpdeskScreenState();
}

class _HelpdeskScreenState extends State<HelpdeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser!;
    final allTickets = provider.tickets;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // My assigned tickets
    var myTickets = allTickets
        .where((t) => t.assignedToId == user.id)
        .toList();

    // Unassigned tickets (open/pending without assignment)
    var unassigned = allTickets
        .where((t) => t.assignedToId == null && (t.status == 'open' || t.status == 'pending'))
        .toList();

    if (_searchQuery.isNotEmpty) {
      myTickets = myTickets
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      unassigned = unassigned
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiket Helpdesk'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ditugaskan'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${myTickets.length}',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum Diambil'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${unassigned.length}',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari tiket...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My assigned tickets
                myTickets.isEmpty
                    ? const EmptyState(
                        message: 'Belum ada tiket yang ditugaskan ke Anda',
                        icon: Icons.inbox_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: myTickets.length,
                        itemBuilder: (_, i) => _HelpdeskTicketCard(
                          ticket: myTickets[i],
                          isDark: isDark,
                          showActions: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailScreen(ticketId: myTickets[i].id),
                            ),
                          ),
                          onStatusChange: (status) =>
                              provider.updateTicketStatus(myTickets[i].id, status),
                        ),
                      ),
                // Unassigned tickets
                unassigned.isEmpty
                    ? const EmptyState(
                        message: 'Semua tiket sudah ditangani',
                        icon: Icons.check_circle_outline_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: unassigned.length,
                        itemBuilder: (_, i) => _HelpdeskTicketCard(
                          ticket: unassigned[i],
                          isDark: isDark,
                          showActions: false,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailScreen(ticketId: unassigned[i].id),
                            ),
                          ),
                          onTakeOver: () {
                            provider.assignTicket(unassigned[i].id, user.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tiket berhasil diambil!',
                                    style: GoogleFonts.plusJakartaSans()),
                                backgroundColor: AppTheme.successGreen,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpdeskTicketCard extends StatelessWidget {
  final ticket;
  final bool isDark;
  final bool showActions;
  final VoidCallback onTap;
  final Function(String)? onStatusChange;
  final VoidCallback? onTakeOver;

  const _HelpdeskTicketCard({
    required this.ticket,
    required this.isDark,
    required this.showActions,
    required this.onTap,
    this.onStatusChange,
    this.onTakeOver,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(category: ticket.category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.id,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.w700)),
                      Text(ticket.title,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                PriorityBadge(priority: ticket.priority),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket.description,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: Colors.grey.shade500, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                StatusBadge(status: ticket.status),
                const SizedBox(width: 8),
                const Icon(Icons.person_outline_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(ticket.createdByName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                const Spacer(),
                if (showActions && onStatusChange != null)
                  _statusDropdown(context)
                else if (onTakeOver != null)
                  _takeOverButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDropdown(BuildContext context) {
    final statuses = ['open', 'in progress', 'resolved', 'pending'];
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: statuses.contains(ticket.status) ? ticket.status : statuses.first,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 14, color: AppTheme.primaryBlue),
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue),
          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (s) {
            if (s != null) onStatusChange!(s);
          },
        ),
      ),
    );
  }

  Widget _takeOverButton() {
    return GestureDetector(
      onTap: onTakeOver,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.successGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Ambil Tiket',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
