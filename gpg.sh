#!/bin/bash

gpg --batch --gen-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 2048
Subkey-Type: 1
Subkey-Length: 2048
Name-Real: terraform
Expire-Date: 0
EOF

gpg --output key --export terraform
