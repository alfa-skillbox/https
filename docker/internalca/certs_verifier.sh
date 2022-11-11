#!/usr/bin/env bash
set -ex
######################
# You can check your work to ensure that the certificate is built correctly
# https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate
######################

openssl verify -CAfile myCA.pem -verify_hostname loalhost localhost.crt