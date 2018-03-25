#!/usr/bin/env bash

mkdir -p nginx/ssl
rm -rf ./nginx/ssl/*

SUBJECT="/C=RU/ST=RND/L=Taganrog/O=Sportdiary=${URL_REACT_APP}"

# Generating ROOT pem files
openssl req -x509 -new -nodes -newkey rsa:2048 -keyout ./nginx/ssl/server_rootCA.key -sha256 -days 1024 -out ./nginx/ssl/server_rootCA.pem -subj "${SUBJECT}" 2> /dev/null

# Generating v3.ext file
cat <<EOF > ./nginx/ssl/v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${URL_FRONTEND}
DNS.2 = ${URL_NODE}
DNS.3 = www.${URL_FRONTEND}
DNS.4 = www.${URL_NODE}
EOF
echo " - Generating SSL key file"
openssl req -new -newkey rsa:2048 -sha256 -nodes -newkey rsa:2048 -keyout ./nginx/ssl/ssl.key -subj "${SUBJECT}" -out ./nginx/ssl/server_rootCA.csr 2> /dev/null

echo " - Generating SSL certificate file"
openssl x509 -req -in ./nginx/ssl/server_rootCA.csr -CA ./nginx/ssl/server_rootCA.pem -CAkey ./nginx/ssl/server_rootCA.key -CAcreateserial -out ./nginx/ssl/ssl.cert -days 3650 -sha256 -extfile ./nginx/ssl/v3.ext 2> /dev/null

echo " - Adding certificate into local keychain"
sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ./nginx/ssl/server_rootCA.pem 2> /dev/null

echo " - Runing garbage collector"
rm -rf ./nginx/ssl/server_rootCA.csr ./nginx/ssl/server_rootCA.key ./nginx/ssl/server_rootCA.pem ./nginx/ssl/v3.ext ./.srl
