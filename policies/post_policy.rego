package backup.post_policy

# Deny if file is not encrypted
deny[msg] {
    not endswith(input.filename, ".gpg")
    msg := "File is not encrypted"
}

# Deny if uploading to wrong bucket
deny[msg] {
    input.destination != "s3://secure-backups"
    msg := "Unauthorized S3 destination"
}

# Allow if all checks pass
allow[msg] {
    not deny[_]
    msg := "File approved for upload"
}
