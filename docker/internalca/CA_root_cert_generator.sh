#!/usr/bin/env bash
set -ex

ROOT=rootCA
ROOT_PATH=./root
ROOT_PASSWORD=rootpass
ROOT_CERT_KEY_NAME=$ROOT.key.pem
ROOT_CERT_PEM_NAME=$ROOT.cert.pem
ROOT_CERT_CRT_NAME=$ROOT.cert.crt
##Generate the private key of the root CA:
#openssl genrsa -out $ROOT_PATH/$ROOT_CERT_KEY_NAME 2048
##Generate the self-signed root CA certificate PEM:
#openssl req -x509 -sha256 -new -nodes -key $ROOT_PATH/$ROOT_CERT_KEY_NAME -days 3650 -out $ROOT_PATH/$ROOT_CERT_PEM_NAME \
#      -subj "/C=RU/ST=MOS/L=Moscow/O=Alfa/OU=Java/CN=localhost/emailAddress=alfa-skillbox@gmail.com"
##Convert CA PEM to CRT for using in trustStores: TODO не нужно
#openssl x509 -outform der -in $ROOT_PATH/$ROOT_CERT_PEM_NAME -out $ROOT_PATH/$ROOT_CERT_CRT_NAME
##Review the certificate:
#openssl x509 -in $ROOT_PATH/$ROOT_CERT_PEM_NAME -text >> $ROOT_PATH/ca_cert_pem.txt


########
# ROOT CA by Keytool
########
keytool -genkeypair -storepass $ROOT_PASSWORD \
        -keystore $ROOT_PATH/$ROOT.jks \
        -dname "cn=RootCA, ou=LocalhostRootCA, o=LocalhostRootCA, c=IN" \
        -alias root_ca \
        -ext bc:c \
        -keyalg RSA -validity 825

keytool -keystore $ROOT_PATH/$ROOT.jks -storepass $ROOT_PASSWORD -alias root_ca -exportcert -rfc -file $ROOT_PATH/$ROOT_CERT_PEM_NAME
