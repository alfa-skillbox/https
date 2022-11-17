#!/usr/bin/env bash
set -ex

######################
# VARS
######################
# Use your own domain name
NAME=localhost
######################
KEYCLOAK=$NAME.keycloak
KEYCLOAK_PATH=./keycloak
KEYCLOAK_KEY_PASSWORD=keycloak_password
KEYCLOAK_STORE_PASSWORD=keycloak_password
KEYCLOAK_IMPORT_PATH=../imports/keycloak
ROOT_PATH=./root
ROOT_CERT_KEY_NAME=rootCA.key.pem
ROOT_CERT_PEM_NAME=rootCA.cert.pem

# Generate keycloak private and public key pair
#openssl genrsa -out $KEYCLOAK_PATH/$KEYCLOAK.key.pem 2048

# Generate keycloak private key
#keytool -genseckey -dname "CN=localhost" \
#      -alias keycloak_local \
#      -keysize 56 \
#      -keyalg DES \
#      -keypass $KEYCLOAK_KEY_PASSWORD \
#      -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
#      -storepass $KEYCLOAK_STORE_PASSWORD \
#      -validity 825
keytool -genkeypair -dname "CN=localhost" \
      -alias keycloak_local \
      -keysize 2048 \
      -keyalg RSA \
      -keypass $KEYCLOAK_KEY_PASSWORD \
      -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
      -storepass $KEYCLOAK_STORE_PASSWORD \
      -validity 825
# Create a certificate-signing request
keytool -certreq -dname "CN=localhost" \
      -alias keycloak_local \
      -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
      -storepass $KEYCLOAK_STORE_PASSWORD \
      -file $KEYCLOAK_PATH/$KEYCLOAK.csr
#keytool -certreq -alias localhost -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore > $KEYCLOAK_PATH/$KEYCLOAK.csr

# Create a certificate-signing request
#openssl req -new -key $KEYCLOAK_PATH/$KEYCLOAK.key.pem -out $KEYCLOAK_PATH/$KEYCLOAK.csr \
#        -subj "/CN=keycloak_local"
#keytool -certreq -alias keycloak_pair \
#        -storepass $KEYCLOAK_STORE_PASSWORD \
#        -keystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
#        -file $KEYCLOAK_PATH/$KEYCLOAK.csr

# Create a config file for the extensions
>$KEYCLOAK_PATH/$KEYCLOAK.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
extendedKeyUsage=serverAuth,clientAuth
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
# DNS.2 = $KEYCLOAK.$NAME # Optionally, add additional domains (I've added a subdomain here)
IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
EOF

# Create the signed server certificate TODO доработать
openssl x509 -req \
    -in $KEYCLOAK_PATH/$KEYCLOAK.csr \
    -CA $ROOT_PATH/$ROOT_CERT_PEM_NAME \
    -passin pass:qwerty \
    -CAkey $ROOT_PATH/$ROOT_CERT_KEY_NAME \
    -CAcreateserial -CAserial $KEYCLOAK_PATH/$KEYCLOAK.srl\
    -out $KEYCLOAK_PATH/$KEYCLOAK.crt \
    -days 825 -sha256 \
    -extfile $KEYCLOAK_PATH/$KEYCLOAK.ext


## export private key from keycloak keystore
## step 1 - converting to pkcs12 using keytool
keytool -importkeystore \
      -srckeystore $KEYCLOAK_PATH/$KEYCLOAK.keystore \
      -srcstorepass $KEYCLOAK_STORE_PASSWORD \
      -destkeystore $KEYCLOAK_PATH/$KEYCLOAK.p12 \
      -deststoretype PKCS12 \
      -srcalias keycloak_local \
      -deststorepass $KEYCLOAK_STORE_PASSWORD \
      -destkeypass $KEYCLOAK_KEY_PASSWORD
#
## step 2 - export private key using openssl
openssl pkcs12 -in $KEYCLOAK_PATH/$KEYCLOAK.p12 -noenc -nocerts -out $KEYCLOAK_PATH/$KEYCLOAK.key.pem -password pass:$KEYCLOAK_STORE_PASSWORD

# copy to keycloak imports directory
cp $KEYCLOAK_PATH/$KEYCLOAK.key.pem $KEYCLOAK_IMPORT_PATH/$KEYCLOAK.key.pem
cp $KEYCLOAK_PATH/$KEYCLOAK.crt $KEYCLOAK_IMPORT_PATH/$KEYCLOAK.crt

# change modification to key and crt keycloak files
chmod 655 $KEYCLOAK_IMPORT_PATH/$KEYCLOAK.key.pem
chmod 655 $KEYCLOAK_IMPORT_PATH/$KEYCLOAK.crt