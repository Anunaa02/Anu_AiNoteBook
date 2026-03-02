import 'package:flutter/material.dart';

class StickerScreen extends StatefulWidget {
  const StickerScreen({super.key});

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen> {
  final List<String> _stickers = [
    '🐶', '🐱', '🦊', '🐻', '🐼',
    '🦁', '🐯', '🦝', '🐨', '🐸',
  ];
  int _currentIndex = 0;
  final List<String> _backgrounds = [
    '💪 Gym Vibes', '☀️ Morning Energy', '🌙 Night Owl',
    '🏆 Winner', '🎵 Music Mood', '📚 Study Mode',
  ];
  int _bgIndex = 0;
  bool _saved = false;

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
                  const Text("AI Stickers",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const Icon(Icons.auto_awesome, color: Color(0xFFc084fc)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Sticker preview card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4c1d95), Color(0xFF6d28d9)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7c3aed).withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _stickers[_currentIndex],
                            style: const TextStyle(fontSize: 100),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _backgrounds[_bgIndex],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mood quick-pick
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Pick a mood:",
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _backgrounds.length,
                        itemBuilder: (ctx, i) => GestureDetector(
                          onTap: () => setState(() => _bgIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _bgIndex == i
                                  ? const LinearGradient(colors: [
                                      Color(0xFF7c3aed),
                                      Color(0xFFa855f7)
                                    ])
                                  : null,
                              color: _bgIndex != i
                                  ? Colors.white.withOpacity(0.08)
                                  : null,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: _bgIndex == i
                                      ? Colors.transparent
                                      : Colors.white24),
                            ),
                            child: Text(_backgrounds[i],
                                style: TextStyle(
                                    color: _bgIndex == i
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 13)),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _actionBtn(
                            label: "Regenerate",
                            icon: Icons.refresh_rounded,
                            onTap: () => setState(() {
                              _saved = false;
                              _currentIndex =
                                  (_currentIndex + 1) % _stickers.length;
                            }),
                            color: Colors.white.withOpacity(0.1),
                            borderColor: Colors.white24,
                            textColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _actionBtn(
                            label: _saved ? "Saved! ✓" : "Save Sticker",
                            icon: _saved
                                ? Icons.check_circle_rounded
                                : Icons.download_rounded,
                            onTap: () => setState(() => _saved = true),
                            color: const Color(0xFF7c3aed),
                            borderColor: Colors.transparent,
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color borderColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
