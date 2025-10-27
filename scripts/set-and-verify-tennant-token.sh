#!/bin/bash

AWS_REGION=us-east-2
USER_POOL_ID=us-east-2_ldXgGgy9P
APP_CLIENT_ID=5e0caq4ro7tetq7nlnudoh60fu

aws cognito-idp describe-user-pool-client \
  --region $AWS_REGION \
  --user-pool-id $USER_POOL_ID \
  --client-id $APP_CLIENT_ID \
  --query 'UserPoolClient.ReadAttributes'

aws cognito-idp update-user-pool-client \
  --region $AWS_REGION \
  --user-pool-id $USER_POOL_ID \
  --client-id $APP_CLIENT_ID \
  --read-attributes "email" "email_verified" "given_name" "family_name" "custom:ownerId" "custom:customerId"

aws cognito-idp describe-user-pool-client \
  --region $AWS_REGION \
  --user-pool-id $USER_POOL_ID \
  --client-id $APP_CLIENT_ID \
  --query 'UserPoolClient.ReadAttributes'
# [
#     "custom:ownerId",
#     "custom:customerId",
#     "email",
#     "email_verified",
#     "family_name",
#     "given_name"
# ]