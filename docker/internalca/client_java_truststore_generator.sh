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
CLIENT=$NAME.client
CLIENT_PATH=./client-java
######################
# Passwords
######################
P12_PASSWORD=qwerty
JKS_PASSWORD=asdfgh
#
## Generate a server private key
#openssl genrsa -out $CLIENT_PATH/$CLIENT.key.pem 2048
#
## Create a certificate-signing request
#openssl req -new -key $CLIENT_PATH/$CLIENT.key.pem -out $CLIENT_PATH/$CLIENT.csr \
#        -subj "/CN=localhost"
#
## Create a config file for the extensions
#>$CLIENT_PATH/$CLIENT.ext cat <<-EOF
#authorityKeyIdentifier=keyid,issuer
#basicConstraints=CA:FALSE
#extendedKeyUsage=serverAuth,clientAuth
#keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
#subjectAltName = @alt_names
#
#[alt_names]
#DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
## DNS.2 = $CLIENT.$NAME # Optionally, add additional domains (Ive added a subdomain here)
#IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
#EOF
#
## CA creates the signed server certificate: out $CLIENT_PATH/$CLIENT.crt
#openssl x509 -req \
#    -in $CLIENT_PATH/$CLIENT.csr \
#    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
#    -passin pass:qwerty \
#    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
#    -CAcreateserial -CAserial $CLIENT_PATH/$CLIENT.srl\
#    -out $CLIENT_PATH/$CLIENT.crt \
#    -days 825 -sha256 \
#    -extfile $CLIENT_PATH/$CLIENT.ext
#
##Converting to pkcs12
#openssl pkcs12 -info \
#       -inkey $CLIENT_PATH/$CLIENT.key.pem \
#       -in $CLIENT_PATH/$CLIENT.crt \
#       -passin pass:qwerty \
#       -export -out $CLIENT_PATH/$CLIENT.p12 \
#       -passout pass:qwerty \
#       -name https-client
#
## Generating keyStore for connection with browser as a server
#keytool -importkeystore \
#       -srckeystore $CLIENT_PATH/$CLIENT.p12 \
#       -srcstorepass $P12_PASSWORD \
#       -srcstoretype pkcs12 \
#       -srcalias https-client \
#       -destkeystore $CLIENT_PATH/$CLIENT.jks \
#       -deststoretype jks \
#       -deststorepass $JKS_PASSWORD \
#       -destalias https-client
#
## Appending root CA cert to the keyStore which makes trustStore from our keyStore
## to interact with https-servers as a client
#keytool -import -keystore $CLIENT_PATH/$CLIENT.jks \
#        -srcstorepass $JKS_PASSWORD \
#        -trustcacerts -alias rootca -file $ROOT_PATH/$ROOT_CERT_PEM_NAME
#
#keytool -list -v -keystore $CLIENT_PATH/$CLIENT.jks \
#        -storepass pass:$JKS_PASSWORD \
#        -alias https-client
#
#keytool -list -v -keystore $CLIENT_PATH/$CLIENT.jks \
#        -storepass pass:$JKS_PASSWORD \
#        -alias rootca

keytool -import -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
        -keystore $CLIENT_PATH/$CLIENT.truststore.jks \
        -alias rootca \
        -storepass pass:$JKS_PASSWORD \
        -storetype jks