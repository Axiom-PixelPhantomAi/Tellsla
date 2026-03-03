#!/usr/bin/env python3
"""
Generate App Store Connect API key JSON for fastlane
"""
import json
import base64
import os
import sys

def main():
    # Read environment variables
    issuer_id = os.environ.get("APP_STORE_CONNECT_ISSUER_ID")
    key_id = os.environ.get("APP_STORE_CONNECT_KEY_IDENTIFIER")
    key_b64 = os.environ.get("APP_STORE_CONNECT_PRIVATE_KEY")
    
    if not all([issuer_id, key_id, key_b64]):
        print("❌ Missing environment variables:")
        print(f"  APP_STORE_CONNECT_ISSUER_ID: {bool(issuer_id)}")
        print(f"  APP_STORE_CONNECT_KEY_IDENTIFIER: {bool(key_id)}")
        print(f"  APP_STORE_CONNECT_PRIVATE_KEY: {bool(key_b64)}")
        sys.exit(1)
    
    # Decode the private key
    try:
        private_key = base64.b64decode(key_b64).decode('utf-8')
    except Exception as e:
        print(f"❌ Failed to decode private key: {e}")
        sys.exit(1)
    
    # Create the API key JSON
    api_key = {
        "key_id": key_id,
        "issuer_id": issuer_id,
        "key": private_key,
        "in_house": False
    }
    
    # Write to fastlane directory
    os.makedirs("fastlane", exist_ok=True)
    output_path = "fastlane/app_store_connect_api_key.json"
    
    with open(output_path, 'w') as f:
        json.dump(api_key, f, indent=2)
    
    # Set restrictive permissions
    os.chmod(output_path, 0o600)
    
    print(f"✅ API key JSON created: {output_path}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
