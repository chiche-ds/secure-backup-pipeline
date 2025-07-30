# Secure Backup Pipeline – Project Overview

The Secure Backup Pipeline is an automated, policy-driven system for secure file backup and replication.  
It performs the following tasks:

1. Monitors directories for new files
2. Performs duplicate detection
3. Classifies files (sensitive, personal, general)
4. Applies security policies (Policy Gate 1 & 2)
5. Scans files for viruses and quarantines threats
6. Compresses and encrypts files
7. Uploads to AWS S3 securely
8. Generates logs and metrics for monitoring

**Use Case:**  
This pipeline is designed for organizations that require **real-time secure backups**, **compliance enforcement**, and **audit-ready logging**.
