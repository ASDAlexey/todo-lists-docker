#!/bin/bash

HASH="$(openssl passwd -apr1 $HTTP_PASSWORD)"
echo "$APP_NAME:$HASH" > ./nginx/configs/.htpasswd
