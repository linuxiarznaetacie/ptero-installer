#!/bin/bash

# Copyright (c) 2025 Jakub Orłowski
# Licensed under the MIT License. See LICENSE for details.

pokaz_banner() {
    cat << "EOF"
  _  _        _     __  __                             
 | || |___ __| |_  |  \/  |__ _ _ _  __ _ __ _ ___ _ _ 
 | __ / _ (_-<  _| | |\/| / _` | ' \/ _` / _` / -_) '_|
 |_||_\___/__/\__| |_|  |_\__,_|_||_\__,_\__, \___|_|  
                                         |___/         
EOF
}

clear
while true; do
    echo "+------------------------------------------------------------+"
    pokaz_banner
    echo "+------------------------------------------------------------+"
    echo "1) Zainstaluj Pterodactyl Panel"
    echo "2) Zainstaluj Wings"
    echo "3) Zainstaluj Blueprint"
    echo "4) Zainstaluj Wtyczki Blueprint"
    echo "5) Wyjście"
    echo "+------------------------------------------------------------+"
    read -p "Wybierz opcję [1-6]: " wybor

    case $wybor in
        1)
            echo "Uruchamiam Instalator Pterodactyl Panel"
            bash <(curl -sSf https://raw.githubusercontent.com/linuxiarznaetacie/ptero-installer/refs/heads/main/pterodactyl.sh)
            ;;
        2)
            echo "Uruchamiam Instalator Pterodactyl Wings"
            bash <(curl -sSf https://raw.githubusercontent.com/linuxiarznaetacie/ptero-installer/refs/heads/main/wings.sh)
            ;;
        3)
            echo "Uruchamiam instalator Blueprint"
            bash <(curl -sSf https://raw.githubusercontent.com/linuxiarznaetacie/ptero-installer/refs/heads/main/blueprint.sh)
            ;;
        4)
            echo "Uruchamiam instalator Wtyczek Blueprint"
            bash <(curl -sSf https://raw.githubusercontent.com/linuxiarznaetacie/ptero-installer/refs/heads/main/addons.sh)
            ;;
        5)
            clear
            echo "Bye Bye <3"
            exit 0
            ;;
        *)
            echo "Niepoprawny wybór, sprobuj ponownie."
            sleep 1
            ;;
    esac

    echo ""
    read -p "Naciśnij Enter, aby kontynuować..."
    clear
done
