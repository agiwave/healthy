import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/health_record.dart';
import '../database/database_helper.dart';

class HealthChart extends StatelessWidget {
  final String type;
  static final dateFormat = DateFormat('MM-dd HH:mm');

  const HealthChart({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HealthRecord>>(
      future: DatabaseHelper.instance.getRecords(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!;
        if (records.isEmpty) {
          return const Center(child: Text('暂无数据'));
        }

        if (records.length <= 1) {
          return const Center(child: Text('需要至少两条记录才能显示图表'));
        }

        records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
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
        final intervals = (diffMinutes / 30).ceil();
        final interval = intervals > 0 ? intervals * 30 / 5 : 30.0;

        // 计算纵轴范围和间隔
        final yValues = records.expand<double>((record) => [
          type == 'blood_pressure' ? record.systolic! : record.value,
          if (type == 'blood_pressure') record.diastolic!,
        ]).toList();

        final minY = (yValues.reduce(min) ~/ 10) * 10.0;  // 向下取整到最近的10
        final maxY = ((yValues.reduce(max) + 9) ~/ 10) * 10.0;  // 向上取整到最近的10
        final yInterval = ((maxY - minY) / 5).ceil() ~/ 5 * 5.0;  // 确保是5的倍数

        return Column(
          children: [
            if (type == 'blood_pressure')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem('收缩压', Colors.blue),
                    const SizedBox(width: 20),
                    _buildLegendItem('舒张压', Colors.red),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildLegendItem('心率', Colors.blue),
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
                                dateFormat.format(date),
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
                          return FlSpot(
                            minutes,
                            type == 'blood_pressure'
                                ? record.systolic!
                                : record.value,
                          );
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
                            return FlSpot(minutes, record.diastolic!);
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
      },
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