#!/bin/bash

# Config
mcsmanager_install_path="/home1/mcsmanager"
mcsmanager_donwload_addr="https://github.com/MCSManager/MCSManager/releases/latest/download/mcsmanager_linux_release.tar.gz"
node="v14.19.1"

error=""
arch=$(uname -m)

printf "\033c"

# print func
echo_cyan() {
  printf '\033[1;36m%b\033[0m\n' "$@"
}
echo_red() {
  printf '\033[1;31m%b\033[0m\n' "$@"
}

echo_green() {
  printf '\033[1;32m%b\033[0m\n' "$@"
}

echo_cyan_n() {
  printf '\033[1;36m%b\033[0m' "$@"
}

echo_yellow() {
  printf '\033[1;33m%b\033[0m\n' "$@"
}

# script info
echo_cyan "+----------------------------------------------------------------------
| MCSManager Installer
+----------------------------------------------------------------------
| Copyright © 2023 MCSManager.
+----------------------------------------------------------------------
| Contributors: Nuomiaa, CreeperKong, Unitwk, FunnyShadow
+----------------------------------------------------------------------
"

Red_Error() {
  echo '================================================='
  printf '\033[1;31;40m%b\033[0m\n' "$@"
  echo '================================================='
  exit 1
}


Install_Node() {
  echo_cyan_n "[+] Install Node.JS environment... "

  rm -irf "$node_install_path"

  cd /home1 || exit

  rm -rf  node-"$node"-linux-"$arch".tar.gz

  wget https://nodejs.org/dist/"$node"/node-"$node"-linux-"$arch".tar.gz

  tar -zxf node-"$node"-linux-"$arch".tar.gz

  rm -rf node-"$node"-linux-"$arch".tar.gz

  if [[ -f "$node_install_path"/bin/node ]] && [[ "$("$node_install_path"/bin/node -v)" == "$node" ]]
  then
    echo_green "Success"
  else
    echo_red "Failed"
    Red_Error "[x] Node installation failed!"
  fi

  echo
  echo_yellow "=============== Node.JS Version ==============="
  echo_yellow " node: $("$node_install_path"/bin/node -v)"
  echo_yellow " npm: v$(/usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm -v)"
  echo_yellow "=============== Node.JS Version ==============="
  echo

  sleep 3
}


Install_MCSManager() {
  echo_cyan "[+] Install MCSManager..."

  # stop service
  systemctl stop mcsm-{web,daemon}

  # delete service
  rm -rf /etc/systemd/system/mcsm-daemon.service
  rm -rf /etc/systemd/system/mcsm-web.service
  systemctl daemon-reload

  mkdir -p ${mcsmanager_install_path} || exit

  # cd /home1/mcsmanager
  cd ${mcsmanager_install_path} || exit


  # donwload MCSManager release
  wget ${mcsmanager_donwload_addr}
  tar -zxf mcsmanager_linux_release.tar.gz -o
  rm -rf "${mcsmanager_install_path}/mcsmanager_linux_release.tar.gz"
  
  # echo "[→] cd daemon"
  cd daemon || exit

  echo_cyan "[+] Install MCSManager-Daemon dependencies..."
  /usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm install --production > npm_install_log

  # echo "[←] cd .."
  cd ../web || exit

  echo_cyan "[+] Install MCSManager-Web dependencies..."
  /usr/bin/env "$node_install_path"/bin/node "$node_install_path"/bin/npm install --production > npm_install_log

  echo
  echo_yellow "=============== MCSManager ==============="
  echo_green " Daemon: ${mcsmanager_install_path}/daemon"
  echo_green " Web: ${mcsmanager_install_path}/web"
  echo_yellow "=============== MCSManager ==============="
  echo
  echo_green "[+] MCSManager installation success!"

  sleep 3
}

Create_Service() {
  echo_cyan "[+] Create MCSManager service..."

  echo "
[Unit]
Description=MCSManager Daemon

[Service]
WorkingDirectory=/home1/mcsmanager/daemon
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment=\"PATH=${PATH}\"

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/mcsm-daemon.service

  echo "
[Unit]
Description=MCSManager Web

[Service]
WorkingDirectory=/home1/mcsmanager/web
ExecStart=${node_install_path}/bin/node app.js
ExecReload=/bin/kill -s QUIT $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Environment=\"PATH=${PATH}\"

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/mcsm-web.service

  systemctl daemon-reload
  systemctl enable mcsm-daemon.service --now
  systemctl enable mcsm-web.service --now

  sleep 3

  printf "\n\n"

  echo_yellow "=================================================================="
  echo_green "Installation is complete! Welcome to the MCSManager panel !!!"
    echo_yellow " "
    echo_cyan_n "HTTP Web Service:        "; echo_yellow "http://<Your IP>:23333"
    echo_cyan_n "Daemon Address:          "; echo_yellow "ws://<Your IP>:24444"
    echo_red "You must expose ports 23333 and 24444 to use the service properly on the Internet."
    echo_yellow " "
    echo_cyan "Usage:"
    echo_cyan "systemctl start mcsm-{daemon,web}.service"
    echo_cyan "systemctl stop mcsm-{daemon,web}.service"
    echo_cyan "systemctl restart mcsm-{daemon,web}.service"
    echo_yellow " "
    echo_green "Official Document: https://docs.mcsmanager.com/"
    echo_yellow "=================================================================="
}



# Environmental inspection
if [[ "$arch" == x86_64 ]]; then
  arch=x64
  #echo "[-] x64 architecture detected"
elif [[ $arch == aarch64 ]]; then
  arch=arm64
  #echo "[-] 64-bit ARM architecture detected"
elif [[ $arch == arm ]]; then
  arch=armv7l
  #echo "[-] 32-bit ARM architecture detected"
elif [[ $arch == ppc64le ]]; then
  arch=ppc64le
  #echo "[-] IBM POWER architecture detected"
elif [[ $arch == s390x ]]; then
  arch=s390x
  #echo "[-] IBM LinuxONE architecture detected"
else
  Red_Error "[x] Sorry, this architecture is not supported yet!"
  Red_Error "[x] Please try to install manually: https://github.com/MCSManager/MCSManager#linux"
  exit
fi

# Define the variable Node installation directory
node_install_path="/home1/node-$node-linux-$arch"

# Check network connection
echo_cyan "[-] Architecture: $arch"

# Install related software
echo_cyan_n "[+] Installing dependent software(git,tar)... "
if [[ -x "$(command -v yum)" ]]; then yum install -y git tar > error;
elif [[ -x "$(command -v apt-get)" ]]; then apt-get install -y git tar > error;
elif [[ -x "$(command -v pacman)" ]]; then pacman -Syu --noconfirm git tar > error;
elif [[ -x "$(command -v zypper)" ]]; then sudo zypper --non-interactive install git tar > error;
fi

# Determine whether the relevant software is installed successfully
if [[ -x "$(command -v git)" && -x "$(command -v tar)" ]]
  then
    echo_green "Success"
  else
    echo_red "Failed"
    echo "$error"
    Red_Error "[x] Related software installation failed, please install git and tar packages manually!"
    exit
fi


# Install the Node environment
Install_Node

# Install MCSManager
Install_MCSManager

# Create MCSManager background service
Create_Service
