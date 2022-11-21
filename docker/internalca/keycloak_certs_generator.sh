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
KEYCLOAK=keycloak
KEYCLOAK_PATH=./keycloak
KEYCLOAK_KEY_PASSWORD=keycloak-password
KEYCLOAK_KEYSTORE_PASSWORD=keycloak-password
KEYCLOAK_KEYSTORE_ALIAS=keycloak-local
###########################
#--- DOCKER IMPORT VARS
###########################
PATH_TO_COPY=../imports/$KEYCLOAK



#--------------------------------------Keycloak (as SSL-SERVER) KeyStore---------------------------------------#
# TODO 1 keypair .jks (генерим ключи SSL сервера)
#             ->
#               2 .csr (создаем запрос на получение с)
#                     ->
#                       3 server .pem certificate (signed by CA)
#                                                               ->
#                                                                 4 CA .pem + server .pem = chain .pem
#                                                                                         ->
#                                                                                           5 Update keypair jks with chain .pem

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
        -importcert \

# 6.####################################
# Exports result .pem certificate signed by CA from SSL-server keystore
# Input: keystore and alias
# Command: exportcert
# Output: result chained .pem cert
########################################
#keytool -v -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
#        -storepass $KEYCLOAK_KEYSTORE_PASSWORD \
#        -alias $KEYCLOAK_KEYSTORE_ALIAS \
#        -exportcert \
#        -rfc -file $KEYCLOAK_PATH/$KEYCLOAK.crt.pem

# 7.####################################
# Converts keypair jks with chain .pem cert
# Input: keypair keystore and alias, chain .pem cert
# Command: importcert
# Output: ssl-server keyStore .jks updated with chain .pem cert
########################################
#openssl x509 -outform pem -in $KEYCLOAK_PATH/$KEYCLOAK.crt.pem -out $KEYCLOAK_PATH/$KEYCLOAK.crt

########################################
#Prints to stdout the contents of the keystore entry identified by alias
########################################
#keytool -list -v -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore -storepass $KEYCLOAK_KEYSTORE_PASSWORD -alias $KEYCLOAK_KEYSTORE_ALIAS

# 7.####################################
# Converts keypair .jks with chain .pem cert
# Input: keypair keystore and alias, chain .pem cert
# Command: importcert
# Output: ssl-server keyStore .jks updated with chain .pem cert
########################################
## step 1 - converting to pkcs12 using keytool
#keytool -importkeystore \
#      -srckeystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
#      -srcstorepass $KEYCLOAK_KEYSTORE_PASSWORD \
#      -destkeystore $KEYCLOAK_PATH/$KEYCLOAK.p12 \
#      -deststoretype PKCS12 \
#      -srcalias $KEYCLOAK_KEYSTORE_ALIAS \
#      -deststorepass $KEYCLOAK_KEYSTORE_PASSWORD \
#      -destkeypass $KEYCLOAK_KEY_PASSWORD

## step 2 - export private key using openssl
openssl pkcs12 -in $KEYCLOAK_PATH/$KEYCLOAK.p12 -noenc -nocerts -out $KEYCLOAK_PATH/$KEYCLOAK.key.pem -password pass:$KEYCLOAK_KEYSTORE_PASSWORD
openssl pkcs12 -in $KEYCLOAK_PATH/$KEYCLOAK.p12 -noenc -nokeys -out $KEYCLOAK_PATH/$KEYCLOAK.crt -password pass:$KEYCLOAK_KEYSTORE_PASSWORD

########################################
# Copies result to docker import
########################################
cp $KEYCLOAK_PATH/$KEYCLOAK.key.pem $PATH_TO_COPY
cp $KEYCLOAK_PATH/$KEYCLOAK.crt $PATH_TO_COPY
#cp $KEYCLOAK_PATH/$KEYCLOAK.p12.crt $PATH_TO_COPY

########################################
# Changes modification of copied files
########################################
chmod 655 $PATH_TO_COPY/$KEYCLOAK.key.pem
chmod 655 $PATH_TO_COPY/$KEYCLOAK.crt
#chmod 655 $PATH_TO_COPY/$KEYCLOAK.p12.crt