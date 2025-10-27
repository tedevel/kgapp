#!/bin/bash

AWS_REGION=us-east-2
USER_POOL_ID=us-east-2_ldXgGgy9P
APP_CLIENT_ID=5e0caq4ro7tetq7nlnudoh60fu


aws cognito-idp admin-update-user-attributes \
  --region $AWS_REGION \
  --user-pool-id $USER_POOL_ID \
  --username <USERNAME> \
  --user-attributes Name=custom:ownerId,Value=<OWNER_ID> Name=custom:customerId,Value=<CUSTOMER_ID>

  