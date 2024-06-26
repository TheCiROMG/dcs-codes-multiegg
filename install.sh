#!/bin/bash

CONFIG_FILE="server_config.cfg"
SCRIPT_FILE="install_script.sh"  # Nombre del script actual

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
    if [ -f "$CONFIG_FILE" ]; then
        SERVER_FILE="server.jar"
        echo "Launching server with JAR file: $SERVER_FILE"
        java -Xms128M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar "$SERVER_FILE" nogui
    else
        echo "Error: Configuration file not found. Please run the setup first."
        exit 1
    fi
}

function optimizeJavaServer {
    echo "view-distance=6" >> server.properties
}

function downloadServer {
    echo "Which platform are you gonna use?"
    echo "1) PaperMC"
    echo "2) PurpurMC"
    echo "3) Velocity"
    echo "4) FoliaMC"
    read -r platform_choice
    
    echo "Enter the version you want to download (e.g., 1.19.2 or latest):"
    read -r version

    case $platform_choice in
        1)
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.papermc.io/v2/projects/paper" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$BUILD/downloads/paper-$version-$BUILD.jar"
            ;;
        2)
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.purpurmc.org/v2/purpur" | jq -r '.versions[-1]')
            fi
            SERVER_FILE="server.jar"
            BUILD="latest"
            DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/$version/latest/download"
            ;;
        3)
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.papermc.io/v2/projects/velocity" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/velocity/versions/$version/builds/$BUILD/downloads/velocity-$version-$BUILD.jar"
            ;;
        4)
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.papermc.io/v2/projects/folia" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/folia/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/folia/versions/$version/builds/$BUILD/downloads/folia-$version-$BUILD.jar"
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac

    if [ -f "$SERVER_FILE" ]; then
        echo "File $SERVER_FILE already exists. Do you want to overwrite it? (yes/no)"
        read -r overwrite_choice
        if [ "$overwrite_choice" != "yes" ]; then
            echo "Download cancelled."
            exit 0
        fi
    fi

    echo "Download in progress, please wait..."
    sleep 4
    forceStuffs

    # Descargar el archivo y guardarlo con el nombre correcto
    curl -L $DOWNLOAD_URL -o download_temp.jar
    if [ $? -ne 0 ]; then
        echo "Download failed. Please check the URL and your internet connection."
        exit 1
    fi

    # Renombrar el archivo descargado a server.jar
    mv download_temp.jar "$SERVER_FILE"

    # Verificar el nombre del archivo descargado
    if [ ! -f "$SERVER_FILE" ]; then
        echo "Error: The downloaded file does not match the expected name $SERVER_FILE."
        ls -l
        exit 1
    fi

    # Leer la versión anterior si existe
    if [ -f "$CONFIG_FILE" ]; then
        EARLIER_VERSION=$(grep "version:" "$CONFIG_FILE" | cut -d' ' -f2)
        EARLIER_BUILD=$(grep "build:" "$CONFIG_FILE" | cut -d' ' -f2)
    else
        EARLIER_VERSION="none"
        EARLIER_BUILD="none"
    fi

    # Guardar el nombre del archivo en el archivo de configuración
    echo "file: $SERVER_FILE" > "$CONFIG_FILE"
    echo "version: $version" >> "$CONFIG_FILE"
    echo "build: $BUILD" >> "$CONFIG_FILE"
    echo "earlier_version: $EARLIER_VERSION" >> "$CONFIG_FILE"
    echo "earlier_build: $EARLIER_BUILD" >> "$CONFIG_FILE"

    display
    echo "Download complete"
    sleep 10
    echo -e ""
    optimizeJavaServer
}

install_jq

if [ ! -f "eula.txt" ]; then
    display
    downloadServer
else
    echo "eula.txt found. Skipping download."
    echo "Would you like to re-download the server file? (yes/no)"
    read -r redownload_choice
    if [ "$redownload_choice" = "yes" ]; then
        display
        downloadServer
    else
        if [ -f "$CONFIG_FILE" ]; then
            SERVER_FILE=$(grep "file:" "$CONFIG_FILE" | cut -d' ' -f2)
            if [ ! -f "$SERVER_FILE" ]; then
                echo "Error: The specified file does not exist."
                exit 1
            fi
        else
            echo "Configuration file not found. Please run the setup first."
            exit 1
        fi
    fi
fi

display
launchJavaServer

# Eliminar el script después de iniciar el servidor
rm -- "$SCRIPT_FILE"
