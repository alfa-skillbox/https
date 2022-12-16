#!/usr/bin/env bash
set -ex

###########################
#- VARS
###########################
#--- INTERNAL ROOT CA VARS
###########################
ROOT=rootCA
ROOT_PATH=./$ROOT
ROOT_KEYSTORE_PASSWORD=$ROOT-password
ROOT_KEYSTORE_ALIAS=root-ca
ROOT_CERT_PEM_NAME=$ROOT.cert.pem
###########################
mkdir -p $ROOT_PATH

# 1.####################################
# Генерим приватный ключ и самоподписанный сертификат для Root CA
# Команда genkeypair создает keystore с самоподписанным сертификатом по-умолчанию
# Input: информация для нового keystore
# Command: genkeypair
# Output: новый keystore .jks файл с самоподписанным сертификатом для Root CA
########################################
keytool -keystore $ROOT_PATH/$ROOT.jks \
        -storepass $ROOT_KEYSTORE_PASSWORD \
        -dname "cn=RootCA, ou=LocalhostRootCA, o=LocalhostRootCA, c=IN" \
        -alias $ROOT_KEYSTORE_ALIAS \
        -ext bc:c \
        -keyalg RSA -validity 825 \
        -genkeypair -v

# ROOT CA with OpenSSL пример
#openssl genpkey -out $ROOT_PATH/$ROOT.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
#openssl req -x509 -new -nodes -key $ROOT_PATH/$ROOT.key -sha256 -days 365 -out $ROOT_PATH/$ROOT.pem -subj /CN=RootCA

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
