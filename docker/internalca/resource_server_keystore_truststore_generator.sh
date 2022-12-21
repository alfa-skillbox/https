#!/usr/bin/env bash
set -ex

###########################
#- VARS
###########################
#--- Domain name
DN=localhost
###########################
#--- INTERNAL ROOT CA VARS
###########################
ROOT=rootCA
ROOT_PATH=./$ROOT
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
# TODO Для успешной работы замените текущий путь на путь к cacerts в своем jdk
#CACERTS_PATH=~/.sdkman/candidates/java/current/lib/security/cacerts
###########################
#--- DOCKER IMPORT VARS
###########################
PATH_TO_COPY=../imports/$SERVER

mkdir -p $SERVER_PATH
mkdir -p $PATH_TO_COPY

#--------------------------------------Resource-server (as SSL-SERVER) KeyStore---------------------------------------#
# 1 Генерим для Resource-server ключи SSL сервера
#    ->
#       2 .csr (создаем запрос на подписание сертификата в CA)
#          ->
#             3 Имитируем подпись сертификата в CA, получаем обратно .pem сертификат
#                ->
#                   4 CA .pem + server .pem = chain .pem
#                      ->
#                         5 Импортим в keystore с шага 1 chain .pem сертификат

# 1.####################################
# Генерим keystore с приватным ключом и самоподписанным сертификатом в алиасе внутри
# Input: инфо для keystore
# Command: genkeypair
# Output: .jks keystore файл с приватным ключом и самоподписанным сертификатом в алиасе внутри
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

# Пример генерации приватного ключа через OpenSSL
#openssl genpkey -out $SERVER_PATH/$SERVER.pkcs8.key -outform PEM -algorithm RSA

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

# -ext {name{:critical} {=value}}
#BC or BasicConstraints
#Values: The full form is: ca:{true|false}[,pathlen:<len>] or <len>, which is short for ca:true,pathlen:<len>. When <len> is omitted, you have ca:true.
#
#KU or KeyUsage
#Values: usage(,usage)*, where usage can be one of digitalSignature, nonRepudiation (contentCommitment), keyEncipherment, dataEncipherment, keyAgreement, keyCertSign, cRLSign, encipherOnly, decipherOnly. The usage argument can be abbreviated with the first few letters (dig for digitalSignature) or in camel-case style (dS for digitalSignature or cRLS for cRLSign), as long as no ambiguity is found. The usage values are case-sensitive.
#
#EKU or ExtendedKeyUsage
#Values: usage(,usage)*, where usage can be one of anyExtendedKeyUsage, serverAuth, clientAuth, codeSigning, emailProtection, timeStamping, OCSPSigning, or any OID string. The usage argument can be abbreviated with the first few letters or in camel-case style, as long as no ambiguity is found. The usage values are case-sensitive.
#
#SAN or SubjectAlternativeName
#Values: type:value(,type:value)*, where type can be EMAIL, URI, DNS, IP, or OID. The value argument is the string format value for the type.
########################################
keytool -v -keystore $ROOT_PATH/rootCA.jks \
        -storepass $ROOT_PASSWORD \
        -alias $ROOT_KEYSTORE_ALIAS \
        -infile $SERVER_PATH/$SERVER.csr \
        -ext ku:c=dig,kE,dE -ext san=dns:$DN -ext EKU=serverAuth,clientAuth \
        -gencert \
        -rfc -outfile $SERVER_PATH/$SERVER.temp.pem

# Пример через OPENSSL
# Шаг 1. Файл конфигурации .ext для использования в процессе подписания
# через subjectAltName задается DNS, доступ с которого будет разрешен

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

# Шаг 2. Имитируем работу с запросом .csr, т.е. подписываем сертификат в Root CA
#openssl x509 -req \
#    -in $SERVER_PATH/$SERVER.csr \
#    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
#    -passin pass:qwerty \
#    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
#    -CAcreateserial -CAserial $SERVER_PATH/$SERVER.srl \
#    -out $SERVER_PATH/$SERVER.crt \
#    -days 825 -sha256 \
#    -extfile $SERVER_PATH/$SERVER.ext

# 4.####################################
# Combine Root CA certificate with SSL-Server certificate
# WARN! Root cert should be on the first position
# Input: Root CA .pem file, ssl-server .pem file
# Command: cat
# Output: chained (combined) ssl-server .pem cert
# без этого шага получаем keytool error: java.lang.Exception: Failed to establish chain from reply
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
# 1 Создать truststore SSL-клиента, положить туда Root CA .pem сертификат
#             ->
#               2 (Optional) cacerts to .jks (копируем сеертификаты из cacerts)

# 1.####################################
# Создаем truststore файл .jks и импортим в него сертификат Root CA
# Input: Root CA .pem cert
# Command: import (or importcert)
# Output: новый файл truststore формата JKS с сертификатом Root CA
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
#keytool -srckeystore $CACERTS_PATH \
#        -srcstorepass changeit \
#        -destkeystore $SERVER_PATH/$SERVER.truststore.jks \
#        -deststorepass $SERVER_TRUSTSTORE_PASSWORD \
#        -deststoretype JKS \
#        -importkeystore

########################################
# Checks certs inside SSL-client trustStore .jks
########################################
keytool -list -v -keystore $SERVER_PATH/$SERVER.truststore.jks -alias $SERVER_TRUSTSTORE_ALIAS -storepass $SERVER_TRUSTSTORE_PASSWORD

########################################
# Copies result to docker import
########################################
cp $SERVER_PATH/$SERVER.truststore.jks $PATH_TO_COPY/truststore.jks
cp $SERVER_PATH/$SERVER.keystore.jks $PATH_TO_COPY/keystore.jks