import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/intervention.dart';

class InterventionFormSheet extends StatefulWidget {
  const InterventionFormSheet({super.key});

  @override
  State<InterventionFormSheet> createState() => _InterventionFormSheetState();
}

class _InterventionFormSheetState extends State<InterventionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  InterventionCategory? _category = InterventionCategory.supplement;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isOngoing = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Track supplement/change',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        helperText:
                            'Supplement, medication, or lifestyle change',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<InterventionCategory?>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        ...InterventionCategory.values.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          ),
                        ),
                        const DropdownMenuItem<InterventionCategory?>(
                          value: null,
                          child: Text('Uncategorized'),
                        ),
                      ],
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        helperText: 'Optional context (brand, reason, etc.)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dosageController,
                            decoration:
                                const InputDecoration(labelText: 'Dosage'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _frequencyController,
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                              helperText: 'e.g. 2x daily',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Start date'),
                      subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _pickDate(isStart: true),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isOngoing,
                      title: const Text('Still taking / practicing'),
                      onChanged: (value) {
                        setState(() {
                          _isOngoing = value;
                          if (value) _endDate = null;
                        });
                      },
                    ),
                    if (!_isOngoing)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Stop date'),
                        subtitle: Text(_endDate == null
                            ? 'Select a date'
                            : DateFormat.yMMMd().format(_endDate!)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _pickDate(isStart: false),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        helperText:
                            'Comma separated (e.g. antihistamine, sleep)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Save protocol'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final draft = InterventionDraft(
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _isOngoing ? null : _endDate,
      category: _category,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty
          ? null
          : _dosageController.text.trim(),
      frequency: _frequencyController.text.trim().isEmpty
          ? null
          : _frequencyController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      tags: tags,
    );
    Navigator.of(context).pop(draft);
  }
}
