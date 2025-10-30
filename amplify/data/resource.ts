import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a
  .schema({
    ExposureType: a.enum(['FOOD', 'ENVIRONMENT']),
    ReactionSeverity: a.enum(['MILD', 'MODERATE', 'SEVERE']),
    TreatmentCategory: a.enum([
      'SUPPLEMENT',
      'MEDICATION',
      'LIFESTYLE',
      'ALTERNATIVE',
      'OTHER',
    ]),
    FoodExposure: a
      .model({
        id: a.id(),
        ownerId: a.string().required(),
        exposureType: a.ref('ExposureType').required(),
        occurredAt: a.datetime().required(),
        items: a.string().array().required(),
        description: a.string(),
        environmentNotes: a.string(),
        location: a.string(),
        temperatureCelsius: a.float(),
        humidityPercent: a.float(),
        airQualityIndex: a.integer(),
        tags: a.string().array(),
        notes: a.string(),
      })
      .authorization((allow) => [
        allow.owner(),
        allow.group('Admin').to(['create', 'read', 'update', 'delete']),
      ]),
    ReactionLog: a
      .model({
        id: a.id(),
        ownerId: a.string().required(),
        loggedAt: a.datetime().required(),
        severity: a.ref('ReactionSeverity').required(),
        symptoms: a.string().array().required(),
        mood: a.string(),
        onsetMinutes: a.integer(),
        relatedExposureId: a.id(),
        notes: a.string(),
        tags: a.string().array(),
        exposure: a.belongsTo('FoodExposure', 'relatedExposureId'),
      })
      .authorization((allow) => [
        allow.owner(),
        allow.group('Admin').to(['create', 'read', 'update', 'delete']),
      ]),
    TreatmentLog: a
      .model({
        id: a.id(),
        ownerId: a.string().required(),
        name: a.string().required(),
        category: a.ref('TreatmentCategory'),
        dosage: a.string(),
        amount: a.string(),
        takenAt: a.datetime().required(),
        purpose: a.string(),
        notes: a.string(),
        tags: a.string().array(),
        relatedExposureId: a.id(),
        relatedReactionId: a.id(),
        exposure: a.belongsTo('FoodExposure', 'relatedExposureId'),
        reaction: a.belongsTo('ReactionLog', 'relatedReactionId'),
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
