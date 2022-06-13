#!/usr/bin/env bash

DOMAINS=$(echo "$DOMAINS" | tr -s ' ')
SslServer="$SslServer"
mail="$mail"

if [ -z "$DOMAINS" ]; then
  echo "[$(date)] Empty env var DOMAINS"
#  exit 1
fi

mkdir -p /etc/nginx/ssl/default/
mkdir -p /etc/nginx/ssl/app/

function CreateDefault() {
  if [ -e "/etc/nginx/ssl/app/cert.pem" ]; then
    echo "[$(date)] default cert exists"
  else
    openssl req -x509 -newkey rsa:4096 -nodes -days 365 \
      -subj "/C=CA/ST=QC/O=Company Inc/CN=example.com" \
      -out /etc/nginx/ssl/default/cert.pem \
      -keyout /etc/nginx/ssl/default/key.pem
    cp /etc/nginx/ssl/default/*.pem  /etc/nginx/ssl/app/
    chmod +w /etc/nginx/ssl/app/*
  fi
}

function StartAcmesh() {
  echo "[$(date)] sleep 2 second to start Acme.sh..."
  sleep 2
  echo "[$(date)] Start Acme.sh..."

  IFS=' '
  read -ra list <<<"$DOMAINS"

  ACME_DOMAIN_OPTION=""

  for i in "${!list[@]}"; do
    if [[ $i == 0 ]]; then
      ACME_DOMAIN_OPTION+="-d ${list[$i]}"
    else
      ACME_DOMAIN_OPTION+=" -d ${list[$i]}"
    fi
  done

  echo "[$(date)] Issue the cert: $DOMAINS with options $ACME_DOMAIN_OPTION"

  if [[ -n "$SslServer" ]]; then
    # 测试环境 https://acme-staging-v02.api.letsencrypt.org/directory
    /root/.acme.sh/acme.sh --set-default-ca --server $SslServer
  fi

  echo "[$(date)] acme.sh register .."
  /root/.acme.sh/acme.sh --register-account -m $mail

  echo "[$(date)] acme.sh issue .."
  /root/.acme.sh/acme.sh --issue --nginx --debug $ACME_DOMAIN_OPTION --renew-hook "nginx -s reload"

  echo "[$(date)] acme.sh install-cert .."
  /root/.acme.sh/acme.sh --install-cert $ACME_DOMAIN_OPTION \
    --fullchain-file /etc/nginx/ssl/app/fullchain.pem \
    --cert-file /etc/nginx/ssl/app/cert.pem \
    --key-file /etc/nginx/ssl/app/key.pem \
    --reloadcmd "nginx -s reload"

  echo "[$(date)] Start cron"
  crond
}

# 生成默认证书, 配置文件中使用，否则nginx启动会失败
CreateDefault

if [[ -n "$DOMAINS" ]]; then
  export -f StartAcmesh
  nohup bash -c StartAcmesh &
fi

echo "[$(date)] Start nginx"
nginx -g "daemon off;"


