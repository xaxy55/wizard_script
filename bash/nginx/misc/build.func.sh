variables() {
  NSAPP=$(echo ${APP,,} | tr -d ' ') # This function sets the NSAPP variable by converting the value of the APP variable to lowercase and removing any spaces.
  var_install="${NSAPP}-install"     # sets the var_install variable by appending "-install" to the value of NSAPP.
  INTEGER='^[0-9]+([.][0-9]+)?$'     # it defines the INTEGER regular expression pattern.
}

# This function sets various color variables using ANSI escape codes for formatting text in the terminal.
color() {
  YW=$(echo "\033[33m")
  BL=$(echo "\033[36m")
  RD=$(echo "\033[01;31m")
  BGN=$(echo "\033[4;92m")
  GN=$(echo "\033[1;92m")
  DGN=$(echo "\033[32m")
  CL=$(echo "\033[m")
  CM="${GN}✓${CL}"
  CROSS="${RD}✗${CL}"
  BFR="\\r\\033[K"
  HOLD=" "
}

# This function enables error handling in the script by setting options and defining a trap for the ERR signal.
catch_errors() {
  set -Eeuo pipefail
  trap 'error_handler $LINENO "$BASH_COMMAND"' ERR
}

# This function is called when an error occurs. It receives the exit code, line number, and command that caused the error, and displays an error message.
error_handler() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local exit_code="$?"
  local line_number="$1"
  local command="$2"
  local error_message="${RD}[ERROR]${CL} in line ${RD}$line_number${CL}: exit code ${RD}$exit_code${CL}: while executing command ${YW}$command${CL}"
  echo -e "\n$error_message\n"
}

# This function displays a spinner.
spinner() {
    local chars="/-\|"
    local spin_i=0
    printf "\e[?25l"
    while true; do
        printf "\r \e[36m%s\e[0m" "${chars:spin_i++%${#chars}:1}"
        sleep 0.1
    done
}

# This function displays an informational message with a yellow color.
msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}   "
  spinner &
  SPINNER_PID=$!
}

# This function displays a success message with a green color.
msg_ok() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

# This function displays a error message with a red color.
msg_error() {
  if [ -n "$SPINNER_PID" ] && ps -p $SPINNER_PID > /dev/null; then kill $SPINNER_PID > /dev/null; fi
  printf "\e[?25h"
  local msg="$1"
  echo -e "${BFR} ${CROSS} ${RD}${msg}${CL}"
}

# Check if the shell is using bash
shell_check() {
  if [[ "$(basename "$SHELL")" != "bash" ]]; then
    clear
    msg_error "Your default shell is currently not set to Bash. To use these scripts, please switch to the Bash shell."
    echo -e "\nExiting..."
    sleep 2
    exit
  fi
}

# Run as root only
root_check() {
  if [[ "$(id -u)" -ne 0 || $(ps -o comm= -p $PPID) == "sudo" ]]; then
    clear
    msg_error "Please run this script as root."
    echo -e "\nExiting..."
    sleep 2
    exit
  fi
}

# This function displays the default values for various settings.
echo_default() {
  echo -e "${DGN}Using Distribution: ${BGN}$var_os${CL}"
  echo -e "${DGN}Using $var_os Version: ${BGN}$var_version${CL}"
  echo -e "${DGN}Using Container Type: ${BGN}$CT_TYPE${CL}"
  echo -e "${DGN}Using Root Password: ${BGN}Automatic Login${CL}"
  echo -e "${DGN}Using Container ID: ${BGN}$NEXTID${CL}"
  echo -e "${DGN}Using Hostname: ${BGN}$NSAPP${CL}"
  echo -e "${DGN}Using Disk Size: ${BGN}$var_disk${CL}${DGN}GB${CL}"
  echo -e "${DGN}Allocated Cores ${BGN}$var_cpu${CL}"
  echo -e "${DGN}Allocated Ram ${BGN}$var_ram${CL}"
  echo -e "${DGN}Using Bridge: ${BGN}vmbr0${CL}"
  echo -e "${DGN}Using Static IP Address: ${BGN}dhcp${CL}"
  echo -e "${DGN}Using Gateway IP Address: ${BGN}Default${CL}"
  echo -e "${DGN}Using Apt-Cacher IP Address: ${BGN}Default${CL}"
  echo -e "${DGN}Disable IPv6: ${BGN}No${CL}"
  echo -e "${DGN}Using Interface MTU Size: ${BGN}Default${CL}"
  echo -e "${DGN}Using DNS Search Domain: ${BGN}Host${CL}"
  echo -e "${DGN}Using DNS Server Address: ${BGN}Host${CL}"
  echo -e "${DGN}Using MAC Address: ${BGN}Default${CL}"
  echo -e "${DGN}Using VLAN Tag: ${BGN}Default${CL}"
  echo -e "${DGN}Enable Root SSH Access: ${BGN}No${CL}"
  echo -e "${DGN}Enable Verbose Mode: ${BGN}No${CL}"
  echo -e "${BL}Creating a ${APP} LXC using the above default settings${CL}"
}

# This function is called when the user decides to exit the script. It clears the screen and displays an exit message.
exit-script() {
  clear
  echo -e "⚠  User exited script \n"
  exit
}

# This function allows the user to configure advanced settings for the script.
advanced_settings() {
  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Here is an instructional tip:" "To make a selection, use the Spacebar." 8 58
  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "Default distribution for $APP" "${var_os} ${var_version} \n \nIf the default Linux distribution is not adhered to, script support will be discontinued. \n" 10 58
  if [ "$var_os" != "alpine" ]; then
    var_os=""
    while [ -z "$var_os" ]; do
      if var_os=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "DISTRIBUTION" --radiolist "Choose Distribution:" 10 58 2 \
        "debian" "" OFF \
        "ubuntu" "" OFF \
        3>&1 1>&2 2>&3); then
        if [ -n "$var_os" ]; then
          echo -e "${DGN}Using Distribution: ${BGN}$var_os${CL}"
        fi
      else
        exit-script
      fi
    done
  fi

  if [ "$var_os" == "debian" ]; then
    var_version=""
    while [ -z "$var_version" ]; do
      if var_version=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "DEBIAN VERSION" --radiolist "Choose Version" 10 58 2 \
        "11" "Bullseye" OFF \
        "12" "Bookworm" OFF \
        3>&1 1>&2 2>&3); then
        if [ -n "$var_version" ]; then
          echo -e "${DGN}Using $var_os Version: ${BGN}$var_version${CL}"
        fi
      else
        exit-script
      fi
    done
  fi

  if [ "$var_os" == "ubuntu" ]; then
    var_version=""
    while [ -z "$var_version" ]; do
      if var_version=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UBUNTU VERSION" --radiolist "Choose Version" 10 58 3 \
        "20.04" "Focal" OFF \
        "22.04" "Jammy" OFF \
        "24.04" "Noble" OFF \
        3>&1 1>&2 2>&3); then
        if [ -n "$var_version" ]; then
          echo -e "${DGN}Using $var_os Version: ${BGN}$var_version${CL}"
        fi
      else
        exit-script
      fi
    done
  fi

  while true; do
    if PW1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --passwordbox "\nSet Root Password (needed for root ssh access)" 9 58 --title "PASSWORD (leave blank for automatic login)" 3>&1 1>&2 2>&3); then
      if [[ ! -z "$PW1" ]]; then
        if [[ "$PW1" == *" "* ]]; then
          whiptail --msgbox "Password cannot contain spaces. Please try again." 8 58
        elif [ ${#PW1} -lt 5 ]; then
          whiptail --msgbox "Password must be at least 5 characters long. Please try again." 8 58
        else
          if PW2=$(whiptail --backtitle "Proxmox VE Helper Scripts" --passwordbox "\nVerify Root Password" 9 58 --title "PASSWORD VERIFICATION" 3>&1 1>&2 2>&3); then
            if [[ "$PW1" == "$PW2" ]]; then
              PW="-password $PW1"
              echo -e "${DGN}Using Root Password: ${BGN}********${CL}"
              break
            else
              whiptail --msgbox "Passwords do not match. Please try again." 8 58
            fi
          else
            exit-script
          fi
        fi
      else
        PW1="Automatic Login"
        PW=""
        echo -e "${DGN}Using Root Password: ${BGN}$PW1${CL}"
        break
      fi
    else
      exit-script
    fi
  done


  if CT_ID=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Container ID" 8 58 $NEXTID --title "CONTAINER ID" 3>&1 1>&2 2>&3); then
    if [ -z "$CT_ID" ]; then
      CT_ID="$NEXTID"
      echo -e "${DGN}Using Container ID: ${BGN}$CT_ID${CL}"
    else
      echo -e "${DGN}Container ID: ${BGN}$CT_ID${CL}"
    fi
  else
    exit
  fi

  if CT_NAME=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Hostname" 8 58 $NSAPP --title "HOSTNAME" 3>&1 1>&2 2>&3); then
    if [ -z "$CT_NAME" ]; then
      HN="$NSAPP"
    else
      HN=$(echo ${CT_NAME,,} | tr -d ' ')
    fi
    echo -e "${DGN}Using Hostname: ${BGN}$HN${CL}"
  else
    exit-script
  fi

  if DISK_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Disk Size in GB" 8 58 $var_disk --title "DISK SIZE" 3>&1 1>&2 2>&3); then
    if [ -z "$DISK_SIZE" ]; then
      DISK_SIZE="$var_disk"
      echo -e "${DGN}Using Disk Size: ${BGN}$DISK_SIZE${CL}"
    else
      if ! [[ $DISK_SIZE =~ $INTEGER ]]; then
        echo -e "${RD}⚠ DISK SIZE MUST BE AN INTEGER NUMBER!${CL}"
        advanced_settings
      fi
      echo -e "${DGN}Using Disk Size: ${BGN}$DISK_SIZE${CL}"
    fi
  else
    exit-script
  fi

  if CORE_COUNT=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate CPU Cores" 8 58 $var_cpu --title "CORE COUNT" 3>&1 1>&2 2>&3); then
    if [ -z "$CORE_COUNT" ]; then
      CORE_COUNT="$var_cpu"
      echo -e "${DGN}Allocated Cores: ${BGN}$CORE_COUNT${CL}"
    else
      echo -e "${DGN}Allocated Cores: ${BGN}$CORE_COUNT${CL}"
    fi
  else
    exit-script
  fi

  if RAM_SIZE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Allocate RAM in MiB" 8 58 $var_ram --title "RAM" 3>&1 1>&2 2>&3); then
    if [ -z "$RAM_SIZE" ]; then
      RAM_SIZE="$var_ram"
      echo -e "${DGN}Allocated RAM: ${BGN}$RAM_SIZE${CL}"
    else
      echo -e "${DGN}Allocated RAM: ${BGN}$RAM_SIZE${CL}"
    fi
  else
    exit-script
  fi

  if BRG=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Bridge" 8 58 vmbr0 --title "BRIDGE" 3>&1 1>&2 2>&3); then
    if [ -z "$BRG" ]; then
      BRG="vmbr0"
      echo -e "${DGN}Using Bridge: ${BGN}$BRG${CL}"
    else
      echo -e "${DGN}Using Bridge: ${BGN}$BRG${CL}"
    fi
  else
    exit-script
  fi

  while true; do
    NET=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Static IPv4 CIDR Address (/24)" 8 58 dhcp --title "IP ADDRESS" 3>&1 1>&2 2>&3)
    exit_status=$?
    if [ $exit_status -eq 0 ]; then
      if [ "$NET" = "dhcp" ]; then
        echo -e "${DGN}Using IP Address: ${BGN}$NET${CL}"
        break
      else
        if [[ "$NET" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
          echo -e "${DGN}Using IP Address: ${BGN}$NET${CL}"
          break
        else
          whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox "$NET is an invalid IPv4 CIDR address. Please enter a valid IPv4 CIDR address or 'dhcp'" 8 58
        fi
      fi
    else
      exit-script
    fi
  done

  if [ "$NET" != "dhcp" ]; then
    while true; do
      GATE1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Enter gateway IP address" 8 58 --title "Gateway IP" 3>&1 1>&2 2>&3)
      if [ -z "$GATE1" ]; then
        whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox "Gateway IP address cannot be empty" 8 58
      elif [[ ! "$GATE1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox "Invalid IP address format" 8 58
      else
        GATE=",gw=$GATE1"
        echo -e "${DGN}Using Gateway IP Address: ${BGN}$GATE1${CL}"
        break
      fi
    done
  else
    GATE=""
    echo -e "${DGN}Using Gateway IP Address: ${BGN}Default${CL}"
  fi

  if [ "$var_os" == "alpine" ]; then
    APT_CACHER=""
    APT_CACHER_IP=""
  else
    if APT_CACHER_IP=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set APT-Cacher IP (leave blank for default)" 8 58 --title "APT-Cacher IP" 3>&1 1>&2 2>&3); then
      APT_CACHER="${APT_CACHER_IP:+yes}"
      echo -e "${DGN}Using APT-Cacher IP Address: ${BGN}${APT_CACHER_IP:-Default}${CL}"
    else
      exit-script
    fi
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "IPv6" --yesno "Disable IPv6?" 10 58); then
    DISABLEIP6="yes"
  else
    DISABLEIP6="no"
  fi
  echo -e "${DGN}Disable IPv6: ${BGN}$DISABLEIP6${CL}"

  if MTU1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set Interface MTU Size (leave blank for default)" 8 58 --title "MTU SIZE" 3>&1 1>&2 2>&3); then
    if [ -z $MTU1 ]; then
      MTU1="Default"
      MTU=""
    else
      MTU=",mtu=$MTU1"
    fi
    echo -e "${DGN}Using Interface MTU Size: ${BGN}$MTU1${CL}"
  else
    exit-script
  fi

  if SD=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a DNS Search Domain (leave blank for HOST)" 8 58 --title "DNS Search Domain" 3>&1 1>&2 2>&3); then
    if [ -z $SD ]; then
      SX=Host
      SD=""
    else
      SX=$SD
      SD="-searchdomain=$SD"
    fi
    echo -e "${DGN}Using DNS Search Domain: ${BGN}$SX${CL}"
  else
    exit-script
  fi

  if NX=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a DNS Server IP (leave blank for HOST)" 8 58 --title "DNS SERVER IP" 3>&1 1>&2 2>&3); then
    if [ -z $NX ]; then
      NX=Host
      NS=""
    else
      NS="-nameserver=$NX"
    fi
    echo -e "${DGN}Using DNS Server IP Address: ${BGN}$NX${CL}"
  else
    exit-script
  fi

  if MAC1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a MAC Address(leave blank for default)" 8 58 --title "MAC ADDRESS" 3>&1 1>&2 2>&3); then
    if [ -z $MAC1 ]; then
      MAC1="Default"
      MAC=""
    else
      MAC=",hwaddr=$MAC1"
      echo -e "${DGN}Using MAC Address: ${BGN}$MAC1${CL}"
    fi
  else
    exit-script
  fi

  if VLAN1=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "Set a Vlan(leave blank for default)" 8 58 --title "VLAN" 3>&1 1>&2 2>&3); then
    if [ -z $VLAN1 ]; then
      VLAN1="Default"
      VLAN=""
    else
      VLAN=",tag=$VLAN1"
    fi
    echo -e "${DGN}Using Vlan: ${BGN}$VLAN1${CL}"
  else
    exit-script
  fi

  if [[ "$PW" == -password* ]]; then
    if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "SSH ACCESS" --yesno "Enable Root SSH Access?" 10 58); then
      SSH="yes"
    else
      SSH="no"
    fi
    echo -e "${DGN}Enable Root SSH Access: ${BGN}$SSH${CL}"
  else
    SSH="no"
    echo -e "${DGN}Enable Root SSH Access: ${BGN}$SSH${CL}"
  fi

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "VERBOSE MODE" --yesno "Enable Verbose Mode?" 10 58); then
    VERB="yes"
  else
    VERB="no"
  fi
  echo -e "${DGN}Enable Verbose Mode: ${BGN}$VERB${CL}"

  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "ADVANCED SETTINGS COMPLETE" --yesno "Ready to create ${APP} LXC?" 10 58); then
    echo -e "${RD}Creating a ${APP} LXC using the above advanced settings${CL}"
  else
    clear
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

install_script() {
  shell_check
  root_check

  if systemctl is-active -q ping-instances.service; then
    systemctl -q stop ping-instances.service
  fi
  NEXTID=$(pvesh get /cluster/nextid)
  timezone=$(cat /etc/timezone)
  header_info
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "SETTINGS" --yesno "Use Default Settings?" --no-button Advanced 10 58); then
    header_info
    echo -e "${BL}Using Default Settings${CL}"
    default_settings
  else
    header_info
    echo -e "${RD}Using Advanced Settings${CL}"
    advanced_settings
  fi
}

start() {
  # if run on host create the container
  if command -v pveversion >/dev/null 2>&1; then
    if ! (whiptail --backtitle "Proxmox VE Helper Scripts" --title "${APP} LXC" --yesno "This will create a New ${APP} LXC. Proceed?" 10 58); then
      clear
      echo -e "⚠  User exited script \n"
      exit
    fi
    SPINNER_PID=""
    install_script
  fi

  if ! command -v pveversion >/dev/null 2>&1; then
    # Example of a Menu
    CHOICE=$(whiptail --title "Menu Example" --menu "Choose an option:" 15 40 4 \
        "1" "Setup new proxy host" \
        "2" "Update Nginx host" \
        "3" "Check Nginx config" \
        "4" "Dry run new proxy host cert" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      if [ $CHOICE = 1 ]; then
        SPINNER_PID=""
        app_new_config_script
      fi
      if [ $CHOICE = 2 ]; then
        # UPDATE script
        if ! (whiptail --backtitle "Proxmox VE Helper Scripts" --title "${APP} LXC UPDATE" --yesno "Support/Update functions for ${APP} LXC.  Proceed?" 10 58); then
          clear
          echo -e "⚠  User exited script \n"
          exit
        fi
          SPINNER_PID=""
          update_script
        fi
      fi
    else
      clear
      echo -e "⚠  User exited script \n"
      exit
    fi
}

# This function sets the description of the container.
description() {
  IP=$(pct exec "$CTID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
  pct set "$CTID" -description "<div align='center'><a href='https://Helper-Scripts.com' target='_blank' rel='noopener noreferrer'><img src='https://raw.githubusercontent.com/tteck/Proxmox/main/misc/images/logo-81x112.png'/></a>

  # ${APP} LXC

  <a href='https://ko-fi.com/proxmoxhelperscripts'><img src='https://img.shields.io/badge/&#x2615;-Buy me a coffee-blue' /></a>
  </div>"
  if [[ -f /etc/systemd/system/ping-instances.service ]]; then
    systemctl start ping-instances.service
  fi
}