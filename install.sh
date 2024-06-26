#!/bin/bash

function display {
    echo -e "\033c"
    echo "========================================================================="
    echo "                  DSC Codes Minecraft Server Installer                   "
    echo "========================================================================="
}

function install_jq {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update && sudo apt-get install -y jq
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install -y jq
        elif [ -x "$(command -v brew)" ]; then
            brew install jq
        else
            echo "Package manager not found. Please install jq manually."
            exit 1
        fi
    else
        echo "jq is already installed."
    fi
}

function forceStuffs {
    echo "motd=Powered by DCS Codes | Change this motd in server.properties" >> server.properties
}

function launchJavaServer {
    java -Xms128M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar $SERVER_FILE nogui
}

FILE=eula.txt

function optimizeJavaServer {
    echo "view-distance=6" >> server.properties
}

install_jq

if [ ! -f "$FILE" ]; then
    display
    sleep 5
    echo "Which platform are you gonna use?"
    echo "1) PaperMC"
    echo "2) PurpurMC"
    echo "3) Velocity"
    echo "4) FoliaMC"
    read -r platform_choice
    
    echo "Enter the version you want to download (e.g., 1.19.2):"
    read -r version

    case $platform_choice in
        1)
            # Obtener el último build para la versión especificada
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="paper-$version-$BUILD.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$BUILD/downloads/paper-$version-$BUILD.jar"
            ;;
        2)
            # Obtener el último build para la versión especificada
            BUILD=$(curl -s "https://api.purpurmc.org/v2/purpur/$version" | jq -r '.builds[-1]')
            SERVER_FILE="purpur-$version-$BUILD.jar"
            DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/$version/builds/$BUILD/downloads/purpur-$version-$BUILD.jar"
            ;;
        3)
            # Obtener el último build para la versión especificada
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="velocity-$version-$BUILD.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/velocity/versions/$version/builds/$BUILD/downloads/velocity-$version-$BUILD.jar"
            ;;
        4)
            # Obtener el último build para la versión especificada
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/folia/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="folia-$version-$BUILD.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/folia/versions/$version/builds/$BUILD/downloads/folia-$version-$BUILD.jar"
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac

    echo "Download in progress, please wait..."
    sleep 4
    forceStuffs

    # Descargar el archivo y guardarlo con el nombre correcto
    curl -L $DOWNLOAD_URL -o download_temp.jar
    if [ $? -ne 0 ]; then
        echo "Download failed. Please check the URL and your internet connection."
        exit 1
    fi

    # Renombrar el archivo descargado
    mv download_temp.jar $SERVER_FILE

    # Verificar el nombre del archivo descargado
    if [ ! -f "$SERVER_FILE" ]; then
        echo "Error: The downloaded file does not match the expected name $SERVER_FILE."
        ls -l
        exit 1
    fi

    display
    echo "Download complete"
    sleep 10
    echo -e ""
    optimizeJavaServer
    launchJavaServer
else
    display
    launchJavaServer
fi
