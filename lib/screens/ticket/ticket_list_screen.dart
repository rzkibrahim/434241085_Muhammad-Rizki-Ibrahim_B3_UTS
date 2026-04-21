import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final statuses = ['all', 'open', 'in progress', 'resolved', 'closed', 'pending'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final role = provider.currentUser?.role ?? 'user';
    var tickets = provider.userTickets;

    // Filter by status
    if (_filterStatus != 'all') {
      tickets = tickets.where((t) => t.status == _filterStatus).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      tickets = tickets.where((t) =>
        t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'user' ? 'Tiket Saya' : 'Semua Tiket'),
        actions: [
          if (role == 'user')
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateTicketScreen())),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari tiket...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Status filter chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: statuses.length,
              itemBuilder: (_, i) {
                final s = statuses[i];
                final selected = _filterStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      s == 'all' ? 'Semua' : s.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : null,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _filterStatus = s),
                    backgroundColor: selected ? AppTheme.primaryBlue : null,
                    selectedColor: AppTheme.primaryBlue,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              },
            ),
          ),
          // Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${tickets.length} tiket ditemukan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: tickets.isEmpty
                ? const EmptyState(
                    message: 'Tidak ada tiket ditemukan',
                    icon: Icons.inbox_outlined,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: tickets.length,
                    itemBuilder: (_, i) => _TicketListItem(
                      ticket: tickets[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticketId: tickets[i].id),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: role == 'user'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CreateTicketScreen())),
              icon: const Icon(Icons.add_rounded),
              label: Text('Buat Tiket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _TicketListItem extends StatelessWidget {
  final ticket;
  final VoidCallback onTap;
  const _TicketListItem({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
                      Text(
                        ticket.id,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue),
                      ),
                      Text(
                        ticket.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PriorityBadge(priority: ticket.priority),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ticket.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.grey.shade500, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatusBadge(status: ticket.status),
                const Spacer(),
                if (ticket.assignedToName != null) ...[
                  const Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    ticket.assignedToName!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${ticket.comments.length}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
