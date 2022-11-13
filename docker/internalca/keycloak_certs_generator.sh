#!/usr/bin/env bash
set -ex

######################
# VARS
######################
# Use your own domain name
NAME=localhost
######################
KEYCLOAK=$NAME.keycloak
KEYCLOAK_PATH=./keycloak
KEYCLOAK_IMPORT_PATH=../imports/$KEYCLOAK
ROOT_PATH=./root
ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem

# Generate a server private key
openssl genrsa -out $KEYCLOAK_PATH/$KEYCLOAK.key.pem 2048

# Create a certificate-signing request
openssl req -new -key $KEYCLOAK_PATH/$KEYCLOAK.key.pem -out $KEYCLOAK_PATH/$KEYCLOAK.csr \
        -subj "/CN=localhost"

# Create a config file for the extensions
>$KEYCLOAK_PATH/$KEYCLOAK.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth,clientAuth
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
# DNS.2 = $KEYCLOAK.$NAME # Optionally, add additional domains (I've added a subdomain here)
IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
EOF

# Create the signed server certificate
openssl x509 -req \
    -in $KEYCLOAK_PATH/$KEYCLOAK.csr \
    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
    -passin pass:qwerty \
    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
    -CAcreateserial -CAserial $KEYCLOAK_PATH/$KEYCLOAK.srl\
    -out $KEYCLOAK_PATH/$KEYCLOAK.crt \
    -days 825 -sha256 \
    -extfile $KEYCLOAK_PATH/$KEYCLOAK.ext

# copy to keycloak imports directory
cp $KEYCLOAK_PATH/$KEYCLOAK.key.pem $KEYCLOAK_IMPORT_PATH
cp $KEYCLOAK_PATH/$KEYCLOAK.crt $KEYCLOAK_IMPORT_PATH

# change modification to key and crt keycloak files
chmod 655 $KEYCLOAK_IMPORT_PATH/$KEYCLOAK.key.pem
chmod 655 $KEYCLOAK_IMPORT_PATH/$KEYCLOAK.crt