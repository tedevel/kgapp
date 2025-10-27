#!/usr/bin/env python3
import os
import sys
import json
import argparse
import requests
import boto3
from requests_aws4auth import AWS4Auth


MT_PROD_API_ENDPOINT = 'https://ithlpd4m7vcfnigzgyiawcwwha.appsync-api.us-east-2.amazonaws.com/graphql'
MT_TEST_API_ENDPOINT = 'https://qjgx43kzwjh5hmlmou244agwbe.appsync-api.us-east-2.amazonaws.com/graphql'
MT_DEV_API_ENDPOINT = 'https://tchze4msqffazhw25donxs6dai.appsync-api.us-east-2.amazonaws.com/graphql'
CHOSEN_API_ENDPOINT = MT_DEV_API_ENDPOINT  # used to query Companies


def get_aws_auth(region: str, service: str = "appsync") -> AWS4Auth:
    session = boto3.Session()
    creds = session.get_credentials()
    if creds is None:
        print("ERROR: No AWS credentials found in your environment/profile.", file=sys.stderr)
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

def main():
    parser = argparse.ArgumentParser(description="Create a Company (IAM-signed AppSync).")
    parser.add_argument("name", help="Company name")
    parser.add_argument("domain", help="Company email domain (e.g., example.com)")
    parser.add_argument("contact_email", help="Primary contact email")
    parser.add_argument("pool", choices=["dev", "test", "prod"], help="User Pool")    
    args = parser.parse_args()

    APPSYNC_URL  = None
    if args.pool == 'prod':
        APPSYNC_URL = MT_PROD_API_ENDPOINT
    elif args.pool == 'test':
        APPSYNC_URL = MT_TEST_API_ENDPOINT
    elif args.pool == 'dev':
        APPSYNC_URL = MT_DEV_API_ENDPOINT
    else:
        print('incorrect user pool')
        return         
    AWS_REGION  = "us-east-2"

    if not APPSYNC_URL:
        print("ERROR: Set APPSYNC_URL env var to your AppSync GraphQL endpoint.", file=sys.stderr)
        sys.exit(2)

    aws_auth = get_aws_auth(AWS_REGION)

    mutation = """
    mutation CreateCompany($input: CreateCompanyInput!) {
      createCompany(input: $input) {
        id
        name
        domain
        contactEmail
      }
    }
    """
    variables = {
        "input": {
            "name": args.name,
            "domain": args.domain,
            "contactEmail": args.contact_email
        }
    }

    try:
        data = appsync_post(APPSYNC_URL, aws_auth, mutation, variables)
        company = data["data"]["createCompany"]
        print("✅ Company created:")
        print(json.dumps(company, indent=2))
    except Exception as e:
        print(f"ERROR creating company: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()