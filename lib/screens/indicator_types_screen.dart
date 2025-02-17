import 'package:flutter/material.dart';
import '../models/indicator_type.dart';
import '../database/database_helper.dart';

class IndicatorTypesScreen extends StatefulWidget {
  const IndicatorTypesScreen({super.key});

  @override
  State<IndicatorTypesScreen> createState() => _IndicatorTypesScreenState();
}

class _IndicatorTypesScreenState extends State<IndicatorTypesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          '指标管理',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: FutureBuilder<List<IndicatorType>>(
        future: DatabaseHelper.instance.getIndicatorTypes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final types = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final type = types[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: Text(
                    type.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${type.unit}${type.isMultiValue ? ' (双值)' : ''}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editIndicatorType(type),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[300],
                        ),
                        onPressed: () => _deleteIndicatorType(type),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addIndicatorType,
        icon: const Icon(Icons.add),
        label: const Text('添加指标'),
        elevation: 2,
      ),
    );
  }

  Future<void> _addIndicatorType() async {
    final type = await showDialog<IndicatorType>(
      context: context,
      builder: (context) => const IndicatorTypeDialog(),
    );

    if (type != null) {
      await DatabaseHelper.instance.insertIndicatorType(type);
      setState(() {});
    }
  }

  Future<void> _editIndicatorType(IndicatorType type) async {
    final updatedType = await showDialog<IndicatorType>(
      context: context,
      builder: (context) => IndicatorTypeDialog(type: type),
    );

    if (updatedType != null) {
      await DatabaseHelper.instance.updateIndicatorType(updatedType);
      setState(() {});
    }
  }

  Future<void> _deleteIndicatorType(IndicatorType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除指标'),
        content: Text('确定要删除${type.name}吗？这将同时删除所有相关记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await DatabaseHelper.instance.deleteIndicatorType(type.id!);
      setState(() {});
    }
  }
}

class IndicatorTypeDialog extends StatefulWidget {
  final IndicatorType? type;

  const IndicatorTypeDialog({super.key, this.type});

  @override
  State<IndicatorTypeDialog> createState() => _IndicatorTypeDialogState();
}

class _IndicatorTypeDialogState extends State<IndicatorTypeDialog> {
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _value1NameController;
  late TextEditingController _value2NameController;
  late bool _isMultiValue;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.type?.code ?? '');
    _nameController = TextEditingController(text: widget.type?.name ?? '');
    _unitController = TextEditingController(text: widget.type?.unit ?? '');
    _value1NameController = TextEditingController(text: widget.type?.majorValueName ?? '');
    _value2NameController = TextEditingController(text: widget.type?.minorValueName ?? '');
    _isMultiValue = widget.type?.isMultiValue ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.type == null ? '添加指标' : '编辑指标'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: '代码'),
              enabled: widget.type == null,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: '单位'),
            ),
            TextField(
              controller: _value1NameController,
              decoration: const InputDecoration(labelText: '第一个值的名称'),
            ),
            CheckboxListTile(
              title: const Text('是否有两个值'),
              value: _isMultiValue,
              onChanged: (value) {
                setState(() {
                  _isMultiValue = value!;
                });
              },
            ),
            if (_isMultiValue)
              TextField(
                controller: _value2NameController,
                decoration: const InputDecoration(labelText: '第二个值的名称'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _codeController.text.isEmpty ||
                _unitController.text.isEmpty ||
                (_isMultiValue && _value2NameController.text.isEmpty)) {
              return;
            }

            final type = IndicatorType(
              id: widget.type?.id,
              code: _codeController.text,
              name: _nameController.text,
              unit: _unitController.text,
              isMultiValue: _isMultiValue,
              majorValueName: _value1NameController.text,
              minorValueName: _isMultiValue ? _value2NameController.text : null,
            );

            Navigator.pop(context, type);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _value1NameController.dispose();
    _value2NameController.dispose();
    super.dispose();
  }
} 