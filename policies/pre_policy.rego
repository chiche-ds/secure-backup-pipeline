package backup.pre_policy

# Deny large files (>500MB)
deny[msg] {
    input.size_mb > 500
    msg := "File too large (>500MB)"
}

# Deny non-text or unsupported files
deny[msg] {
    not endswith(input.filename, ".txt")
    msg := "Unsupported file type (only .txt allowed for demo)"
}

# Allow if no deny triggered
allow[msg] {
    not deny[_]
    msg := "File passed pre-processing policy"
}
