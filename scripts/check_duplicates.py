#!/usr/bin/env python3
import hashlib, os, json, sys

HASH_DB = "/opt/secure-backup-pipeline/logs/hashes.json"
os.makedirs(os.path.dirname(HASH_DB), exist_ok=True)

# Load existing hashes
if os.path.exists(HASH_DB):
    with open(HASH_DB) as f:
        hash_db = json.load(f)
else:
    hash_db = {}

def sha256(file_path):
    h = hashlib.sha256()
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            h.update(chunk)
    return h.hexdigest()

file_path = sys.argv[1]
file_hash = sha256(file_path)

if file_hash in hash_db:
    print(f"DUPLICATE: {file_path}")
    sys.exit(1)
else:
    hash_db[file_hash] = file_path
    with open(HASH_DB, "w") as f:
        json.dump(hash_db, f)
    print(f"NEW FILE: {file_path}")
    sys.exit(0)
