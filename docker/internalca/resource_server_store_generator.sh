#!/usr/bin/env bash
set -ex

###########################
#- VARS
###########################
#--- Domain name
DN=host.docker.internal
###########################
#--- INTERNAL ROOT CA VARS
###########################
ROOT=rootCA
ROOT_PATH=./root
ROOT_PASSWORD=$ROOT-password
ROOT_KEYSTORE_ALIAS=root-ca
ROOT_CERT_PEM_NAME=$ROOT.cert.pem
###########################
#--- RESOURCE SERVER VARS
###########################
SERVER=resource-server
SERVER_PATH=./$SERVER
SERVER_KEYSTORE_ALIAS=$SERVER-local
SERVER_TRUSTSTORE_ALIAS=$SERVER-internal-ca-root
SERVER_KEY_PASSWORD=$SERVER-password
SERVER_KEYSTORE_PASSWORD=$SERVER-password
SERVER_TRUSTSTORE_PASSWORD=$SERVER-password
###########################
#--- YOUR JDK'S CACERTS VARS
###########################
CACERTS_PATH=~/.sdkman/candidates/java/current/lib/security/cacerts
###########################
#--- DOCKER IMPORT VARS
###########################
PATH_TO_COPY=../imports/$SERVER

#--------------------------------------Resource-server (as SSL-SERVER) KeyStore---------------------------------------#
# 1 keypair .jks (генерим ключи SSL сервера)
#             ->
#               2 .csr (создаем запрос на получение с)
#                     ->
#                       3 server .pem certificate (signed by CA)
#                                                               ->
#                                                                 4 CA .pem + server .pem = chain .pem
#                                                                                         ->
#                                                                                           5 Update keypair jks with chain .pem

# 1.####################################
# Generate keypair (private + public keys)
# Input: keystore info
# Command: genkeypair
# Output: .jks file with keypair
########################################
keytool -v -keystore $SERVER_PATH/$SERVER.keystore.jks \
        -storepass $SERVER_KEYSTORE_PASSWORD \
        -keypass $SERVER_KEY_PASSWORD \
        -alias $SERVER_KEYSTORE_ALIAS \
        -dname "CN=$SERVER" \
        -keysize 2048 \
        -keyalg RSA \
        -validity 825 \
        -genkeypair

# The same with OPENSSL example
#openssl genrsa -out $SERVER_PATH/$SERVER.key.pem 2048

# 2.####################################
# Generate a certificate-signing request
# Input: keypair keystore and alias
# Command: certreq
# Output: .csr request file
########################################
keytool -v -keystore $SERVER_PATH/$SERVER.keystore.jks \
        -storepass $SERVER_KEYSTORE_PASSWORD \
        -alias $SERVER_KEYSTORE_ALIAS \
        -dname "CN=$SERVER" \
        -certreq \
        -file $SERVER_PATH/$SERVER.csr

# The same with OPENSSL example
#openssl req -new -key $SERVER_PATH/$SERVER.key.pem -out $SERVER_PATH/$SERVER.csr -subj "/CN=$SERVER"

# 3.####################################
# Sign certificate with Root CA
# Input: root ca keystore and his alias, .csr request,
#        extension params
# Command: gencert
# Output: PEM (with -rfc) or DER certificate file
########################################
keytool -v -keystore $ROOT_PATH/rootCA.jks \
        -storepass $ROOT_PASSWORD \
        -alias $ROOT_KEYSTORE_ALIAS \
        -infile $SERVER_PATH/$SERVER.csr \
        -ext ku:c=dig,kE,dE -ext san=dns:$DN -ext EKU=serverAuth,clientAuth \
        -gencert \
        -rfc -outfile $SERVER_PATH/$SERVER.temp.pem

# The same with OPENSSL example
# Part 1. Create a .ext config file for using in signing process
#>$SERVER_PATH/$SERVER.ext cat <<-EOF
#authorityKeyIdentifier=keyid,issuer
#basicConstraints=CA:FALSE
#extendedKeyUsage=serverAuth,clientAuth
#keyUsage = digitalSignature, nonRepudiation, dataEncipherment
#subjectAltName = @alt_names
#
#[alt_names]
#DNS.1 = $DN # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
## DNS.2 = $SERVER.$DN # Optionally, add additional domains (I've added a subdomain here)
#IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
#EOF

# Part 2. Sign certificate with Root CA
#openssl x509 -req \
#    -in $SERVER_PATH/$SERVER.csr \
#    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
#    -passin pass:qwerty \
#    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
#    -CAcreateserial -CAserial $SERVER_PATH/$SERVER.srl \
#    -out $SERVER_PATH/$SERVER.crt \
#    -days 825 -sha256 \
#    -extfile $SERVER_PATH/$SERVER.ext

# Part 3. Converting .crt -> .pem
#openssl x509 -in $SERVER_PATH/$SERVER.crt -out $SERVER_PATH/$SERVER.pem -outform PEM

# 4.####################################
# Combine Root CA certificate with SSL-Server certificate
# WARN! Root cert should be on the first position
# Input: Root CA .pem file, ssl-server .pem file
# Command: cat
# Output: chained (combined) ssl-server .pem cert
########################################
cat $ROOT_PATH/$ROOT_CERT_PEM_NAME $SERVER_PATH/$SERVER.temp.pem > $SERVER_PATH/$SERVER.pem

# 5.####################################
# Update keypair jks with chain .pem cert
# Input: keypair keystore and alias, chain .pem cert
# Command: importcert
# Output: ssl-server keyStore .jks updated with chain .pem cert
########################################
keytool -v -keystore $SERVER_PATH/$SERVER.keystore.jks -trustcacerts \
        -storepass $SERVER_KEYSTORE_PASSWORD \
        -alias $SERVER_KEYSTORE_ALIAS \
        -file $SERVER_PATH/$SERVER.pem \
        -importcert

########################################
#Prints to stdout the contents of the keystore entry identified by alias
########################################
keytool -list -v -keystore $SERVER_PATH/$SERVER.keystore.jks -alias $SERVER_KEYSTORE_ALIAS -storepass $SERVER_KEYSTORE_PASSWORD


#--------------------------------------Resource-server (as SSL-CLIENT) TrustStore-------------------------------------#
# 1 .jks + CA .pem (создать хранилище SSL клиента, положить туда CA .pem сертификат)
#             ->
#               2 (Optional) cacerts to .jks (копируем сеертификаты из cacerts)

# 1.####################################
# Creates server truststore .jks file and
# imports here CA .pem cert
# Input: CA .pem cert
# Command: import (or importcert)
# Output: new truststore .jks file with CA .pem cert
########################################
keytool -v -keystore $SERVER_PATH/$SERVER.truststore.jks \
        -storepass $SERVER_TRUSTSTORE_PASSWORD \
        -alias $SERVER_TRUSTSTORE_ALIAS \
        -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
        -import -trustcacerts

# 2 Optional ###########################
# Imports jdk's public CA certs (from cacerts keystore) inside our truststore.jks
# The purpose is to get all public CA certs inside our truststore.jks
# Input: jdk's cacerts, SSL-client trustStore .jks
# Command: importkeystore
# Output: updated SSL-client trustStore .jks
########################################
keytool -srckeystore $CACERTS_PATH \
        -srcstorepass changeit \
        -destkeystore $SERVER_PATH/$SERVER.truststore.jks \
        -deststorepass $SERVER_TRUSTSTORE_PASSWORD \
        -deststoretype JKS \
        -importkeystore

########################################
# Checks certs inside SSL-client trustStore .jks
########################################
keytool -list -v -keystore $SERVER_PATH/$SERVER.truststore.jks -alias $SERVER_TRUSTSTORE_ALIAS -storepass $SERVER_TRUSTSTORE_PASSWORD

########################################
# Copies result to docker import
########################################
cp $SERVER_PATH/$SERVER.truststore.jks $PATH_TO_COPY/truststore.jks
cp $SERVER_PATH/$SERVER.keystore.jks $PATH_TO_COPY/keystore.jks