#!/bin/bash

CONFIG_FILE="server_config.cfg"
SCRIPT_FILE="install_script.sh"  # Nombre del script actual
TEMP_CONFIG_FILE="temp_config.cfg"

function display {
    echo -e "\033c"
    echo "========================================================================="
    echo "                  DSC Codes Minecraft Server Installer                   "
    echo "========================================================================="
}

function install_dependencies {
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing curl..."
        apk update && apk add curl
    else
        echo "curl is already installed."
    fi

    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        apk add jq
    else
        echo "jq is already installed."
    fi
}

function forceStuffs {
    echo "motd=Powered by DCS Codes | Change this motd in server.properties" >> server.properties
}

function optimizeJavaServer {
    echo "view-distance=6" >> server.properties
}

function downloadServer {
    display
    echo "Which platform are you gonna use?"
    echo "1) PaperMC"
    echo "2) PurpurMC"
    echo "3) Velocity"
    echo "4) FoliaMC"
    read -r platform_choice
    echo "platform_choice=$platform_choice" > $TEMP_CONFIG_FILE
    
    display
    echo "Enter the version you want to download (e.g., 1.19.2 or latest):"
    read -r version
    echo "version=$version" >> $TEMP_CONFIG_FILE

    source $TEMP_CONFIG_FILE

    case $platform_choice in
        1)
            fork_name="PaperMC"
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.papermc.io/v2/projects/paper" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$BUILD/downloads/paper-$version-$BUILD.jar"
            ;;
        2)
            fork_name="PurpurMC"
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.purpurmc.org/v2/purpur" | jq -r '.versions[-1]')
            fi
            SERVER_FILE="server.jar"
            BUILD="latest"
            DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/$version/latest/download"
            ;;
        3)
            fork_name="Velocity"
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.papermc.io/v2/projects/velocity" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/velocity/versions/$version/builds/$BUILD/downloads/velocity-$version-$BUILD.jar"
            ;;
        4)
            fork_name="FoliaMC"
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

    display
    echo "Selected platform: $fork_name"
    echo "Version: $version"
    echo "Build: $BUILD"

    if [ -f "$SERVER_FILE" ]; then
        display
        echo "File $SERVER_FILE already exists. Do you want to overwrite it? (yes/no)"
        read -r overwrite_choice
        if [ "$overwrite_choice" != "yes" ]; then
            echo "Download cancelled."
            exit 0
        fi
    fi

    display
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

install_dependencies

if [ ! -f "eula.txt" ]; then
    display
    downloadServer
else
    display
    echo "eula.txt found. Skipping download."
    display
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

# Eliminar el script después de completar la configuración
rm -- "$SCRIPT_FILE"
rm -- "$TEMP_CONFIG_FILE"

# Salir con un código de éxito
exit 0
