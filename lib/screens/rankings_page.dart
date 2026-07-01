import 'package:flutter/material.dart';
import '../models/badge.dart';
import '../models/user_rank.dart';
import '../services/database_service.dart';

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
      body: SafeArea(
        child: StreamBuilder<List<UserRank>>(
          stream: dbService.getRankingsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading rankings: ${snapshot.error}'),
              );
            }

            final rankings = snapshot.data ?? [];

            final sortedRankings = List<UserRank>.from(rankings);
            sortedRankings.sort((a, b) {
              final ptsA = _getUserPoints(a);
              final ptsB = _getUserPoints(b);
              return _descending ? ptsB.compareTo(ptsA) : ptsA.compareTo(ptsB);
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rankings',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'See how you compare with others',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF111C4A,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _descending
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: const Color(0xFF111C4A),
                          ),
                          tooltip: _descending
                              ? 'Sort Ascending'
                              : 'Sort Descending',
                          onPressed: () {
                            setState(() {
                              _descending = !_descending;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Horizontal Filter Scroll Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF111C4A),
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            selectedColor: const Color(0xFF111C4A),
                            checkmarkColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : const Color(
                                        0xFF111C4A,
                                      ).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (sortedRankings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: const Color(0xFFE6EAF2)),
                      ),
                      child: const Center(
                        child: Text(
                          'No rankings yet. Start playing to get listed!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedRankings.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rank = sortedRankings[index];
                        final isTopThree = index < 3;
                        final colorsMap = const [
                          Color(0xFFFFD700),
                          Color(0xFFC0C0C0),
                          Color(0xCD853F3A),
                        ];
                        final userPoints = _getUserPoints(rank);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE6EAF2)),
                          ),
                          child: Row(
                            children: [
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
                                          color: Color(0xFF4B5565),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE6EAF2),
                                    width: 1.5,
                                  ),
                                ),
                                child:
                                    rank.avatarUrl != null &&
                                        rank.avatarUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          rank.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.person_rounded,
                                                    size: 24,
                                                    color: Color(0xFF141053),
                                                  ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 24,
                                        color: Color(0xFF141053),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rank.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF121826),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (rank.selectedBadges.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4.0,
                                        runSpacing: 4.0,
                                        children: rank.selectedBadges.map((
                                          badgeId,
                                        ) {
                                          final badge = allBadges.firstWhere(
                                            (b) => b.id == badgeId,
                                          );
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badge.color.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: badge.color.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  badge.icon,
                                                  color: badge.color,
                                                  size: 10,
                                                ),
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
                              Text(
                                '$userPoints pts',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF141053),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
