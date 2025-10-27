import 'dart:convert';

import 'package:uuid/uuid.dart';

enum EntryType { food, environment }

enum MealType { breakfast, lunch, dinner, snack, drink, other }

enum SymptomKind {
  anxiety,
  brainFog,
  respiratory,
  cardio,
  skin,
  gi,
  pain,
  energy,
  other,
}

enum SymptomSeverity { mild, moderate, severe }

extension EnumDisplay on Enum {
  String get label {
    final raw = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String get apiValue => name.toUpperCase();
}

EntryType entryTypeFromApi(String value) => EntryType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => EntryType.food,
    );

MealType? mealTypeFromApi(String? value) => value == null
    ? null
    : MealType.values.firstWhere(
        (type) => type.apiValue == value,
        orElse: () => MealType.other,
      );

SymptomKind? symptomKindFromApi(String? value) => value == null
    ? null
    : SymptomKind.values.firstWhere(
        (type) => type.apiValue == value,
        orElse: () => SymptomKind.other,
      );

SymptomSeverity? symptomSeverityFromApi(String? value) => value == null
    ? null
    : SymptomSeverity.values.firstWhere(
        (type) => type.apiValue == value,
        orElse: () => SymptomSeverity.moderate,
      );

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.entryType,
    required this.title,
    required this.occurredAt,
    required this.symptoms,
    this.mealType,
    this.foodCategory,
    this.portionDescription,
    this.preparedHow,
    this.environmentTrigger,
    this.environmentDetails,
    this.location,
    this.temperatureCelsius,
    this.humidityPercent,
    this.airQualityIndex,
    this.onsetMinutesOverall,
    this.moodBefore,
    this.moodAfter,
    this.energyShift,
    this.hydration,
    this.symptomHeadline,
    this.notes,
    this.tags = const [],
  });

  final String id;
  final EntryType entryType;
  final String title;
  final DateTime occurredAt;
  final MealType? mealType;
  final String? foodCategory;
  final String? portionDescription;
  final String? preparedHow;
  final String? environmentTrigger;
  final String? environmentDetails;
  final String? location;
  final double? temperatureCelsius;
  final double? humidityPercent;
  final int? airQualityIndex;
  final int? onsetMinutesOverall;
  final String? moodBefore;
  final String? moodAfter;
  final String? energyShift;
  final String? hydration;
  final String? symptomHeadline;
  final String? notes;
  final List<String> tags;
  final List<SymptomEntry> symptoms;

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final symptomsPayload = json['symptoms'];
    final rawSymptoms = symptomsPayload is Map<String, dynamic>
        ? symptomsPayload['items']
        : json['symptoms'];
    return JournalEntry(
      id: json['id'] as String,
      entryType: entryTypeFromApi(json['entryType'] as String? ?? 'FOOD'),
      title: json['title'] as String? ?? 'Entry',
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.now(),
      mealType: mealTypeFromApi(json['mealType'] as String?),
      foodCategory: json['foodCategory'] as String?,
      portionDescription: json['portionDescription'] as String?,
      preparedHow: json['preparedHow'] as String?,
      environmentTrigger: json['environmentTrigger'] as String?,
      environmentDetails: json['environmentDetails'] as String?,
      location: json['location'] as String?,
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
      humidityPercent: (json['humidityPercent'] as num?)?.toDouble(),
      airQualityIndex: json['airQualityIndex'] as int?,
      onsetMinutesOverall: json['onsetMinutesOverall'] as int?,
      moodBefore: json['moodBefore'] as String?,
      moodAfter: json['moodAfter'] as String?,
      energyShift: json['energyShift'] as String?,
      hydration: json['hydration'] as String?,
      symptomHeadline: json['symptomHeadline'] as String?,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      symptoms: (rawSymptoms as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(SymptomEntry.fromJson)
              .toList() ??
          const [],
    );
  }
}

class SymptomEntry {
  const SymptomEntry({
    required this.id,
    this.symptomType,
    this.severity,
    this.onsetMinutes,
    this.durationMinutes,
    this.heartRateChange,
    this.temperatureChange,
    this.breathingDifficulty,
    this.notes,
  });

  final String id;
  final SymptomKind? symptomType;
  final SymptomSeverity? severity;
  final int? onsetMinutes;
  final int? durationMinutes;
  final int? heartRateChange;
  final double? temperatureChange;
  final bool? breathingDifficulty;
  final String? notes;

  factory SymptomEntry.fromJson(Map<String, dynamic> json) => SymptomEntry(
        id: json['id'] as String? ?? const Uuid().v4(),
        symptomType: symptomKindFromApi(json['symptomType'] as String?),
        severity: symptomSeverityFromApi(json['severity'] as String?),
        onsetMinutes: json['onsetMinutes'] as int?,
        durationMinutes: json['durationMinutes'] as int?,
        heartRateChange: json['heartRateChange'] as int?,
        temperatureChange: (json['temperatureChange'] as num?)?.toDouble(),
        breathingDifficulty: json['breathingDifficulty'] as bool?,
        notes: json['notes'] as String?,
      );
}

class JournalEntryDraft {
  JournalEntryDraft({
    required this.entryType,
    required this.title,
    required this.occurredAt,
    this.mealType,
    this.foodCategory,
    this.portionDescription,
    this.preparedHow,
    this.environmentTrigger,
    this.environmentDetails,
    this.location,
    this.temperatureCelsius,
    this.humidityPercent,
    this.airQualityIndex,
    this.onsetMinutesOverall,
    this.moodBefore,
    this.moodAfter,
    this.energyShift,
    this.hydration,
    this.symptomHeadline,
    this.notes,
    List<String>? tags,
    List<SymptomDraft>? symptoms,
  })  : tags = tags ?? <String>[],
        symptoms = symptoms ?? <SymptomDraft>[];

  final EntryType entryType;
  final String title;
  final DateTime occurredAt;
  final MealType? mealType;
  final String? foodCategory;
  final String? portionDescription;
  final String? preparedHow;
  final String? environmentTrigger;
  final String? environmentDetails;
  final String? location;
  final double? temperatureCelsius;
  final double? humidityPercent;
  final int? airQualityIndex;
  final int? onsetMinutesOverall;
  final String? moodBefore;
  final String? moodAfter;
  final String? energyShift;
  final String? hydration;
  final String? symptomHeadline;
  final String? notes;
  final List<String> tags;
  final List<SymptomDraft> symptoms;

  Map<String, dynamic> toInput({
    required String ownerId,
    required String entryId,
  }) {
    return {
      'id': entryId,
      'ownerId': ownerId,
      'entryType': entryType.apiValue,
      'title': title,
      'occurredAt': occurredAt.toIso8601String(),
      'mealType': mealType?.apiValue,
      'foodCategory': foodCategory,
      'portionDescription': portionDescription,
      'preparedHow': preparedHow,
      'environmentTrigger': environmentTrigger,
      'environmentDetails': environmentDetails,
      'location': location,
      'temperatureCelsius': temperatureCelsius,
      'humidityPercent': humidityPercent,
      'airQualityIndex': airQualityIndex,
      'onsetMinutesOverall': onsetMinutesOverall,
      'moodBefore': moodBefore,
      'moodAfter': moodAfter,
      'energyShift': energyShift,
      'hydration': hydration,
      'symptomHeadline': symptomHeadline,
      'notes': notes,
      'tags': tags.isEmpty ? null : tags,
    }..removeWhere((_, value) => value == null);
  }

  List<Map<String, dynamic>> symptomInputs({
    required String ownerId,
    required String entryId,
  }) {
    return symptoms
        .map((symptom) => symptom.toInput(ownerId: ownerId, entryId: entryId))
        .toList();
  }

  String toJson() => jsonEncode(toInput(ownerId: 'debug', entryId: 'draft'));
}

class SymptomDraft {
  SymptomDraft({
    required this.symptomType,
    required this.severity,
    required this.onsetMinutes,
    this.durationMinutes,
    this.heartRateChange,
    this.temperatureChange,
    this.breathingDifficulty,
    this.notes,
  });

  final SymptomKind symptomType;
  final SymptomSeverity severity;
  final int onsetMinutes;
  final int? durationMinutes;
  final int? heartRateChange;
  final double? temperatureChange;
  final bool? breathingDifficulty;
  final String? notes;

  Map<String, dynamic> toInput({
    required String ownerId,
    required String entryId,
  }) {
    return {
      'ownerId': ownerId,
      'journalEntryId': entryId,
      'symptomType': symptomType.apiValue,
      'severity': severity.apiValue,
      'onsetMinutes': onsetMinutes,
      'durationMinutes': durationMinutes,
      'heartRateChange': heartRateChange,
      'temperatureChange': temperatureChange,
      'breathingDifficulty': breathingDifficulty,
      'notes': notes,
    }..removeWhere((_, value) => value == null);
  }
}
