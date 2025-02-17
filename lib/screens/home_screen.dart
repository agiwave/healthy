import 'package:flutter/material.dart';
import '../widgets/health_chart.dart';
import '../widgets/record_list.dart';
import 'record_form_screen.dart';
import '../models/indicator_type.dart';
import '../database/database_helper.dart';
import 'indicator_types_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedType = 'blood_pressure';
  final _chartKey = GlobalKey<State>();  // 添加 key 用于刷新图表
  final _listKey = GlobalKey<State>();   // 添加 key 用于刷新列表
  bool _isInitialized = false;  // 添加初始化标志

  @override
  void initState() {
    super.initState();
    _initDatabase();  // 添加初始化函数
  }

  Future<void> _initDatabase() async {
    await DatabaseHelper.instance.database;
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
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
                      ).then((_) => setState(() {}));
                    } else {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
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
                key: _chartKey,
                type: _selectedType,
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
                key: _listKey,
                type: _selectedType,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordFormScreen(type: _selectedType),
            ),
          );
          setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('添加记录'),
        elevation: 2,
      ),
    );
  }
} 