import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/badge.dart';

/// Shows a dialog celebrating newly unlocked badges.
void showBadgeCelebrationDialog(BuildContext context, List<String> badgeIds) {
  final newlyUnlocked = allBadges
      .where((b) => badgeIds.contains(b.id))
      .toList();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFFD700),
                  size: 48,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Badge Earned!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF121826),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                newlyUnlocked.length == 1
                    ? 'Congratulations! You unlocked a new achievement.'
                    : 'Wow! You unlocked ${newlyUnlocked.length} new achievements!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: newlyUnlocked.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final badge = newlyUnlocked[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: badge.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: badge.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(badge.icon, color: badge.color, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  badge.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF121826),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  badge.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4B5565),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Awesome!'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a top-toast overlay for a newly unlocked badge.
void showBadgeTopToast(BuildContext context, String badgeId) {
  final badge = allBadges.firstWhere((b) => b.id == badgeId);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: _TopToastWidget(
          badge: badge,
          onDismiss: () => overlayEntry.remove(),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);
}

// ─── Top Toast Widget ────────────────────────────────────────────────────────

class _TopToastWidget extends StatefulWidget {
  final BadgeDefinition badge;
  final VoidCallback onDismiss;

  const _TopToastWidget({required this.badge, required this.onDismiss});

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _yAnimation = Tween<double>(
      begin: -120.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3, milliseconds: 500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.badge.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.badge.icon, color: widget.badge.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'lib/assets/icon/trophy.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFFFD700),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Badge Earned!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlocked "${widget.badge.name}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
              ),
              onPressed: () {
                _controller.reverse().then((_) {
                  widget.onDismiss();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
