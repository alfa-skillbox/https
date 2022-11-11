#!/usr/bin/env bash
set -ex

ROOT_PATH=internalca/root
#Generate the private key of the root CA:
openssl genrsa -out ./$ROOT_PATH/rootCAKey.pem 2048
#Generate the self-signed root CA certificate:
openssl req -x509 -sha256 -new -nodes -key rootCAKey.pem -days 3650 -out rootCACert.pem


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

NAME=localhost # Use your own domain name
# Generate a private key
openssl genrsa  \
       -out $NAME.key 2048

openssl req -x509 -new -nodes -key $NAME.key -sha256 -days 825 -out $NAME.crt \
        -subj "/C=RU/ST=Moscow/L=Moscow/O=Alfa/OU=Java/CN=localhost/emailAddress=vonavi.ashas@gmail.com"

# Create a certificate-signing request
openssl req -new -key $NAME.key -out $NAME.csr \
        -subj "/C=RU/ST=Moscow/L=Moscow/O=Alfa/OU=Java/CN=localhost/emailAddress=vonavi.ashas@gmail.com"

# Create a config file for the extensions
#>$NAME.ext cat <<-EOF
#authorityKeyIdentifier=keyid,issuer
#basicConstraints=CA:FALSE
#extendedKeyUsage=serverAuth,clientAuth
#keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
#subjectAltName = @alt_names
#[alt_names]
#DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
## DNS.2 = bar.$NAME # Optionally, add additional domains (I've added a subdomain here)
#IP.1 = 127.0.0.1 # Optionally, add an IP address (if the connection which you have planned requires it)
#EOF

# Create the signed certificate
#openssl x509 -req -in $NAME.csr -CA myCA.pem -passin pass:qwerty -CAkey myCA.key -CAcreateserial \
#-out $NAME.crt -days 825 -sha256 -extfile $NAME.ext
#
chmod 655 $NAME.key
chmod 655 $NAME.crt

openssl pkcs12 \
       -inkey $NAME.key \
       -in $NAME.crt \
       -export -out $NAME.p12 \
       -passout pass:qwerty

keytool -importkeystore \
       -srckeystore $NAME.p12 \
       -srcstorepass qwerty \
       -srcstoretype pkcs12 \
       -destkeystore $NAME.jks \
       -deststoretype jks \
       -deststorepass qwerty

############
#
# variant 2
# https://stackoverflow.com/a/52684817
############

# generate a self-signed cert using the keytool
#CN=localhost, OU=Java, O=Alfa, L=Unknown, ST=Msk, C=RU
#keytool -genkey -alias $NAME -keyalg RSA -keystore keycloak.jks -validity 825

# convert .jks to .p12

#keytool -importkeystore -srckeystore keycloak.jks -destkeystore keycloak.p12 -deststoretype PKCS12

# generate .crt from .p12 keystore

#openssl pkcs12 -in keycloak.p12 -nokeys -out $NAME.crt

# generate .key from .p12 keystore

#openssl pkcs12 -in keycloak.p12 -nocerts -nodes -out $NAME.key

#chmod 655 $NAME.key
#chmod 655 $NAME.crt