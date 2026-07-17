import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: Text('Please log in to view analytics.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Your Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF121826),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF121826)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No analytics data available.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int questionsAnswered = data['questionsAnswered'] ?? 0;
          final int questionsCorrect = data['questionsCorrect'] ?? 0;
          final int questionsIncorrect = questionsAnswered - questionsCorrect;

          final int caPoints = data['computerArchitecturePoints'] ?? 0;
          final int cnPoints = data['computerNetworkingPoints'] ?? 0;
          final int sePoints = data['softwareEngineeringPoints'] ?? 0;

          final int caAnswered = data['caAnswered'] ?? 0;
          final int caCorrect = data['caCorrect'] ?? 0;
          final int caIncorrect = caAnswered - caCorrect;

          final int cnAnswered = data['cnAnswered'] ?? 0;
          final int cnCorrect = data['cnCorrect'] ?? 0;
          final int cnIncorrect = cnAnswered - cnCorrect;

          final int seAnswered = data['seAnswered'] ?? 0;
          final int seCorrect = data['seCorrect'] ?? 0;
          final int seIncorrect = seAnswered - seCorrect;

          if (questionsAnswered == 0 &&
              caPoints == 0 &&
              cnPoints == 0 &&
              sePoints == 0) {
            return const Center(
              child: Text('Play some quizzes to generate analytics!'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Accuracy Breakdown'),
                const SizedBox(height: 16),
                _buildAccuracyPieChart(
                  questionsCorrect,
                  questionsIncorrect,
                  questionsAnswered,
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Points by Subject'),
                const SizedBox(height: 16),
                _buildPointsBarChart(caPoints, cnPoints, sePoints),
                const SizedBox(height: 32),
                _buildSectionTitle('Subject Statistics'),
                const SizedBox(height: 16),
                _buildSubjectStatsCard(
                  'Computer Architecture',
                  caAnswered,
                  caCorrect,
                  caIncorrect,
                  const Color(0xFF003F91),
                ),
                const SizedBox(height: 16),
                _buildSubjectStatsCard(
                  'Computer Networking',
                  cnAnswered,
                  cnCorrect,
                  cnIncorrect,
                  const Color(0xFF0091EA),
                ),
                const SizedBox(height: 16),
                _buildSubjectStatsCard(
                  'Software Engineering',
                  seAnswered,
                  seCorrect,
                  seIncorrect,
                  const Color(0xFF37474F),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF121826),
      ),
    );
  }

  Widget _buildAccuracyPieChart(int correct, int incorrect, int total) {
    if (total == 0) return const Text('No questions answered yet.');

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFF4CAF50),
                  value: correct.toDouble(),
                  title: '${((correct / total) * 100).round()}%',
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (incorrect > 0)
                  PieChartSectionData(
                    color: const Color(0xFFF44336),
                    value: incorrect.toDouble(),
                    title: '${((incorrect / total) * 100).round()}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF121826),
                ),
              ),
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBarChart(int ca, int cn, int se) {
    final double maxPts = [
      ca,
      cn,
      se,
    ].reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxPts == 0 ? 10 : maxPts + (maxPts * 0.2),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  String text;
                  switch (value.toInt()) {
                    case 0:
                      text = 'Arch';
                      break;
                    case 1:
                      text = 'Net';
                      break;
                    case 2:
                      text = 'Soft Eng';
                      break;
                    default:
                      text = '';
                      break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: ca.toDouble(),
                  color: const Color(0xFF003F91),
                  width: 26,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: cn.toDouble(),
                  color: const Color(0xFF0091EA),
                  width: 26,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: se.toDouble(),
                  color: const Color(0xFF37474F),
                  width: 26,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectStatsCard(
    String title,
    int answered,
    int correct,
    int wrong,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF121826),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Answered',
                answered.toString(),
                const Color(0xFF6B7280),
              ),
              _buildStatItem(
                'Correct',
                correct.toString(),
                const Color(0xFF4CAF50),
              ),
              _buildStatItem(
                'Wrong',
                wrong.toString(),
                const Color(0xFFF44336),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
