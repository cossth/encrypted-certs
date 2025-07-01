#!/bin/bash

if [[ -z "${CERT_PASS:-}" && -f .env ]]; then
  echo "📦 Loading environment variables from .env"
  set -o allexport
  source .env
  set +o allexport
fi

set -euo pipefail

# Define supported file extensions
TARGET_EXTENSIONS=("crt" "csr" "key" "srl")

# Check password
if [[ -z "${CERT_PASS:-}" ]]; then
  echo "❌ ERROR: CERT_PASS environment variable is not set."
  exit 1
fi

encrypt_file() {
  local file="$1"
  local enc_file="${file}.enc"
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$file" -out "$enc_file" -pass env:CERT_PASS
  echo "🔒 Encrypted: $file -> $enc_file"
}

encrypt_files() {
  echo "🔐 Encrypting eligible files recursively (skipping already encrypted)..."
  for ext in "${TARGET_EXTENSIONS[@]}"; do
    find . -type f -name "*.${ext}" ! -name "*.enc" | while read -r file; do
      if [[ ! -f "${file}.enc" ]]; then
        encrypt_file "$file"
      fi
    done
  done
}

encrypt_files_all() {
  echo "🔐 Encrypting eligible files recursively (overwriting .enc files)..."
  for ext in "${TARGET_EXTENSIONS[@]}"; do
    find . -type f -name "*.${ext}" ! -name "*.enc" | while read -r file; do
      encrypt_file "$file"
    done
  done
}

decrypt_file() {
  local enc_file="$1"
  local original_file="${enc_file%.enc}"
  openssl enc -d -aes-256-cbc -pbkdf2 -in "$enc_file" -out "$original_file" -pass env:CERT_PASS
  echo "🔓 Decrypted: $enc_file -> $original_file"
}

decrypt_files() {
  echo "🔓 Decrypting .enc files recursively..."
  find . -type f -name "*.enc" | while read -r enc_file; do
    original_file="${enc_file%.enc}"
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$enc_file" -out "$original_file" -pass env:CERT_PASS
    echo "🔓 Decrypted: $enc_file -> $original_file"
  done
}

clean_files() {
  echo "🧹 Cleaning unencrypted certificate files recursively..."
  for ext in "${TARGET_EXTENSIONS[@]}"; do
    find . -type f -name "*.${ext}" ! -name "*.enc" | while read -r file; do
      if [[ -f "${file}.enc" ]]; then
        rm -v "$file"
      fi
    done
  done
}

case "${1:-}" in
  encrypt)
    if [[ "${2:-}" == "all" ]]; then
      encrypt_files_all
    elif [[ -n "${2:-}" ]]; then
      encrypt_file "$2"
    else
      encrypt_files
    fi
    ;;
  decrypt)
    if [[ -n "${2:-}" ]]; then
      decrypt_file "$2"
    else
      decrypt_files
    fi
    ;;
  clean)
    clean_files
    ;;
  *)
    echo "Usage: CERT_PASS=your-password $0 [encrypt|decrypt|clean] [file|all]"
    exit 1
    ;;
esac
