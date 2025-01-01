#!/bin/bash
### Author: Tin Trung Ngo
### Contact: trungtinth1011@gmail.com

# Global variables
HOSTNAME=$(uname -n)
CURRENT_DAY=$(date)
CURRENT_TIMESTAMP="$(date +'%Y%b%d')"
DIR="report"-"$HOSTNAME"-"$CURRENT_TIMESTAMP"
FUNCTIONS=("System Information" "Resources Utilization" "System Services" "Network Status" "Generate report" "Clean up report" "Check Usage" "Exit")
HAS_CURL="$(type "curl" &>/dev/null && echo true || echo false)"
HAS_WGET="$(type "wget" &>/dev/null && echo true || echo false)"

# Detect current system architecture.
case $(uname -m) in
  aarch64) ARCH="arm64" ;;
  arm64) ARCH="arm64" ;;
  x86_64) ARCH="amd64" ;;
esac

# Detect current OS.
case $(echo `uname`|tr '[:upper:]' '[:lower:]') in
  linux) OS="linux" ;;
  darwin) OS="darwin" ;;
  mingw*|cygwin*) OS='windows';;
esac

# Runs the given command as root (detects if we are root already)
runAsRoot() {
  [ $EUID -ne 0 ] && sudo "${@}" || "${@}"
}


# Create report directory
createDir() {
  [ ! -d ./"$DIR" ] && mkdir ./"$DIR" && chown -R $USER ./"$DIR" && printf "Directory "$DIR" created.\n" || printf "Directory $DIR existed!\n"
}


# Cleanup report directory
deleteDir() {
  [ -d "$DIR" ] && rm -rf "./$DIR" && printf "Directory $DIR cleaned.\n" || printf "Directory $DIR does not exist!\n"
  printSelection
}


# Printout script usage
printUsage() {
  printf "\n"
  printf "THIS SCRIPT OFFERS THE FOLLOWING OPTIONS:\n"
  printf "\tSystem Information\n"
  printf "\t\tShow information about current system\n"
  printf "\tResources Utilization\n"
  printf "\t\tShow current resources utilization (CPU,RAM,Disk,...)\n"
  printf "\tSystem Services\n"
  printf "\t\tShow current running services and processes\n"
  printf "\tNetwork Status\n"
  printf "\t\tShow network DNS configuration and networking services\n"
  printf "\tGenerate report\n"
  printf "\t\tGenerate a report folder include above information\n"
  printf "\tClean up report\n"
  printf "\t\tCleanup the report folder\n"
  printf "\tCheck Usage\n"
  printf "\t\tShow script usage\n"
  printSelection
}


# Return selection menu when a function is finish
printSelection() {
  printf "\n"
  case $OS in
    darwin)
      for ((i = 1; i <= "${#FUNCTIONS[@]}"; i++)); do printf "$i) ${FUNCTIONS[$i]}\t"; done ;;
    linux)
      for i in "${!FUNCTIONS[@]}"; do printf "$(($i + 1))) ${FUNCTIONS[$i]}\t"; done ;;
  esac
  printf "\n"
}


# Show information about current system
systemCheck() {
case $OS in
    darwin)
      system_profiler SPHardwareDataType SPSoftwareDataType ;;
    linux)
      hostnamectl ;;
    *)
      printf "Unknown system architecture\n" ;;
  esac
printSelection
}

systemCheck-report() {
  if [ "$(ls "./$DIR" | grep "systeminfo.txt")" = "" ]; then
    case $OS in
      darwin)
        echo "System Information" >>./$DIR/systeminfo.txt
        system_profiler SPHardwareDataType SPSoftwareDataType >>./$DIR/systeminfo.txt
        printf "System Information reported!\n" ;;
      linux)
        echo "System Information" >>./$DIR/systeminfo.txt
        hostnamectl >>./$DIR/systeminfo.txt
        printf "System Information reported!\n" ;;
      *)
        printf "Unknown system architecture\n" ;;
    esac
  else
    printf "System Information report existed!\n"
  fi
}


# Show current resources utilization (CPU,RAM,Disk,...)
resourcesCheck() {
  case $OS in
    darwin)
      diskutil list ;;
    linux)
      df -hPT ;;
    *)
      printf "Unknown system architecture\n" ;;
  esac
  printSelection
}

resourcesCheck-report() {
  if [ "$(ls "./$DIR" | grep "resourcesinfo.txt")" = "" ]; then
    case $OS in
      darwin)
        echo "Resources Information" >> ./$DIR/resourcesinfo.txt
        diskutil list >> ./$DIR/resourcesinfo.txt
        printf "Resources Information reported!\n" ;;
      linux)
        echo "Resources Information" >> ./$DIR/resourcesinfo.txt
        df -hPT >> ./$DIR/resourcesinfo.txt
        printf "Resources Information reported!\n" ;;
      *)
        printf "Unknown system architecture\n" ;;
    esac
  else
    printf "Resources Information report existed!\n"
  fi
}


# Show current running services and processes
servicesCheck(){
  case $OS in
    darwin)
      launchctl list | grep -v '-'
      ps aux ;;
    linux)
      systemctl --type=service --state=running
      ps aux ;;
    *)
      printf "Unknown system architecture\n" ;;
  esac
  printSelection
}

servicesCheck-report() {
  if [ "$(ls "./$DIR" | grep "services.txt")" = "" ]; then
    case $OS in
      darwin)
        echo "Services Information" >> ./$DIR/services.txt
        launchctl list | grep -v '-' >> ./$DIR/services.txt
        ps aux >> ./$DIR/services.txt
        printf "Services Information reported!\n" ;;
      linux)
        echo "Services Information" >> ./$DIR/services.txt
        systemctl --type=service --state=running >> ./$DIR/services.txt
        ps aux >> ./$DIR/services.txt
        printf "Services Information reported!\n" ;;
      *)
        printf "Unknown system architecture\n" ;;
    esac
  else
    printf "Services Information report existed!\n"
  fi
}


#  Show network DNS configuration and networking services
networkCheck() {
  case $OS in
    darwin)
      cat /etc/hosts
      netstat -f inet -p tcp
      cat /etc/resolv.conf ;;
    linux)
      cat /etc/hosts
      netstat -t && netstat -ntlp -4
      cat /etc/resolv.conf ;;
    *)
      printf "Unknown system architecture\n" ;;
  esac
  printSelection
}

networkCheck-report() {
  if [ "$(ls "./$DIR" | grep "network.txt")" = "" ]; then
    case $OS in
      darwin)
        echo "Network Information" >> ./$DIR/network.txt
        cat /etc/hosts >> ./$DIR/network.txt
        netstat -f inet -p tcp >> ./$DIR/network.txt
        cat /etc/resolv.conf >> ./$DIR/network.txt
        printf "Network Information reported!\n" ;;
      linux)
        echo "Network Information" >> ./$DIR/network.txt
        cat /etc/hosts >> ./$DIR/network.txt
        netstat -t && netstat -ntlp -4 >> ./$DIR/network.txt
        cat /etc/resolv.conf >> ./$DIR/network.txt
        printf "Network Information reported!\n" ;;
      *)
        printf "Unknown system architecture\n" ;;
    esac
  else
    printf "Network Information report existed!\n"
  fi
}


# Generate a report folder include above information
genReport() {
  createDir
  systemCheck-report
  resourcesCheck-report
  servicesCheck-report
  networkCheck-report
  printSelection
}


# User's choices logic
PS3="Select a function: "

while true; do
  select FUNC in "${FUNCTIONS[@]}"; do
    case $REPLY in
      1) systemCheck ;;
      2) resourcesCheck ;;
      3) servicesCheck ;;
      4) networkCheck ;;
      5) genReport ;;
      6) deleteDir ;;
      7) printUsage ;;
      $((${#FUNCTIONS[@]}))) printf "Exitting... Bye!\n" && break 2 ;;
      *) printf "Error - Unknown selection $REPLY\n" && break ;;
    esac
  done
done
