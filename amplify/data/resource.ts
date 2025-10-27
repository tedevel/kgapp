import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a
  .schema({
    EntryType: a.enum(['FOOD', 'ENVIRONMENT']),
    InterventionCategory: a.enum([
      'SUPPLEMENT',
      'MEDICATION',
      'LIFESTYLE',
      'ALTERNATIVE',
      'OTHER',
    ]),
    MealType: a.enum([
      'BREAKFAST',
      'LUNCH',
      'DINNER',
      'SNACK',
      'DRINK',
      'OTHER',
    ]),
    SymptomKind: a.enum([
      'ANXIETY',
      'BRAIN_FOG',
      'RESPIRATORY',
      'CARDIO',
      'SKIN',
      'GI',
      'PAIN',
      'ENERGY',
      'OTHER',
    ]),
    SymptomSeverity: a.enum(['MILD', 'MODERATE', 'SEVERE']),
    JournalEntry: a
      .model({
        id: a.id(),
        ownerId: a.string().required(),
        entryType: a.ref('EntryType').required(),
        title: a.string().required(),
        occurredAt: a.datetime().required(),
        mealType: a.ref('MealType'),
        foodCategory: a.string(),
        portionDescription: a.string(),
        preparedHow: a.string(),
        environmentTrigger: a.string(),
        environmentDetails: a.string(),
        location: a.string(),
        temperatureCelsius: a.float(),
        humidityPercent: a.float(),
        airQualityIndex: a.integer(),
        onsetMinutesOverall: a.integer(),
        moodBefore: a.string(),
        moodAfter: a.string(),
        energyShift: a.string(),
        hydration: a.string(),
        symptomHeadline: a.string(),
        notes: a.string(),
        tags: a.string().array(),
        symptoms: a.hasMany('SymptomEntry', 'journalEntryId'),
      })
      .authorization((allow) => [
        allow.owner(),
        allow.group('Admin').to(['create', 'read', 'update', 'delete']),
      ]),
    SymptomEntry: a
      .model({
        id: a.id(),
        ownerId: a.string().required(),
        journalEntryId: a.id().required(),
        symptomType: a.ref('SymptomKind').required(),
        severity: a.ref('SymptomSeverity').required(),
        onsetMinutes: a.integer().required(),
        durationMinutes: a.integer(),
        heartRateChange: a.integer(),
        temperatureChange: a.float(),
        breathingDifficulty: a.boolean(),
        notes: a.string(),
        journalEntry: a.belongsTo('JournalEntry', 'journalEntryId'),
      })
      .authorization((allow) => [
        allow.owner(),
        allow.group('Admin').to(['create', 'read', 'update', 'delete']),
      ]),
    Intervention: a
      .model({
        id: a.id(),
        ownerId: a.string().required(),
        name: a.string().required(),
        category: a.ref('InterventionCategory'),
        description: a.string(),
        dosage: a.string(),
        frequency: a.string(),
        startDate: a.datetime().required(),
        endDate: a.datetime(),
        notes: a.string(),
        active: a.boolean().default(true),
        tags: a.string().array(),
      })
      .authorization((allow) => [
        allow.owner(),
        allow.group('Admin').to(['create', 'read', 'update', 'delete']),
      ]),
  })
  .authorization((allow) => [
    allow.authenticated('identityPool').to(['read']),
    allow.group('Admin').to(['create', 'read', 'update', 'delete']),
  ]);

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
    // iam auth implemented by default in gen2 (used by data console, etc)
  },
  name: 'kgFoodJournalData',
});
