#!/usr/bin/env bash
set -ex

#VARS
# domain name
NAME=localhost
ROOT_PATH=./root
#ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem
CLIENT=$NAME.client
CLIENT_PATH=./client-java
SERVER=$NAME.resource.server
SERVER_PATH=./server-java
KEYCLOAK=$NAME.keycloak
KEYCLOAK_PATH=./keycloak

######################
# You can check your work to ensure that the certificate is built correctly
# https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate
######################
#CA crt
keytool -printcert -file $ROOT_PATH/$ROOT_CERT_PEM_NAME
#CLIENT
openssl verify -show_chain -verbose -CAfile $ROOT_PATH/$ROOT_CERT_PEM_NAME -verify_hostname $NAME -purpose sslserver $CLIENT_PATH/$CLIENT.crt
#SERVER
openssl verify -show_chain -verbose -CAfile $ROOT_PATH/$ROOT_CERT_PEM_NAME -verify_hostname $NAME -purpose sslserver $SERVER_PATH/$SERVER.crt
#KEYCLOAK
openssl verify -show_chain -verbose -CAfile $ROOT_PATH/$ROOT_CERT_PEM_NAME -verify_hostname $NAME -purpose sslserver $KEYCLOAK_PATH/$KEYCLOAK.crt
#DB
#openssl verify -CAfile $ROOT_PATH/$ROOT_CERT_PEM_NAME -verify_hostname $NAME $DB_PATH/$DB.crt