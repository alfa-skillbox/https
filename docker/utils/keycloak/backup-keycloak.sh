#!/usr/bin/env bash
#
# backup-keycloak.sh
set -ex
# Copy the export bash script to the (already running) keycloak container
# to perform an export
KEYCLOAK_CONTAINER_NAME=keycloak-local
chmod 655 docker-exec-cmd.sh
docker cp ./docker-exec-cmd.sh $KEYCLOAK_CONTAINER_NAME:/tmp/docker-exec-cmd.sh

# Execute the script inside of the container
docker exec -it $KEYCLOAK_CONTAINER_NAME /tmp/docker-exec-cmd.sh
# Grab the finished export from the container
docker cp $KEYCLOAK_CONTAINER_NAME:/tmp/realms-export-single-file.json .