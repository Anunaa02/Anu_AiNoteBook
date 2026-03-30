import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';

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

  // ✨ AI Sticker Generator
  final TextEditingController _promptCtrl = TextEditingController();
  String? _aiStickerUrl;
  bool _generating = false;

  Future<void> _generateAISticker() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    
    setState(() { _generating = true; _aiStickerUrl = null; });
    
    try {
      final url = await ApiService.generateSticker(_promptCtrl.text.trim());
      if (mounted) {
        setState(() { _aiStickerUrl = url; _generating = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✨ Sticker generated!'),
            backgroundColor: const Color(0xFF7c3aed),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {  
      if (!mounted) return;
      setState(() => _generating = false);
      
      String errorMsg = e.toString().replaceFirst('Exception: ', '');
      
      Color bgColor = Colors.red.shade700;
      IconData icon = Icons.error_outline;
      
      // Check for specific error types
      if (errorMsg.contains('invalid') || errorMsg.contains('401')) {
        errorMsg = '🔑 Invalid OpenAI API key';
        bgColor = Colors.red.shade700;
        icon = Icons.vpn_key_off;
      } else if (errorMsg.contains('rate limit') || errorMsg.contains('429')) {
        errorMsg = '⏳ Rate limited - please try again in a moment';
        bgColor = Colors.orange.shade700;
        icon = Icons.schedule;
      } else if (errorMsg.contains('quota') || errorMsg.contains('insufficient')) {
        errorMsg = '💳 OpenAI quota exceeded - check billing';
        bgColor = Colors.red.shade700;
        icon = Icons.warning;
      } else if (errorMsg.contains('Network')) {
        errorMsg = '🌐 Network error - check connection';
        bgColor = Colors.red.shade700;
        icon = Icons.cloud_off;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMsg, maxLines: 2)),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

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
                  const Text("Stickers",
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
                          Text(_stickers[_currentIndex],
                              style: const TextStyle(fontSize: 100)),
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

                    // ✨ AI Sticker Generator
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text('✨', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 6),
                              Text(
                                'Generate AI Sticker',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _promptCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'e.g., "happy cat", "cute dog"...',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _generating ? null : _generateAISticker,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7c3aed),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFF4c1d95),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _generating
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Generate 🎨'),
                            ),
                          ),
                          if (_aiStickerUrl != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _aiStickerUrl!.startsWith('data:image/svg')
                                    ? SvgPicture.string(
                                      String.fromCharCodes(
                                        base64Decode(
                                          _aiStickerUrl!.split(',')[1],
                                        ),
                                      ),
                                      width: 300,
                                      height: 300,
                                      fit: BoxFit.contain,
                                    )
                                    : Image.network(
                                      _aiStickerUrl!,
                                      width: 300,
                                      height: 300,
                                      fit: BoxFit.contain,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
