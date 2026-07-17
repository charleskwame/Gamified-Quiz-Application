import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/shop_item.dart';
import '../widgets/home/particle_background.dart';

/// Shop screen displaying purchasable power-up items.
/// Shows live coin balance and item counts from Firestore.
/// Users can tap BUY to purchase items with quiz coins.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final DatabaseService _db = DatabaseService();
  final Set<String> _purchasing = {}; // Track which items are being purchased
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _buyItem(ShopItem item, String uid) async {
    if (_purchasing.contains(item.id)) return;

    setState(() => _purchasing.add(item.id));

    try {
      final success = await _db.purchaseItem(
        uid: uid,
        itemId: item.id,
        price: item.price,
        maxItems: 3,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Purchased ${item.name}!'),
            backgroundColor: const Color(0xFF4ADE80),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Not enough coins or at max capacity (3)!'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _purchasing.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    // If not logged in, show a simple message
    if (uid == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ParticleBackground(
          child: SafeArea(
            child: Center(
              child: Text(
                'Sign in to access the shop',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ),
          ),
        ),
      );
    }

    // Stream user data for live balances
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ParticleBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final coins = data?['quizCoins'] as int? ?? 0;
            final shieldCount = data?['shieldCount'] as int? ?? 0;
            final skipCount = data?['skipCount'] as int? ?? 0;
            final pauseCount = data?['pauseTimerCount'] as int? ?? 0;

            // Map item IDs to their current count
            int getCount(String itemId) {
              switch (itemId) {
                case 'shield':
                  return shieldCount;
                case 'skip_question':
                  return skipCount;
                case 'no_deductions':
                  return pauseCount;
                case 'pause_timer':
                  return pauseCount;
                default:
                  return 0;
              }
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header ─────────────────────────────────
                    Row(
                      children: [
                        SvgPicture.asset(
                          'lib/assets/icon/store.svg',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Shop',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF003F91),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Power-ups and items to enhance your quiz experience',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ─── Coin Balance (live from Firestore) ─────
                    _buildCoinBalance(coins),
                    const SizedBox(height: 28),

                    // ─── Shop Items ─────────────────────────────
                    ...List.generate(ShopItem.placeholderItems.length, (index) {
                      final item = ShopItem.placeholderItems[index];
                      final count = getCount(item.id);
                      return _buildAnimatedSection(
                        index: index,
                        child: _ShopItemCard(
                          item: item,
                          ownedCount: count,
                          canAfford: coins >= item.price,
                          isPurchasing: _purchasing.contains(item.id),
                          onBuy: () => _buyItem(item, uid),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),

                    // ─── Footer note ────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF003F91).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: const Color(0xFF003F91),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can hold a maximum of 3 of each item at a time.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Debug: Seed coins for all users (debug mode only) ──
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _seedAllCoins(context),
                          icon: const Icon(
                            Icons.auto_fix_high_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Give 100 coins to all existing users',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD700),
                            side: const BorderSide(
                              color: Color(0xFFFFD700),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _seedAllCoins(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    if (!context.mounted) return;
    scaffold.showSnackBar(
      const SnackBar(
        content: Text(
          'This migration is disabled in-app under the current Firestore rules.',
        ),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  Widget _buildCoinBalance(int coins) {
    return Row(
      children: [
        SvgPicture.asset('lib/assets/icon/coin.svg', width: 40, height: 40),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Coins',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$coins',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD700),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF003F91).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF003F91).withValues(alpha: 0.2),
            ),
          ),
          child: const Text(
            'Earn more',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF003F91),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return _StaggeredFadeSlide(index: index + 1, child: child);
  }
}

// ─── Shop Item Card ─────────────────────────────────────────────────────────

class _ShopItemCard extends StatelessWidget {
  final ShopItem item;
  final int ownedCount;
  final bool canAfford;
  final bool isPurchasing;
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.ownedCount,
    required this.canAfford,
    required this.isPurchasing,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMaxed = ownedCount >= 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF003F91).withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // ─── Icon ─────────────────────────────
              SvgPicture.asset(item.iconAsset, width: 56, height: 56),
              const SizedBox(width: 16),

              // ─── Name & Description ────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF121826),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                    ),
                    if (ownedCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Owned: $ownedCount / 3',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isMaxed
                              ? const Color(0xFFFFD700)
                              : const Color(0xFF003F91).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ─── Price & Buy Button ────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price tag
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'lib/assets/icon/coin.svg',
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.price}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Buy button or status
                  if (isMaxed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'MAXED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD700),
                          letterSpacing: 0.8,
                        ),
                      ),
                    )
                  else if (isPurchasing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    SizedBox(
                      width: 60,
                      height: 32,
                      child: FilledButton(
                        onPressed: canAfford ? onBuy : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF003F91),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.withValues(
                            alpha: 0.15,
                          ),
                          disabledForegroundColor: Colors.grey.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: Text(
                          canAfford ? 'BUY' : '💸',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Staggered Animation (mirrors home screen pattern) ──────────────────────

class _StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeSlide({required this.index, required this.child});

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final startDelay = Duration(milliseconds: 100 * widget.index);
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    Future.delayed(startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}
