class CommentModel {
  final String id;
  final String ticketId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.createdAt,
  });
}

class TicketHistoryModel {
  final String id;
  final String ticketId;
  final String action;
  final String performedBy;
  final String performedByRole;
  final DateTime timestamp;

  TicketHistoryModel({
    required this.id,
    required this.ticketId,
    required this.action,
    required this.performedBy,
    required this.performedByRole,
    required this.timestamp,
  });
}

class TicketModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority; // low, medium, high
  final String status; // open, in progress, resolved, closed, pending
  final String createdById;
  final String createdByName;
  final String? assignedToId;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> attachments;
  final List<CommentModel> comments;
  final List<TicketHistoryModel> history;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdById,
    required this.createdByName,
    this.assignedToId,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.comments = const [],
    this.history = const [],
  });

  TicketModel copyWith({
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    String? assignedToId,
    String? assignedToName,
    DateTime? updatedAt,
    List<String>? attachments,
    List<CommentModel>? comments,
    List<TicketHistoryModel>? history,
  }) {
    return TicketModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdById: createdById,
      createdByName: createdByName,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      history: history ?? this.history,
    );
  }
}
