import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'edit_ticket_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _commentCtrl = TextEditingController();
  bool _sendingComment = false;
  File? _commentAttachment;

  Future<void> _pickCommentImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _commentAttachment = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _sendComment() async {
    if (_commentCtrl.text.trim().isEmpty && _commentAttachment == null) return;
    setState(() => _sendingComment = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    
    String finalMsg = _commentCtrl.text.trim();
    if (_commentAttachment != null) {
      finalMsg += (finalMsg.isNotEmpty ? '\n\n' : '') + '[Mendelampirkan Foto: ${_commentAttachment!.path.split('/').last}]';
    }

    context.read<AppProvider>().addComment(widget.ticketId, finalMsg);
    _commentCtrl.clear();
    setState(() {
      _sendingComment = false;
      _commentAttachment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final ticket = provider.getTicketById(widget.ticketId);
    final user = provider.currentUser!;
    final role = user.role;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tiket')),
        body: const Center(child: Text('Tiket tidak ditemukan')),
      );
    }

    final isOwner = ticket.createdById == user.id;
    final canDelete = role == 'admin' || (role == 'user' && isOwner && ticket.status == 'open');
    final canEdit = role == 'user' && isOwner && ticket.status == 'open';

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.id),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditTicketScreen(ticketId: widget.ticketId))),
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _showDeleteDialog(context),
            ),
          if (role == 'helpdesk' || role == 'admin')
            IconButton(
              icon: const Icon(Icons.update_rounded),
              onPressed: () => _showStatusDialog(context, ticket.status),
            ),
          if (role == 'admin')
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () => _showAssignDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Ticket header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                          Text(ticket.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          Text(ticket.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                    ),
                    PriorityBadge(priority: ticket.priority),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusBadge(status: ticket.status),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt),
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _infoRow(Icons.person_outline_rounded, 'Pelapor', ticket.createdByName),
                if (ticket.assignedToName != null)
                  _infoRow(Icons.support_agent_rounded, 'Ditangani', ticket.assignedToName!),
              ],
            ),
          ),
          // Tabs
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.primaryBlue,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(text: 'Deskripsi'),
                Tab(text: 'Komentar'),
                Tab(text: 'Riwayat'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Description tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    ticket.description,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.7,
                      color: isDark ? Colors.white70 : const Color(0xFF374151)),
                  ),
                ),
                // Comments tab
                Column(
                  children: [
                    Expanded(
                      child: ticket.comments.isEmpty
                          ? const EmptyState(
                              message: 'Belum ada komentar',
                              icon: Icons.chat_bubble_outline_rounded)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: ticket.comments.length,
                              itemBuilder: (_, i) {
                                final c = ticket.comments[i];
                                final isMe = c.authorId == user.id;
                                return _CommentBubble(
                                  comment: c,
                                  isMe: isMe,
                                );
                              },
                            ),
                    ),
                    // Comment input
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10, offset: const Offset(0, -2))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_commentAttachment != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_commentAttachment!, width: 60, height: 60, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 0, right: 0,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _commentAttachment = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _pickCommentImage,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.add_photo_alternate_rounded, color: AppTheme.primaryBlue, size: 20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _commentCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis komentar...',
                                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    isDense: true,
                                  ),
                                  maxLines: null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _sendingComment ? null : _sendComment,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _sendingComment
                                      ? const SizedBox(width: 18, height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // History tab
                ticket.history.isEmpty
                    ? const EmptyState(
                        message: 'Belum ada riwayat',
                        icon: Icons.history_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ticket.history.length,
                        itemBuilder: (_, i) {
                          final h = ticket.history[ticket.history.length - 1 - i];
                          return _HistoryItem(history: h);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text('$label: ', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Tiket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('Yakin ingin menghapus tiket ini?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            onPressed: () {
              context.read<AppProvider>().deleteTicket(widget.ticketId);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, String current) {
    final statuses = ['open', 'in progress', 'resolved', 'closed', 'pending'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Status', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((s) => ListTile(
            title: StatusBadge(status: s),
            trailing: s == current ? const Icon(Icons.check, color: AppTheme.primaryBlue) : null,
            onTap: () {
              context.read<AppProvider>().updateTicketStatus(widget.ticketId, s);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    final helpdeskList = context.read<AppProvider>().helpdeskUsers;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign Tiket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: helpdeskList.map((h) => ListTile(
            leading: AvatarWidget(initials: h.avatar, role: h.role, size: 36),
            title: Text(h.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(h.department, style: GoogleFonts.plusJakartaSans(fontSize: 11)),
            onTap: () {
              context.read<AppProvider>().assignTicket(widget.ticketId, h.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tiket di-assign ke ${h.name}', style: GoogleFonts.plusJakartaSans()),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          )).toList(),
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final comment;
  final bool isMe;
  const _CommentBubble({required this.comment, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = comment.authorRole == 'helpdesk'
        ? AppTheme.accentCyan
        : comment.authorRole == 'admin'
            ? AppTheme.purpleAccent
            : AppTheme.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            AvatarWidget(
              initials: comment.authorName.substring(0, 2).toUpperCase(),
              role: comment.authorRole,
              size: 32,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      comment.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700, color: roleColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('HH:mm').format(comment.createdAt),
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppTheme.primaryBlue
                        : isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    comment.content,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isMe ? Colors.white : null,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final history;
  const _HistoryItem({required this.history});

  @override
  Widget build(BuildContext context) {
    Color roleColor;
    switch (history.performedByRole) {
      case 'admin': roleColor = AppTheme.purpleAccent; break;
      case 'helpdesk': roleColor = AppTheme.accentCyan; break;
      default: roleColor = AppTheme.primaryBlue;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 40, color: Colors.grey.shade200),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.action,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'oleh ${history.performedBy} • ${DateFormat('dd MMM, HH:mm').format(history.timestamp)}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
