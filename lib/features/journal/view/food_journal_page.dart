import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/food_journal_repository.dart';
import '../models/intervention.dart';
import '../models/journal_entry.dart';
import '../widgets/entry_form.dart';
import '../widgets/intervention_form.dart';

class FoodJournalPage extends StatefulWidget {
  const FoodJournalPage({super.key});

  @override
  State<FoodJournalPage> createState() => _FoodJournalPageState();
}

class _FoodJournalPageState extends State<FoodJournalPage> {
  final _repository = FoodJournalRepository();
  late Future<List<JournalEntry>> _entriesFuture;
  late Future<List<Intervention>> _interventionsFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _repository.fetchEntries();
    _interventionsFuture = _repository.fetchInterventions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: const [SignOutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _openEntryForm,
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Protocols & supplements',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Add regimen',
                  onPressed: _openInterventionForm,
                  icon: const Icon(Icons.medication_outlined),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Intervention>>(
            future: _interventionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Interventions unavailable'),
                  subtitle: Text('${snapshot.error}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _reloadInterventions,
                  ),
                );
              }
              final interventions = snapshot.data ?? const <Intervention>[];
              if (interventions.isEmpty) {
                return ListTile(
                  title: const Text('No active supplements or changes'),
                  subtitle: const Text('Use the + button to log one.'),
                  trailing: TextButton(
                    onPressed: _openInterventionForm,
                    child: const Text('Add'),
                  ),
                );
              }
              return SizedBox(
                height: 104,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) => _InterventionCard(
                    intervention: interventions[index],
                  ),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: interventions.length.clamp(0, 8).toInt(),
                ),
              );
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isSubmitting
                ? const LinearProgressIndicator()
                : const SizedBox(height: 4),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<JournalEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      error: snapshot.error!,
                      onRetry: _refresh,
                    );
                  }
                  final entries = snapshot.data ?? const <JournalEntry>[];
                  if (entries.isEmpty) {
                    return _EmptyState(onCreate: _openEntryForm);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemBuilder: (_, index) =>
                        _EntryCard(entry: entries[index]),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: entries.length,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _entriesFuture = _repository.fetchEntries();
      _interventionsFuture = _repository.fetchInterventions();
    });
    await Future.wait([_entriesFuture, _interventionsFuture]);
  }

  void _reloadInterventions() {
    setState(() {
      _interventionsFuture = _repository.fetchInterventions();
    });
  }

  Future<void> _openEntryForm() async {
    final draft = await showModalBottomSheet<JournalEntryDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const JournalEntryFormSheet(),
    );
    if (draft == null) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _repository.createEntry(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry saved')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save entry: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openInterventionForm() async {
    final draft = await showModalBottomSheet<InterventionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const InterventionFormSheet(),
    );
    if (draft == null) {
      return;
    }
    try {
      await _repository.createIntervention(draft);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Protocol saved')),
      );
      _reloadInterventions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save protocol: $error')),
      );
    }
  }
}

class _InterventionCard extends StatelessWidget {
  const _InterventionCard({required this.intervention});

  final Intervention intervention;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateRange = _dateRange();
    final details = [
      intervention.dosage,
      intervention.frequency,
    ]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return SizedBox(
      width: 240,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: intervention.active
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : theme.colorScheme.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                intervention.name,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (intervention.category != null)
                Text(
                  intervention.category!.label,
                  style: theme.textTheme.labelMedium,
                ),
              const SizedBox(height: 4),
              Text(
                dateRange,
                style: theme.textTheme.bodySmall,
              ),
              if (details.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    details.join(' • '),
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if ((intervention.notes ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    intervention.notes!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateRange() {
    final start = DateFormat('MMM d').format(intervention.startDate);
    if (intervention.endDate == null) {
      return '$start → ongoing';
    }
    final end = DateFormat('MMM d').format(intervention.endDate!);
    return '$start → $end';
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d, yyyy • h:mm a');
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(formatter.format(entry.occurredAt)),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      label: Text(entry.entryType.label),
                      backgroundColor: theme.colorScheme.surfaceVariant,
                    ),
                    if (entry.entryType == EntryType.food &&
                        entry.mealType != null)
                      Chip(
                        label: Text(entry.mealType!.label),
                        backgroundColor: theme.colorScheme.secondaryContainer
                            .withOpacity(0.4),
                      ),
                  ],
                ),
              ],
            ),
            if (entry.entryType == EntryType.environment)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _EnvironmentDetails(entry: entry),
              ),
            if ((entry.symptomHeadline ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.symptomHeadline!,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 12),
            if (entry.symptoms.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.symptoms
                    .map(
                      (symptom) => Chip(
                        avatar: Icon(
                          Icons.circle,
                          size: 12,
                          color: _severityColor(symptom.severity, theme),
                        ),
                        label: Text(
                          [
                            symptom.symptomType?.label ?? 'Unknown',
                            if (symptom.onsetMinutes != null)
                              '${symptom.onsetMinutes}m',
                          ].join(' • '),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'No symptom details recorded',
                style: theme.textTheme.bodySmall,
              ),
            if ((entry.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(entry.notes!, style: theme.textTheme.bodyMedium),
            ],
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: entry.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor:
                            theme.colorScheme.primaryContainer.withOpacity(0.4),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _severityColor(SymptomSeverity? severity, ThemeData theme) {
    return switch (severity) {
      SymptomSeverity.mild => theme.colorScheme.tertiary,
      SymptomSeverity.moderate => theme.colorScheme.primary,
      SymptomSeverity.severe => theme.colorScheme.error,
      _ => theme.colorScheme.outline,
    };
  }
}

class _EnvironmentDetails extends StatelessWidget {
  const _EnvironmentDetails({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];
    if (entry.temperatureCelsius != null) {
      chips.add(Text(
        'Temp: ${entry.temperatureCelsius!.toStringAsFixed(1)}°C',
        style: theme.textTheme.bodyMedium,
      ));
    }
    if (entry.humidityPercent != null) {
      chips.add(Text(
        'Humidity: ${entry.humidityPercent!.toStringAsFixed(0)}%',
        style: theme.textTheme.bodyMedium,
      ));
    }
    if (entry.airQualityIndex != null) {
      chips.add(Text(
        'AQI: ${entry.airQualityIndex}',
        style: theme.textTheme.bodyMedium,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((entry.environmentTrigger ?? '').isNotEmpty)
          Text(
            entry.environmentTrigger!,
            style: theme.textTheme.titleSmall,
          ),
        if ((entry.environmentDetails ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(entry.environmentDetails!),
          ),
        if ((entry.location ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Location: ${entry.location}'),
          ),
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: chips,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      children: [
        Icon(
          Icons.note_alt_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        const Text(
          'No entries yet',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Track foods, environments, and the symptoms that follow so you can spot histamine and MCAS patterns.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onCreate,
          child: const Text('Add your first entry'),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 24),
        const Text(
          'We couldn\'t load your journal',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          '$error',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () {
            onRetry();
          },
          child: const Text('Try again'),
        ),
      ],
    );
  }
}
