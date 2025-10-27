Multi-Tenant Primer (Amplify Gen 2 + Cognito + AppSync)

⸻

1) Core Idea
	•	Each record (e.g., Tag, TagEvent) stores tenant keys on the item.
	•	A Cognito ID token carries custom claims that mirror those tenant keys.
	•	AppSync auth rules compare “item key == user claim” so each tenant only sees its own data.

⸻

2) User Identity (Custom Claims / Attributes)

We use Cognito custom user attributes that appear as ID token claims:
	•	custom:ownerId – company that owns the asset
	•	custom:customerId – company that currently uses/has access to the asset

Make sure the User Pool Client ReadAttributes include custom:ownerId and custom:customerId, so the claims are present in the ID token.

⸻

3) Data Model (Examples)

Company

Company: a.model({
  id: a.id().required(),
  name: a.string().required(),
  domain: a.string(),
  contactEmail: a.string(),
})
.secondaryIndexes(ix => [
  ix('domain').sortKeys(['id']).name('CompanyByDomain'),
])
.authorization(allow => [
  allow.group('PlatformAdmin').to(['create','read','update','delete'])
])

Tag (owner + customer)

Tag: a.model({
  owner_id: a.id().required(),     // checked against custom:ownerId
  customer_id: a.id().required(),  // checked against custom:customerId
  id: a.id().required(),           // primary key
  // ... other fields ...
})
.identifier(['id'])
.secondaryIndexes(ix => [
  ix('owner_id').sortKeys(['last_conn_dt']),
  ix('owner_id').sortKeys(['asset_id']),
])
.authorization(allow => [
  allow.ownerDefinedIn('owner_id').identityClaim('custom:ownerId'),
  allow.ownerDefinedIn('customer_id').identityClaim('custom:customerId'),
  allow.group('Admin').to(['create','read','update','delete']),
])

TagEvent (Time-Bounded Visibility)

When writing an event, copy both owner_id and the current customer_id (customer_id is optional):

TagEvent: a.model({
  owner_id: a.id().required(),
  customer_id: a.id().required(),
  tag_id: a.id().required(),
  event_dt: a.datetime().required(),
  // ... other fields ...
})
.identifier(['tag_id','event_dt'])
.secondaryIndexes(ix => [
  ix('owner_id').sortKeys(['event_dt']),
  ix('customer_id').sortKeys(['event_dt']),
])
.authorization(allow => [
  allow.ownerDefinedIn('owner_id').identityClaim('custom:ownerId'),
  allow.ownerDefinedIn('customer_id').identityClaim('custom:customerId'),
  allow.group('Admin').to(['create','read','update','delete']),
])

Why this works:
If customer_id changes from FOOBAR → ACME today, future events carry ACME and FOOBAR no longer sees new events, but still sees historical events written while they were the customer.

⸻

4) Pre-Token Lambda

The pre-token lambda reads the user attributes (ownerId, customerId; a user will typically have just one) and injects those claims into the returned JWT on sign in.

⸻

5) Frontend (Flutter) – Calling GraphQL

Configure Amplify
	•	amplify_outputs.dart should have:
	•	default_authorization_type: AMAZON_COGNITO_USER_POOLS
	•	authorization_types includes AWS_IAM (for backend/Lambdas if needed)

Always Query with User Pools - manually inject the idToken into the 'Authorization' header

    // Grab a fresh ID token (so AppSync gets the latest claims)
    final sess = await Amplify.Auth.fetchAuthSession();
    final idToken =
        (sess as CognitoAuthSession).userPoolTokensResult.value.idToken.raw;

    do {
      final variables = {
        if (nextToken != null) 'nextToken': nextToken,
      };

      final request = GraphQLRequest<String>(
        document: document,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
        // Force user-pool auth at the wire level:
        headers: {
          'Authorization': idToken,
        },
      );

Verify Token Claims (Debug)

Decode the ID token and confirm claims:


final session = await Amplify.Auth.fetchAuthSession();
final idToken = (session as CognitoAuthSession).userPoolTokensResult.value.idToken;
debugPrint('ID token chars: ${idToken.raw.length}');
debugPrint('ownerId claim: ${idToken.claims["custom:ownerId"]}');



⸻

6) Backend vs App Auth Modes
	•	Flutter app: uses User Pools (ID token has custom:* claims -> auth rules pass).
	•	Lambdas / scripts: usually use IAM (SigV4) to call AppSync. Grant read/write with IAM rules or admin group rules as appropriate.

⸻

7) Provisioning Workflow

① Create a Company
	•	Use IAM-signed AppSync mutation (Python script) with name, domain, contactEmail.
	•	Save returned Company.id (not necessary - company name/id lookup occurs in user creation)

② Create a User
	•	Admin-create the Cognito user (temporary password or send invite).
	•	Set custom:ownerId and/or custom:customerId to the Company.id (UUID), not the name.

Cognito console may not clearly display custom attributes; use the CLI (/scripts) to verify.

⸻

9) Available Scripts
	•	setup_new_company.py – creates Company via AppSync (IAM-signed). 
`python python/setup_new_company.py QP qptag.com kevin@qptag.com`
	•	setup_new_user.py – creates Cognito user (temporary password or invite), then sets custom:ownerId / custom:customerId by looking up Company.id from Company.name.
`python python/setup_new_user.py "kevin@qptag.com" 'Password!1' "QP" owner`

⸻

10) Owner/Customer Access Pattern (Summary)
	•	A record is visible if any rule matches.
	•	Tag: visible if custom:ownerId == tag.owner_id OR custom:customerId == tag.customer_id.
	•	TagEvent: visibility is point-in-time (uses customer_id at write time).
Changing customer_id affects future events only; historical events remain visible to the previous customer for auditability.

⸻
