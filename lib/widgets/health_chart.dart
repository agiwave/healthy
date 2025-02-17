import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/health_record.dart';
import '../models/indicator_type.dart';

class HealthChart extends StatelessWidget {
  final String type;
  final List<HealthRecord> records;
  final IndicatorType _selectedType;
  static final dateFormat = DateFormat('MM-dd HH:mm');

  const HealthChart({
    super.key,
    required this.type,
    required this.records,
    required IndicatorType selectedType,
  }) : _selectedType = selectedType;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // 如果记录少于2条，使用默认间隔
    if (records.length < 2) {
      return const Center(child: Text('需要至少两条记录才能显示图表'));
    }

    final minTime = records.first.timestamp;
    final maxTime = records.last.timestamp;
    
    final adjustedMinTime = DateTime(
      minTime.year,
      minTime.month,
      minTime.day,
      minTime.hour,
      (minTime.minute ~/ 30) * 30,
    );
    
    final diffMinutes = maxTime.difference(adjustedMinTime).inMinutes;
    // 确保 diffMinutes 至少为 30，避免间隔为 0
    final interval = max(30.0, ((diffMinutes + 29) / 30).ceil() * 30 / 5);

    // 计算纵轴范围和间隔
    final yValues = records.expand<double>((record) => [
      record.value1,
      if (type == 'blood_pressure' && record.value2 != null) record.value2!,
    ]).toList();

    // 确保有最小范围
    final minY = (yValues.reduce(min) ~/ 10) * 10.0;
    final maxY = ((yValues.reduce(max) + 9) ~/ 10) * 10.0;
    final yInterval = max(5.0, ((maxY - minY + 4) / 5).ceil() * 5.0);

    return Column(
      children: [
        if (type == 'blood_pressure')
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(_selectedType.value1Name, Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem(_selectedType.value2Name!, Colors.red),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildLegendItem(_selectedType.value1Name, Colors.blue),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = adjustedMinTime.add(
                          Duration(minutes: (value ~/ 1) * 30),
                        );
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            HealthChart.dateFormat.format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      interval: interval,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: records.map((record) {
                      final minutes = record.timestamp
                          .difference(adjustedMinTime)
                          .inMinutes
                          .toDouble();
                      return FlSpot(minutes, record.value1);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    dotData: const FlDotData(show: true),
                  ),
                  if (type == 'blood_pressure')
                    LineChartBarData(
                      spots: records.map((record) {
                        final minutes = record.timestamp
                            .difference(adjustedMinTime)
                            .inMinutes
                            .toDouble();
                        return FlSpot(minutes, record.value2!);
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      dotData: const FlDotData(show: true),
                    ),
                ],
                minX: 0,
                maxX: diffMinutes.toDouble(),
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
} 