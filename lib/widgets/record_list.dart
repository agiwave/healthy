import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../database/database_helper.dart';
import '../screens/record_form_screen.dart';
import 'package:intl/intl.dart';

class RecordList extends StatelessWidget {
  final String type;
  final List<HealthRecord> records;
  final VoidCallback onRecordDeleted;
  final VoidCallback onRecordEdited;

  const RecordList({
    super.key,
    required this.type,
    required this.records,
    required this.onRecordDeleted,
    required this.onRecordEdited,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('暂无记录'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = records[index];
        return Dismissible(
          key: Key(record.id.toString()),
          background: Container(
            color: Colors.red[100],
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('删除记录'),
                content: const Text('确定要删除这条记录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('删除', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (direction) async {
            await DatabaseHelper.instance.deleteRecord(record.id!);
            onRecordDeleted();
          },
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              type == 'blood_pressure'
                  ? '${record.systolic}/${record.diastolic} mmHg'
                  : '${record.value} bpm',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecordFormScreen(
                      type: type,
                      record: record,
                    ),
                  ),
                ).then((_) => onRecordEdited());
              },
            ),
          ),
        );
      },
    );
  }
} 