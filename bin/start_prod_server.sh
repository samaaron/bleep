#!/bin/bash
set -e # Quit script on error
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKING_DIR="$(pwd)"
cd "${SCRIPT_DIR}"../

## Uncomment and insert the correct values for cert-path, key-path and host name.

# sudo PHX_SERVER=true BLEEP_SECURE_SERVER=true BLEEP_SSL_CERT_PATH='cert-path' BLEEP_SSL_KEY_PATH='key-path' SECRET_KEY_BASE=`mix phx.gen.secret` PHX_HOST=example.com HTTPS_PORT=443 MIX_ENV=prod elixir -S mix phx.server

# Restore working directory as it was prior to this script running...
cd "${WORKING_DIR}"