#!/bin/bash

function display {
    echo -e "\033c"
    echo "========================================================================="
    echo "                  DSC Codes Minecraft Server Installer                   "
    echo "========================================================================="
}

function forceStuffs {
    curl -O https://cdn.discordapp.com/attachments/946264593746001960/969858011357151252/FE_1.png
    echo "motd=Powered by DCS Codes | Change this motd in server.properties" >> server.properties
}

function launchJavaServer {
    java -Xms128M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar $SERVER_FILE nogui
}

FILE=eula.txt

function optimizeJavaServer {
    echo "view-distance=6" >> server.properties
}

if [ ! -f "$FILE" ]; then
    mkdir -p plugins
    display
    sleep 5
    echo "Which platform are you gonna use?"
    echo "1) PaperMC"
    echo "2) PurpurMC"
    echo "3) Waterfall"
    read -r platform_choice
    
    echo "Enter the version you want to download (e.g., 1.19.2):"
    read -r version

    case $platform_choice in
        1)
            SERVER_FILE="paper-$version.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$version/builds/latest/downloads/paper-$version-latest.jar"
            ;;
        2)
            SERVER_FILE="purpur-$version.jar"
            DOWNLOAD_URL="https://api.purpurmc.org/v2/purpur/$version/latest/download"
            ;;
        3)
            SERVER_FILE="waterfall-$version.jar"
            DOWNLOAD_URL="https://api.papermc.io/v2/projects/waterfall/versions/$version/builds/latest/downloads/waterfall-$version-latest.jar"
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac

    sleep 1
    echo "Starting the download for $platform_choice $version, please wait"
    sleep 4
    forceStuffs
    curl -O $DOWNLOAD_URL
    display
    echo "Download complete"
    sleep 10
    echo -e ""
    optimizeJavaServer
    launchJavaServer
else
    if [ -f plugins ]; then
        mkdir plugins
    fi
    if [ -f BungeeCord.jar ]; then
        display
        java -Xms512M -Xmx512M -jar BungeeCord.jar
    else
        display
        launchJavaServer
    fi
fi
