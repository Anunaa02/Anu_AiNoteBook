import 'dart:async';

import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'calendar_screen.dart';
import 'sticker_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'services/notification_service.dart';

class MainScreen extends StatefulWidget {
  final int initialTabIndex;
  final DateTime? initialCalendarDay;

  const MainScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialCalendarDay,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  DateTime? _calendarJumpDay;
  int _calendarJumpToken = 0;
  StreamSubscription<DateTime>? _calendarTapSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;

    final startupDay =
        widget.initialCalendarDay ?? NotificationService.consumePendingCalendarDay();
    if (startupDay != null) {
      _currentIndex = 1;
      _calendarJumpDay = _normalizeDay(startupDay);
      _calendarJumpToken = 1;
    }

    _calendarTapSub = NotificationService.calendarDayTapStream.listen((day) {
      if (!mounted) return;
      setState(() {
        _currentIndex = 1;
        _calendarJumpDay = _normalizeDay(day);
        _calendarJumpToken += 1;
      });
    });
  }

  @override
  void dispose() {
    _calendarTapSub?.cancel();
    super.dispose();
  }

  DateTime _normalizeDay(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    return DateTime(local.year, local.month, local.day);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onSwitchTab: (i) => setState(() => _currentIndex = i)),
      CalendarScreen(
        jumpToDay: _calendarJumpDay,
        jumpToDayToken: _calendarJumpToken,
      ),
      StickerScreen(onSwitchTab: (i) => setState(() => _currentIndex = i)),
      NotificationsScreen(
        onUnreadCountChanged: (count) {
          if (_unreadNotificationCount == count) return;
          setState(() => _unreadNotificationCount = count);
        },
      ),
      ProfileScreen(onSwitchTab: (i) => setState(() => _currentIndex = i)),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF1a0033),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a0033),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, 0),
                _navItem(Icons.calendar_month_rounded, 1),
                _navItem(Icons.auto_awesome_rounded, 2),
                _navItem(
                  Icons.notifications_rounded,
                  3,
                  badge: _unreadNotificationCount > 0,
                ),
                _navItem(Icons.person_rounded, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, {bool badge = false}) {
    final bool selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFFc084fc)
                    : Colors.white54,
                size: 26),
            if (badge && !selected)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFf87171),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
