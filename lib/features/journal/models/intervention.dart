import 'package:uuid/uuid.dart';

enum InterventionCategory {
  supplement,
  medication,
  lifestyle,
  alternative,
  other,
}

InterventionCategory categoryFromApi(String? value) {
  if (value == null) return InterventionCategory.other;
  return InterventionCategory.values.firstWhere(
    (category) => category.name.toUpperCase() == value,
    orElse: () => InterventionCategory.other,
  );
}

extension InterventionCategoryDisplay on InterventionCategory {
  String get label {
    switch (this) {
      case InterventionCategory.supplement:
        return 'Supplement';
      case InterventionCategory.medication:
        return 'Medication';
      case InterventionCategory.lifestyle:
        return 'Lifestyle';
      case InterventionCategory.alternative:
        return 'Alternative';
      case InterventionCategory.other:
        return 'Other';
    }
  }

  String get apiValue => name.toUpperCase();
}

class Intervention {
  const Intervention({
    required this.id,
    required this.name,
    required this.startDate,
    this.category,
    this.description,
    this.dosage,
    this.frequency,
    this.endDate,
    this.notes,
    this.active = true,
    this.tags = const [],
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final InterventionCategory? category;
  final String? description;
  final String? dosage;
  final String? frequency;
  final String? notes;
  final bool active;
  final List<String> tags;

  factory Intervention.fromJson(Map<String, dynamic> json) {
    return Intervention(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Unknown',
      category: json['category'] == null
          ? null
          : categoryFromApi(json['category'] as String?),
      description: json['description'] as String?,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      notes: json['notes'] as String?,
      active: json['active'] as bool? ?? true,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class InterventionDraft {
  InterventionDraft({
    required this.name,
    required this.startDate,
    this.category,
    this.description,
    this.dosage,
    this.frequency,
    this.endDate,
    this.notes,
    List<String>? tags,
  }) : tags = tags ?? <String>[];

  final String name;
  final DateTime startDate;
  final DateTime? endDate;
  final InterventionCategory? category;
  final String? description;
  final String? dosage;
  final String? frequency;
  final String? notes;
  final List<String> tags;

  Map<String, dynamic> toInput({
    required String ownerId,
    required String interventionId,
  }) {
    return {
      'id': interventionId,
      'ownerId': ownerId,
      'name': name,
      'category': category?.apiValue,
      'description': description,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'notes': notes,
      'active': endDate == null,
      'tags': tags.isEmpty ? null : tags,
    }..removeWhere((_, value) => value == null);
  }
}
