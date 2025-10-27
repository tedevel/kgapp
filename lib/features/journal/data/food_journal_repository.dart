import 'dart:convert';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/intervention.dart';
import '../models/journal_entry.dart';

class FoodJournalRepository {
  FoodJournalRepository({AmplifyClass? amplify})
      : _amplify = amplify ?? Amplify;

  final AmplifyClass _amplify;

  Future<List<JournalEntry>> fetchEntries({int limit = 50}) async {
    final user = await _amplify.Auth.getCurrentUser();
    final request = GraphQLRequest<String>(
      document: _listJournalEntries,
      variables: <String, dynamic>{
        'filter': {
          'ownerId': {'eq': user.userId},
        },
        'limit': limit,
      },
    );

    final response = await _amplify.API.query(request: request).response;
    _ensureNoErrors(response);

    final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final list =
        decoded['listJournalEntries'] as Map<String, dynamic>? ?? const {};
    final items = (list['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(JournalEntry.fromJson)
            .toList() ??
        const <JournalEntry>[];

    final sorted = [...items]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return sorted;
  }

  Future<void> createEntry(JournalEntryDraft draft) async {
    final user = await _amplify.Auth.getCurrentUser();
    final entryId = const Uuid().v4();

    final entryRequest = GraphQLRequest<String>(
      document: _createJournalEntryMutation,
      variables: {
        'input': draft.toInput(ownerId: user.userId, entryId: entryId),
      },
    );

    final entryResponse =
        await _amplify.API.mutate(request: entryRequest).response;
    _ensureNoErrors(entryResponse);

    final symptomInputs = draft.symptomInputs(
      ownerId: user.userId,
      entryId: entryId,
    );

    for (final input in symptomInputs) {
      final request = GraphQLRequest<String>(
        document: _createSymptomEntryMutation,
        variables: {'input': input},
      );
      final response = await _amplify.API.mutate(request: request).response;
      _ensureNoErrors(response);
    }
  }

  Future<List<Intervention>> fetchInterventions({
    bool activeOnly = true,
  }) async {
    final user = await _amplify.Auth.getCurrentUser();
    final filter = <String, dynamic>{
      'ownerId': {'eq': user.userId},
      if (activeOnly) 'active': {'eq': true},
    };
    final request = GraphQLRequest<String>(
      document: _listInterventionsQuery,
      variables: {
        'filter': filter,
        'limit': 100,
      },
    );
    final response = await _amplify.API.query(request: request).response;
    _ensureNoErrors(response);
    final decoded = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final payload =
        decoded['listInterventions'] as Map<String, dynamic>? ?? const {};
    final items = (payload['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Intervention.fromJson)
            .toList() ??
        const <Intervention>[];
    final sorted = [...items]..sort((a, b) {
        final endA = a.endDate ?? DateTime.now().add(const Duration(days: 365));
        final endB = b.endDate ?? DateTime.now().add(const Duration(days: 365));
        return endB.compareTo(endA);
      });
    return sorted;
  }

  Future<void> createIntervention(InterventionDraft draft) async {
    final user = await _amplify.Auth.getCurrentUser();
    final interventionId = const Uuid().v4();
    final request = GraphQLRequest<String>(
      document: _createInterventionMutation,
      variables: {
        'input': draft.toInput(
          ownerId: user.userId,
          interventionId: interventionId,
        ),
      },
    );
    final response = await _amplify.API.mutate(request: request).response;
    _ensureNoErrors(response);
  }

  void _ensureNoErrors(GraphQLResponse<String> response) {
    if (response.errors.isEmpty) {
      return;
    }
    final message = response.errors.map((error) => error.message).join('\n');
    throw DataLayerException(message);
  }
}

class DataLayerException implements Exception {
  DataLayerException(this.message);

  final String message;

  @override
  String toString() => 'DataLayerException: $message';
}

const _listJournalEntries = r'''
query ListJournalEntries($filter: ModelJournalEntryFilterInput, $limit: Int, $nextToken: String) {
  listJournalEntries(filter: $filter, limit: $limit, nextToken: $nextToken) {
    items {
      id
      ownerId
      entryType
      title
      occurredAt
      mealType
      foodCategory
      portionDescription
      preparedHow
      environmentTrigger
      environmentDetails
      location
      temperatureCelsius
      humidityPercent
      airQualityIndex
      onsetMinutesOverall
      moodBefore
      moodAfter
      energyShift
      hydration
      symptomHeadline
      notes
      tags
      symptoms {
        items {
          id
          symptomType
          severity
          onsetMinutes
          durationMinutes
          heartRateChange
          temperatureChange
          breathingDifficulty
          notes
        }
      }
    }
    nextToken
  }
}
''';

const _createJournalEntryMutation = r'''
mutation CreateJournalEntry($input: CreateJournalEntryInput!) {
  createJournalEntry(input: $input) {
    id
  }
}
''';

const _createSymptomEntryMutation = r'''
mutation CreateSymptomEntry($input: CreateSymptomEntryInput!) {
  createSymptomEntry(input: $input) {
    id
  }
}
''';

const _listInterventionsQuery = r'''
query ListInterventions($filter: ModelInterventionFilterInput, $limit: Int, $nextToken: String) {
  listInterventions(filter: $filter, limit: $limit, nextToken: $nextToken) {
    items {
      id
      ownerId
      name
      category
      description
      dosage
      frequency
      startDate
      endDate
      notes
      active
      tags
    }
    nextToken
  }
}
''';

const _createInterventionMutation = r'''
mutation CreateIntervention($input: CreateInterventionInput!) {
  createIntervention(input: $input) {
    id
  }
}
''';
