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
  late IndicatorType _selectedType;
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
      final types = await DatabaseHelper.instance.getIndicatorTypes();
      setState(() {
        _selectedType = types.first;
        _isInitialized = true;
        _loadRecords();
      });
    }
  }

  void _loadRecords() {
    _recordsFuture = DatabaseHelper.instance.getRecords(_selectedType.code);
  }

  void _refreshData() {
    setState(() {
      _loadRecords();
    });
  }

  void _onTypeChanged(IndicatorType type) {
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
        centerTitle: true,
        title: Text(
          _selectedType.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          FutureBuilder<List<IndicatorType>>(
            future: DatabaseHelper.instance.getIndicatorTypes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              final types = snapshot.data!;
              return PopupMenuButton<IndicatorType>(
                icon: const Icon(Icons.more_vert, color: Colors.black87),
                itemBuilder: (context) => [
                  ...types.map((type) => PopupMenuItem(
                    value: type,
                    child: Text(type.name),
                  )),
                  PopupMenuItem<IndicatorType>(
                    value: IndicatorType(code: '__', name: '', unit:'', isMultiValue: false, value1Name: ''),
                    child: const Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 8),
                        Text('管理指标'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value.code == '__') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IndicatorTypesScreen(),
                      ),
                    ).then((_) => _refreshData());
                  } else {
                    _onTypeChanged(value);
                  }
                },
              );
            },
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
                    type: _selectedType.code,
                    records: records,
                    selectedType: _selectedType,
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
                    type: _selectedType.code,
                    records: records,
                    onRecordDeleted: _refreshData,
                    onRecordEdited: _refreshData,
                    selectedType: _selectedType,
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
              builder: (context) => RecordFormScreen(type: _selectedType.code),
            ),
          );
          _refreshData();
        },
        icon: const Icon(Icons.add),
        label: const Text('添加记录'),
        elevation: 2,
      ),
    );
  }
} 