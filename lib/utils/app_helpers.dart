import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return const Color(0xFF3B82F6);
      case 'in progress': return const Color(0xFFF59E0B);
      case 'resolved': return const Color(0xFF10B981);
      case 'closed': return const Color(0xFF6B7280);
      case 'pending': return const Color(0xFFEF4444);
      default: return const Color(0xFF94A3B8);
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open': return 'Open';
      case 'in progress': return 'Proses';
      case 'resolved': return 'Selesai';
      case 'closed': return 'Tutup';
      case 'pending': return 'Tunda';
      default: return status.toUpperCase();
    }
  }

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      case 'low': return const Color(0xFF10B981);
      default: return const Color(0xFF94A3B8);
    }
  }

  static String priorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return 'Tinggi';
      case 'medium': return 'Sedang';
      case 'low': return 'Rendah';
      default: return priority.toUpperCase();
    }
  }

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hardware': return Icons.computer;
      case 'software': return Icons.apps;
      case 'network': return Icons.wifi;
      case 'account': return Icons.manage_accounts;
      default: return Icons.confirmation_number;
    }
  }

  static String categoryLabel(String category) {
    return category; 
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }
}
