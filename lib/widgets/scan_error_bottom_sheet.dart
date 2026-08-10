import 'package:flutter/material.dart';
import '../services/ai_extraction_service.dart';

/// A modern, dark-themed modal bottom sheet displaying clear scan error details,
/// hints, and options to retry scanning or enter document details manually.
class ScanErrorBottomSheet extends StatelessWidget {
  final ScanException exception;
  final VoidCallback? onRetry;
  final VoidCallback? onManualEntry;

  const ScanErrorBottomSheet({
    super.key,
    required this.exception,
    this.onRetry,
    this.onManualEntry,
  });

  /// Displays the modal bottom sheet for the given [exception].
  static Future<void> show({
    required BuildContext context,
    required ScanException exception,
    VoidCallback? onRetry,
    VoidCallback? onManualEntry,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ScanErrorBottomSheet(
        exception: exception,
        onRetry: () {
          Navigator.pop(ctx);
          if (onRetry != null) onRetry();
        },
        onManualEntry: () {
          Navigator.pop(ctx);
          if (onManualEntry != null) onManualEntry();
        },
      ),
    );
  }

  IconData _getIcon() {
    switch (exception.type) {
      case ScanErrorType.missingApiKey:
        return Icons.key_off_rounded;
      case ScanErrorType.noInternet:
        return Icons.wifi_off_rounded;
      case ScanErrorType.timeout:
        return Icons.timer_off_outlined;
      case ScanErrorType.unreadableDocument:
        return Icons.find_in_page_outlined;
      case ScanErrorType.apiError:
        return Icons.cloud_off_rounded;
      case ScanErrorType.unknown:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getBadgeColor() {
    switch (exception.type) {
      case ScanErrorType.missingApiKey:
      case ScanErrorType.noInternet:
        return const Color(0xFFF59E0B); // Amber warning
      case ScanErrorType.timeout:
      case ScanErrorType.unreadableDocument:
        return const Color(0xFF3B82F6); // Soft blue
      case ScanErrorType.apiError:
      case ScanErrorType.unknown:
        return const Color(0xFFEF4444); // Red error
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final iconData = _getIcon();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Indicator Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon & Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(iconData, size: 28, color: badgeColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exception.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Document Scanning',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Error Message
            Text(
              exception.message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Helpful Hint Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: Color(0xFF10B981), // Emerald green accent
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exception.hint,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Secondary action: Manual fill
                Expanded(
                  child: OutlinedButton(
                    onPressed: onManualEntry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fill Manually',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Primary action: Try again / retake photo
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
