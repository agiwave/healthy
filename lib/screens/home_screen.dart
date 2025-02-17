import 'package:flutter/material.dart';
import '../widgets/health_chart.dart';
import '../widgets/record_list.dart';
import 'record_form_screen.dart';
import '../models/indicator_type.dart';
import '../database/database_helper.dart';
import 'indicator_types_screen.dart';
import '../models/health_record.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'blood_pressure';
  bool _isInitialized = false;
  late Future<List<HealthRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    await DatabaseHelper.instance.database;
    if (mounted) {
      setState(() {
        _isInitialized = true;
        _loadRecords();
      });
    }
  }

  void _loadRecords() {
    _recordsFuture = DatabaseHelper.instance.getRecords(_selectedType);
  }

  void _refreshData() {
    setState(() {
      _loadRecords();
    });
  }

  void _onTypeChanged(String type) {
    setState(() {
      _selectedType = type;
      _loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          '健康指标监测',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FutureBuilder<List<IndicatorType>>(
              future: DatabaseHelper.instance.getIndicatorTypes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final types = snapshot.data!;
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  itemBuilder: (context) => [
                    ...types.map((type) => PopupMenuItem(
                      value: type.code,
                      child: Text(type.name),
                    )),
                    const PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 18),
                          SizedBox(width: 8),
                          Text('管理指标'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'manage') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IndicatorTypesScreen(),
                        ),
                      ).then((_) => _refreshData());  // 管理指标后刷新数据
                    } else {
                      _onTypeChanged(value);  // 使用新方法处理类型切换
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<HealthRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!;
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  margin: const EdgeInsets.all(16.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: HealthChart(
                    type: _selectedType,
                    records: records,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Card(
                  margin: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RecordList(
                    type: _selectedType,
                    records: records,
                    onRecordDeleted: _refreshData,
                    onRecordEdited: _refreshData,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordFormScreen(type: _selectedType),
            ),
          );
          _refreshData();  // 使用刷新方法替代 setState
        },
        icon: const Icon(Icons.add),
        label: const Text('添加记录'),
        elevation: 2,
      ),
    );
  }
} 