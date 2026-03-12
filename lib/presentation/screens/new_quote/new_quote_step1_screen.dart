import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../providers/new_quote_provider.dart';

class NewQuoteStep1Screen extends ConsumerStatefulWidget {
  const NewQuoteStep1Screen({super.key});

  @override
  ConsumerState<NewQuoteStep1Screen> createState() =>
      _NewQuoteStep1ScreenState();
}

class _NewQuoteStep1ScreenState extends ConsumerState<NewQuoteStep1Screen>
    with SingleTickerProviderStateMixin {
  final _addressController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;

  // Waveform animation
  late AnimationController _waveController;
  bool _isRecording = false;
  bool _isStartingRecord = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String? _documentsDir;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _primeDocsDir();
    _playerSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
      }
      if (_isPlaying != state.playing) {
        setState(() => _isPlaying = state.playing);
      }
    });
    // Pre-fill address from state on first open
    final state = ref.read(newQuoteProvider);
    _addressController.text = state.jobAddress;
    if (state.voiceNotePath != null) {
      _recordingPath = state.voiceNotePath;
      _hasRecording = true;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _addressController.dispose();
    _audioRecorder.dispose();
    _playerSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _primeDocsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    _documentsDir = dir.path;
  }

  Future<String> _ensureDocsDir() async {
    if (_documentsDir != null) return _documentsDir!;
    final dir = await getApplicationDocumentsDirectory();
    _documentsDir = dir.path;
    return _documentsDir!;
  }

  // ── Back/Discard ─────────────────────────────────────────────────────────

  Future<void> _onBack() async {
    final state = ref.read(newQuoteProvider);
    final isDirty =
        state.selectedJobType != null ||
        state.photos.isNotEmpty ||
        state.jobAddress.isNotEmpty ||
        _hasRecording;

    if (!isDirty) {
      if (mounted) context.pop();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Discard this quote?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'All progress on this quote will be lost.',
          style: TextStyle(color: Colors.grey.shade400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Keep Editing',
              style: TextStyle(color: Color(0xFFEC5B13)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      ref.read(newQuoteProvider.notifier).reset();
      context.pop();
    }
  }

  // ── Photo Picker ──────────────────────────────────────────────────────────

  Future<void> _showImageSourceSheet() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1C1F2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Job Photo',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC5B13).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFFEC5B13),
                ),
              ),
              title: const Text(
                'Take a Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Use your camera',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC5B13).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFFEC5B13),
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Select existing photo',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (result == null) return;
    final picked = await _imagePicker.pickImage(
      source: result,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      ref.read(newQuoteProvider.notifier).addPhoto(File(picked.path));
    }
  }

  // ── Audio Recording ───────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_isRecording || _isStartingRecord) return;
    _isStartingRecord = true;
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) return;
      await _audioPlayer.stop();
      final dirPath = await _ensureDocsDir();
      _recordingPath =
          '$dirPath/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: _recordingPath!,
      );
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _hasRecording = false;
        _isPlaying = false;
      });
      _waveController.repeat(reverse: true);
    } finally {
      _isStartingRecord = false;
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    await _audioRecorder.stop();
    _waveController.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _hasRecording = true;
      _isPlaying = false;
    });
    if (_recordingPath != null) {
      ref.read(newQuoteProvider.notifier).setVoiceNote(_recordingPath!);
    }
  }

  Future<void> _togglePlayback() async {
    if (_recordingPath == null || _isRecording) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }
      await _audioPlayer.setFilePath(_recordingPath!);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playback error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // ── Validation & Navigation ───────────────────────────────────────────────

  void _onContinue() {
    final state = ref.read(newQuoteProvider);
    if (state.selectedJobType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a job type to continue.'),
          backgroundColor: const Color(0xFF1C1F2A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    ref
        .read(newQuoteProvider.notifier)
        .setJobAddress(_addressController.text.trim());
    context.push('/new-quote/step2');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newQuoteProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: _onBack,
        ),
        centerTitle: true,
        title: Text(
          'New Quote',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '1 of 3',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress pills
          const _StepProgressPills(currentStep: 1),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Job Type ─────────────────────────────────────────────
                  const _SectionLabel('Job Type'),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.jobTypes.map((type) {
                        final isSelected = state.selectedJobType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _JobTypeChip(
                            label: type,
                            isSelected: isSelected,
                            onTap: () {
                              if (isSelected) {
                                ref
                                    .read(newQuoteProvider.notifier)
                                    .deselectJobType();
                              } else {
                                ref
                                    .read(newQuoteProvider.notifier)
                                    .selectJobType(type);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Job Photos ────────────────────────────────────────────
                  const _SectionLabel('Job Photos'),
                  const SizedBox(height: 12),
                  if (state.photos.isEmpty)
                    _PhotoAddBox(onTap: _showImageSourceSheet)
                  else ...[
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            state.photos.length +
                            (state.photos.length < 5 ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          if (i == state.photos.length) {
                            // Add more button
                            return GestureDetector(
                              onTap: _showImageSourceSheet,
                              child: Container(
                                width: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1F2A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEC5B13,
                                    ).withAlpha(60),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Color(0xFFEC5B13),
                                  size: 28,
                                ),
                              ),
                            );
                          }
                          return _PhotoThumb(
                            file: state.photos[i],
                            onRemove: () => ref
                                .read(newQuoteProvider.notifier)
                                .removePhoto(i),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${state.photos.length}/5 photos added',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // ── Voice Note ────────────────────────────────────────────
                  const _SectionLabel('Voice Note (Optional)'),
                  const SizedBox(height: 12),
                  _VoiceNoteCard(
                    isRecording: _isRecording,
                    hasRecording: _hasRecording,
                    waveController: _waveController,
                    onStartRecord: _startRecording,
                    onStopRecord: _stopRecording,
                    onClear: () {
                      _audioPlayer.stop();
                      setState(() {
                        _hasRecording = false;
                        _isPlaying = false;
                        _recordingPath = null;
                      });
                      ref.read(newQuoteProvider.notifier).clearVoiceNote();
                    },
                    onPlayPause: _togglePlayback,
                    isPlaying: _isPlaying,
                  ),
                  const SizedBox(height: 32),

                  // ── Job Address ───────────────────────────────────────────
                  const _SectionLabel('Job Address'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '123 Main St, City, State',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFEC5B13),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1C1F2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEC5B13),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _ContinueBottomBar(onContinue: _onContinue),
    );
  }
}

// ─── Step Progress Pills ──────────────────────────────────────────────────────

class _StepProgressPills extends StatelessWidget {
  final int currentStep;
  const _StepProgressPills({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i + 1 == currentStep;
          final isDone = i + 1 < currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                decoration: BoxDecoration(
                  gradient: isActive || isDone
                      ? const LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                        )
                      : null,
                  color: isActive || isDone ? null : const Color(0xFF2A2D3E),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Job Type Chip ────────────────────────────────────────────────────────────

class _JobTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _JobTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFF1C1F2A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade700,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEC5B13).withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade400,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Photo Add Box ────────────────────────────────────────────────────────────

class _PhotoAddBox extends StatelessWidget {
  final VoidCallback onTap;
  const _PhotoAddBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1F2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEC5B13).withAlpha(77),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC5B13).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFFEC5B13),
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add Job Images',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'High resolution preferred',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEC5B13).withAlpha(77)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = 16.0;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );

    final metrics = path.computeMetrics().first;
    double distance = 0;
    while (distance < metrics.length) {
      final endDistance = (distance + dashWidth < metrics.length)
          ? distance + dashWidth
          : metrics.length;
      final segment = metrics.extractPath(distance, endDistance);
      canvas.drawPath(segment, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

// ─── Photo Thumbnail ──────────────────────────────────────────────────────────

class _PhotoThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F1117), width: 2),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Voice Note Card ──────────────────────────────────────────────────────────

class _VoiceNoteCard extends StatelessWidget {
  final bool isRecording;
  final bool hasRecording;
  final bool isPlaying;
  final AnimationController waveController;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;
  final VoidCallback onClear;
  final VoidCallback onPlayPause;

  const _VoiceNoteCard({
    required this.isRecording,
    required this.hasRecording,
    required this.isPlaying,
    required this.waveController,
    required this.onStartRecord,
    required this.onStopRecord,
    required this.onClear,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F2A),
        borderRadius: BorderRadius.circular(20),
        border: isRecording
            ? Border.all(
                color: const Color(0xFFEC5B13).withAlpha(120),
                width: 2,
              )
            : null,
      ),
      child: Column(
        children: [
          // Waveform
          SizedBox(
            height: 48,
            child: AnimatedBuilder(
              animation: waveController,
              builder: (_, __) {
                final t = waveController.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(11, (i) {
                    final phase = (i / 10) * math.pi * 2;
                    final wave = math.sin(t * math.pi * 2 + phase);
                    final height = isRecording
                        ? 8.0 + (wave.abs() * 28.0)
                        : (hasRecording
                              ? 8.0 + ((math.sin(phase)).abs() * 16.0)
                              : 6.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 4,
                        height: height,
                        decoration: BoxDecoration(
                          color: isRecording
                              ? const Color(0xFFEC5B13)
                              : (hasRecording
                                    ? const Color(0xFFEC5B13).withAlpha(180)
                                    : Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Mic button
          GestureDetector(
            onLongPressStart: (_) {
              HapticFeedback.heavyImpact();
              onStartRecord();
            },
            onLongPressEnd: (_) {
              HapticFeedback.lightImpact();
              onStopRecord();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFEC5B13,
                    ).withAlpha(isRecording ? 120 : 60),
                    blurRadius: isRecording ? 24 : 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!hasRecording)
            Text(
              isRecording
                  ? 'RECORDING… RELEASE TO STOP'
                  : 'TAP AND HOLD TO RECORD',
              style: TextStyle(
                color: isRecording
                    ? const Color(0xFFEC5B13)
                    : Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Voice note recorded',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onPlayPause,
                  child: Row(
                    children: [
                      Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFFEC5B13),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPlaying ? 'Pause' : 'Play',
                        style: const TextStyle(
                          color: Color(0xFFEC5B13),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Continue Bottom Bar ──────────────────────────────────────────────────────

class _ContinueBottomBar extends StatelessWidget {
  final VoidCallback onContinue;
  const _ContinueBottomBar({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1117),
        border: Border(top: BorderSide(color: Color(0xFF1C1F2A), width: 1)),
      ),
      child: GestureDetector(
        onTap: onContinue,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC5B13).withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Next Step',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
