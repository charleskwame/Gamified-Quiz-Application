import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/badge.dart';
import '../models/user_rank.dart';
import '../services/database_service.dart';
import '../widgets/home/particle_background.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  String _selectedCategory = 'All';
  bool _descending = true;

  int _getUserPoints(UserRank rank) {
    switch (_selectedCategory) {
      case 'Computer Architecture':
        return rank.computerArchitecturePoints;
      case 'Software Engineering':
        return rank.softwareEngineeringPoints;
      case 'Computer Networking':
        return rank.computerNetworkingPoints;
      default:
        return rank.score;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final categories = [
      'All',
      'Computer Architecture',
      'Software Engineering',
      'Computer Networking',
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ParticleBackground(
        child: SafeArea(
          child: StreamBuilder<List<UserRank>>(
            stream: dbService.getRankingsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading rankings: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                );
              }

              final rankings = snapshot.data ?? [];

              final sortedRankings = List<UserRank>.from(rankings);
              sortedRankings.sort((a, b) {
                final ptsA = _getUserPoints(a);
                final ptsB = _getUserPoints(b);
                return _descending
                    ? ptsB.compareTo(ptsA)
                    : ptsA.compareTo(ptsB);
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Header
                    _buildAnimatedSection(index: 0, child: _buildHeader()),

                    const SizedBox(height: 20),

                    // Section 2: Category filters
                    _buildAnimatedSection(
                      index: 1,
                      child: _buildCategoryFilters(categories),
                    ),

                    const SizedBox(height: 24),

                    // Section 3: Rankings list or empty state
                    if (sortedRankings.isEmpty)
                      _buildAnimatedSection(index: 2, child: _buildEmptyState())
                    else
                      ...List.generate(sortedRankings.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < sortedRankings.length - 1 ? 12 : 0,
                          ),
                          child: _buildAnimatedSection(
                            index: index + 2,
                            child: _buildRankingCard(
                              rank: sortedRankings[index],
                              index: index,
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rankings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'See how you compare with others',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2246).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: IconButton(
            icon: Icon(
              _descending
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: const Color(0xFFFFD700),
            ),
            tooltip: _descending ? 'Sort Ascending' : 'Sort Descending',
            onPressed: () {
              setState(() {
                _descending = !_descending;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8C52FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : const Color(0xFF1E2246).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 48),
          SizedBox(height: 12),
          Text(
            'No rankings yet. Start playing to get listed!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard({required UserRank rank, required int index}) {
    final isTopThree = index < 3;
    final colorsMap = const [
      Color(0xFFFFD700),
      Color(0xFFC0C0C0),
      Color(0xFFCD7F32),
    ];
    final userPoints = _getUserPoints(rank);
    final showXpSeparately = _selectedCategory != 'All';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank indicator
          SizedBox(
            width: 36,
            child: isTopThree
                ? Icon(
                    Icons.emoji_events_rounded,
                    color: colorsMap[index],
                    size: 24,
                  )
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isTopThree
                    ? colorsMap[index].withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: rank.avatarUrl != null && rank.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: SvgPicture.network(
                      rank.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        size: 24,
                        color: Colors.white60,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 24,
                    color: Colors.white60,
                  ),
          ),
          const SizedBox(width: 12),
          // Name, badges, XP row
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Text(
                  rank.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // Badges
                if (rank.selectedBadges.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: rank.selectedBadges.map((badgeId) {
                      final badge = allBadges.firstWhere(
                        (b) => b.id == badgeId,
                      );
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badge.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: badge.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(badge.icon, color: badge.color, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              badge.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: badge.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Points column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Total XP (always shown)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFFFD700),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${rank.score} XP',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              // Category-specific points (only shown when filtering)
              if (showXpSeparately) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.diamond_rounded,
                      color: const Color(0xFF6366F1),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$userPoints pts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Wraps content in a staggered slide-up animation matching home screen
  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return _StaggeredFadeSlide(index: index, child: child);
  }
}

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
