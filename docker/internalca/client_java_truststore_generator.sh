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
ROOT_CERT_CRT_NAME=rootCA.cert.crt
CLIENT=$NAME.client
CLIENT_PATH=./client-java
PATH_TO_COPY=../../https-client/src/main/resources
######################
# Passwords
######################
TRUSTSTORE_PASSWORD=qwerty

#openssl x509 -in <(openssl s_client -showcerts -verify 2 -connect localhost:8443</dev/null) \
#openssl x509 -in <(openssl s_client -showcerts -verify 2 -connect localhost:8443 < /dev/null) \
#        -out $CLIENT_PATH/$CLIENT.crt
#
#openssl x509 -in $CLIENT_PATH/$CLIENT.crt -out $CLIENT_PATH/$CLIENT.pem -outform PEM

keytool -importcert -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
        -keystore $CLIENT_PATH/$CLIENT.truststore.jks \
        -alias internal_ca_root \
        -storepass $TRUSTSTORE_PASSWORD

#keytool -importcert \
#        -file $CLIENT_PATH/$CLIENT.pem \
#        -keystore $CLIENT_PATH/$CLIENT.truststore.jks \
#        -alias keycloak_local \
#        -storepass pass:qwerty \
#        -storetype jks

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
## Generating keyStore made for browser to connect a client (as a server for browser)
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
#
##keytool -import -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
##        -keystore $CLIENT_PATH/$CLIENT.truststore.jks \
##        -alias rootca \
##        -storepass pass:$JKS_PASSWORD \
##        -storetype jks
#
#keytool -importcert -v -noprompt -trustcacerts -file ./root/rootCA.cert.crt \
#        -keystore ./client-java/localhost.client.truststore.jks \
#        -alias rootca \
#        -storepass pass:qwerty \
#        -storetype jks
#
#keytool -importcert -alias root_keycloak_sub \
#        -file keycloak/localhost.keycloak.cer \
#        -keystore ./client-java/localhost.client.truststore.jks \
#        -storepass pass:qwerty \
#        -storetype jks
#
## из статьи https://habr.com/ru/company/dbtc/blog/487318/
#keytool -import -trustcacerts -alias caroot \
#        -file ./root/rootCA.cert.crt \
#        -keystore ./client-java/localhost.client.truststore.jks \
#        -storepass pass:qwerty \
#        -storetype jks
#
## check truststore entries (certificates)
#keytool -list -v -keystore ./client-java/localhost.client.truststore.jks -storepass pass:qwerty

cp $CLIENT_PATH/$CLIENT.truststore.jks $PATH_TO_COPY