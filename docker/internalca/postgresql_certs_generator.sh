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

if [ -d "$POSTGRE_PATH" ]
then
	if [ "$(ls -A $(pwd)/$POSTGRE_PATH)" ]; then
     rm $POSTGRE_PATH/*
	else
    echo "$POSTGRE_PATH is Empty"
	fi
else
	echo "Directory $POSTGRE_PATH not found."
fi
PATH_TO_CLEAN=$PATH_TO_COPY
ls -la $PATH_TO_CLEAN
if [ -d "$PATH_TO_CLEAN" ]
then
	if [ "$(ls -A $PATH_TO_CLEAN)" ]; then
     sudo rm $PATH_TO_CLEAN/*
	else
    echo "$PATH_TO_CLEAN is Empty"
	fi
else
	echo "Directory $PATH_TO_CLEAN not found."
fi
ls -la $PATH_TO_CLEAN

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
#new ROOT CA
#openssl genpkey -out $ROOT_PATH/new_root.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
#openssl req -x509 -new -nodes -key $ROOT_PATH/new_root.key -sha256 -days 365 -out $ROOT_PATH/new_root.pem \
#        -subj /CN=localhost


# 1.####################################
# Generate key
# Input: keystore info
# Command: genkeypair
# Output: .jks file with keypair
########################################
openssl genpkey -out $POSTGRE_PATH/$POSTGRE.pkcs8.key -outform PEM -algorithm RSA
# for old postgres version the pkcs1 format should be used
openssl rsa -in $POSTGRE_PATH/$POSTGRE.pkcs8.key -outform PEM -out $POSTGRE_PATH/$POSTGRE.pkcs1.key -traditional
# 2.####################################
# Generate a certificate-signing request
# Input: keypair keystore and alias
# Command: certreq
# Output: .csr request file
########################################
openssl req -verbose -new -nodes -sha256 \
        -key $POSTGRE_PATH/$POSTGRE.pkcs8.key \
        -subj "/CN=$POSTGRE" \
        -out $POSTGRE_PATH/$POSTGRE.csr

# 3.####################################
# Sign certificate with Root CA
# Input: root ca keystore and his alias, .csr request,
#        extension params
# Command: gencert
# Output: PEM (with -rfc) or DER certificate file
########################################

# The same with OPENSSL example
# Create a .ext config file for using in signing process
>$POSTGRE_PATH/$POSTGRE.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth,clientAuth
keyUsage = digitalSignature, nonRepudiation, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DN # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
# DNS.2 = $POSTGRE.$DN # Optionally, add additional domains (I've added a subdomain here)
IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
EOF

#TODO понять, куда пристроить эту фразу
#org.postgresql.util.PSQLException: FATAL: client certificates can only be checked if a root certificate store is available

# Part 2. Sign certificate with Root CA
openssl x509 -req -sha256 \
    -in $POSTGRE_PATH/$POSTGRE.csr \
    -CA $ROOT_PATH/$ROOT.cert.pem \
    -passin pass:$ROOT_PASSWORD \
    -CAkey $ROOT_PATH/$ROOT.key \
    -CAcreateserial \
    -CAserial $POSTGRE_PATH/$POSTGRE.srl \
    -days 365 \
    -extfile $POSTGRE_PATH/$POSTGRE.ext \
    -out $POSTGRE_PATH/$POSTGRE.crt

#cat $ROOT_PATH/$ROOT_CERT_PEM_NAME $POSTGRE_PATH/$POSTGRE.crt > $POSTGRE_PATH/$POSTGRE.chained.pem
# Part 3. Converting .crt -> .pem
#openssl x509 -in $ROOT_PATH/$ROOT_CERT_PEM_NAME -trustout -out $ROOT_PATH/$ROOT.trust.pem
#openssl x509 -in $POSTGRE_PATH/$POSTGRE.crt -trustout -out $POSTGRE_PATH/$POSTGRE.crt
#cat $ROOT_PATH/$ROOT.trust.pem $POSTGRE_PATH/$POSTGRE.pem > $POSTGRE_PATH/$POSTGRE.chained.pem

# 4.####################################
# Combine Root CA certificate with SSL-Server certificate
# WARN! Root cert should be on the first position
# Input: Root CA .pem file, ssl-server .pem file
# Command: cat
# Output: chained (combined) ssl-server .pem cert
########################################
#cat $ROOT_PATH/$ROOT_CERT_PEM_NAME $SERVER_PATH/$SERVER.temp.pem > $SERVER_PATH/$SERVER.pem


#openssl req -new -text -out server.req
#openssl rsa -in privkey.pem -out server.key
##rm privkey.pem
#openssl req -x509 -in server.req -text -key server.key -out server.crt
#
#cp server.crt $PATH_TO_COPY/server.crt
#cp server.key $PATH_TO_COPY/server.key


########################################
# Copies result to docker import
########################################
cp $POSTGRE_PATH/$POSTGRE.pkcs8.key $PATH_TO_COPY/server.key
cp $POSTGRE_PATH/$POSTGRE.crt $PATH_TO_COPY/server.crt

#sudo chown 999 $PATH_TO_COPY/server.key
sudo chmod 600 $PATH_TO_COPY/server.key
#sudo chown 0:70 $PATH_TO_COPY/server.crt
#sudo chmod 640 $PATH_TO_COPY/server.crt