#!/bin/bash

# Pobieranie danych wstępnych
PUBLIC_IP=$(curl -s ifconfig.me)
HOST_MAN_LINK="" # Tutaj wklej swój link

# Wymuszenie roota
if [ "$EUID" -ne 0 ]; then
  echo "Ten skrypt wymaga uprawnień roota. Próba restartu z sudo..."
  exec sudo "$0" "$@"
fi

apt update && apt upgrade -y
clear

# --- POBIERANIE DANYCH ---

while [ -z "$email" ]; do
    read -p "Wpisz tutaj swoj adres e-mail (autora): " email
done

while [ -z "$app_url" ]; do
    read -p "Wpisz tutaj swoj URL (np. http://panel.example.com): " app_url
done

read -p "Wpisz strefę czasową (domyslnie: Europe/Warsaw): " timezone
timezone=${timezone:-Europe/Warsaw}

read -p "Nazwa bazy danych (domyslnie: pterodactyl): " MYSQL_DB
MYSQL_DB=${MYSQL_DB:-pterodactyl}

read -p "Uzytkownik bazy MySQL (domyslnie: pterodactyl): " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-pterodactyl}

while [ -z "$MYSQL_PASSWORD" ]; do
    read -s -p "Hasło do bazy MySQL: " MYSQL_PASSWORD
    echo ""
done

while [ -z "$user_email" ]; do
    read -p "E-mail do logowania w panelu: " user_email
done

read -p "Login admina (domyslnie: admin): " user_username
user_username=${user_username:-admin}

read -p "Imie (domyslnie: admin): " user_firstname
user_firstname=${user_firstname:-admin}

read -p "Nazwisko (domyslnie: admin): " user_lastname
user_lastname=${user_lastname:-admin}

while [ -z "$user_password" ]; do
    read -s -p "Hasło do panelu (min. 8 znaków): " user_password
    echo ""
done

clear
echo "Rozpoczynam instalację..."

# --- KONFIGURACJA BAZY DANYCH ---
# Automatyczne utworzenie bazy i użytkownika
mariadb -u root -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DB};"
mariadb -u root -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mariadb -u root -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'127.0.0.1' WITH GRANT OPTION; FLUSH PRIVILEGES;"

# --- INSTALACJA PLIKÓW ---
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl || exit

# Zakładam, że pliki panelu już tam są lub zostaną pobrane. 
# Jeśli ich nie ma, odkomentuj poniższe linie:
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

cp .env.example .env
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader -n
php artisan key:generate --force

# Konfiguracja środowiska
php artisan p:environment:setup \
    --author="$email" \
    --url="$app_url" \
    --timezone="$timezone" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="localhost" \
    --redis-pass="null" \
    --redis-port="6379" \
    --settings-ui=true

php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="$MYSQL_DB" \
    --username="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD"

php artisan migrate --seed --force

# Tworzenie użytkownika
php artisan p:user:make \
    --email="$user_email" \
    --username="$user_username" \
    --name-first="$user_firstname" \
    --name-last="$user_lastname" \
    --password="$user_password" \
    --admin=1

# Uprawnienia (Standard dla Debian/Ubuntu to www-data)
chown -R nginx:nginx /var/www/pterodactyl/*

# --- SERWIS KOLEJKI ---
cat <<EOF > /etc/systemd/system/pteroq.service
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now redis-server
systemctl enable --now pteroq.service

# --- NGINX ---
apt install nginx -y
rm -f /etc/nginx/sites-enabled/default

cat <<EOF > /etc/nginx/sites-available/pterodactyl.conf
server {
    listen 80;
    server_name 0.0.0.0; # Możesz tu wpisać domenę

    root /var/www/pterodactyl/public;
    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
systemctl restart nginx
systemctl restart pteroq.service

clear
echo "+------------------------------------------------+"
echo "        POMYSLNIE ZAINSTALOWANO PANEL"
echo "  "
echo "       ZALOGUJ SIE DO PANELU POD ADRESEM:"
echo "             http://$PUBLIC_IP"
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
