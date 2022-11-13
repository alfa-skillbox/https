#!/usr/bin/env bash
set -ex

ROOT_PATH=./root
ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem
ROOT_CERT_CRT_NAME=rootCA.cert.crt
#Generate the private key of the root CA:
openssl genrsa -out $ROOT_PATH/$ROOT_CERT_KEY_NAME 2048
#Generate the self-signed root CA certificate PEM:
openssl req -x509 -sha256 -new -nodes -key $ROOT_PATH/$ROOT_CERT_KEY_NAME -days 3650 -out $ROOT_PATH/$ROOT_CERT_PEM_NAME \
      -subj "/C=RU/ST=MOS/L=Moscow/O=Alfa/OU=Java/CN=localhost/emailAddress=alfa-skillbox@gmail.com"
#Convert CCA PEM to CRT for using in trustStores:
openssl x509 -outform der -in $ROOT_PATH/$ROOT_CERT_PEM_NAME -out $ROOT_PATH/$ROOT_CERT_CRT_NAME
#Review the certificate:
openssl x509 -in $ROOT_PATH/$ROOT_CERT_PEM_NAME -text >> $ROOT_PATH/ca_cert_pem.txt
