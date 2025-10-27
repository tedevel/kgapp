#!/usr/bin/env python3
import os
import sys
import json
import argparse
import requests
import boto3
from botocore.exceptions import ClientError
from requests_aws4auth import AWS4Auth

MT_PROD_API_ENDPOINT = 'https://ithlpd4m7vcfnigzgyiawcwwha.appsync-api.us-east-2.amazonaws.com/graphql'
MT_TEST_API_ENDPOINT = 'https://qjgx43kzwjh5hmlmou244agwbe.appsync-api.us-east-2.amazonaws.com/graphql'
MT_DEV_API_ENDPOINT = 'https://tchze4msqffazhw25donxs6dai.appsync-api.us-east-2.amazonaws.com/graphql'
CHOSEN_API_ENDPOINT = MT_PROD_API_ENDPOINT

PROD_POOL_ID = "us-east-2_aLqQR1UeF"
TEST_POOL_ID = 'us-east-2_EEUIdBPvX'
DEV_POOL_ID = 'us-east-2_32a0QUTC8'
CHOSEN_POOL_ID = DEV_POOL_ID

def get_aws_auth(region: str, service: str = "appsync") -> AWS4Auth:
    session = boto3.Session()
    creds = session.get_credentials()
    if creds is None:
        print("ERROR: No AWS credentials found (profile/ENV).", file=sys.stderr)
        sys.exit(2)
    frozen = creds.get_frozen_credentials()
    return AWS4Auth(frozen.access_key, frozen.secret_key, region, service, session_token=frozen.token)

def appsync_post(url: str, aws_auth: AWS4Auth, query: str, variables: dict):
    payload = {"query": query, "variables": variables}
    headers = {"Content-Type": "application/json"}
    resp = requests.post(url, auth=aws_auth, json=payload, headers=headers)
    if resp.status_code != 200:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text}")
    data = resp.json()
    if "errors" in data and data["errors"]:
        raise RuntimeError(json.dumps(data["errors"], indent=2))
    return data

def find_company_id_by_name(appsync_url: str, region: str, name: str) -> str:
    aws_auth = get_aws_auth(region)
    query = """
    query FindCompanyByName($name: String!) {
      listCompanies(filter: { name: { eq: $name } }) {
        items { id name }
      }
    }
    """
    data = appsync_post(appsync_url, aws_auth, query, {"name": name})
    items = data["data"]["listCompanies"]["items"]
    if not items:
        raise RuntimeError(f"No company found with name='{name}'.")
    if len(items) > 1:
        raise RuntimeError(f"Multiple companies found with name='{name}'. Please resolve duplicates.")
    return items[0]["id"]

def user_exists(cognito, user_pool_id: str, username: str) -> bool:
    try:
        cognito.admin_get_user(UserPoolId=user_pool_id, Username=username)
        return True
    except ClientError as e:
        if e.response.get("Error", {}).get("Code") == "UserNotFoundException":
            return False
        raise

def create_user_with_temp_password(
    cognito, user_pool_id: str, email: str, temp_password: str, attributes: dict, suppress=True
):
    params = {
        "UserPoolId": user_pool_id,
        "Username": email,
        "UserAttributes": [{"Name": "email", "Value": email},
                           {"Name": "email_verified", "Value": "true"}]
                         + [{"Name": k, "Value": v} for k, v in attributes.items()],
        "TemporaryPassword": temp_password,
    }
    if suppress:
        params["MessageAction"] = "SUPPRESS"  # don't send email
    cognito.admin_create_user(**params)

def create_user_and_set_permanent_password(
    cognito, user_pool_id: str, email: str, password: str, attributes: dict, suppress=True
):
    params = {
        "UserPoolId": user_pool_id,
        "Username": email,
        "UserAttributes": [{"Name": "email", "Value": email},
                           {"Name": "email_verified", "Value": "true"}]
                         + [{"Name": k, "Value": v} for k, v in attributes.items()],
    }
    if suppress:
        params["MessageAction"] = "SUPPRESS"
    try:
        cognito.admin_create_user(**params)
    except ClientError as e:
        if e.response.get("Error", {}).get("Code") != "UsernameExistsException":
            raise
    # Now set permanent password
    cognito.admin_set_user_password(
        UserPoolId=user_pool_id, Username=email, Password=password, Permanent=True
    )

def set_temp_password_for_existing_user(cognito, user_pool_id: str, email: str, temp_password: str):
    # For an existing user, you can set a password and keep it temporary by Permanent=False.
    cognito.admin_set_user_password(
        UserPoolId=user_pool_id, Username=email, Password=temp_password, Permanent=False
    )

def set_permanent_password_for_existing_user(cognito, user_pool_id: str, email: str, password: str):
    cognito.admin_set_user_password(
        UserPoolId=user_pool_id, Username=email, Password=password, Permanent=True
    )

def main():
    parser = argparse.ArgumentParser(
        description="Create/Update Cognito user and attach companyId by company name."
    )
    parser.add_argument("email", help="User email (username)")
    parser.add_argument("password", help="Initial password (temp or permanent based on mode)")
    parser.add_argument("company_name", help="Company name to attach to user")
    parser.add_argument("pool", choices=["dev", "test", "prod"], help="User Pool")
    parser.add_argument("role", choices=["owner", "customer"], help="Role to tag (owner/customer)")
    parser.add_argument(
        "--mode",
        choices=["temp", "permanent"],
        default="temp",
        help="Password mode: 'temp' (NEW_PASSWORD_REQUIRED) or 'permanent' (default: temp)",
    )
    parser.add_argument(
        "--send-invite",
        action="store_true",
        help="If set, do NOT suppress Cognito emails during create (emails/SMS will be sent).",
    )
    args = parser.parse_args()

    APPSYNC_URL  = None
    AWS_REGION   = "us-east-2"
    USER_POOL_ID = None
    if args.pool == 'prod':
        APPSYNC_URL = MT_PROD_API_ENDPOINT
        USER_POOL_ID = PROD_POOL_ID
    elif args.pool == 'test':
        APPSYNC_URL = MT_TEST_API_ENDPOINT
        USER_POOL_ID = TEST_POOL_ID  
    elif args.pool == 'dev':
        APPSYNC_URL = MT_DEV_API_ENDPOINT
        USER_POOL_ID = DEV_POOL_ID 
    else:
        print('incorrect user pool')
        return             

    if not APPSYNC_URL:
        print("ERROR: Set APPSYNC_URL to your AppSync GraphQL endpoint.", file=sys.stderr)
        sys.exit(2)
    if not USER_POOL_ID:
        print("ERROR: Set USER_POOL_ID to your Cognito User Pool ID.", file=sys.stderr)
        sys.exit(2)

    # 1) Look up the company ID by name
    try:
        company_id = find_company_id_by_name(APPSYNC_URL, AWS_REGION, args.company_name)
        print(f"Found company '{args.company_name}' → id={company_id}")
    except Exception as e:
        print(f"ERROR looking up company: {e}", file=sys.stderr)
        sys.exit(1)

    # 2) Build attributes
    base_attrs = {}
    if args.role == "owner":
        base_attrs["custom:ownerId"] = company_id
    else:
        base_attrs["custom:customerId"] = company_id

    # 3) Create/update user & set password according to mode
    cognito = boto3.client("cognito-idp", region_name=AWS_REGION)
    suppress = not args.send_invite

    try:
        exists = user_exists(cognito, USER_POOL_ID, args.email)

        if args.mode == "temp":
            if exists:
                # Put user back into NEW_PASSWORD_REQUIRED with a temp password
                set_temp_password_for_existing_user(cognito, USER_POOL_ID, args.email, args.password)
                # Also make sure attributes are up to date
                cognito.admin_update_user_attributes(
                    UserPoolId=USER_POOL_ID,
                    Username=args.email,
                    UserAttributes=[{"Name": k, "Value": v} for k, v in base_attrs.items()],
                )
                print(f"✅ Updated existing user '{args.email}' with TEMP password (NEW_PASSWORD_REQUIRED).")
            else:
                # Create with a temp password (no email by default)
                create_user_with_temp_password(
                    cognito, USER_POOL_ID, args.email, args.password, base_attrs, suppress=suppress
                )
                print(f"✅ Created user '{args.email}' with TEMP password (NEW_PASSWORD_REQUIRED).")

        else:  # permanent
            if exists:
                set_permanent_password_for_existing_user(cognito, USER_POOL_ID, args.email, args.password)
                cognito.admin_update_user_attributes(
                    UserPoolId=USER_POOL_ID,
                    Username=args.email,
                    UserAttributes=[{"Name": k, "Value": v} for k, v in base_attrs.items()],
                )
                print(f"✅ Updated existing user '{args.email}' with PERMANENT password.")
            else:
                create_user_and_set_permanent_password(
                    cognito, USER_POOL_ID, args.email, args.password, base_attrs, suppress=suppress
                )
                print(f"✅ Created user '{args.email}' with PERMANENT password.")

        print("Attributes set:", base_attrs)

    except ClientError as e:
        print(f"ERROR creating/updating user: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()