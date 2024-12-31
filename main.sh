#!/usr/bin/bash
### Author: Tin Trung Ngo
### Contact: trungtinth1011@gmail.com

: ${USE_SUDO:="true"}

HAS_CURL="$(type "curl" &> /dev/null && echo true || echo false)"
HAS_WGET="$(type "wget" &> /dev/null && echo true || echo false)"
CURRENT_DAY=$(date)
CURRENT_TIMESTAMP="$(date +'%Y%b%d%H%M')"
HOSTNAME=$(uname -n)
OS=$(echo `uname`|tr '[:upper:]' '[:lower:]')
DIR="$HOSTNAME"-"$CURRENT_TIMESTAMP"

# Detect current system architecture.
initArch() {
  ARCHITECT=$(uname -m)
  case $ARCHITECT in
    aarch64) ARCHITECT="arm64";;
    arm64) ARCHITECT="arm64";;
    x86_64) ARCHITECT="amd64";;
  esac
}

# Runs the given command as root (detects if we are root already)
runAsRoot() {
  [ $EUID -ne 0 -a "$USE_SUDO" = "true" ] && sudo "${@}" || "${@}"
}

# Create report directory
createDir() {
  [ ! -d ./"$DIR" ] && mkdir ./"$DIR" && chown -R $USER ./"$DIR" && printf "Directory "$DIR" created\n" || printf "Directory $DIR existed!\n"
}

# Cleanup report directory
deleteDir() {
  [ -d "$DIR" ] && rm -rf "./$DIR" && printf "Directory $DIR cleaned" || printf "Directory $DIR does not exist!"
  printSelection
}

# Printout script usage
printUsage() {
  printf "This script is used to check system health and utilities"
  printSelection
}

# Return selection menu when a function is finish
printSelection() {
  printf "\n---\n"
  for ((i = 1; i <= ${#SELECTIONS[@]}; i++)); do
    printf "$i) ${SELECTIONS[$i]}\t"
  done
  printf "$((${#SELECTIONS[@]}+1))) Quit\n"
}

checkOSInfo() {
#command -v hostnamectl >> /dev/null
case $ARCHITECT in
  arm64)
    echo "OS Information" >> ./$DIR/osinfo.txt
    system_profiler SPSoftwareDataType >> ./$DIR/osinfo.txt
    printf "OS Information checked." ;;
  amd64)
    echo "OS Information" >> ./$DIR/osinfo.txt
    hostnamectl >> ./$DIR/osinfo.txt
    printf "OS Information checked." ;;
  *)
    printf "Unknown system architecture" ;;
esac
}

proceedHealthCheck() {
  initArch
  createDir
  checkOSInfo
  printSelection
}



# User's choices logic
PS3="Select an option: "
SELECTIONS=("Healthcheck" "Clean up" "Usage")

while true; do
  select SELECTION in "${SELECTIONS[@]}" "Quit"
  do
    case $REPLY in
      1) proceedHealthCheck ;;
      2) deleteDir ;;
      3) printUsage ;;
      $((${#SELECTIONS[@]}+1))) echo "Quitting...Goodbye!" && break 2 ;;
      *) echo "Error - Unknown selection $REPLY" && break ;;
    esac
  done
done
