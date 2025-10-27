import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/journal_entry.dart';

class JournalEntryFormSheet extends StatefulWidget {
  const JournalEntryFormSheet({super.key});

  @override
  State<JournalEntryFormSheet> createState() => _JournalEntryFormSheetState();
}

class _JournalEntryFormSheetState extends State<JournalEntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _headlineController = TextEditingController();
  final _tagsController = TextEditingController();
  final _overallOnsetController = TextEditingController();
  final _moodBeforeController = TextEditingController();
  final _moodAfterController = TextEditingController();
  final _preparedHowController = TextEditingController();
  final _locationController = TextEditingController();
  final _environmentTriggerController = TextEditingController();
  final _environmentDetailsController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _aqiController = TextEditingController();
  EntryType _entryType = EntryType.food;
  MealType? _mealType;
  DateTime _occurredAt = DateTime.now();
  final List<_EditableSymptom> _symptoms = [_EditableSymptom()];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _headlineController.dispose();
    _tagsController.dispose();
    _overallOnsetController.dispose();
    _moodBeforeController.dispose();
    _moodAfterController.dispose();
    _preparedHowController.dispose();
    _locationController.dispose();
    _environmentTriggerController.dispose();
    _environmentDetailsController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _aqiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.95,
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
                            'New journal entry',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<EntryType>(
                      segments: const [
                        ButtonSegment(
                          value: EntryType.food,
                          label: Text('Food'),
                          icon: Icon(Icons.restaurant),
                        ),
                        ButtonSegment(
                          value: EntryType.environment,
                          label: Text('Environment'),
                          icon: Icon(Icons.landscape),
                        ),
                      ],
                      selected: {_entryType},
                      onSelectionChanged: (selection) {
                        setState(() => _entryType = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: _entryType == EntryType.food
                            ? 'Food or meal *'
                            : 'Trigger or environment *',
                        helperText: _entryType == EntryType.food
                            ? 'Example: Eggs with toast'
                            : 'Example: Walked into cold grocery store',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tell us what you encountered.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_entryType == EntryType.food)
                      DropdownButtonFormField<MealType?>(
                        value: _mealType,
                        decoration:
                            const InputDecoration(labelText: 'Meal type'),
                        items: [
                          const DropdownMenuItem<MealType?>(
                            value: null,
                            child: Text('No specific meal type'),
                          ),
                          ...MealType.values.map(
                            (type) => DropdownMenuItem<MealType?>(
                              value: type,
                              child: Text(type.label),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _mealType = value),
                      ),
                    if (_entryType == EntryType.environment)
                      Column(
                        children: [
                          TextFormField(
                            controller: _environmentTriggerController,
                            decoration: const InputDecoration(
                              labelText: 'What changed?',
                              helperText:
                                  'Environment, smells, air quality, travel, etc.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _environmentDetailsController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Details',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _temperatureController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Temperature (°C)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _humidityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Humidity (%)',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _aqiController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'AQI'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('When did this happen?'),
                      subtitle: Text(
                        DateFormat('MMM d • h:mm a').format(_occurredAt),
                      ),
                      trailing: const Icon(Icons.schedule),
                      onTap: _pickDateTime,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Where were you?',
                        helperText: 'Optional location or environment notes',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_entryType == EntryType.food)
                      TextFormField(
                        controller: _preparedHowController,
                        decoration: const InputDecoration(
                          labelText: 'How was it prepared?',
                          helperText: 'Leftovers, restaurant, reheated, etc.',
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _headlineController,
                      decoration: const InputDecoration(
                        labelText: 'Symptom headline',
                        helperText: 'Short summary of how you felt',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _overallOnsetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Overall onset (minutes)',
                        helperText: 'How long before symptoms kicked in?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _moodBeforeController,
                            decoration: const InputDecoration(
                              labelText: 'Mood before',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _moodAfterController,
                            decoration: const InputDecoration(
                              labelText: 'Mood after',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      minLines: 3,
                      maxLines: 5,
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
                            'Comma separated (ex: eggs, leftovers, cold-room)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Symptoms',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._symptoms.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SymptomCard(
                              index: entry.key,
                              symptom: entry.value,
                              canRemove: _symptoms.length > 1,
                              onChanged: () => setState(() {}),
                              onRemove: () => _removeSymptom(entry.key),
                            ),
                          ),
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addSymptom,
                        icon: const Icon(Icons.add),
                        label: const Text('Add another symptom'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Save entry'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) return;
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _addSymptom() {
    setState(() => _symptoms.add(_EditableSymptom()));
  }

  void _removeSymptom(int index) {
    if (_symptoms.length == 1) return;
    setState(() => _symptoms.removeAt(index));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final symptomDrafts = _symptoms
        .map((symptom) => symptom.toDraft())
        .whereType<SymptomDraft>()
        .toList();

    if (symptomDrafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one symptom.')),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final draft = JournalEntryDraft(
      entryType: _entryType,
      title: _titleController.text.trim(),
      occurredAt: _occurredAt,
      mealType: _entryType == EntryType.food ? _mealType : null,
      preparedHow: _entryType == EntryType.food
          ? _preparedHowController.text.trim().isEmpty
              ? null
              : _preparedHowController.text.trim()
          : null,
      environmentTrigger: _entryType == EntryType.environment
          ? _environmentTriggerController.text.trim().isEmpty
              ? null
              : _environmentTriggerController.text.trim()
          : null,
      environmentDetails: _entryType == EntryType.environment
          ? _environmentDetailsController.text.trim().isEmpty
              ? null
              : _environmentDetailsController.text.trim()
          : null,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      temperatureCelsius: _entryType == EntryType.environment
          ? double.tryParse(_temperatureController.text.trim())
          : null,
      humidityPercent: _entryType == EntryType.environment
          ? double.tryParse(_humidityController.text.trim())
          : null,
      airQualityIndex: _entryType == EntryType.environment
          ? int.tryParse(_aqiController.text.trim())
          : null,
      onsetMinutesOverall: int.tryParse(_overallOnsetController.text.trim()),
      moodBefore: _moodBeforeController.text.trim().isEmpty
          ? null
          : _moodBeforeController.text.trim(),
      moodAfter: _moodAfterController.text.trim().isEmpty
          ? null
          : _moodAfterController.text.trim(),
      symptomHeadline: _headlineController.text.trim().isEmpty
          ? null
          : _headlineController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      tags: tags,
      symptoms: symptomDrafts,
    );

    Navigator.of(context).pop(draft);
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({
    required this.index,
    required this.symptom,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _EditableSymptom symptom;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Symptom ${index + 1}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: 'Remove symptom',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            DropdownButtonFormField<SymptomKind>(
              value: symptom.symptomType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: SymptomKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(kind.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                symptom.symptomType = value;
                onChanged();
              },
              validator: (value) {
                if (value == null) {
                  return 'Pick a symptom';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SymptomSeverity>(
              value: symptom.severity,
              decoration: const InputDecoration(labelText: 'Severity'),
              items: SymptomSeverity.values
                  .map(
                    (severity) => DropdownMenuItem(
                      value: severity,
                      child: Text(severity.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                symptom.severity = value;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: symptom.onsetMinutes == null
                        ? ''
                        : '${symptom.onsetMinutes}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Onset (minutes)',
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      symptom.onsetMinutes = parsed ?? symptom.onsetMinutes;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: symptom.durationMinutes == null
                        ? ''
                        : '${symptom.durationMinutes}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                    ),
                    onChanged: (value) {
                      symptom.durationMinutes = int.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: symptom.breathingDifficulty,
              title: const Text('Breathing felt restricted'),
              onChanged: (value) {
                symptom.breathingDifficulty = value;
                onChanged();
              },
            ),
            TextFormField(
              initialValue: symptom.notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Symptom notes',
                alignLabelWithHint: true,
              ),
              onChanged: (value) {
                symptom.notes = value;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableSymptom {
  _EditableSymptom()
      : severity = SymptomSeverity.moderate,
        onsetMinutes = 60;

  SymptomKind? symptomType;
  SymptomSeverity severity;
  int onsetMinutes;
  int? durationMinutes;
  bool breathingDifficulty = false;
  String notes = '';

  SymptomDraft? toDraft() {
    final type = symptomType;
    if (type == null) {
      return null;
    }
    return SymptomDraft(
      symptomType: type,
      severity: severity,
      onsetMinutes: onsetMinutes,
      durationMinutes: durationMinutes,
      breathingDifficulty: breathingDifficulty ? true : null,
      notes: notes.trim().isEmpty ? null : notes.trim(),
    );
  }
}
