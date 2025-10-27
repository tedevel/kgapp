import { defineFunction } from '@aws-amplify/backend';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cdk from 'aws-cdk-lib';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const setCompanyId = defineFunction(
  (scope) =>
    new lambda.Function(scope, 'SetCompanyIdPython', {
      runtime: lambda.Runtime.PYTHON_3_12,
      handler: 'handler.handler',
      code: lambda.Code.fromAsset(__dirname), // bundles handler.py
      timeout: cdk.Duration.seconds(3),
    }),
  { resourceGroupName: 'auth' } // <<< put this function in the AUTH stack
);