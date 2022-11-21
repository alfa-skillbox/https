#!/usr/bin/env bash
set -ex

###########################
#- VARS
###########################
#--- INTERNAL ROOT CA VARS
###########################
ROOT_PATH=./root
ROOT_CERT_PEM_NAME=rootCA.cert.pem
###########################
#--- GATEWAY VARS
###########################
GATEWAY=gateway
GATEWAY_PATH=./$GATEWAY
GATEWAY_TRUSTSTORE_ALIAS=$GATEWAY-internal-ca-root
GATEWAY_TRUSTSTORE_PASSWORD=$GATEWAY-password
###########################
#--- DOCKER IMPORT VARS
###########################
PATH_TO_COPY=../imports/$GATEWAY

#--------------------------------------Gateway (as SSL-CLIENT) TrustStore-------------------------------------#
# 1 .jks + CA .pem (создать хранилище SSL-клиента, положить туда Root CA .pem сертификат)

# 1.####################################
# Creates gateway truststore .jks file and
# imports here CA .pem cert
# Input: CA .pem cert
# Command: import (or importcert)
# Output: new truststore .jks file with CA .pem cert
########################################
keytool -keystore $GATEWAY_PATH/$GATEWAY.truststore.jks \
        -storepass $GATEWAY_TRUSTSTORE_PASSWORD \
        -alias $GATEWAY_TRUSTSTORE_ALIAS \
        -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
        -importcert -v

########################################
# Checks entries (certificates) inside SSL-client trustStore .jks
########################################
keytool -keystore $GATEWAY_PATH/$GATEWAY.truststore.jks \
        -storepass $GATEWAY_TRUSTSTORE_PASSWORD \
        -alias $GATEWAY_TRUSTSTORE_ALIAS \
        -list -v

########################################
# Copies result to docker import
########################################
cp $GATEWAY_PATH/$GATEWAY.truststore.jks $PATH_TO_COPY/truststore.jks