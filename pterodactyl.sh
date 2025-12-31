#!/bin/bash

PUBLIC_IP=$(curl -s ifconfig.me)
HOST_MAN_LINK= # Tutaj bedzie link do menu host manager

if [ "$EUID" -ne 0 ]; then
  echo "Ten skrypt wymaga uprawnień roota. Próba restartu z sudo..."
  exec sudo "$0" "$@"
fi

apt update && apt upgrade -y
clear

while [ -z "$email" ]; do
    read -p "Wpisz tutaj swoj adres e-mail: " email
    if [ -z "$email" ]; then
        echo "Pole nie może być puste. Wpisz swoj adres e-mail!"
    fi
done

while [ -z "$app_url" ]; do
    read -p "Wpisz tutaj swoj URL do strony (nawet jak masz cloudflare tunnel): " app_url
    if [ -z "$app_url" ]; then
        echo "Pole nie może być puste. Wpisz tutaj swoj URL do strony!"
    fi
done

read -p "Wpisz tutaj swoją strefę czasową w formacie TZ (domyslnie: Europe/Warsaw): " timezone
if [ -z "$timezone" ]; then
    timezone="Europe/Warsaw"

read -p "Wpisz nazwe bazy danych MySQL (domyslnie: pterodactyl_db): " MYSQL_DB
if [ -z "$MYSQL_DB" ]; then
    MYSQL_DB="pterodactyl"

read -p "Wpisz nazwe uzytkownika bazy MySQL (domyslnie: pterodactyl): " MYSQL_USER
if [ -z "$MYSQL_USER" ]; then
    MYSQL_USER="pterodactyl"

while [ -z "$MYSQL_PASSWORD" ]; do
    read -p "Wpisz swoje hasło do bazy MySQL: " MYSQL_PASSWORD
    if [ -z "$MYSQL_PASSWORD" ]; then
        echo "Pole nie może być puste. Wpisz tutaj hasło MySQL!"
    fi
done

while [ -z "$user_email" ]; do
    read -p "Wpisz swoj e-mail do zalogowania do panelu pterodactyl: " user_email
    if [ -z "$user_email" ]; then
        echo "Pole nie może być puste. Wpisz tutaj adres e-mail!"
    fi
done

read -p "Wpisz nazwe uzytkownika do pterodactyl panel (domyslnie: admin): " user_username
if [ -z "$user_username" ]; then
    $user_username="admin"

read -p "Wpisz swoje imie do pterodactyl panel (domyslnie: admin): " user_firstname
if [ -z "$user_firstname" ]; then
    $user_firstname="admin"

read -p "Wpisz swoje nazwisko do pterodactyl panel (domyslnie: admin): " user_lastname
if [ -z "$user_lastname" ]; then
    $user_lastname="admin"

while [ -z "$user_password" ]; do
    read -p "Wpisz swoje hasło do panelu pterodactyl: " user_password
    if [ -z "$user_password" ]; then
        echo "Pole nie może być puste. Wpisz tutaj hasło do panelu pterodactyl!"
    fi
done

fi
clear
cd /var/www/pterodactyl
mariadb -u root -p
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$database_password';
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
exit

cp .env.example .env
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
php artisan key:generate --force
grep APP_KEY /var/www/pterodactyl/.env

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

  php artisan p:user:make \
    --email="$user_email" \
    --username="$user_username" \
    --name-first="$user_firstname" \
    --name-last="$user_lastname" \
    --password="$user_password" \
    --admin=1
    
chown -R nginx:nginx /var/www/pterodactyl/*

cd /etc/systemd/system
cat <<EOF > pteroq.service
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

apt install nginx -y && rm /etc/nginx/sites-enabled/default
cd /etc/nginx/sites-available

cat <<EOF > pterodactyl.conf
server {
    listen 80;
    server_name 0.0.0.0;

    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
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

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
systemctl restart nginx

systemctl restart pteroq.service
clear

echo "+------------------------------------------------+"
echo "         POMYSLNIE ZAINSTALOWANO PANEL"
echo "  "
echo "       ZALOGUJ SIE DO PANELU Z TEGO LINKU:"
echo "             http://$PUBLIC_IP:80/"
echo "  "
echo "+------------------------------------------------+"


read -p "Czy chcesz uruchomic menu glowne? (t/n): " odpowiedz

if [[ "$odpowiedz" == "t" || "$odpowiedz" == "T" ]]; then
    clear
    bash <(curl -sSf $HOST_MAN_LINK)
else
    # Jeśli użytkownik wpisze cokolwiek innego niż 't'
    clear
    exit 0
fi
