#!/usr/bin/env bash
set -ex

######################
# VARS
######################
# Use your own domain name
NAME=localhost
######################
ROOT_PATH=./root
ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem
SERVER=$NAME.resource.server
SERVER_PATH=./server-java

# Generate a server private key
openssl genrsa -out $SERVER_PATH/$SERVER.key.pem 2048

# Create a certificate-signing request
openssl req -new -key $SERVER_PATH/$SERVER.key.pem -out $SERVER_PATH/$SERVER.csr \
        -subj "/CN=localhost"

# Create a config file for the extensions
>$SERVER_PATH/$SERVER.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth,clientAuth
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
# DNS.2 = $SERVER.$NAME # Optionally, add additional domains (I've added a subdomain here)
IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
EOF

# Create the signed server certificate
openssl x509 -req \
    -in $SERVER_PATH/$SERVER.csr \
    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
    -passin pass:qwerty \
    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
    -CAcreateserial -CAserial $SERVER_PATH/$SERVER.srl\
    -out $SERVER_PATH/$SERVER.crt \
    -days 825 -sha256 \
    -extfile $SERVER_PATH/$SERVER.ext
#
#chmod 655 $NAME.key
#chmod 655 $NAME.crt
#
#openssl pkcs12 \
#       -inkey $NAME.key \
#       -in $NAME.crt \
#       -export -out $NAME.p12 \
#       -passout pass:qwerty
#
#keytool -importkeystore \
#       -srckeystore $NAME.p12 \
#       -srcstorepass qwerty \
#       -srcstoretype pkcs12 \
#       -destkeystore $NAME.jks \
#       -deststoretype jks \
#       -deststorepass qwerty