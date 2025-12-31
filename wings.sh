#!/bin/bash

HOST_MAN_LINK="" # Tutaj wklej swój link

if [ "$EUID" -ne 0 ]; then
  echo "Ten skrypt wymaga uprawnień roota. Próba restartu z sudo..."
  exec sudo "$0" "$@"
fi

curl -sSL https://get.docker.com/ | CHANNEL=stable bash
sudo systemctl enable --now docker

mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings
cd /etc/systemd/system

cat <<EOF > wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now wings

echo ""
read -p "Czy chcesz automatycznie skonfigurowac Wings? (t/n): " confirm
echo ""

if [[ $confirm != "t" && $confirm != "T" ]]; then
    echo "Pomyslnie zainstalowano Wings, bez konfiguracji!"
    exit 1
fi

clear
echo "+----------------------------------------------------+"
echo "Po dodaniu swojego node wejdz w ten link"
echo "https://<TWOJ_LINK_DO_PANELU>/admin/nodes"
echo "a następnie kliknij na swoje node"
echo "Wejdz w Configuration, i kopiuj i wklejaj rzeczy"
echo "Zgodzie z poleceniami instalatora"
echo "+----------------------------------------------------+"

while [ -z "$UUID" ]; do
    read -s -p "Wpisz swoje UUID : " UUID
    echo ""
done

while [ -z "$TOKEN_ID" ]; do
    read -s -p "Wpisz swoj Token ID: " TOKEN_ID
    echo ""
done

while [ -z "$TOKEN" ]; do
    read -s -p "Wpisz swoj Token: " TOKEN
    echo ""
done

while [ -z "$REMOTE" ]; do
    read -s -p "Wpisz swoj adres panelu remote: " REMOTE
    echo ""
done

while [ -z "$PORT" ]; do
    read -s -p "Wpisz swoj port wings: " PORT
    echo ""
done

apt update
apt install openssl -y
mkdir /etc/certs
cd /etc/certs
openssl req -x509 -newkey rsa:2048 -nodes -keyout privkey.pem -out fullchain.pem -days 365 -subj "/C=PL/ST=Warmińsko-Mazurskie/L=Olsztyn/O=MojaFirma/CN=localhost"

cd /etc/pterodactyl

cat <<EOF > config.yml
debug: false
uuid: $UUID
token_id: $TOKEN_ID
token: $TOKEN
api:
  host: 0.0.0.0
  port: $PORT
  ssl:
    enabled: true
    cert: /etc/certs/fullchain.pem
    key: /etc/certs/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '$REMOTE'
EOF

systemctl restart wings --now

clear
echo "+------------------------------------------------+"
echo "        POMYSLNIE ZAINSTALOWANO WINGS"
echo "  "
echo "        TWOJE NODE POWINNO JUZ DZIALAC:"
echo "  JESLI COS NIE DZIALA ZOBACZ DOKUMENTACJE PANELU"
echo "  https://pterodactyl.io/wings/1.0/installing.html"
echo "  "
echo "+------------------------------------------------+"

read -p "Czy chcesz uruchomic menu glowne? (t/n): " odpowiedz

if [[ "$odpowiedz" == "t" || "$odpowiedz" == "T" ]]; then
    clear
    if [ -n "$HOST_MAN_LINK" ]; then
        bash <(curl -sSf "$HOST_MAN_LINK")
    fi
else
    clear
    exit 0
fi



