import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/ticket_model.dart';
import '../models/notification_model.dart';
import '../utils/dummy_data.dart';

class AppProvider extends ChangeNotifier {
  UserModel? _currentUser;
  List<TicketModel> _tickets = List.from(DummyData.tickets);
  List<UserModel> _users = List.from(DummyData.users);
  List<NotificationModel> _notifications = List.from(DummyData.notifications);
  bool _isDarkMode = false;
  final Uuid _uuid = const Uuid();

  UserModel? get currentUser => _currentUser;
  List<TicketModel> get tickets => _tickets;
  List<UserModel> get users => _users;
  List<NotificationModel> get notifications => _notifications;
  bool get isDarkMode => _isDarkMode;

  // Filtered notifications for current user
  List<NotificationModel> get userNotifications {
    if (_currentUser == null) return [];
    // Admin/helpdesk see all, users see only their own
    if (_currentUser!.role != 'user') return _notifications;
    return _notifications.where((n) {
      final ticket = _tickets.firstWhere(
        (t) => t.id == n.ticketId,
        orElse: () => _tickets.first,
      );
      return ticket.createdById == _currentUser!.id;
    }).toList();
  }

  int get unreadCount => userNotifications.where((n) => !n.isRead).length;

  // Auth
  bool login(String username, String password) {
    final user = _users.firstWhere(
      (u) => u.username == username && u.password == password,
      orElse: () => _users[0],
    );
    if (user.username == username && user.password == password) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  bool register(String name, String email, String username, String password, String department, String phone) {
    final exists = _users.any((u) => u.username == username || u.email == email);
    if (exists) return false;
    final newUser = UserModel(
      id: 'u${_uuid.v4().substring(0, 6)}',
      name: name,
      email: email,
      username: username,
      password: password,
      role: 'user',
      department: department,
      avatar: name.substring(0, 2).toUpperCase(),
      phone: phone,
    );
    _users.add(newUser);
    notifyListeners();
    return true;
  }

  bool resetPassword(String email, String newPassword) {
    final idx = _users.indexWhere((u) => u.email == email);
    if (idx == -1) return false;
    final u = _users[idx];
    _users[idx] = UserModel(
      id: u.id, name: u.name, email: u.email,
      username: u.username, password: newPassword,
      role: u.role, department: u.department,
      avatar: u.avatar, phone: u.phone,
    );
    notifyListeners();
    return true;
  }

  void updateProfile(String name, String email, String phone, String department) {
    if (_currentUser == null) return;
    final idx = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (idx == -1) return;
    final updated = _currentUser!.copyWith(
      name: name, email: email, phone: phone, department: department,
    );
    _users[idx] = UserModel(
      id: updated.id, name: updated.name, email: updated.email,
      username: updated.username, password: _users[idx].password,
      role: updated.role, department: updated.department,
      avatar: name.substring(0, 2).toUpperCase(), phone: updated.phone,
    );
    _currentUser = _users[idx];
    notifyListeners();
  }

  // Tickets
  List<TicketModel> get userTickets {
    if (_currentUser == null) return [];
    if (_currentUser!.role == 'user') {
      return _tickets.where((t) => t.createdById == _currentUser!.id).toList();
    }
    return _tickets;
  }

  TicketModel? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
  }) {
    if (_currentUser == null) return;
    final ticketNumber = _tickets.length + 1;
    final id = 'TKT-${ticketNumber.toString().padLeft(3, '0')}';
    final newTicket = TicketModel(
      id: id,
      title: title,
      description: description,
      category: category,
      priority: priority,
      status: 'open',
      createdById: _currentUser!.id,
      createdByName: _currentUser!.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      history: [
        TicketHistoryModel(
          id: _uuid.v4(),
          ticketId: id,
          action: 'Tiket dibuat',
          performedBy: _currentUser!.name,
          performedByRole: _currentUser!.role,
          timestamp: DateTime.now(),
        ),
      ],
    );
    _tickets.insert(0, newTicket);
    _addNotification(
      title: 'Tiket baru dibuat',
      body: 'Tiket "$title" berhasil dibuat',
      ticketId: id,
      type: 'new_ticket',
    );
    notifyListeners();
  }

  void updateTicketStatus(String ticketId, String newStatus) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    final ticket = _tickets[idx];
    final newHistory = List<TicketHistoryModel>.from(ticket.history)
      ..add(TicketHistoryModel(
        id: _uuid.v4(),
        ticketId: ticketId,
        action: 'Status diubah menjadi ${_statusLabel(newStatus)}',
        performedBy: _currentUser?.name ?? 'System',
        performedByRole: _currentUser?.role ?? 'system',
        timestamp: DateTime.now(),
      ));
    _tickets[idx] = ticket.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      history: newHistory,
    );
    _addNotification(
      title: 'Status tiket diperbarui',
      body: 'Status "${ ticket.title}" diubah menjadi ${_statusLabel(newStatus)}',
      ticketId: ticketId,
      type: 'status_update',
    );
    notifyListeners();
  }

  void assignTicket(String ticketId, String helpdeskId) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    final helpdesk = _users.firstWhere((u) => u.id == helpdeskId);
    final ticket = _tickets[idx];
    final newHistory = List<TicketHistoryModel>.from(ticket.history)
      ..add(TicketHistoryModel(
        id: _uuid.v4(),
        ticketId: ticketId,
        action: 'Tiket di-assign ke ${helpdesk.name}',
        performedBy: _currentUser?.name ?? 'Admin',
        performedByRole: _currentUser?.role ?? 'admin',
        timestamp: DateTime.now(),
      ));
    _tickets[idx] = ticket.copyWith(
      assignedToId: helpdeskId,
      assignedToName: helpdesk.name,
      status: 'in progress',
      updatedAt: DateTime.now(),
      history: newHistory,
    );
    notifyListeners();
  }

  void updateTicket({
    required String ticketId,
    required String title,
    required String description,
    required String category,
    required String priority,
  }) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    final ticket = _tickets[idx];
    final newHistory = List<TicketHistoryModel>.from(ticket.history)
      ..add(TicketHistoryModel(
        id: _uuid.v4(),
        ticketId: ticketId,
        action: 'Tiket diperbarui',
        performedBy: _currentUser?.name ?? 'User',
        performedByRole: _currentUser?.role ?? 'user',
        timestamp: DateTime.now(),
      ));
    _tickets[idx] = ticket.copyWith(
      title: title,
      description: description,
      category: category,
      priority: priority,
      updatedAt: DateTime.now(),
      history: newHistory,
    );
    notifyListeners();
  }

  void deleteTicket(String ticketId) {
    _tickets.removeWhere((t) => t.id == ticketId);
    _notifications.removeWhere((n) => n.ticketId == ticketId);
    notifyListeners();
  }

  void addComment(String ticketId, String content) {
    if (_currentUser == null) return;
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;
    final ticket = _tickets[idx];
    final newComment = CommentModel(
      id: _uuid.v4(),
      ticketId: ticketId,
      authorId: _currentUser!.id,
      authorName: _currentUser!.name,
      authorRole: _currentUser!.role,
      content: content,
      createdAt: DateTime.now(),
    );
    final newComments = List<CommentModel>.from(ticket.comments)..add(newComment);
    final newHistory = List<TicketHistoryModel>.from(ticket.history)
      ..add(TicketHistoryModel(
        id: _uuid.v4(),
        ticketId: ticketId,
        action: 'Komentar ditambahkan oleh ${_currentUser!.name}',
        performedBy: _currentUser!.name,
        performedByRole: _currentUser!.role,
        timestamp: DateTime.now(),
      ));
    _tickets[idx] = ticket.copyWith(
      comments: newComments,
      updatedAt: DateTime.now(),
      history: newHistory,
    );
    _addNotification(
      title: 'Komentar baru',
      body: '${_currentUser!.name} menambahkan komentar pada tiket "${ticket.title}"',
      ticketId: ticketId,
      type: 'new_comment',
    );
    notifyListeners();
  }

  // Users (admin only)
  void createUser({
    required String name,
    required String email,
    required String username,
    required String password,
    required String role,
    required String department,
    required String phone,
  }) {
    final newUser = UserModel(
      id: _uuid.v4().substring(0, 8),
      name: name,
      email: email,
      username: username,
      password: password,
      role: role,
      department: department,
      avatar: name.substring(0, 2).toUpperCase(),
      phone: phone,
    );
    _users.add(newUser);
    notifyListeners();
  }

  void deleteUser(String userId) {
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  // Notifications
  void _addNotification({
    required String title,
    required String body,
    required String ticketId,
    required String type,
  }) {
    _notifications.insert(0, NotificationModel(
      id: _uuid.v4(),
      title: title,
      body: body,
      ticketId: ticketId,
      type: type,
      createdAt: DateTime.now(),
    ));
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open': return 'Open';
      case 'in progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      case 'pending': return 'Pending';
      default: return status;
    }
  }

  // Stats
  Map<String, int> get ticketStats {
    final relevant = userTickets;
    return {
      'total': relevant.length,
      'open': relevant.where((t) => t.status == 'open').length,
      'in_progress': relevant.where((t) => t.status == 'in progress').length,
      'resolved': relevant.where((t) => t.status == 'resolved').length,
      'closed': relevant.where((t) => t.status == 'closed').length,
      'pending': relevant.where((t) => t.status == 'pending').length,
    };
  }

  List<UserModel> get helpdeskUsers =>
      _users.where((u) => u.role == 'helpdesk').toList();
}
