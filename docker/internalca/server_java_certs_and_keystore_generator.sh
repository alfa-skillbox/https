#!/usr/bin/env bash
set -ex

######################
# VARS
######################
SERVER=resource.server
ROOT_PATH=./root
ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem
SERVER_PATH=./server-java
# Use your own domain name
NAME=localhost 

# Generate a server private key
openssl genrsa -out $SERVER_PATH/$NAME.$SERVER.key.pem 2048

#openssl req -x509 -new -nodes -key $NAME.$SERVER.key.pem -sha256 -days 825 -out $NAME.$SERVER.csr \
#        -subj "/C=RU/ST=Moscow/L=Moscow/O=Alfa/OU=Java/CN=localhost"

# Create a certificate-signing request
openssl req -new -key $SERVER_PATH/$NAME.$SERVER.key.pem -out $SERVER_PATH/$NAME.$SERVER.csr \
        -subj "/CN=localhost"

# Create a config file for the extensions
>$SERVER_PATH/$NAME.$SERVER.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth,clientAuth
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
# DNS.2 = bar.$NAME # Optionally, add additional domains (I've added a subdomain here)
IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
EOF

# Create the signed server certificate
openssl x509 -req \
    -in $SERVER_PATH/$NAME.$SERVER.csr \
    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
    -passin pass:qwerty \
    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
    -CAcreateserial -CAserial $SERVER_PATH/$NAME.$SERVER.srl\
    -out $SERVER_PATH/$NAME.$SERVER.crt \
    -days 825 -sha256 \
    -extfile $SERVER_PATH/$NAME.$SERVER.ext
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

############
#
# variant 2
# https://stackoverflow.com/a/52684817
############

# generate a self-signed cert using the keytool
#CN=localhost, OU=Java, O=Alfa, L=Unknown, ST=Msk, C=RU
#keytool -genkey -alias $NAME -keyalg RSA -keystore keycloak.jks -validity 825

# convert .jks to .p12

#keytool -importkeystore -srckeystore keycloak.jks -destkeystore keycloak.p12 -deststoretype PKCS12

# generate .crt from .p12 keystore

#openssl pkcs12 -in keycloak.p12 -nokeys -out $NAME.crt

# generate .key from .p12 keystore

#openssl pkcs12 -in keycloak.p12 -nocerts -nodes -out $NAME.key

#chmod 655 $NAME.key
#chmod 655 $NAME.crt