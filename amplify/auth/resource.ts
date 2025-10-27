import { defineAuth } from '@aws-amplify/backend';
import { setCompanyId } from '../functions/set-company-id/resource';
/**
 * Define and configure your auth resource
 * @see https://docs.amplify.aws/gen2/build-a-backend/auth
 */
export const auth = defineAuth({
  loginWith: {
    email: true,
  },

  userAttributes: {
    "custom:ownerId": {
      dataType: "String",
      mutable: true,
      maxLen: 128,
      minLen: 1,
    },
    "custom:customerId": {
      dataType: "String",
      mutable: true,
      maxLen: 128,
      minLen: 1,
    },

  },
  triggers: {
    preTokenGeneration: setCompanyId,
  },
});
