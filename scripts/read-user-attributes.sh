#!/usr/bin/env bash

set -euo pipefail

AWS_REGION=us-east-2
USER_POOL_ID=us-east-2_ldXgGgy9P
APP_CLIENT_ID=5e0caq4ro7tetq7nlnudoh60fu


if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <username>"
  exit 1
fi

USERNAME="$1"

aws cognito-idp admin-get-user \
  --region "$AWS_REGION" \
  --user-pool-id "$USER_POOL_ID" \
  --username "$USERNAME" \
  --query '{Username:Username,Enabled:Enabled,UserStatus:UserStatus,Attributes:UserAttributes}' \
  --output json