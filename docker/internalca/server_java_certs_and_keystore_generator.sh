#!/usr/bin/env bash
set -ex

######################
# VARS
######################
# Domain name
NAME=localhost
######################
ROOT_PATH=./root
ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem
ROOT_CERT_CRT_NAME=rootCA.cert.crt
SERVER=$NAME.server
SERVER_PATH=./server-java
PATH_TO_COPY=../../https-server/src/main/resources
SERVER_KEY_PASSWORD=https_server_password
SERVER_KEYSTORE_PASSWORD=https_server_password
SERVER_TRUSTSTORE_PASSWORD=https_server_password

# Generate a https-server private key
openssl genrsa -out $SERVER_PATH/$SERVER.key.pem 2048
openssl req -new -key $SERVER_PATH/$SERVER.key.pem -out $SERVER_PATH/$SERVER.csr \
        -subj "/CN=localhost"
#keytool -genkeypair -dname "CN=localhost" \
#      -alias server-local \
#      -keysize 2048 \
#      -keyalg RSA \
#      -keypass $SERVER_KEY_PASSWORD \
#      -keystore $SERVER_PATH/$SERVER.keystore \
#      -storepass $SERVER_KEYSTORE_PASSWORD \
#      -validity 825

# Create a certificate-signing request
#keytool -certreq -dname "CN=localhost" \
#      -alias https-server-local \
#      -keystore $SERVER_PATH/$SERVER.keystore \
#      -storepass $SERVER_KEYSTORE_PASSWORD \
#      -file $SERVER_PATH/$SERVER.csr
#openssl genrsa -out $SERVER_PATH/$SERVER.key.pem 2048

# TODO важно понять, на какой ресурс выписывается сертификат ()
# Create a config file for the extensions
>$SERVER_PATH/$SERVER.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth
keyUsage = digitalSignature, nonRepudiation, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
# DNS.2 = $SERVER.$NAME # Optionally, add additional domains (I've added a subdomain here)
IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
EOF

# Create the signed server certificate
openssl x509 -req \
    -in $SERVER_PATH/$SERVER.csr \
    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
    -passin pass:qwerty \
    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
    -CAcreateserial -CAserial $SERVER_PATH/$SERVER.srl \
    -out $SERVER_PATH/$SERVER.crt \
    -days 825 -sha256 \
    -extfile $SERVER_PATH/$SERVER.ext
# Import root ca cert
#keytool -import -keystore $SERVER_PATH/$SERVER.keystore -file root.crt -alias root
keytool -importcert -trustcacerts -file $ROOT_PATH/$ROOT_CERT_CRT_NAME \
        -keystore $SERVER_PATH/$SERVER.truststore.jks \
        -alias internal_ca_root \
        -storepass $SERVER_TRUSTSTORE_PASSWORD \
        -storetype JKS
keytool -importkeystore \
      -srckeystore $SERVER_PATH/$SERVER.truststore.jks \
      -srcstorepass $SERVER_TRUSTSTORE_PASSWORD \
      -destkeystore $SERVER_PATH/$SERVER.truststore.p12 \
      -deststoretype PKCS12 \
      -srcalias internal_ca_root \
      -deststorepass $SERVER_TRUSTSTORE_PASSWORD

#      -destkeypass qwerty
# Import root ca cert to keystore
#keytool -importcert -file $ROOT_PATH/$ROOT_CERT_CRT_NAME \
#        -keystore $SERVER_PATH/$SERVER.keystore \
#        -alias https-server-local \
#        -storepass $SERVER_KEYSTORE_PASSWORD
# Import certificate signed by ca to keystore
#keytool -importcert -file $SERVER_PATH/$SERVER.crt \
#        -keystore $SERVER_PATH/$SERVER.keystore \
#        -alias https-server-local \
#        -storepass $SERVER_KEYSTORE_PASSWORD

# Create p12 from key and crt


#chmod 655 $NAME.key
#chmod 655 $NAME.crt
# server.key + server.crt -> keystore.p12
openssl pkcs12 \
       -inkey $SERVER_PATH/$SERVER.key.pem \
       -in $SERVER_PATH/$SERVER.crt \
       -export -out $SERVER_PATH/$SERVER.keystore.p12 \
       -passout pass:$SERVER_KEYSTORE_PASSWORD \
       -name server_local
# trust.p12 -> trust.jks
keytool -importkeystore \
       -srckeystore $SERVER_PATH/$SERVER.keystore.p12 \
       -srcstorepass $SERVER_KEYSTORE_PASSWORD \
       -srcstoretype pkcs12 \
       -srcalias server_local \
       -destkeystore $SERVER_PATH/$SERVER.keystore.jks \
       -deststoretype jks \
       -destalias server_local \
       -deststorepass $SERVER_KEYSTORE_PASSWORD
# ca.pem -> trust.jks
#keytool -importcert -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
#        -keystore $SERVER_PATH/$SERVER.keystore.jks \
#        -alias server_local \
#        -storepass $SERVER_TRUSTSTORE_PASSWORD \
#        -storetype JKS
#
#keytool -importcert -file $ROOT_PATH/$ROOT_CERT_PEM_NAME \
#        -keystore $SERVER_PATH/$SERVER.keystore \
#        -alias internal_ca_root \
#        -storepass $SERVER_KEYSTORE_PASSWORD

cp $SERVER_PATH/$SERVER.truststore.jks $PATH_TO_COPY
cp $SERVER_PATH/$SERVER.truststore.p12 $PATH_TO_COPY
#cp $SERVER_PATH/$SERVER.keystore $PATH_TO_COPY
cp $SERVER_PATH/$SERVER.keystore.p12 $PATH_TO_COPY
cp $SERVER_PATH/$SERVER.keystore.jks $PATH_TO_COPY