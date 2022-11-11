#!/usr/bin/env bash
set -ex

ROOT_PATH=root
ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem
#Generate the private key of the root CA:
openssl genrsa -out $ROOT_PATH/$ROOT_CERT_KEY_NAME 2048
#Generate the self-signed root CA certificate:
openssl req -x509 -sha256 -new -nodes -key $ROOT_PATH/$ROOT_CERT_KEY_NAME -days 3650 -out $ROOT_PATH/$ROOT_CERT_PEM_NAME \
      -subj "/C=RU/ST=MOS/L=Moscow/O=Alfa/OU=Java/CN=localhost/emailAddress=alfa-skillbox@gmail.com"
#Review the certificate:
openssl x509 -in $ROOT_PATH/$ROOT_CERT_PEM_NAME -text >> $ROOT_PATH/ca_cert_pem.txt

######################
# Become a Certificate Authority
# https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate
######################

# Generate private key
#openssl genrsa -des3 -passout pass:qwerty -out myCA.key 2048
# Generate root certificate
#openssl req -x509 -new -nodes -passin pass:qwerty -key myCA.key -sha256 -days 825 -out myCA.pem \
#        -subj "/C=RU/ST=Moscow/L=Moscow/O=Alfa/OU=Java/CN=localhost/emailAddress=vonavi.ashas@gmail.com"

######################
# Create CA-signed certs
######################
