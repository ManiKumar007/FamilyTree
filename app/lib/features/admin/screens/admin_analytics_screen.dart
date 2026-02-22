import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/admin_providers.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final growthAsync = ref.watch(userGrowthProvider(_selectedDays));
    final distributionAsync = ref.watch(treeDistributionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select Time Range',
            onSelected: (days) => setState(() => _selectedDays = days),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userGrowthProvider(_selectedDays));
              ref.invalidate(treeDistributionProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Growth Chart
              Text(
                'User Growth (Last $_selectedDays days)',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final r = Responsive(context);
                  return SizedBox(
                    height: r.chartHeight,
                    child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: growthAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                    data: (data) {
                      if (data.isEmpty) {
                        return const Center(child: Text('No data available'));
                      }
                      return LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= data.length) return const Text('');
                                  final index = value.toInt();
                                  final date = data[index].date.split('-');
                                  return Text('${date[1]}/${date[2]}', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: data.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
                              }).toList(),
                              isCurved: true,
                              color: kSecondaryColor,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: kSecondaryColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
                  );
                },
              ),
            const SizedBox(height: 32),

            // Tree Size Distribution
            Text(
              'Family Tree Size Distribution',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final r = Responsive(context);
                return SizedBox(
                  height: r.chartHeight,
                  child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: distributionAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                    data: (data) {
                      if (data.isEmpty) {
                        return const Center(child: Text('No data available'));
                      }
                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: data.map((e) => e.userCount.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${data[groupIndex].sizeRange}\n${rod.toY.toInt()} users',
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 60,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= data.length) return const Text('');
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        data[value.toInt()].sizeRange,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          barGroups: data.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.userCount.toDouble(),
                                  color: kOtherColor,
                                  width: 20,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
