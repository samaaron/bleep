#!/bin/bash
set -e # Quit script on error
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKING_DIR="$(pwd)"
cd "${SCRIPT_DIR}"/../

## Insert the correct values for cert-path, key-path and host name:
MIX_ENV=prod mix assets.deploy
PHX_SERVER=true BLEEP_SECURE_SERVER=true HTTPS_PORT=443 BLEEP_SSL_CERT_PATH='cert-path' BLEEP_SSL_KEY_PATH='key-path' PHX_HOST=example.com MIX_ENV=prod SECRET_KEY_BASE=`mix phx.gen.secret` elixir --erl "-detached" -S mix phx.server

# Restore working directory as it was prior to this script running...
cd "${WORKING_DIR}"