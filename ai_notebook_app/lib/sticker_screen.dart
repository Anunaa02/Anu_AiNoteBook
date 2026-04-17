import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

class StickerScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const StickerScreen({super.key, this.onSwitchTab});

  @override
  State<StickerScreen> createState() => _StickerScreenState();
}

class _StickerScreenState extends State<StickerScreen> {
  final List<String> _stickers = [
    '🐶',
    '🐱',
    '🦊',
    '🐻',
    '🐼',
    '🦁',
    '🐯',
    '🦝',
    '🐨',
    '🐸',
  ];
  final int _currentIndex = 0;
  final List<String> _backgrounds = [
    '💪 Gym Vibes',
    '☀️ Morning Energy',
    '🌙 Night Owl',
    '🏆 Winner',
    '🎵 Music Mood',
    '📚 Study Mode',
  ];
  int _bgIndex = 0;

  // ✨ AI Sticker Generator
  final TextEditingController _promptCtrl = TextEditingController();
  String? _aiStickerUrl;
  bool _generating = false;
  bool _savingToCalendar = false;

  String _formatDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatReminder(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  Future<DateTime?> _pickCalendarDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final base = initial ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null || !mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );

    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _saveGeneratedStickerToCalendar() async {
    if (_aiStickerUrl == null || _aiStickerUrl!.trim().isEmpty) return;

    final picked = await _pickCalendarDateTime(initial: DateTime.now());
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _savingToCalendar = true);

    try {
      final prompt = _promptCtrl.text.trim();
      final label = prompt.isNotEmpty ? prompt : 'Generated sticker';
      final noteDay = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
      final noteDate = _formatDateOnly(noteDay);
      final reminderAt = picked.toUtc().toIso8601String();

      final noteId = await ApiService.createNote(
        title: label,
        content: label,
        mood: '✨',
        noteDate: noteDate,
        reminderAt: reminderAt,
      );

      if (noteId == null || noteId.isEmpty) {
        throw Exception('Note creation failed');
      }

      final ok = await ApiService.saveNoteSticker(noteId, _aiStickerUrl!.trim());
      if (!ok) {
        throw Exception('Sticker save failed');
      }

      await NotificationService.scheduleReminderNotification(
        noteId: noteId,
        reminderAt: picked,
        title: label,
        body: label,
        stickerUrl: _aiStickerUrl!.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sticker saved for ${_formatReminder(picked)}'),
          backgroundColor: const Color(0xFF7c3aed),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      widget.onSwitchTab?.call(1);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save sticker to calendar'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingToCalendar = false);
      }
    }
  }

  Future<void> _generateAISticker() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    
    setState(() { _generating = true; _aiStickerUrl = null; });
    
    try {
      final url = await ApiService.generateSticker(_promptCtrl.text.trim());
      await NotificationService.showStickerGeneratedNotification(
        title: 'Sticker generated',
        body: _promptCtrl.text.trim(),
        stickerUrl: url,
      );
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

  bool _isSvgDataUri(String value) => value.startsWith('data:image/svg');

  bool _isDataUri(String value) => value.startsWith('data:');

  bool _isSvgUrl(String value) {
    final uri = Uri.tryParse(value);
    final path = uri?.path.toLowerCase() ?? value.toLowerCase();
    return path.endsWith('.svg');
  }

  Widget _imageErrorPlaceholder({double size = 300}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.white70, size: 36),
          SizedBox(height: 8),
          Text(
            'Sticker load failed',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStickerImage(
    String src, {
    required double width,
    required double height,
    BoxFit fit = BoxFit.contain,
  }) {
    if (_isSvgDataUri(src)) {
      return SvgPicture.string(
        String.fromCharCodes(base64Decode(src.split(',').last)),
        width: width,
        height: height,
        fit: fit,
      );
    }

    if (_isDataUri(src)) {
      return Image.memory(
        base64Decode(src.split(',').last),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _imageErrorPlaceholder(size: width),
      );
    }

    if (_isSvgUrl(src)) {
      return SvgPicture.network(
        src,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) => SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _imageErrorPlaceholder(size: width),
    );
  }

  Widget _buildHeroCard() {
    return Container(
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
            color: const Color(0xFF7c3aed).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(_stickers[_currentIndex], style: const TextStyle(fontSize: 100)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _backgrounds[_bgIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
            const Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Stickers",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.auto_awesome, color: Color(0xFFc084fc)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    _buildHeroCard(),

                    const SizedBox(height: 20),

                    // Mood quick-pick
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pick a mood:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _backgrounds.length,
                        itemBuilder: (ctx, i) {
                          final selected = _bgIndex == i;
                          return GestureDetector(
                            onTap: () => setState(() => _bgIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF7c3aed),
                                          Color(0xFFa855f7),
                                        ],
                                      )
                                    : null,
                                color: selected
                                    ? null
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                _backgrounds[i],
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ✨ AI Sticker Generator
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: null,
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
                              hintText:
                                  'Describe sticker idea (e.g. cozy study night, gym motivation)',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
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
                                  : const Text('Generate Sticker'),
                            ),
                          ),
                          if (_aiStickerUrl != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildStickerImage(
                                  _aiStickerUrl!,
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _savingToCalendar
                                    ? null
                                    : _saveGeneratedStickerToCalendar,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFc084fc)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: null,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: _savingToCalendar
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.calendar_month),
                                label: Text(
                                  _savingToCalendar
                                      ? 'Saving...'
                                      : 'Calendar дээр хадгалах',
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

}
