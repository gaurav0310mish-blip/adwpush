#!/bin/bash
set -euo pipefail

echo "==== Creating OCI config ===="
mkdir -p ~/.oci

# Decode the private key
echo "$OCI_PRIVATE_KEY_BASE64" | base64 -d > ~/.oci/oci_api_key.pem
chmod 600 ~/.oci/oci_api_key.pem

# Create OCI config file
cat > ~/.oci/config <<EOF
[DEFAULT]
user=${OCI_USER_OCID}
fingerprint=${OCI_FINGERPRINT}
tenancy=${OCI_TENANCY_OCID}
region=${OCI_REGION}
key_file=/home/runner/.oci/oci_api_key.pem
EOF

chmod 600 ~/.oci/config

echo "==== Testing OCI connection ===="
oci os ns get >/dev/null
echo "Connected to OCI successfully."

echo "==== Downloading ADW wallet ===="
oci db autonomous-database generate-wallet \
  --autonomous-database-id "${ADW_DB_OCID}" \
  --password "${ADW_WALLET_PASSWORD}" \
  --file wallet.zip

echo "==== Extracting wallet ===="
rm -rf wallet
unzip -o wallet.zip -d wallet
export TNS_ADMIN="$(pwd)/wallet"

echo "==== Installing SQLcl ===="
curl -L https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip -o sqlcl.zip
unzip -o sqlcl.zip -d sqlcl
export PATH="$(pwd)/sqlcl/sqlcl/bin:$PATH"

echo "==== Running SQL script ===="
sql -s "${ADW_USER}/${ADW_PASSWORD}@${ADW_TNS}" @"sql/run_script.sql"

echo "==== ADW SQL execution complete ===="
