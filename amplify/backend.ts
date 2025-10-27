// amplify/backend.ts
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { data } from './data/resource';
import { setCompanyId } from './functions/set-company-id/resource';
import * as lambda from 'aws-cdk-lib/aws-lambda';

const backend = defineBackend({ auth, data, setCompanyId });

// Cast IFunction -> Function to access L2 helpers
const triggerFn = backend.setCompanyId.resources.lambda as unknown as lambda.Function;

