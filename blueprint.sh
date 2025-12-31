#!/bin/bash

PTERODACTYL_DIRECTORY="/var/www/pterodactyl"
HOST_MAN_LINK="" # Tutaj wklej swój link

if [ "$EUID" -ne 0 ]; then
  echo "Ten skrypt wymaga uprawnień roota. Próba restartu z sudo..."
  exec sudo "$0" "$@"
fi

apt install -y curl wget unzip -y

cd $PTERODACTYL_DIRECTORY

wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)" -O "$PTERODACTYL_DIRECTORY/release.zip"
unzip -o release.zip

apt install -y ca-certificates curl git gnupg unzip wget zip -y
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt update
apt install nodejs -y

cd $PTERODACTYL_DIRECTORY
npm i -g yarn
yarn install

touch $PTERODACTYL_DIRECTORY/.blueprintrc

echo \
'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > $PTERODACTYL_DIRECTORY/.blueprintrc

chmod +x $PTERODACTYL_DIRECTORY/blueprint.sh
bash $PTERODACTYL_DIRECTORY/blueprint.sh
clear
clear
echo "+------------------------------------------------+"
echo "        POMYSLNIE ZAINSTALOWANO BLUEPRINT"
echo "  "
echo "       ZALOGUJ SIE DO PANELU I INSTALUJ:"
echo "                ULUBIONE WTYCZKI!"
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


