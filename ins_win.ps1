# Configuración de archivos
$BasePath = $PSScriptRoot
$CONFIG_FILE = Join-Path $BasePath "server_config.cfg"
$SCRIPT_FILE = Join-Path $BasePath "install_script.ps1"  # Nombre del script actual

# Función para mostrar el banner
function Display-Banner {
    Clear-Host
    Write-Host "========================================================================="
    Write-Host "                  DSC Codes Minecraft Server Installer                   "
    Write-Host "========================================================================="
}

# Función para instalar dependencias
function Install-Dependencies {
    if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
        Write-Host "curl is not installed. Installing curl..."
        choco install curl -y
    } else {
        Write-Host "curl is already installed."
    }

    if (-not (Get-Command jq -ErrorAction SilentlyContinue)) {
        Write-Host "jq is not installed. Installing jq..."
        $jqUrl = "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
        $jqPath = Join-Path $BasePath "jq.exe"
        Invoke-WebRequest -Uri $jqUrl -OutFile $jqPath
    } else {
        Write-Host "jq is already installed."
    }
}

# Función para forzar configuraciones en server.properties
function Force-Stuffs {
    Add-Content -Path (Join-Path $BasePath "server.properties") -Value "motd=Powered by DCS Codes | Change this motd in server.properties"
}

# Función para optimizar el servidor Java
function Optimize-JavaServer {
    Add-Content -Path (Join-Path $BasePath "server.properties") -Value "view-distance=6"
}

# Función para crear el archivo eula.txt
function Create-Eula {
    Set-Content -Path (Join-Path $BasePath "eula.txt") -Value "eula=true"
}

# Función para convertir la marca de tiempo a una fecha legible
function Convert-Date {
    param (
        [string]$timestamp
    )
    if ($timestamp -match '^\d+$') {
        # Si el timestamp es un número, se asume que es epoch time en milisegundos
        [System.DateTimeOffset]::FromUnixTimeMilliseconds($timestamp).ToString("yyyy-MM-dd HH:mm:ss")
    } else {
        # Si el timestamp no es un número, se asume que es una fecha ISO 8601
        [System.DateTime]::Parse($timestamp).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# Función para comparar versiones y fechas
function Compare-Versions {
    param (
        [string]$new_version,
        [string]$new_build,
        [string]$new_date,
        [string]$earlier_version,
        [string]$earlier_build,
        [string]$earlier_date
    )

    if ($new_version -eq $earlier_version) {
        Write-Host "You are downloading the same version of Minecraft."
        if ($new_build -eq $earlier_build) {
            Write-Host "You are downloading the same build."
        } else {
            if ($new_date -gt $earlier_date) {
                Write-Host "You are downloading a newer build of the same version."
            } else {
                Write-Host "You are downloading an older build of the same version."
            }
        }
    } else {
        if ($new_date -gt $earlier_date) {
            Write-Host "You are downloading a newer version of Minecraft."
        } else {
            Write-Host "You are downloading an older version of Minecraft."
        }
    }
}

# Función para descargar el servidor
function Download-Server {
    Write-Host "Which platform are you gonna use?"
    Write-Host "1) PaperMC"
    Write-Host "2) PurpurMC"
    Write-Host "3) Velocity"
    Write-Host "4) FoliaMC"
    $platform_choice = Read-Host
    
    Write-Host "Enter the version you want to download (e.g., 1.19.2 or latest):"
    $version = Read-Host

    $jqPath = Join-Path $BasePath "jq.exe"

    switch ($platform_choice) {
        1 {
            $fork_name = "PaperMC"
            if ($version -eq "latest") {
                $version = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/paper" | Select-Object -ExpandProperty Content | & $jqPath -r '.versions | last'
            }
            $BUILD = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/paper/versions/$version" | Select-Object -ExpandProperty Content | & $jqPath -r '.builds | last'
            $SERVER_FILE = "server.jar"
            $DOWNLOAD_URL = "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$BUILD/downloads/paper-$version-$BUILD.jar"
            $BUILD_TIMESTAMP = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$BUILD" | Select-Object -ExpandProperty Content | & $jqPath -r '.time'
            $BUILD_DATE = Convert-Date -timestamp $BUILD_TIMESTAMP
        }
        2 {
            $fork_name = "PurpurMC"
            if ($version -eq "latest") {
                $version = Invoke-WebRequest -Uri "https://api.purpurmc.org/v2/purpur" | Select-Object -ExpandProperty Content | & $jqPath -r '.versions | last'
            }
            $SERVER_FILE = "server.jar"
            $BUILD = Invoke-WebRequest -Uri "https://api.purpurmc.org/v2/purpur/$version" | Select-Object -ExpandProperty Content | & $jqPath -r '.builds | last'
            $DOWNLOAD_URL = "https://api.purpurmc.org/v2/purpur/$version/$BUILD/download"
            $BUILD_TIMESTAMP = Invoke-WebRequest -Uri "https://api.purpurmc.org/v2/purpur/$version/$BUILD" | Select-Object -ExpandProperty Content | & $jqPath -r '.timestamp'
            $BUILD_DATE = Convert-Date -timestamp $BUILD_TIMESTAMP
        }
        3 {
            $fork_name = "Velocity"
            if ($version -eq "latest") {
                $version = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/velocity" | Select-Object -ExpandProperty Content | & $jqPath -r '.versions | last'
            }
            $BUILD = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/velocity/versions/$version" | Select-Object -ExpandProperty Content | & $jqPath -r '.builds | last'
            $SERVER_FILE = "server.jar"
            $DOWNLOAD_URL = "https://api.papermc.io/v2/projects/velocity/versions/$version/builds/$BUILD/downloads/velocity-$version-$BUILD.jar"
            $BUILD_TIMESTAMP = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/velocity/versions/$version/builds/$BUILD" | Select-Object -ExpandProperty Content | & $jqPath -r '.time'
            $BUILD_DATE = Convert-Date -timestamp $BUILD_TIMESTAMP
        }
        4 {
            $fork_name = "FoliaMC"
            if ($version -eq "latest") {
                $version = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/folia" | Select-Object -ExpandProperty Content | & $jqPath -r '.versions | last'
            }
            $BUILD = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/folia/versions/$version" | Select-Object -ExpandProperty Content | & $jqPath -r '.builds | last'
            $SERVER_FILE = "server.jar"
            $DOWNLOAD_URL = "https://api.papermc.io/v2/projects/folia/versions/$version/builds/$BUILD/downloads/folia-$version-$BUILD.jar"
            $BUILD_TIMESTAMP = Invoke-WebRequest -Uri "https://api.papermc.io/v2/projects/folia/versions/$version/builds/$BUILD" | Select-Object -ExpandProperty Content | & $jqPath -r '.time'
            $BUILD_DATE = Convert-Date -timestamp $BUILD_TIMESTAMP
        }
        default {
            Write-Host "Invalid option"
            exit 1
        }
    }

    # Verificar que la URL de descarga no esté vacía
    if (-not [string]::IsNullOrEmpty($DOWNLOAD_URL)) {
        Write-Host "Selected platform: $fork_name"
        Write-Host "Version: $version"
        Write-Host "Build: $BUILD"
        Write-Host "Build Date: $BUILD_DATE"

        if (Test-Path $SERVER_FILE) {
            Write-Host "File $SERVER_FILE already exists. Do you want to overwrite it? (yes/no)"
            $overwrite_choice = Read-Host
            if ($overwrite_choice -ne "yes") {
                Write-Host "Download cancelled."
                exit 0
            }
        }

        if (Test-Path $CONFIG_FILE) {
            $EARLIER_VERSION = (Select-String -Path $CONFIG_FILE -Pattern "version:" | ForEach-Object { $_.Line.Split(' ')[1] })
            $EARLIER_BUILD = (Select-String -Path $CONFIG_FILE -Pattern "build:" | ForEach-Object { $_.Line.Split(' ')[1] })
            $EARLIER_DATE = (Select-String -Path $CONFIG_FILE -Pattern "date:" | ForEach-Object { $_.Line.Split(' ')[1] })
            Compare-Versions -new_version $version -new_build $BUILD -new_date $BUILD_DATE -earlier_version $EARLIER_VERSION -earlier_build $EARLIER_BUILD -earlier_date $EARLIER_DATE
        }

        Write-Host "Download in progress, please wait..."
        Start-Sleep -Seconds 4
        Force-Stuffs

        # Descargar el archivo y guardarlo con el nombre correcto
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile (Join-Path $BasePath "download_temp.jar")
        if (-not $?) {
            Write-Host "Download failed. Please check the URL and your internet connection."
            exit 1
        }

        # Renombrar el archivo descargado a server.jar
        Rename-Item -Path (Join-Path $BasePath "download_temp.jar") -NewName $SERVER_FILE

        # Verificar el nombre del archivo descargado
        if (-not (Test-Path $SERVER_FILE)) {
            Write-Host "Error: The downloaded file does not match the expected name $SERVER_FILE."
            Get-ChildItem -Path $BasePath
            exit 1
        }

        # Guardar el nombre del archivo en el archivo de configuración
        Set-Content -Path $CONFIG_FILE -Value "file: $SERVER_FILE"
        Add-Content -Path $CONFIG_FILE -Value "version: $version"
        Add-Content -Path $CONFIG_FILE -Value "build: $BUILD"
        Add-Content -Path $CONFIG_FILE -Value "date: $BUILD_DATE"

        Display-Banner
        Write-Host "Download complete"
        Start-Sleep -Seconds 10
        Write-Host ""
        Optimize-JavaServer
    } else {
        Write-Host "Error: The download URL is empty. Please check the version and build information."
        exit 1
    }
}

Install-Dependencies

if (-not (Test-Path (Join-Path $BasePath "eula.txt"))) {
    Display-Banner
    Create-Eula
    Download-Server
} else {
    Display-Banner
    Write-Host "eula.txt found. Skipping download."
    Write-Host "Would you like to re-download the server file? (yes/no)"
    $redownload_choice = Read-Host
    if ($redownload_choice -eq "yes") {
        Display-Banner
        Download-Server
    } else {
        if (Test-Path $CONFIG_FILE) {
            $SERVER_FILE = (Select-String -Path $CONFIG_FILE -Pattern "file:" | ForEach-Object { $_.Line.Split(' ')[1] })
            if (-not (Test-Path $SERVER_FILE)) {
                Write-Host "Error: The specified file does not exist."
                exit 1
            }
        } else {
            Write-Host "Configuration file not found. Please run the setup first."
            exit 1
        }
    }
}

# Salir con un código de éxito
exit 0