import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../ticket/ticket_list_screen.dart';
import '../ticket/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_screen.dart';
import '../helpdesk/helpdesk_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final unread = context.watch<AppProvider>().unreadCount;
    final role = user?.role ?? 'user';

    List<Widget> screens;
    List<BottomNavigationBarItem> items;

    if (role == 'admin') {
      screens = [
        const DashboardScreen(),
        const AdminScreen(),
        const TicketListScreen(),
        const NotificationScreen(),
        const ProfileScreen(),
      ];
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_rounded), label: 'Admin'),
        const BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_rounded), label: 'Tiket'),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_rounded),
          ),
          label: 'Notifikasi',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
      ];
    } else if (role == 'helpdesk') {
      screens = [
        const DashboardScreen(),
        const HelpdeskScreen(),
        const NotificationScreen(),
        const ProfileScreen(),
      ];
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.headset_mic_rounded), label: 'Tiket'),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_rounded),
          ),
          label: 'Notifikasi',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
      ];
    } else {
      screens = [
        const DashboardScreen(),
        const TicketListScreen(),
        const NotificationScreen(),
        const ProfileScreen(),
      ];
      items = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_rounded), label: 'Tiket Saya'),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.notifications_rounded),
          ),
          label: 'Notifikasi',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex.clamp(0, screens.length - 1),
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex.clamp(0, items.length - 1),
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: items.map((item) => NavigationDestination(
          icon: item.icon,
          label: item.label!,
        )).toList(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
