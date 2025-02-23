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
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'dart:io';

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
    final records =
        await DatabaseHelper.instance.getRecords(_selectedType.code);

    // Create Excel workbook and sheet
    var excel = Excel.createExcel();
    Sheet sheet = excel[excel.getDefaultSheet()!];

    // Add header row
    List<String> headers = _selectedType.isMultiValue
        ? [
            'Timestamp',
            _selectedType.majorValueName,
            _selectedType.minorValueName ?? ''
          ]
        : ['Timestamp', _selectedType.majorValueName];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = headers[i];
    }

    // Add data rows
    for (var i = 0; i < records.length; i++) {
      var record = records[i];
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = DateFormat('yyyy-MM-dd HH:mm').format(record.timestamp);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = record.majorValue;

      if (_selectedType.isMultiValue && record.minorValue != null) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
            .value = record.minorValue;
      }
    }

    // Save file
    var fileBytes = excel.encode();
    if (fileBytes != null) {
      final String fileName =
          '${_selectedType.name}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: Localization.translate('save_excel_file'),
        fileName: fileName,
        allowedExtensions: ['xlsx'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        await File(outputFile).writeAsBytes(fileBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Localization.translate('data_exported'))),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
      );

      if (result != null) {
        var file = File(result.files.single.path!);
        var bytes = await file.readAsBytes();
        var excel = Excel.decodeBytes(bytes);

        var sheet = excel.tables[excel.getDefaultSheet()!];
        if (sheet == null) throw Exception('No sheet found in Excel file');

        // Skip header row and process data
        for (var row in sheet.rows.skip(1)) {
          if (row.isEmpty) continue;

          try {
            var timestamp = DateFormat('yyyy-MM-dd HH:mm')
                .parse(row[0]?.value.toString() ?? '');
            var majorValue = double.parse(row[1]?.value.toString() ?? '');
            double? minorValue;

            if (_selectedType.isMultiValue && row.length > 2) {
              var minorStr = row[2]?.value.toString();
              if (minorStr != null && minorStr.isNotEmpty) {
                minorValue = double.parse(minorStr);
              }
            }

            await DatabaseHelper.instance.insertRecord(HealthRecord(
              timestamp: timestamp,
              majorValue: majorValue,
              minorValue: minorValue,
              type: _selectedType.code,
            ));
          } catch (e) {
            print('Error processing row: $e');
            continue;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Localization.translate('data_imported'))),
        );

        _refreshData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate('import_error'))),
      );
    }
  }

  Future<void> _clearData() async {
    await DatabaseHelper.instance.clearRecords(_selectedType.code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Localization.translate('data_cleared'))),
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
                      value: IndicatorType(
                          code: '__',
                          name: '',
                          unit: '',
                          isMultiValue: false,
                          majorValueName: ''),
                      child: Row(
                        children: [
                          const Icon(Icons.settings, size: 18),
                          const SizedBox(width: 8),
                          Text(Localization.translate(
                              'manage_indicators')), // Use localized string
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
                value: 'export_excel',
                child: Text(Localization.translate('export_excel')),
              ),
              PopupMenuItem<String>(
                value: 'import_excel',
                child: Text(Localization.translate('import_excel')),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text(Localization.translate('clear')),
              ),
              PopupMenuItem<String>(
                value: 'change_language',
                child: Text(Localization.translate('change_language')),
              ),
            ],
            onSelected: (value) {
              if (value == 'export_excel') {
                _exportData();
              } else if (value == 'import_excel') {
                _importData();
              } else if (value == 'clear') {
                _clearData();
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
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecordFormScreen(type: _selectedType),
              ),
            );
            _refreshData();
          },
          child: const Icon(Icons.add, size: 24),
          elevation: 4,
          shape: const CircleBorder(),
          backgroundColor: Colors.teal[400],
        ),
      ),
    );
  }
}
