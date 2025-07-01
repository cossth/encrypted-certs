# Certificate Management

This directory provides a secure workflow for storing and managing sensitive certificate files in your Git repository. All certificate files are encrypted before being committed, ensuring that secrets are not exposed.

## Features

- Encrypts certificate files (`.crt`, `.key`, `.csr`, `.srl`, etc.) using AES-256-CBC.
- Decrypts files on demand for local use.
- Uses a password from the `CERT_PASS` environment variable.
- Supports loading environment variables from a `.env` file.
- Example `.sample.env` provided.

## Usage

### 1. Prepare your environment

Copy the sample environment file and set your password:
```sh
cp .sample.env .env
# Edit .env and set CERT_PASS to a strong password
```

### 2. Generate certificates (example)

```sh
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -subj "/CN=example.com" -days 365 -out ca.crt
openssl genrsa -out client.key 2048
openssl req -new -key client.key -subj "/CN=client.example.com" -out client.csr
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.crt
```

### 3. Encrypt all certificate files

```sh
CERT_PASS=your-password ./cert-crypto.sh encrypt
```

### 4. Decrypt files when needed

```sh
CERT_PASS=your-password ./cert-crypto.sh decrypt
```

> **Note:** Never commit unencrypted certificate files. The `.gitignore` is configured to only allow encrypted (`*.enc`) files.

## Security Notes

- Always use a strong, unique password for `CERT_PASS`.
- Do **not** commit your `.env` file or any unencrypted certificate files.
- Share the password securely with trusted team members only.

## File Reference

- `.gitignore` – Ensures only encrypted files are tracked.
- `.gitattributes` – Optional: configure custom diff/filter for encrypted files.
- `cert-crypto.sh` – Script to encrypt/decrypt certificate files.
- `.sample.env` – Example environment file for setting `CERT_PASS`.

---
**Keep your secrets safe!**