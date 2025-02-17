import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard
import 'package:health_tracker/screens/language_selection_screen.dart';
import '../widgets/health_chart.dart';
import '../widgets/record_list.dart';
import 'record_form_screen.dart';
import '../models/indicator_type.dart';
import '../database/database_helper.dart';
import 'indicator_types_screen.dart';
import '../models/health_record.dart';
import '../utils/localization.dart'; // Import the localization utility
import 'package:provider/provider.dart'; // Import provider
import '../providers/locale_provider.dart'; // Import the locale provider

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

  Future<void> _exportData() async {
    final records = await DatabaseHelper.instance.getRecords(_selectedType.code);
    StringBuffer buffer = StringBuffer();
    if (_selectedType.isMultiValue) {
      buffer.writeln('Timestamp,Major Value,Minor Value'); // Header
      for (var record in records) {
        buffer.writeln('${record.timestamp},${record.majorValue},${record.minorValue}');
      }
    } else {
      buffer.writeln('Timestamp,Major Value'); // Header
      for (var record in records) {
        buffer.writeln('${record.timestamp},${record.majorValue}');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Localization.translate('data_cleared') ?? 'Data exported to clipboard')),
    );
  }

  Future<void> _importData() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      String? data = clipboardData!.text;
      if (data != null && data.isNotEmpty) {
        List<String> lines = data.split('\n');
        for (var line in lines.skip(1)) { // Skip header
          if (line.isNotEmpty) {
            List<String> values = line.split(',');
            DateTime timestamp = DateTime.parse(values[0]);
            double majorValue = double.parse(values[1]);
            double? minorValue = values.length > 2 ? double.parse(values[2]) : null;

            await DatabaseHelper.instance.insertRecord(HealthRecord(
              timestamp: timestamp,
              majorValue: majorValue,
              minorValue: minorValue,
              type: _selectedType.code,
            ));
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Localization.translate('data_imported') ?? 'Data imported')),
        );

        _refreshData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate('no_data_in_clipboard') ?? 'No data in clipboard')),
      );
    }
  }

  Future<void> _clearData() async {
    await DatabaseHelper.instance.clearRecords(_selectedType.code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Localization.translate('data_cleared') ?? 'Data cleared')),
    );

    _refreshData();
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            FutureBuilder<List<IndicatorType>>(
              future: DatabaseHelper.instance.getIndicatorTypes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final types = snapshot.data!;
                
                return PopupMenuButton<IndicatorType>(
                  child: Text(
                    _selectedType.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  itemBuilder: (context) => [
                    ...types.map((type) => PopupMenuItem(
                      value: type,
                      child: Text(type.name),
                    )),
                    PopupMenuItem<IndicatorType>(
                      value: IndicatorType(code: '__', name: '', unit: '', isMultiValue: false, majorValueName: ''),
                      child: Row(
                        children: [
                          const Icon(Icons.settings, size: 18),
                          const SizedBox(width: 8),
                          Text(Localization.translate('manage_indicators') ?? 'Manage Indicators'), // Use localized string
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add), // Plus icon
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'export',
                child: Text(Localization.translate('export') ?? 'Export'), // Use localized string
              ),
              PopupMenuItem<String>(
                value: 'import',
                child: Text(Localization.translate('import') ?? 'Import'), // Use localized string
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text(Localization.translate('clear') ?? 'Clear'), // Use localized string
              ),
              PopupMenuItem<String>(
                value: 'change_language',
                child: Text(Localization.translate('change_language') ?? 'Change Language'), // Use localized string
              ),
            ],
            onSelected: (value) {
              if (value == 'export') {
                _exportData(); // Call export function
              } else if (value == 'import') {
                _importData(); // Call import function
              } else if (value == 'clear') {
                _clearData(); // Call clear data function
              } else if (value == 'change_language') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LanguageSelectionScreen(),
                  ),
                ).then((_) => {});
              }
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
                    type: _selectedType,
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
                    type: _selectedType,
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
              builder: (context) => RecordFormScreen(type: _selectedType),
            ),
          );
          _refreshData();
        },
        icon: const Icon(Icons.add),
        label: Text(Localization.translate('add_record') ?? 'Add Record'), // Use localized string
        elevation: 2,
      ),
    );
  }
}