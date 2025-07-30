# Pipeline Workflow

The **Secure Backup Pipeline** is designed to automate secure file backup and cloud replication while enforcing security policies and compliance.

---

## 1. Workflow Overview

1. **File Detection**  
   - The pipeline monitors a directory (`/data/to-backup`) using a watcher script.
   - Any new or modified file is automatically queued for processing.

2. **Duplicate Check**  
   - Files are hashed using SHA-256.
   - If a file’s hash already exists in `hashes.json`, it is **skipped** to prevent redundant uploads.

3. **File Classification**  
   - Files are classified into:
     - **Sensitive** (contains keywords like `confidential`, `password`, `client data`)
     - **Personal** (contains personal or identifiable data)
     - **General** (no sensitive content)
   
4. **Policy Gate 1**  
   - Ensures that the file meets pre-processing rules before scanning:
     - Correct file type
     - Within allowed size limits
     - Not blacklisted

5. **Virus Scan & Quarantine**  
   - File is scanned using **ClamAV or clamdscan**.
   - Infected files are moved to `logs/quarantine/` and skipped.

6. **Compression & Encryption**  
   - Clean files are compressed (e.g., `.zst`) and then encrypted using GPG symmetric encryption.
   - Ensures files are safe and immutable before upload.

7. **Policy Gate 2**  
   - Ensures the file is:
     - Compressed and encrypted
     - Stored in an authorized location
   - Files failing this check are skipped.

8. **Upload to S3**  
   - Final encrypted file is uploaded to the configured AWS S3 bucket.
   - Upload logs are generated for auditing.

9. **Logging & Dashboard**  
   - Every step is logged to `logs/backup_pipeline.log`.
   - Optional monitoring with **Prometheus + Grafana** provides:
     - Files processed (success, skipped, failed)
     - CPU and memory usage
     - Average processing time

---

## 2. Workflow Diagram

```mermaid
flowchart LR
    A[File Detected] --> B[Duplicate Check]
    B --> C[File Classification]
    C --> D[Policy Gate 1]
    D -->|Pass| E[Virus Scan]
    D -->|Fail| H[Skip/Quarantine]
    E -->|Clean| F[Compress & Encrypt]
    E -->|Infected| H
    F --> G[Policy Gate 2]
    G -->|Pass| I[S3 Upload & Logs]
    G -->|Fail| H
