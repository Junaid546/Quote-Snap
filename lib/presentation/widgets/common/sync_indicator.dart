import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/sync_provider.dart';
import '../../../data/services/sync_service.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);

    // IDLE + ONLINE + all synced: invisible
    if (sync.status == SyncStatus.idle &&
        sync.isOnline &&
        sync.unsyncedCount == 0) {
      return const SizedBox.shrink();
    }

    final (color, icon, label, isLoading) = _resolveVisuals(sync);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 40,
      width: double.infinity,
      color: color,
      child: GestureDetector(
        onTap: sync.status == SyncStatus.error
            ? () => ref.read(syncProvider.notifier).triggerManualSync()
            : null,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData, String, bool) _resolveVisuals(SyncState sync) {
    if (!sync.isOnline) {
      return (
        const Color(0xFFB45309), // amber
        Icons.wifi_off_rounded,
        'Offline — ${sync.unsyncedCount} quotes pending sync',
        false,
      );
    }

    switch (sync.status) {
      case SyncStatus.syncing:
        return (
          const Color(0xFF3B82F6), // blue
          Icons.cloud_sync_rounded,
          'Syncing to cloud...',
          true,
        );
      case SyncStatus.success:
        return (
          const Color(0xFF16A34A), // green
          Icons.cloud_done_rounded,
          'All synced ✓',
          false,
        );
      case SyncStatus.error:
        return (
          const Color(0xFFDC2626), // red
          Icons.cloud_off_rounded,
          'Sync failed — tap to retry',
          false,
        );
      case SyncStatus.idle:
        return (
          const Color(0xFF475569), // slate
          Icons.cloud_queue_rounded,
          '${sync.unsyncedCount} items pending',
          false,
        );
    }
  }
}
