#!/usr/bin/env bash

mkdir -p configs
if [ ${COMPOSE_ENVIRONMENT} == 'local' ]
then
cat <<EOF > ./configs/config.json
{
  "development": {
    "cloudinary": {
      "cloud_name": "$DEV_CLOUDINARY_CLOUD_NAME",
      "api_key": "$DEV_CLOUDINARY_API_KEY",
      "api_secret": "$DEV_CLOUDINARY_API_SECRET"
    }
  },
  "production": {
    "cloudinary": {
      "cloud_name": "$PROD_CLOUDINARY_CLOUD_NAME",
      "api_key": "$PROD_CLOUDINARY_CLOUD_NAME",
      "api_secret": "$PROD_CLOUDINARY_CLOUD_NAME"
    }
  }
}

EOF
else
if [ ${ENVIRONMENT} == 'development' ]; then
cat <<EOF > ./configs/config.json
{
  "development": {
    "cloudinary": {
      "cloud_name": "$DEV_CLOUDINARY_CLOUD_NAME",
      "api_key": "$DEV_CLOUDINARY_API_KEY",
      "api_secret": "$DEV_CLOUDINARY_API_SECRET"
    }
  },
}
EOF
fi

if [ ${ENVIRONMENT} == 'production' ]; then
cat <<EOF > ./configs/config.json
{
  "production": {
    "cloudinary": {
      "cloud_name": "$PROD_CLOUDINARY_CLOUD_NAME",
      "api_key": "$PROD_CLOUDINARY_CLOUD_NAME",
      "api_secret": "$PROD_CLOUDINARY_CLOUD_NAME"
    }
  }
}
EOF
fi
fi
