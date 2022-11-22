#!/usr/bin/env bash
set -ex

###########################
#- VARS
###########################
#--- INTERNAL ROOT CA VARS
###########################
ROOT=rootCA
ROOT_PATH=./root
ROOT_KEYSTORE_PASSWORD=$ROOT-password
ROOT_KEYSTORE_ALIAS=root-ca
ROOT_CERT_PEM_NAME=$ROOT.cert.pem
###########################

# 1.####################################
# Generates the private key and self-signet root CA certificate
# Input: info for new .jks
# Command: genkeypair
# Output: new keystore .jks file with self-signet root CA certificate
########################################
keytool -keystore $ROOT_PATH/$ROOT.jks \
        -storepass $ROOT_KEYSTORE_PASSWORD \
        -dname "cn=RootCA, ou=LocalhostRootCA, o=LocalhostRootCA, c=IN" \
        -alias $ROOT_KEYSTORE_ALIAS \
        -ext bc:c \
        -keyalg RSA -validity 825 \
        -genkeypair -v

########################################
# Exports self-signet root CA .pem certificate
########################################
keytool -keystore $ROOT_PATH/$ROOT.jks \
        -storepass $ROOT_KEYSTORE_PASSWORD \
        -alias $ROOT_KEYSTORE_ALIAS \
        -exportcert \
        -rfc -file $ROOT_PATH/$ROOT_CERT_PEM_NAME

########################################
# Exports root CA private key
########################################
openssl pkcs12 -in $ROOT_PATH/$ROOT.jks \
        -password pass:$ROOT_KEYSTORE_PASSWORD \
        -noenc -nocerts \
        -out $ROOT_PATH/$ROOT.key
