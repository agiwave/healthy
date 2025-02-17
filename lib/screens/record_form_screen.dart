import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

class RecordFormScreen extends StatefulWidget {
  final String type;
  final HealthRecord? record;

  const RecordFormScreen({
    super.key,
    required this.type,
    this.record,
  });

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _valueController;
  late TextEditingController _systolicController;
  late TextEditingController _diastolicController;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: widget.record?.value.toString() ?? '',
    );
    _systolicController = TextEditingController(
      text: widget.record?.systolic?.toString() ?? '',
    );
    _diastolicController = TextEditingController(
      text: widget.record?.diastolic?.toString() ?? '',
    );
    _selectedDateTime = widget.record?.timestamp ?? DateTime.now();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.record == null ? '添加记录' : '编辑记录',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: const Text('记录时间'),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDateTime,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.type == 'blood_pressure') ...[
                  _buildTextField(
                    controller: _systolicController,
                    label: '收缩压',
                    suffix: 'mmHg',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _diastolicController,
                    label: '舒张压',
                    suffix: 'mmHg',
                  ),
                ] else
                  _buildTextField(
                    controller: _valueController,
                    label: '心率',
                    suffix: 'bpm',
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveRecord,
                    child: Text(widget.record == null ? '添加' : '保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入$label';
        }
        return null;
      },
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final record = HealthRecord(
      id: widget.record?.id,
      type: widget.type,
      value: widget.type == 'blood_pressure'
          ? double.parse(_systolicController.text)
          : double.parse(_valueController.text),
      systolic: widget.type == 'blood_pressure'
          ? double.parse(_systolicController.text)
          : null,
      diastolic: widget.type == 'blood_pressure'
          ? double.parse(_diastolicController.text)
          : null,
      timestamp: _selectedDateTime,
    );

    if (widget.record == null) {
      await DatabaseHelper.instance.insertRecord(record);
    } else {
      await DatabaseHelper.instance.updateRecord(record);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }
} 