#!/usr/bin/env bash
set -ex

###########################
#- VARS
###########################
#--- INTERNAL ROOT CA VARS
###########################
ROOT=rootCA
ROOT_PATH=./$ROOT
ROOT_CERT_PEM_NAME=$ROOT.cert.pem
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

mkdir -p $GATEWAY_PATH
mkdir -p $PATH_TO_COPY

#--------------------------------------Gateway (as SSL-CLIENT) TrustStore-------------------------------------#
# 1 Создать truststore SSL-клиента, положить туда Root CA .pem сертификат

# 1.####################################
# Создаем truststore файл .jks и импортим в него сертификат Root CA
# Input: Root CA .pem cert
# Command: import (or importcert)
# Output: новый файл truststore формата JKS с сертификатом Root CA
########################################
keytool -keystore $GATEWAY_PATH/$GATEWAY.truststore.jks \
        -storepass $GATEWAY_TRUSTSTORE_PASSWORD \
        -alias $GATEWAY_TRUSTSTORE_ALIAS \
        -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
        -importcert -v

########################################
# Copies result to docker import
########################################
cp $GATEWAY_PATH/$GATEWAY.truststore.jks $PATH_TO_COPY/truststore.jks