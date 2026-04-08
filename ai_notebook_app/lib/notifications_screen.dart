import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _notifs = [
    _Notif(
      icon: '💬',
      title: "Don't forget to write in\nyour journal today 📖",
      subtitle: "7:00 PM · Reminder",
      time: "40m ago",
      read: false,
    ),
    _Notif(
      icon: '😊',
      title: "Remember to stay positive!\nIn positia",
      subtitle: "· Reminder",
      time: "40m",
      read: false,
    ),
    _Notif(
      icon: '🌙',
      title: "Write about how you feel\nbefore sleep 🌙",
      subtitle: "Tap to view",
      time: "20m",
      read: true,
    ),
  ];

  int get _unreadCount => _notifs.where((n) => !n.read).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a0033), Color(0xFF2d1b4e)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Notifications",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Stack(
                    children: [
                      const Icon(Icons.notifications_rounded,
                          color: Colors.white70, size: 28),
                      if (_unreadCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFf87171),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "$_unreadCount",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Mark all read
            if (_unreadCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => setState(
                          () => _notifs.forEach((n) => n.read = true)),
                      child: const Text("Mark all as read",
                          style: TextStyle(
                              color: Color(0xFFc084fc), fontSize: 13)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _notifs.length,
                itemBuilder: (ctx, i) {
                  final n = _notifs[i];
                  return GestureDetector(
                    onTap: () => setState(() => n.read = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: n.read
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: n.read
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFF7c3aed).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4c1d95),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                                  child: n.imageUrl != null 
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.network(n.imageUrl!, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Text(n.icon, style: const TextStyle(fontSize: 22)),
                                          ),
                                        )
                                      : Text(n.icon,
                                    style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title,
                                    style: TextStyle(
                                        color: n.read
                                            ? Colors.white70
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: n.read
                                            ? FontWeight.normal
                                            : FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.add,
                                        color: Color(0xFFc084fc), size: 14),
                                    const SizedBox(width: 4),
                                    Text(n.subtitle,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(n.time,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11)),
                              const SizedBox(height: 6),
                              if (!n.read)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFa855f7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notif {
  final String icon, title, subtitle, time;
  final String? imageUrl;
  bool read;
  _Notif({
    required this.icon,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.read,
  });
}
