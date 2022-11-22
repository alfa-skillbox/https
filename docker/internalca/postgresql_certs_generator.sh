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
POSTGRE=postgre
POSTGRE_PATH=./$POSTGRE
POSTGRE_KEYSTORE_ALIAS=$POSTGRE-local
POSTGRE_TRUSTSTORE_ALIAS=$POSTGRE-internal-ca-root
POSTGRE_KEY_PASSWORD=$POSTGRE-password
POSTGRE_KEYSTORE_PASSWORD=$POSTGRE-password
POSTGRE_TRUSTSTORE_PASSWORD=$POSTGRE-password
###########################
#--- DOCKER IMPORT VARS
###########################
PATH_TO_COPY=../imports/$POSTGRE/certs

#--------------------------------------Postgresql (as SSL-SERVER) KeyStore---------------------------------------#
# https://www.postgresql.org/docs/8.4/ssl-tcp.html
# 1 keypair .jks (генерим ключи SSL сервера)
#             ->
#               2 .csr (создаем запрос на получение с)
#                     ->
#                       3 server .pem certificate (signed by CA)
#                                                               ->
#                                                                 4 CA .pem + server .pem = chain .pem
#                                                                                         ->
#                                                                                           5 Update keypair jks with chain .pem

# 1.####################################
# Generate key
# Input: keystore info
# Command: genkeypair
# Output: .jks file with keypair
########################################
#openssl genrsa -out $POSTGRE_PATH/$POSTGRE.key 2048

# 2.####################################
# Generate a certificate-signing request
# Input: keypair keystore and alias
# Command: certreq
# Output: .csr request file
########################################
#openssl req -new -key $POSTGRE_PATH/$POSTGRE.key -out $POSTGRE_PATH/$POSTGRE.csr -subj "/CN=$POSTGRE"

# 3.####################################
# Sign certificate with Root CA
# Input: root ca keystore and his alias, .csr request,
#        extension params
# Command: gencert
# Output: PEM (with -rfc) or DER certificate file
########################################

# The same with OPENSSL example
# Create a .ext config file for using in signing process
#>$POSTGRE_PATH/$POSTGRE.ext cat <<-EOF
#authorityKeyIdentifier=keyid,issuer
#basicConstraints=CA:FALSE
#extendedKeyUsage=serverAuth,clientAuth
#keyUsage = digitalSignature, nonRepudiation, dataEncipherment
#subjectAltName = @alt_names
#
#[alt_names]
#DNS.1 = $DN # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
## DNS.2 = $POSTGRE.$DN # Optionally, add additional domains (I've added a subdomain here)
#IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
#EOF

# Part 2. Sign certificate with Root CA
#openssl x509 -req \
#    -in $POSTGRE_PATH/$POSTGRE.csr \
#    -CA $ROOT_PATH/$ROOT.jks \
#    -passin pass:$ROOT_PASSWORD \
#    -CAkey $ROOT_PATH/$ROOT.key \
#    -CAcreateserial -CAserial $POSTGRE_PATH/$POSTGRE.srl \
#    -out $POSTGRE_PATH/$POSTGRE.pem \
#    -days 825 -sha256 \
#    -extfile $POSTGRE_PATH/$POSTGRE.ext

#cat $ROOT_PATH/$ROOT_CERT_PEM_NAME $POSTGRE_PATH/$POSTGRE.pem > $POSTGRE_PATH/$POSTGRE.chained.pem
# Part 3. Converting .crt -> .pem
#openssl x509 -in $ROOT_PATH/$ROOT_CERT_PEM_NAME -trustout -out $ROOT_PATH/$ROOT.trust.pem
#cat $ROOT_PATH/$ROOT.trust.pem $POSTGRE_PATH/$POSTGRE.pem > $POSTGRE_PATH/$POSTGRE.chained.pem

# 4.####################################
# Combine Root CA certificate with SSL-Server certificate
# WARN! Root cert should be on the first position
# Input: Root CA .pem file, ssl-server .pem file
# Command: cat
# Output: chained (combined) ssl-server .pem cert
########################################
#cat $ROOT_PATH/$ROOT_CERT_PEM_NAME $SERVER_PATH/$SERVER.temp.pem > $SERVER_PATH/$SERVER.pem


openssl req -new -text -out server.req
openssl rsa -in privkey.pem -out server.key
#rm privkey.pem
openssl req -x509 -in server.req -text -key server.key -out server.crt

cp server.crt $PATH_TO_COPY/server.crt
cp server.key $PATH_TO_COPY/server.key


########################################
# Copies result to docker import
########################################
#cp $POSTGRE_PATH/$POSTGRE.key $PATH_TO_COPY/server.key
#cp $POSTGRE_PATH/$POSTGRE.chained.pem $PATH_TO_COPY/server.crt

sudo chown 70:70 $PATH_TO_COPY/server.key
sudo chmod 600 $PATH_TO_COPY/server.key