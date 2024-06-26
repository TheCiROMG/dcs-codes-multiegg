#!/bin/bash

CONFIG_FILE="server_config.cfg"
SCRIPT_FILE="install_script.sh"  # Nombre del script actual

# Función para mostrar el banner
function display {
    echo -e "\033c"
    echo "========================================================================="
    echo "                  DSC Codes Minecraft Server Installer                   "
    echo "========================================================================="
}

# Función para instalar dependencias
function install_dependencies {
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Installing curl..."
        sudo apt-get update && sudo apt-get install -y curl
    else
        echo "curl is already installed."
    fi

    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        sudo apt-get update && sudo apt-get install -y jq
    else
        echo "jq is already installed."
    fi
}

# Función para forzar configuraciones en server.properties
function forceStuffs {
    echo "motd=Powered by DCS Codes | Change this motd in server.properties" >> server.properties
}

# Función para optimizar el servidor Java
function optimizeJavaServer {
    echo "view-distance=6" >> server.properties
}

# Función para crear el archivo eula.txt
function createEula {
    echo "eula=true" > eula.txt
}

# Función para convertir la marca de tiempo a una fecha legible
function convertDate {
    local timestamp=$1
    date -d "$timestamp" +"%Y-%m-%d %H:%M:%S"
}

# Función para comparar versiones y fechas
function compareVersions {
    local new_version=$1
    local new_build=$2
    local new_date=$3
    local earlier_version=$4
    local earlier_build=$5
    local earlier_date=$6

    if [ "$new_version" = "$earlier_version" ]; then
        echo "You are downloading the same version of Minecraft."
        if [ "$new_build" = "$earlier_build" ]; then
            echo "You are downloading the same build."
        else
            if [ "$new_date" \> "$earlier_date" ]; then
                echo "You are downloading a newer build of the same version."
            else
                echo "You are downloading an older build of the same version."
            fi
        fi
    else
        if [ "$new_date" \> "$earlier_date" ]; then
            echo "You are downloading a newer version of Minecraft."
        else
            echo "You are downloading an older version of Minecraft."
        fi
    fi
}

# Función para descargar el servidor
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
            fork_name="PaperMC"
            if [ "$version" = "latest" ]; then
                version=$(curl -s "https://api.papermc.io/v2/projects/paper" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$BUILD/downloads/paper-$version-$BUILD.jar"
            BUILD_TIMESTAMP=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$BUILD" | jq -r '.time')
            BUILD_DATE=$(convertDate "$BUILD_TIMESTAMP")
            ;;
        2)
            fork_name="PurpurMC"
            if [ "$version" = "latest" ];then
                version=$(curl -s "https://api.purpurmc.org/v2/purpur" | jq -r '.versions[-1]')
            fi
            SERVER_FILE="server.jar"
            BUILD="latest"
            DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/$version/latest/download"
            BUILD_TIMESTAMP=$(curl -s "https://api.purpurmc.org/v2/purpur/$version/latest" | jq -r '.timestamp')
            BUILD_DATE=$(convertDate "$BUILD_TIMESTAMP")
            ;;
        3)
            fork_name="Velocity"
            if [ "$version" = "latest" ];then
                version=$(curl -s "https://api.papermc.io/v2/projects/velocity" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/velocity/versions/$version/builds/$BUILD/downloads/velocity-$version-$BUILD.jar"
            BUILD_TIMESTAMP=$(curl -s "https://api.papermc.io/v2/projects/velocity/versions/$version/builds/$BUILD" | jq -r '.time')
            BUILD_DATE=$(convertDate "$BUILD_TIMESTAMP")
            ;;
        4)
            fork_name="FoliaMC"
            if [ "$version" = "latest" ];then
                version=$(curl -s "https://api.papermc.io/v2/projects/folia" | jq -r '.versions[-1]')
            fi
            BUILD=$(curl -s "https://api.papermc.io/v2/projects/folia/versions/$version" | jq -r '.builds[-1]')
            SERVER_FILE="server.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/folia/versions/$version/builds/$BUILD/downloads/folia-$version-$BUILD.jar"
            BUILD_TIMESTAMP=$(curl -s "https://api.papermc.io/v2/projects/folia/versions/$version/builds/$BUILD" | jq -r '.time')
            BUILD_DATE=$(convertDate "$BUILD_TIMESTAMP")
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac

    echo "Selected platform: $fork_name"
    echo "Version: $version"
    echo "Build: $BUILD"
    echo "Build Date: $BUILD_DATE"

    if [ -f "$SERVER_FILE" ]; then
        echo "File $SERVER_FILE already exists. Do you want to overwrite it? (yes/no)"
        read -r overwrite_choice
        if [ "$overwrite_choice" != "yes" ]; then
            echo "Download cancelled."
            exit 0
        fi
    fi

    if [ -f "$CONFIG_FILE" ]; then
        EARLIER_VERSION=$(grep "version:" "$CONFIG_FILE" | cut -d' ' -f2)
        EARLIER_BUILD=$(grep "build:" "$CONFIG_FILE" | cut -d' ' -f2)
        EARLIER_DATE=$(grep "date:" "$CONFIG_FILE" | cut -d' ' -f2)
        compareVersions "$version" "$BUILD" "$BUILD_DATE" "$EARLIER_VERSION" "$EARLIER_BUILD" "$EARLIER_DATE"
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
    if [ ! -f "$SERVER_FILE" ];then
        echo "Error: The downloaded file does not match the expected name $SERVER_FILE."
        ls -l
        exit 1
    fi

    # Guardar el nombre del archivo en el archivo de configuración
    echo "file: $SERVER_FILE" > "$CONFIG_FILE"
    echo "version: $version" >> "$CONFIG_FILE"
    echo "build: $BUILD" >> "$CONFIG_FILE"
    echo "date: $BUILD_DATE" >> "$CONFIG_FILE"

    display
    echo "Download complete"
    sleep 10
    echo -e ""
    optimizeJavaServer
}

install_dependencies

if [ ! -f "eula.txt" ];then
    display
    createEula
    downloadServer
else
    echo "eula.txt found. Skipping download."
    echo "Would you like to re-download the server file? (yes/no)"
    read -r redownload_choice
    if [ "$redownload_choice" = "yes" ];then
        display
        downloadServer
    else
        if [ -f "$CONFIG_FILE" ];then
            SERVER_FILE=$(grep "file:" "$CONFIG_FILE" | cut -d' ' -f2)
            if [ ! -f "$SERVER_FILE" ];then
                echo "Error: The specified file does not exist."
                exit 1
            fi
        else
            echo "Configuration file not found. Please run the setup first."
            exit 1
        fi
    fi
fi

# Salir con un código de éxito
exit 0
