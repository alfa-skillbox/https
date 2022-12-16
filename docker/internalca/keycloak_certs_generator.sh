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
KEYCLOAK=keycloak
KEYCLOAK_PATH=./$KEYCLOAK
KEYCLOAK_KEY_PASSWORD=$KEYCLOAK-password
KEYCLOAK_KEYSTORE_PASSWORD=$KEYCLOAK-password
KEYCLOAK_KEYSTORE_ALIAS=$KEYCLOAK-local
###########################
#--- DOCKER IMPORT VARS
###########################
PATH_TO_COPY=../imports/$KEYCLOAK

mkdir -p $KEYCLOAK_PATH

#--------------------------------------Keycloak (as SSL-SERVER) KeyStore---------------------------------------#
# 1. Генерим для Keycloak ключи (в виде keystore) SSL сервера
#             ->
#               2 .csr (создаем запрос на подписание сертификата в CA)
#                     ->
#                       3 Имитируем подпись сертификата в CA, получаем обратно .pem сертификат
#                           ->
#                              4 CA .pem + keycloak .pem = chain .pem
#                                   ->
#                                      5 Импортим в keystore с шага 1 chain .pem сертификат
#                                          ->
#                                              6 С помощью OpenSSL pkcs12 удобно достаем ключ

# 1.####################################
# Generates keypair (private + public keys)
# Input: keystore info
# Command: genkeypair
# Output: keystore file with keypair
########################################
keytool -v -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
        -storepass $KEYCLOAK_KEYSTORE_PASSWORD \
        -alias $KEYCLOAK_KEYSTORE_ALIAS \
        -storetype PKCS12 \
        -dname "CN=$KEYCLOAK" \
        -keysize 2048 \
        -keyalg RSA \
        -keypass $KEYCLOAK_KEY_PASSWORD \
        -validity 825 \
        -genkeypair

# 2.####################################
# Generates a certificate-signing request
# Input: keypair keystore and alias
# Command: certreq
# Output: .csr request file
########################################
keytool -v -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
        -storepass $KEYCLOAK_KEYSTORE_PASSWORD \
        -alias $KEYCLOAK_KEYSTORE_ALIAS \
        -dname "CN=$KEYCLOAK" \
        -certreq \
        -file $KEYCLOAK_PATH/$KEYCLOAK.csr \

# 3.####################################
# Signs certificate with Root CA
# Input: root ca keystore and his alias, .csr request,
#        extension params
# Command: gencert
# Output: PEM (with -rfc) or DER certificate file
########################################
keytool -v -keystore $ROOT_PATH/$ROOT.jks \
        -storepass $ROOT_PASSWORD \
        -alias $ROOT_KEYSTORE_ALIAS \
        -infile $KEYCLOAK_PATH/$KEYCLOAK.csr \
        -ext ku:c=dig,kE,dE -ext san=dns:$DN -ext EKU=serverAuth,clientAuth \
        -gencert \
        -rfc -outfile $KEYCLOAK_PATH/$KEYCLOAK.temp.pem

# 4.####################################
# Combines Root CA certificate with SSL-Server certificate
# WARN! Root cert should be on the first position
# Input: Root CA .pem file, ssl-server .pem file
# Command: cat
# Output: chained (combined) ssl-server .pem cert
########################################
cat $ROOT_PATH/$ROOT_CERT_PEM_NAME $KEYCLOAK_PATH/$KEYCLOAK.temp.pem > $KEYCLOAK_PATH/$KEYCLOAK.pem

# 5.####################################
# Updates keypair keystore with chained .pem cert
# Input: keypair keystore and alias, chained .pem cert
# Command: importcert
# Output: ssl-server keyStore .jks updated with chained .pem cert
########################################
keytool -v -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore -trustcacerts \
        -storepass $KEYCLOAK_KEYSTORE_PASSWORD \
        -alias $KEYCLOAK_KEYSTORE_ALIAS \
        -file $KEYCLOAK_PATH/$KEYCLOAK.pem \
        -importcert

openssl pkcs12 -in $KEYCLOAK_PATH/$KEYCLOAK.keystore -noenc -nocerts -out $KEYCLOAK_PATH/$KEYCLOAK.key.pem -password pass:$KEYCLOAK_KEYSTORE_PASSWORD
openssl pkcs12 -in $KEYCLOAK_PATH/$KEYCLOAK.keystore -noenc -nokeys -out $KEYCLOAK_PATH/$KEYCLOAK.crt -password pass:$KEYCLOAK_KEYSTORE_PASSWORD

########################################
# Copies result to docker import
########################################
cp $KEYCLOAK_PATH/$KEYCLOAK.key.pem $PATH_TO_COPY
cp $KEYCLOAK_PATH/$KEYCLOAK.crt $PATH_TO_COPY

########################################
# Changes modification of copied files
########################################
chmod 655 $PATH_TO_COPY/$KEYCLOAK.key.pem
chmod 655 $PATH_TO_COPY/$KEYCLOAK.crt