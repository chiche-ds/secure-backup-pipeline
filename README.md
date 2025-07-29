# Secure Backup & Replication Pipeline

### Project Overview
This project is the implementation of my **Master’s thesis**:  
**“Design and Implementation of a Secure, Policy-Aware Data Backup and Replication Solution to the Cloud.”**  

It provides an **open-source, automated backup system** that ensures **data security, compliance, and audit readiness** by integrating:

- **Real-time file monitoring**
- **Policy-as-code enforcement** using Open Policy Agent (OPA)
- **Malware scanning** and automatic quarantine
- **Data compression and AES-256 encryption**
- **Secure replication to AWS S3 with Object Lock**
- **Full observability with Prometheus, Loki, and Grafana**

This solution is designed for **SMEs and public institutions in Cameroon** to comply with  
**Cameroon Data Protection Law 2024/017**, especially Articles **17, 19, and 22**.

---

## Features
- 🔹 **Real-time detection** of new and modified files using `inotify`  
- 🔹 **Duplicate detection** using SHA-256 hash database  
- 🔹 **Policy Enforcement #1 (Pre-processing)**: Classifies files, checks size/type  
- 🔹 **Malware scanning with ClamAV** and **automatic quarantine** for infected files  
- 🔹 **Compression and AES-256 GPG encryption** for secure storage  
- 🔹 **Policy Enforcement #2 (Post-processing)**: Verifies encryption & destination authorization  
- 🔹 **Cloud replication to AWS S3** with Object Lock (immutability)  
- 🔹 **Audit-ready logging** with Prometheus + Loki  
- 🔹 **Visual dashboard** in Grafana showing:
  - Files processed
  - Files quarantined or rejected
  - Upload success/failure
  - End-to-end latency

---

## Pipeline Architecture

```text
[File Detected] 
    ↓
[Duplicate Check] → Duplicate → [Skip & Log]
    ↓
[Policy Check 1] → Denied → [Skip & Log]
    ↓
[Virus Scan] → Infected → [Quarantine & Log]
    ↓
[Compress + Encrypt]
    ↓
[Policy Check 2] → Denied → [Hold in Staging]
    ↓
[AWS S3 Upload + Object Lock]
    ↓
[Logs & Grafana Dashboard]
```

---

## Technology Stack
- **OS**: Ubuntu Server 22.04
- **Monitoring & Logging**: Prometheus, Loki, Grafana
- **File Monitoring**: `inotify-tools`
- **Security**: ClamAV, SHA-256 hashing, GPG AES-256 encryption
- **Policy Engine**: Open Policy Agent (OPA)
- **Cloud Storage**: AWS S3 (Object Lock enabled)
- **Automation**: Bash + Python scripts

---

## Folder Structure
```
secure-backup-pipeline/
├── README.md
├── docs/          # Documentation & diagrams
├── scripts/       # Bash & Python scripts for the backup pipeline
├── policies/      # OPA policy files (Pre & Post processing)
├── configs/       # Prometheus, Loki, and AWS configurations
├── dashboards/    # Grafana dashboards (JSON exports)
├── tests/         # Test scenarios & results
└── logs/          # Sample logs for demonstration
```

---

## Compliance Context
This project directly supports **Cameroon Data Protection Law 2024/017**, including:
- **Article 17**: Data confidentiality and protection
- **Article 19**: Secure retention and encryption
- **Article 22**: Breach logging and timely notification

---

## Getting Started
1. **Clone the Repository**
   ```bash
   git clone https://github.com/chiche-ds/secure-backup-pipeline.git
   cd secure-backup-pipeline
   ```
2. **Setup VM Environment**
   - Install Ubuntu Server 22.04
   - Install required packages (`git`, `inotify-tools`, `clamav`, `gpg`, `awscli`)
3. **Run File Detection**
   ```bash
   bash scripts/watch_and_queue.sh
   ```
4. **Process Files Through the Pipeline**
   - Duplicate check → Policy #1 → Virus scan → Compression/Encryption → Policy #2 → S3 Upload

---

## License
This project is licensed under the **MIT License**.
