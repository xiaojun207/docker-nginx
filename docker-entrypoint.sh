#!/usr/bin/env bash
# author by xiaojun207

export DOMAINS=$(echo "$SslDomains" | tr -s ';')
export SslServer="$SslServer"
export mail="$mail"
export SSL_DIR="/etc/nginx/ssl"
export RELOAD_CMD="nginx -s reload"

if [ -z "$mail" ]; then
  echo "[$(date)] Empty env var mail, set mail=\"youmail@example.com\""
  mail="youmail@example.com"
fi

if [ -z "$DOMAINS" ]; then
  echo "[$(date)] Empty env var SslDomains"
fi

mkdir -p ${SSL_DIR}/

function CreateDefault() {
  # true if the file exists and is not empty
  if [ -s "${SSL_DIR}/fullchain.pem" ]; then
    echo "[$(date)] default cert exists in :${SSL_DIR}"
  else
    echo "[$(date)] create default cert to :${SSL_DIR}"
    openssl req -x509 -newkey rsa:4096 -nodes -days 365 \
      -subj "/C=CA/ST=QC/O=Company Inc/CN=example.com" \
      -out ${SSL_DIR}/fullchain.pem \
      -keyout ${SSL_DIR}/key.pem
    chmod +w ${SSL_DIR}/*
  fi
}

function StartAcmesh() {
  echo "[$(date)] sleep 2 second to start Acme.sh..."
  sleep 2
  echo "[$(date)] Start Acme.sh..."
  echo "[$(date)] SSL_DIR :${SSL_DIR}"
  echo "[$(date)] mail :${mail}"
  echo "[$(date)] RELOAD_CMD :${RELOAD_CMD}"

  IFS=' '
  read -ra list <<<"$DOMAINS"

  ACME_DOMAIN_OPTION=""

  for i in "${!list[@]}"; do
    if [[ $i == 0 ]]; then
      ACME_DOMAIN_OPTION+="-d ${list[$i]}"
    else
      ACME_DOMAIN_OPTION+=" -d ${list[$i]}"
    fi

    if [[ -n "$dns" ]]; then
       ACME_DOMAIN_OPTION+=" --dns $dns"
    fi
  done

  echo "[$(date)] Issue the cert: $DOMAINS with options $ACME_DOMAIN_OPTION"

  if [[ -n "$SslServer" ]]; then
    # 测试环境 https://acme-staging-v02.api.letsencrypt.org/directory
    /root/.acme.sh/acme.sh --set-default-ca --server $SslServer
  fi

  echo "[$(date)] 1、acme.sh register .."
  /root/.acme.sh/acme.sh --register-account -m $mail

  echo "[$(date)] 2、acme.sh issue .."
  /root/.acme.sh/acme.sh --issue --nginx $ACME_DOMAIN_OPTION --renew-hook "${RELOAD_CMD}"

  echo "[$(date)] 3、acme.sh install-cert .."
  /root/.acme.sh/acme.sh --install-cert $ACME_DOMAIN_OPTION \
    --fullchain-file ${SSL_DIR}/fullchain.pem \
    --cert-file "${SSL_DIR}/cert.pem" \
    --key-file ${SSL_DIR}/key.pem \
    --reloadcmd "${RELOAD_CMD}"

  echo "[$(date)] Start acme.sh crond "
  crond
}

if [[ -n "$DOMAINS" ]]; then
  echo "[$(date)] 生成默认证书, 配置文件中使用，否则nginx启动会失败"
  CreateDefault

  export -f StartAcmesh
  nohup bash -c StartAcmesh "${SSL_DIR}" "${RELOAD_CMD}" &
fi

echo "[$(date)] Start nginx"
nginx -g "daemon off;"


