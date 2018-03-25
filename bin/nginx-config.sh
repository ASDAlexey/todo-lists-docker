#!/usr/bin/env bash

mkdir -p nginx/configs/conf.d
rm -rf ./nginx/configs/conf.d/*

domains="$URL_FRONTEND www.$URL_FRONTEND";
redirect_path="https://\$mod_host\$url_without_slash\$mod_args"

function replaceEndSlash(){
echo "# redirect from page with slash to page without slash on the end of url
    if ( \$uri ~ ^/(.*)/$ ) {
        return 301 $redirect_path;
    }";
}

function generateListenSSL {
    if [ $1 ] && [ $1 == '80' ]; then
    echo "listen 80;"
    fi
    if [ $1 ] && [ $1 == '443' ]; then
    echo "listen 443 ssl http2;"
    echo "    ssl_certificate /etc/nginx/ssl/ssl.cert;"
    echo "    ssl_certificate_key /etc/nginx/ssl/ssl.key;"
    fi
    if [ $2 ] && [ $2 == '443' ]; then
    echo "    listen 443 ssl http2;"
    echo "    ssl_certificate /etc/nginx/ssl/ssl.cert;"
    echo "    ssl_certificate_key /etc/nginx/ssl/ssl.key;"
    fi
}

function assets {
    if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then
        root=/var/www/html/${PATH_FRONTEND}/dist;
    else
        root=/var/www/html/${PATH_FRONTEND};
    fi
    echo "location ~* ^.+\.(jpg|jpeg|gif|png|ico|svg|eot|ttf|woff|woff2|json|js|css|mp3|ogg|mpe?g|avi|zip|gz|bz2?|rar|swf|br)$ {
      root $root;
      expires max;
      log_not_found off;
    }"
}

function basic {
    space=$([ $1 ]  && [ $1 == 'cache' ] && echo "    " || echo "")
    if [ $1 ] && [ $1 == 'cache' ]; then
    echo "# cache files
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # SSL cache
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    "
    fi

    echo "$space# prevent hacker scanners
    if ( \$http_user_agent ~* (nmap|nikto|wikto|sf|sqlmap|bsqlbf|w3af|acunetix|havij|appscan) ) {
        return 301 https://www.google.com;
    }

    # prevent users from opening in an iframe
    add_header X-Frame-Options SAMEORIGIN;

    charset utf8;"
}

function spaLocation(){
    echo "try_files \$uri\$args \$uri\$args/ /index.html;"
}

if [ ${COMPOSE_ENVIRONMENT} == 'local' ]; then
cat <<EOF > nginx/configs/conf.d/redirects.conf
# redirect http to https
server {
    $(generateListenSSL 80)
    server_name $domains;
    return 301 $redirect_path;
}

# redirect www to non-www
server {
    $(generateListenSSL 443)
    server_name "~^www\.(.*)$" ;
    return 301 $redirect_path;
}
EOF

cat <<EOF > nginx/configs/conf.d/$URL_FRONTEND.conf
server {
    $(generateListenSSL 443)

    server_name $URL_FRONTEND;

    $(basic)

    $(replaceEndSlash)

    root /var/www/html/${PATH_FRONTEND}/dist;

    location / {
        $(spaLocation)
    }

    $(assets)
}
EOF
fi

if [ ${COMPOSE_ENVIRONMENT} == 'server' ] && [ ${CLUSTER} == 'self' ]; then
cat <<EOF > nginx/configs/conf.d/$URL_FRONTEND.conf
server {
    $(generateListenSSL 80)

    server_name $URL_FRONTEND;

    $(basic)

    root /var/www/html/${PATH_FRONTEND};

    location / {
        $(spaLocation)
    }

    $(assets)
}
EOF
fi
