#!/bin/bash

# Copyright (c) 2025 Jakub Orłowski
# Licensed under the MIT License. See LICENSE for details.

HOST_MAN_LINK="" # Tutaj wklej swój link

if [ "$EUID" -ne 0 ]; then
  echo "Ten skrypt wymaga uprawnień roota. Próba restartu z sudo..."
  exec sudo "$0" "$@"
fi

apt install git -y
cd /
git clone https://github.com/linuxiarznaetacie/nebula-theme.git
cd nebula-theme
cp nebula.blueprint /var/www/pterodactyl/nebula.blueprint
cd /var/www/pterodactyl
blueprint -install nebula

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

