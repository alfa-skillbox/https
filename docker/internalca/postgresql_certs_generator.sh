#!/usr/bin/env bash
set -ex

###########################
#- VARS
###########################
#--- Domain name
DN=localhost
###########################
#--- INTERNAL ROOT CA VARS
###########################
ROOT=rootCA
ROOT_PATH=./$ROOT
ROOT_PASSWORD=$ROOT-password
###########################
#--- RESOURCE SERVER VARS
###########################
POSTGRE=postgre
POSTGRE_PATH=./$POSTGRE
###########################
#--- DOCKER IMPORT VARS
###########################
PATH_TO_COPY=../imports/$POSTGRE/certs
PATH_TO_INIT=../imports/$POSTGRE/init

mkdir -p $POSTGRE_PATH
mkdir -p $PATH_TO_COPY

#--------------------------------------Postgresql (as SSL-SERVER) cert & key---------------------------------------#
#
# 1 Генерим приватный ключ PEM
#             ->
#               2 Создаем запрос в CA на подпись сертификата .csr
#                     ->
#                       3 Создаем файл конфигурации для настройки разрешений сертификата и подписываем сертификат Postgre



# 1.####################################
# Генерим приватный ключ PEM для Postgres
# Input: -
# Command: genkeypair
# Output: файл приватного ключа .key
########################################
openssl genpkey -out $POSTGRE_PATH/$POSTGRE.pkcs8.key -outform PEM -algorithm RSA
# for old postgres version the pkcs1 format should be used
#openssl rsa -in $POSTGRE_PATH/$POSTGRE.pkcs8.key -outform PEM -out $POSTGRE_PATH/$POSTGRE.pkcs1.key -traditional

# 2.####################################
# Создаем запрос в CA на подпись сертификата
# Input: приватный ключ с шага 1
# Command: certreq
# Output: .csr request file
########################################
openssl req -verbose -new -nodes -sha256 \
        -key $POSTGRE_PATH/$POSTGRE.pkcs8.key \
        -subj "/CN=$POSTGRE" \
        -out $POSTGRE_PATH/$POSTGRE.csr

# 3.####################################
# Имитация работы CA.
# Создаем файл конфигурации для настройки разрешений сертификата
# и подписываем сертификат Postgre
# Input: Root CA key and his key password, .csr request, extension params
# Command: gencert
# Output: .crt файл формата PEM
########################################

# Шаг 1. Файл конфигурации .ext для использования в процессе подписания
# через subjectAltName задается DNS, доступ с которого будет разрешен
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

# Шаг 2. Имитируем работу с запросом .csr, т.е. подписываем сертификат в Root CA
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

########################################
# Copies result to docker import
########################################
cp $POSTGRE_PATH/$POSTGRE.pkcs8.key $PATH_TO_COPY/server.key
cp $POSTGRE_PATH/$POSTGRE.crt $PATH_TO_COPY/server.crt

# solved "postgres using ssl" problem with
# https://stackoverflow.com/questions/55072221/deploying-postgresql-docker-with-ssl-certificate-and-key-with-volumes
sudo chmod 600 $PATH_TO_COPY/server.key

# генерация файла конфигурации pg_hba.conf для инициализации SSL в postgres
echo 'hostssl alfa_skillbox_https_resource_server_db postgres all md5' > $POSTGRE_PATH/pg_hba.conf
cp $POSTGRE_PATH/pg_hba.conf $PATH_TO_INIT/pg_hba.conf

# генерация скрипта, который подложит pg_hba.conf вместо дефолтного после старта postgres
# проверка исполнения через > cat /var/lib/postgresql/data/pg_hba.conf из консоли докера
>$POSTGRE_PATH/init_pg_hba.sh cat <<-EOF
#!/bin/sh
cp -f /var/lib/postgresql/pg_hba.conf /var/lib/postgresql/data/pg_hba.conf
EOF
sudo chmod +x $POSTGRE_PATH/init_pg_hba.sh
cp $POSTGRE_PATH/init_pg_hba.sh $PATH_TO_INIT/init_pg_hba.sh