#!/bin/bash

HOST_MAN_LINK="" # Tutaj wklej swój link

if [ "$EUID" -ne 0 ]; then
  echo "Ten skrypt wymaga uprawnień roota. Próba restartu z sudo..."
  exec sudo "$0" "$@"
fi

apt install git -y
cd /
git clone https://github.com/linuxiarznaetacie/animated-computing-machine.git
cd animated-computing-machine
cp pstatistic.blueprint /var/www/pterodactyl/pstatistic.blueprint
cp pteromonaco.blueprint /var/www/pterodactyl/pteromonaco.blueprint
cp redirect.blueprint /var/www/pterodactyl/redirect.blueprint
cp resourcemanager.blueprint /var/www/pterodactyl/resourcemanager.blueprint
cp nebula.blueprint /var/www/pterodactyl/nebula.blueprint
cd /var/www/pterodactyl
blueprint -install nebula resourcemanager redirect pteromonaco pstatistic

clear
echo "+------------------------------------------------+"
echo "        POMYSLNIE ZAINSTALOWANO MOTYW"
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
