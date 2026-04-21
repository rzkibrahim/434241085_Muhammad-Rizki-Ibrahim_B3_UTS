import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../ticket/ticket_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userSearch = '';
  String _ticketSearch = '';
  String _roleFilter = 'all';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = provider.ticketStats;

    // Filter users
    var users = provider.users.where((u) => u.id != provider.currentUser!.id).toList();
    if (_roleFilter != 'all') users = users.where((u) => u.role == _roleFilter).toList();
    if (_userSearch.isNotEmpty) {
      users = users.where((u) =>
          u.name.toLowerCase().contains(_userSearch.toLowerCase()) ||
          u.email.toLowerCase().contains(_userSearch.toLowerCase())).toList();
    }

    // Filter tickets
    var tickets = provider.tickets;
    if (_ticketSearch.isNotEmpty) {
      tickets = tickets.where((t) =>
          t.title.toLowerCase().contains(_ticketSearch.toLowerCase()) ||
          t.id.toLowerCase().contains(_ticketSearch.toLowerCase()) ||
          t.createdByName.toLowerCase().contains(_ticketSearch.toLowerCase())).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () => _showCreateUserDialog(context),
            tooltip: 'Tambah User',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people_rounded, size: 18), text: 'Manajemen User'),
            Tab(icon: Icon(Icons.confirmation_num_rounded, size: 18), text: 'Semua Tiket'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // User management tab
          Column(
            children: [
              // Summary
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, AppTheme.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('Total User',
                        provider.users.where((u) => u.role == 'user').length, Colors.white),
                    _dividerV(),
                    _summaryItem('Helpdesk',
                        provider.users.where((u) => u.role == 'helpdesk').length, Colors.white),
                    _dividerV(),
                    _summaryItem('Admin',
                        provider.users.where((u) => u.role == 'admin').length, Colors.white),
                  ],
                ),
              ),
              // Search & filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _userSearch = v),
                        decoration: InputDecoration(
                          hintText: 'Cari pengguna...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _roleFilter,
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Semua')),
                            DropdownMenuItem(value: 'user', child: Text('User')),
                            DropdownMenuItem(value: 'helpdesk', child: Text('Helpdesk')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: (v) => setState(() => _roleFilter = v!),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? const EmptyState(
                        message: 'Tidak ada pengguna ditemukan',
                        icon: Icons.people_outline_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: users.length,
                        itemBuilder: (_, i) => _UserCard(
                          user: users[i],
                          isDark: isDark,
                          onDelete: () => _confirmDeleteUser(context, users[i]),
                          onEdit: () => _showEditUserDialog(context, users[i]),
                        ),
                      ),
              ),
            ],
          ),
          // All tickets tab
          Column(
            children: [
              // Ticket summary
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    _ticketSummaryChip('Open', stats['open']!, const Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    _ticketSummaryChip('Progress', stats['in_progress']!, AppTheme.accentAmber),
                    const SizedBox(width: 6),
                    _ticketSummaryChip('Resolved', stats['resolved']!, AppTheme.successGreen),
                    const SizedBox(width: 6),
                    _ticketSummaryChip('Closed', stats['closed']!, Colors.grey),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _ticketSearch = v),
                  decoration: InputDecoration(
                    hintText: 'Cari tiket...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: tickets.isEmpty
                    ? const EmptyState(
                        message: 'Tidak ada tiket ditemukan',
                        icon: Icons.inbox_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: tickets.length,
                        itemBuilder: (_, i) => _AdminTicketCard(
                          ticket: tickets[i],
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailScreen(ticketId: tickets[i].id),
                            ),
                          ),
                          onStatusChange: (s) => provider.updateTicketStatus(tickets[i].id, s),
                          onDelete: () => _confirmDeleteTicket(context, tickets[i].id),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateUserDialog(context),
              icon: const Icon(Icons.person_add_rounded),
              label: Text('Tambah User', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _summaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _dividerV() {
    return Container(width: 1, height: 36, color: Colors.white.withOpacity(0.3));
  }

  Widget _ticketSummaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text('$count', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus User', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Hapus pengguna "${user.name}"?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              context.read<AppProvider>().deleteUser(user.id);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTicket(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Tiket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Yakin hapus tiket $ticketId?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              context.read<AppProvider>().deleteTicket(ticketId);
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'user';
    String dept = 'IT';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Text('Tambah Pengguna Baru',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  _modalField(nameCtrl, 'Nama Lengkap', Icons.person_outline_rounded),
                  const SizedBox(height: 10),
                  _modalField(emailCtrl, 'Email', Icons.email_outlined,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 10),
                  _modalField(usernameCtrl, 'Username', Icons.alternate_email_rounded),
                  const SizedBox(height: 10),
                  _modalField(passCtrl, 'Password', Icons.lock_outline_rounded,
                      obscure: true),
                  const SizedBox(height: 10),
                  _modalField(phoneCtrl, 'No. Telepon', Icons.phone_outlined,
                      type: TextInputType.phone),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(labelText: 'Role', isDense: true),
                          items: ['user', 'helpdesk', 'admin']
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) => setModalState(() => role = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: dept,
                          decoration: const InputDecoration(labelText: 'Departemen', isDense: true),
                          items: ['IT', 'Finance', 'HR', 'Marketing', 'Operations']
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) => setModalState(() => dept = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        context.read<AppProvider>().createUser(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          username: usernameCtrl.text.trim(),
                          password: passCtrl.text,
                          role: role,
                          department: dept,
                          phone: phoneCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pengguna berhasil ditambahkan!',
                                style: GoogleFonts.plusJakartaSans()),
                            backgroundColor: AppTheme.successGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Text('Tambah Pengguna',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final phoneCtrl = TextEditingController(text: user.phone);
    final deptCtrl = TextEditingController(text: user.department);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Edit Pengguna',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _modalField(nameCtrl, 'Nama Lengkap', Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _modalField(emailCtrl, 'Email', Icons.email_outlined),
            const SizedBox(height: 10),
            _modalField(phoneCtrl, 'Telepon', Icons.phone_outlined),
            const SizedBox(height: 10),
            _modalField(deptCtrl, 'Departemen', Icons.business_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.read<AppProvider>().updateProfile(
                    nameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    phoneCtrl.text.trim(),
                    deptCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Data pengguna diperbarui!',
                          style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Text('Simpan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
      ),
      validator: (v) => v!.isEmpty ? '$label diperlukan' : null,
    );
  }
}

class _UserCard extends StatelessWidget {
  final user;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Color roleColor;
    String roleLabel;
    switch (user.role) {
      case 'admin': roleColor = AppTheme.purpleAccent; roleLabel = 'Admin'; break;
      case 'helpdesk': roleColor = AppTheme.accentCyan; roleLabel = 'Helpdesk'; break;
      default: roleColor = AppTheme.primaryBlue; roleLabel = 'User';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          AvatarWidget(initials: user.avatar, role: user.role, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(user.email,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(roleLabel,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
                    ),
                    const SizedBox(width: 6),
                    Text(user.department,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                color: AppTheme.primaryBlue,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: onDelete,
                color: AppTheme.dangerRed,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminTicketCard extends StatelessWidget {
  final ticket;
  final bool isDark;
  final VoidCallback onTap;
  final Function(String) onStatusChange;
  final VoidCallback onDelete;

  const _AdminTicketCard({
    required this.ticket,
    required this.isDark,
    required this.onTap,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(category: ticket.category),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.id,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.w700)),
                      Text(ticket.title,
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: onDelete,
                  color: AppTheme.dangerRed,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusBadge(status: ticket.status),
                const SizedBox(width: 8),
                PriorityBadge(priority: ticket.priority),
                const Spacer(),
                const Icon(Icons.person_outline_rounded, size: 11, color: Colors.grey),
                const SizedBox(width: 3),
                Text(ticket.createdByName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
              ],
            ),
            if (ticket.assignedToName != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.support_agent_rounded, size: 11, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(ticket.assignedToName!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            // Quick status change
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['open', 'in progress', 'resolved', 'closed'].map((s) {
                  final selected = ticket.status == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onStatusChange(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? statusColor(s)
                              : statusColor(s).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : statusColor(s),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color statusColor(String s) {
    switch (s) {
      case 'open': return const Color(0xFF3B82F6);
      case 'in progress': return AppTheme.accentAmber;
      case 'resolved': return AppTheme.successGreen;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }
}
