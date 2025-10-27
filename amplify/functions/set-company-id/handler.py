# handler.py
import json

def handler(event, context):
    print("Pre Token Generation (no-DB):", json.dumps({"triggerSource": event.get("triggerSource")}))
    
    # Ensure response scaffolding exists
    event.setdefault("response", {})
    cod = event["response"].get("claimsOverrideDetails") or {}
    claims_to_add = dict(cod.get("claimsToAddOrOverride") or {})

    # Read user attributes safely
    user_attrs = (event.get("request") or {}).get("userAttributes") or {}
    owner_id = user_attrs.get("custom:ownerId")
    customer_id = user_attrs.get("custom:customerId")

    if owner_id:
        claims_to_add["custom:ownerId"] = owner_id
        print(f"Set token claim custom:ownerId = {owner_id}")
    else:
        print("User has no custom:ownerId; leaving claims unchanged")

    if customer_id:
        claims_to_add["custom:customerId"] = customer_id
        print(f"Set token claim custom:customerId = {customer_id}")
    else:
        print("User has no custom:customerId; leaving claims unchanged")        

    # Re-assemble override details while preserving any existing fields
    out = {"claimsToAddOrOverride": claims_to_add}
    if "claimsToSuppress" in cod:
        out["claimsToSuppress"] = cod["claimsToSuppress"]
    if "groupOverrideDetails" in cod:
        out["groupOverrideDetails"] = cod["groupOverrideDetails"]

    event["response"]["claimsOverrideDetails"] = out
    return event