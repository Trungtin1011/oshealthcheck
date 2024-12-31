#!/bin/bash
### Author: Tin Trung Ngo
### Contact: trungtinth1011@gmail.com

# Global variables
HOSTNAME=$(uname -n)
CURRENT_DAY=$(date)
CURRENT_TIMESTAMP="$(date +'%Y%b%d')"
OS=$(echo `uname`|tr '[:upper:]' '[:lower:]')
DIR="report"-"$HOSTNAME"-"$CURRENT_TIMESTAMP"
FUNCTIONS=("Usage" "Host check" "Generate report" "Clean up report" "Exit")
HAS_CURL="$(type "curl" &> /dev/null && echo true || echo false)"
HAS_WGET="$(type "wget" &> /dev/null && echo true || echo false)"

# Detect current system architecture.
case $(uname -m) in
  aarch64) ARCHITECT="arm64";;
  arm64) ARCHITECT="arm64";;
  x86_64) ARCHITECT="amd64";;
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
  printf "This script is used to check system health and utilities.\n"
  printSelection
}

# Return selection menu when a function is finish
printSelection() {
  printf "\n"
  case $ARCHITECT in
    arm64)
      for ((i=1; i <= "${#FUNCTIONS[@]}"; i++)); do printf "$i) ${FUNCTIONS[$i]}\t"; done ;;
    amd64)
      for i in "${!FUNCTIONS[@]}"; do printf "$(($i+1))) ${FUNCTIONS[$i]}\t"; done ;;
  esac
  printf "\n"
}

checkHost() {
  case $ARCHITECT in
    arm64)
      system_profiler SPHardwareDataType SPSoftwareDataType ;;
    amd64)
      hostnamectl ;;
    *)
      printf "Unknown system architecture\n" ;;
  esac
  printSelection
}

checkHost-report() {
  if [ "$(ls "./$DIR" | grep "osinfo.txt")" = "" ]; then
    case $ARCHITECT in
      arm64)
        echo "OS Information" >> ./$DIR/osinfo.txt
        system_profiler SPHardwareDataType SPSoftwareDataType >> ./$DIR/osinfo.txt
        printf "OS Information reported!\n" ;;
      amd64)
        echo "OS Information" >> ./$DIR/osinfo.txt
        hostnamectl >> ./$DIR/osinfo.txt
        printf "OS Information reported!\n" ;;
      *)
        printf "Unknown system architecture\n" ;;
    esac
  else
    printf "OS Information report existed!\n"
  fi

}

genReport() {
  createDir
  checkHost-report
  printSelection
}


# User's choices logic
PS3="Select a function: "

while true; do
  select FUNC in "${FUNCTIONS[@]}"
  do
    case $REPLY in
      1) printUsage ;;
      2) checkHost ;;
      3) genReport ;;
      4) deleteDir ;;
      $((${#FUNCTIONS[@]}))) printf "Exitting... Bye!\n" && break 2 ;;
      *) printf "Error - Unknown selection $REPLY\n" && break ;;
    esac
  done
done
