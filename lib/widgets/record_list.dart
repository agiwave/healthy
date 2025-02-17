import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../database/database_helper.dart';
import '../screens/record_form_screen.dart';
import 'package:intl/intl.dart';

class RecordList extends StatefulWidget {
  final String type;

  const RecordList({
    super.key,
    required this.type,
  });

  @override
  State<RecordList> createState() => _RecordListState();
}

class _RecordListState extends State<RecordList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HealthRecord>>(
      future: DatabaseHelper.instance.getRecords(widget.type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data!;
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_add, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无记录',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
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
                setState(() {});
              },
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  widget.type == 'blood_pressure'
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
                          type: widget.type,
                          record: record,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
} 