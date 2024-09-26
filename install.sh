#!/bin/bash
# Reset
Color_Off='\033[0m'       # Text Reset
# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
# Background
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow

if [ $SUDO_USER ]; then user=$SUDO_USER; else user=$(whoami); fi

# Checks if a command exists
exists()
{
    command -v "$1" >/dev/null 2>&1
}

# Prints install message and asks for confirmation
startup_install()
{
    printf "${On_Yellow}#######################################################${Color_Off}\n"
    printf "${On_Yellow}#${On_Green}        Ascension Launcher: Installer                ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}# ################################################### #${Color_Off}\n"
    printf "${On_Yellow}#${On_Green} Please run as a normal user. We only require        ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}#${On_Green} sudo (root) permission for installing dependencies. ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}#${On_Red}                 press 'y' to continue               ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}#######################################################${Color_Off}\n"

    read -p "Press 'y' to continue: " -n 1 -r
    echo    # move to a new line

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        printf "${On_Red}Cancelling..${Color_Off}\n"
        exit
    fi
    clear
}

#Installs Wine and Winetricks
install_wine()
{
    printf "${Yellow}Updating apt and installing Wine.\n"
    if exists apt; then
        printf "${Green}- Detected apt..\n"
        sudo apt update -qq
        sudo apt install -qqy wine winetricks mono-complete
    elif exists yum; then
        printf "${Green}- Detected yum..\n"
        sudo yum update -q
        sudo yum install -qy wine winetricks mono-complete
    elif exists pacman; then
        printf "${Green}- Detected pacman..\n"
        sudo pacman -Syu
        sudo pacman -Sy wine winetricks mono --noconfirm
    else
        printf "${On_Red}Unknown platform."
        printf "${On_Red}We expect that you will install wine and winetricks yourself."
    fi

    if ! exists wine; then
        printf "${On_Red}!! Wine was not installed. Please install it manually."
        exit
    fi

    if ! exists winetricks; then
        printf "${On_Red}!! Winetricks was not installed. Please install it manually."
        exit
    fi

    if ! exists wget; then
        printf "${On_Red}!! wget was not installed. Please install it manually."
        exit
    fi

    if ! exists mono; then
        printf "${On_Red}!! mono was not installed. Please install it manually."
        exit
    fi
}

#Configures Wine for Ascension
configure_wine()
{
    printf "${Yellow}Configuring Wine for Ascension.${Color_Off} \n"
    export WINEPREFIX="/home/$user/.config/projectascension/WoW"
    export WINEARCH=win32

    printf "${Green}Installing wine-mono${Color_Off} \n"
    wget https://dl.winehq.org/wine/wine-mono/9.1.0/wine-mono-9.1.0-x86.msi
    wine msiexec /i wine-mono-9.1.0-x86.msi
    rm -rf wine-mono-9.1.0-x86.msi

    printf "${Green}Installing dependencies via WineTricks..${Color_Off}\n"
    winetricks win10 ie8 corefonts dotnet48 vcrun2015

    read -p "Would you like to install DXVK (A Vulkan-based translation layer for Direct3D 9/10/11 which allows running 3D applications on Linux using Wine.)? (y/n)" -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        printf "${Green}Downloading DXVK${Color_Off} \n"
        wget -q https://github.com/doitsujin/dxvk/releases/download/v2.3.1/dxvk-2.3.1.tar.gz
        
        printf "${Green}Unpacking DXVK${Color_Off} \n"
        tar xzf dxvk-2.3.1.tar.gz

        printf "${Green}Installing DXVK${Color_Off} "
        chmod +x dxvk-2.3.1/setup_dxvk.sh
        bash dxvk-2.3.1/setup_dxvk.sh install
    fi
}

#Installs the Ascension Launcher and sets up the directory
install_launcher()
{
    local flag=$1

    download_url="https://api.ascension.gg/api/bootstrap/launcher/latest?unix=1"
    dir="/home/$user/ascension-launcher"
    printf "${Yellow}Installing Ascension Launcher to $dir${Color_Off}\n"

    mkdir -p $dir
    wget -O $dir/ascension-launcher.AppImage $download_url
    chmod +x $dir/ascension-launcher.AppImage
    
    if [ $flag -eq 0 ]; then
        cp "${BASH_SOURCE}" $dir/update.sh
        chmod +x $dir/update.sh
    fi
}

# Prints update message and asks for confirmation
startup_update()
{
    printf "${On_Yellow}#######################################################${Color_Off}\n"
    printf "${On_Yellow}#${On_Green}          Ascension Launcher: Updater                ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}# ################################################### #${Color_Off}\n"
    printf "${On_Yellow}#${On_Green} Please run as a normal user. We only require        ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}#${On_Green} sudo (root) permission for installing dependencies. ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}#${On_Red}                 press 'Y' to continue               ${On_Yellow}#${Color_Off} \n"
    printf "${On_Yellow}#######################################################${Color_Off}\n"

    read -p "Press 'Y' to continue: " -n 1 -r
    echo    # move to a new line

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        printf "${On_Red}Cancelling..${Color_Off}\n"
        exit
    fi
    clear
}

# Closes running instances of the launcher
close_running_launchers()
{
    killall "projectascension"
    killall "electron"
}

make_desktop_icon()
{
    touch /home/$user/Desktop/ProjectAscension.desktop

    echo "[Desktop Entry]" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "Name=Ascension" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "Exec=projectascension" >> /home/$user/Desktop/ProjectAscension.desktop
    #echo "Icon=/home/$user/ascension-launcher/ascension.png" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "Type=Application" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "Categories=Game;" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "Terminal=false" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "StartupNotify=true" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "Comment=Ascension Launcher" >> /home/$user/Desktop/ProjectAscension.desktop
    echo "Path=/home/$user/ascension-launcher" >> /home/$user/Desktop/ProjectAscension.desktop

    chmod +x /home/$user/Desktop/ProjectAscension.desktop
}

set_application_sym_link()
{
    dir="/home/$user/ascension-launcher"
    sudo ln -s $dir/ascension-launcher.AppImage /usr/bin/projectascension
}

# Check if we are root, if so exit
if [ $(id -u) -eq 0 ]; then
    printf "${On_Red}Please do not run as root.${Color_Off}\n"
    exit
fi

# Check if we have any arguments
# If not installing, else we are updating
if [ "$#" -eq 0 ]; then
    startup_install # Prints install message and asks for confirmation
    install_wine # Installs Wine and Winetricks
    configure_wine # Configures Wine for Ascension
    install_launcher 0 # Installs the Ascension Launcher and sets updater up
    set_application_sym_link # Sets up a symlink for the launcher
    make_desktop_icon # Creates a desktop icon
    projectascension # Starts the launcher
else
    startup_update # Prints update message and asks for confirmation
    close_running_launchers # Closes running instances of the launcher
    install_wine # Installs Wine and Winetricks
    install_launcher 1 # Updates just the Ascension Launcher
    projectascension # Starts the launcher
fi
