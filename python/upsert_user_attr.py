#!/usr/bin/env python3
"""
set_user_company_attr.py

Set a Cognito user's company attribute (custom:ownerId or custom:customerId)
by looking up the company ID (from AppSync) by company name.

Usage:
  python set_user_company_attr.py <username> <attribute> <company_name>
  [--user-pool-id US-EAST-2_xxx] [--appsync-url https://.../graphql]
  [--region us-east-2] [--profile default]

Examples:
  python set_user_company_attr.py "user@example.com" ownerId "SBS"
  python set_user_company_attr.py "user@example.com" customer "QP" --profile myaws
"""

import argparse
import json
import sys
import requests
import boto3
from botocore.exceptions import ClientError
from requests_aws4auth import AWS4Auth

# ---------- Defaults (your requested hardcodes) ----------
APPSYNC_URL  = "https://ithlpd4m7vcfnigzgyiawcwwha.appsync-api.us-east-2.amazonaws.com/graphql"
AWS_REGION   = "us-east-2"
USER_POOL_ID = "us-east-2_aLqQR1UeF"


# ---------- Helpers ----------
def get_boto3_session(profile: str | None):
    return boto3.Session(profile_name=profile) if profile else boto3.Session()

def get_aws_auth(session: boto3.Session, region: str, service: str = "appsync") -> AWS4Auth:
    creds = session.get_credentials()
    if creds is None:
        print("ERROR: No AWS credentials found (env/profile).", file=sys.stderr)
        sys.exit(2)
    frozen = creds.get_frozen_credentials()
    return AWS4Auth(frozen.access_key, frozen.secret_key, region, service, session_token=frozen.token)

def appsync_post(url: str, aws_auth: AWS4Auth, query: str, variables: dict):
    headers = {"Content-Type": "application/json"}
    resp = requests.post(url, auth=aws_auth, json={"query": query, "variables": variables}, headers=headers)
    if resp.status_code != 200:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text}")
    data = resp.json()
    if "errors" in data and data["errors"]:
        raise RuntimeError(json.dumps(data["errors"], indent=2))
    return data

def find_company_id_by_name(appsync_url: str, aws_auth: AWS4Auth, name: str) -> str:
    """
    Try exact (case-sensitive) name match first.
    Fallback to case-insensitive match within first page (limit=1000).
    """
    q_exact = """
    query FindCompanyByName($name: String!) {
      listCompanies(filter: { name: { eq: $name } }) {
        items { id name }
      }
    }
    """
    data = appsync_post(appsync_url, aws_auth, q_exact, {"name": name})
    items = (data.get("data", {}).get("listCompanies", {}) or {}).get("items", []) or []
    if len(items) == 1:
        return items[0]["id"]
    if len(items) > 1:
        raise RuntimeError(f"Multiple companies found with exact name '{name}'. Resolve duplicates.")

    q_all = """
    query ListCompanies($limit: Int) {
      listCompanies(limit: $limit) {
        items { id name }
        nextToken
      }
    }
    """
    data2 = appsync_post(appsync_url, aws_auth, q_all, {"limit": 1000})
    items2 = (data2.get("data", {}).get("listCompanies", {}) or {}).get("items", []) or []
    matches = [c for c in items2 if c.get("name", "").strip().lower() == name.strip().lower()]
    if not matches:
        raise RuntimeError(f"No company found named '{name}'.")
    if len(matches) > 1:
        raise RuntimeError(f"Multiple companies (case-insensitive) named '{name}'. Resolve duplicates.")
    return matches[0]["id"]

def user_exists(cognito, user_pool_id: str, username: str) -> bool:
    try:
        cognito.admin_get_user(UserPoolId=user_pool_id, Username=username)
        return True
    except ClientError as e:
        if e.response.get("Error", {}).get("Code") == "UserNotFoundException":
            return False
        raise

def update_user_attribute(cognito, user_pool_id: str, username: str, attr_name: str, value: str):
    cognito.admin_update_user_attributes(
        UserPoolId=user_pool_id,
        Username=username,
        UserAttributes=[{"Name": attr_name, "Value": value}],
    )


# ---------- Main ----------
def main():
    p = argparse.ArgumentParser(description="Set Cognito user's owner/customer company attribute by company name.")
    p.add_argument("username", help="Cognito username (email)")
    p.add_argument("attribute", help="Which attribute to set: ownerId|owner or customerId|customer")
    p.add_argument("company_name", help="Company name (e.g., SBS, QP, NUTRIEN)")

    # Allow overrides, but default to your hardcoded values
    p.add_argument("--user-pool-id", default=USER_POOL_ID, help=f"Cognito User Pool ID (default: {USER_POOL_ID})")
    p.add_argument("--appsync-url",  default=APPSYNC_URL,  help="AppSync GraphQL endpoint URL (default: hardcoded)")
    p.add_argument("--region",       default=AWS_REGION,   help=f"AWS region (default: {AWS_REGION})")
    p.add_argument("--profile", default=None, help="AWS profile name (optional)")

    args = p.parse_args()

    # Normalize attribute input
    attr_in = args.attribute.strip().lower()
    if attr_in in ("owner", "ownerid"):
        cognito_attr = "custom:ownerId"
    elif attr_in in ("customer", "customerid"):
        cognito_attr = "custom:customerId"
    else:
        print("ERROR: attribute must be one of: ownerId, owner, customerId, customer", file=sys.stderr)
        sys.exit(2)

    # AWS sessions/clients
    session = get_boto3_session(args.profile)
    aws_auth = get_aws_auth(session, args.region)
    cognito = session.client("cognito-idp", region_name=args.region)

    # Ensure user exists
    if not user_exists(cognito, args.user_pool_id, args.username):
        print(f"ERROR: User '{args.username}' not found in pool {args.user_pool_id}.", file=sys.stderr)
        sys.exit(1)

    # Lookup companyId
    try:
        company_id = find_company_id_by_name(args.appsync_url, aws_auth, args.company_name)
        print(f"Company '{args.company_name}' → {company_id}")
    except Exception as e:
        print(f"ERROR looking up company: {e}", file=sys.stderr)
        sys.exit(1)

    # Update attribute
    try:
        update_user_attribute(cognito, args.user_pool_id, args.username, cognito_attr, company_id)
        print(f"✅ Updated {args.username}: {cognito_attr} = {company_id}")
    except ClientError as e:
        print(f"ERROR updating user attribute: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()