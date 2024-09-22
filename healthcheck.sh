#!/bin/bash
#
# WARNING: You need to be the super user before running the script
# This script works well on Debian 11, CentOS 7, Ubuntu 20.04, Red Hat 8.2
#
#
# USAGE: ./osCheck.sh -s before 
#        OR ./osCheck.sh -s after 
#        OR ./osCheck.sh -s compare  (must execute after executing 2 previous commands)
#           => This flag "-s" will indicate whether the stage we are running is 
#               before/after migration or you want to compare the files
#
# OUTPUT: A folder named: hostname-stage-date (ex: ubuntu-before-20230102)
#
#===================================== Tasks to do ====================================#
#                                                                                      #
# 1. OS services: Collect service status: run before shutdown/after start VM           #
# 2. CPU/RAM/Disk: CPU + RAM in total, Disk in detail                                  #
# 3. DNS: Copy & save file /etc/hosts to compare                                       #
# 4. Mountpoint: Listing mountpoint & compare with fstab                               #
# 5. Proxy/Internet: Check internet access                                             #
# 6. Port status: Show TCP/UDP listening port                                          #
# 7. TCP/IP config: Save IPconfig to "ipconfig.txt", save route print to "route.txt"   #
# 8. Disable personal firewall: Check iptable status                                   #
# 9. Show DNS resolve                                                                  #
# 10. Show running processes                                                           #
# 11. Show environment variables                                                       #
#                                                                                      #
#===================================== Tasks to do ====================================#            
while getopts s: flag   #Get the stage flag
do
    case "${flag}" in
        s) st=${OPTARG};;
    esac
done
STAGE=$st
now=$(date)
tstamp="$(date +'%Y%m%d')"
hn=$HOSTNAME
if [ "$STAGE" == "before" ]     # If the flag indicate before migrating stage
then
#
    # Create the folder for the stage (before/after)
    if [ ! -d ./"$hn"-"$STAGE"-"$tstamp" ] 
    then
        mkdir ./"$hn"-"$STAGE"-"$tstamp"
        chown -R $USER ./"$hn"-"$STAGE"-"$tstamp"
    fi
#
    # 1. OS services: Collect service status
    echo "Checking the machine before migrating..."
#
    echo "---------- OS information ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
#
    command -v hostnamectl >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'hostnamectl' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo "  'hostnamectl' command does not exist in this OS version"
    else
        # Command to check OS information
        sudo hostnamectl >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 1: Copied OS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        else
            echo "   Task 1: Failed to copy OS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        fi
#
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo "---------- Service status ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
    fi
#
    # Command to check system services
    command -v systemctl >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'systemctl' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo "  'systemctl' command does not exist in this OS version"
    else
        sudo systemctl  --type=service --state=running >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 1: Copied Service status to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        else
            echo "   Task 1: Failed to copy Service status to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        fi  
#
        #Check if all running services are enabled
        sudo systemctl  list-unit-files --state=enabled --type=service |egrep -v 'UNIT' |awk '{print $1}' > ENSRV
#
        sudo systemctl  --type=service --state=running |egrep -v 'UNIT|LOAD|ACTIVE|SUB|To' |awk '{print $1}' > RUNSRV
#
        #sudo diff -w ENSRV RUNSRV >> CMP
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo " ---------- Services that is running and enabled ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        grep -f RUNSRV ENSRV -x  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        grep -f RUNSRV ENSRV -x  >> TMP
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
#
        echo "---------- Services that is running without being enabled ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        grep -f TMP RUNSRV -xv >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        sed -i '$ d' ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
#
        rm -rf ENSRV 
        rm -rf RUNSRV
        rm -rf TMP
#
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo 
    fi
#
    #2. CPU/RAM/Disk
    echo "---------- CPU usage ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
#
    command -v lscpu >> /dev/null
    if [ ! $? -eq 0 ] 
    then
        echo "  'lscpu' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
        echo "  'lscpu' command does not exist in this OS version"
    else    
        # Command to check CPU usage
        sudo lscpu >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
#
        if [ $? -eq 0 ]
        then
            echo "   Task 2: Copied CPU information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt"
        else
            echo "   Task 2: Failed to copy CPU information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
    fi
#
    echo "---------- RAM usage ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt    
    # Command to check RAM usage
    command -v free >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'free' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
        echo "  'free' command does not exist in this OS version"
    else
        sudo free --mega -ht >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
#
        if [ $? -eq 0 ]
        then
            echo "   Task 2: Copied memory information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt"
        else
            echo "   Task 2: Failed to copy memory information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt  
    fi
#
    echo "---------- Disks usage ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
    # Command to check Disks usage
    command -v fdisk >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'fdisk' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo "  'fdisk' command does not exist in this OS version"
    else
        sudo fdisk -l | grep '^Disk /dev/' >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        # Another command to check disks usage
        sudo lsblk /dev/sda >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 2: Copied disk information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt"
        else
            echo "   Task 2: Failed to copy disk information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt"
        fi
#
        echo  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        sudo lsblk /dev/sdb >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        sudo lsblk /dev/sdc >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
#
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo
    fi
#
    #3. Copy /etc/hosts > hosts-"$tstamp".txt
    echo "---------- OS Host ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
    # Command to check hosts
    if [ ! -f /etc/hosts ]; then
        echo "  File /etc/hosts does not exist" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        echo "  File /etc/hosts does not exist"
    else
        sudo cat /etc/hosts >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 3: Copied file /etc/hosts to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt"
        else
            echo "   Task 3: Failed to copy file /etc/hosts to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        echo
    fi
#
    #4. Mountpoint: Listing mountpoint & compare with fstab 
    echo "---------- Mountpoints ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
    # Command to check mount point
    command -v df >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'df' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo "  'df' command does not exist in this OS version"
    else
        sudo df -PTh >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
#
        echo "" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo "---------- Compare with fstab ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo "" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
#
        # ====== Start comparing mountpoint vs fstab
        NAME=$(uname -n)
        sudo df -hPT |egrep -v 'Filesystem|tmpfs|devtmpfs' |awk '{print $7}' > FS_ITEMS
#
        sudo cat /etc/fstab |egrep -v 'tmpfs' |awk '$1 !~/#|^$/ {print $2}' >> FS_ITEMS
#
        printf "%-30s%-40s%-15s%-15s%-s\n" HOSTNAME FILESYSTEM MOUNTED ETC_FSTAB >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        printf "%-30s%-40s%-15s%-15s%-s\n" -------- ---------- ------- --------- >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
#
        for FS in $(cat FS_ITEMS |sort |uniq)
        do
#
        FS_DF=$(sudo df -hPT |grep -v Filesystem |awk '{print $7}' |grep -E "(^|\s)${FS}($|\s)")
        FS_FSTAB=$(sudo cat /etc/fstab |egrep -v 'tmpfs' | awk '$1 !~/#|^$|swap/ {print $2}' |grep -E "(^|\s)${FS}($|\s)")
#
        if [ "$FS" = "$FS_DF" ]; then
            PR_MOUNT="Yes"
        else
            PR_MOUNT="No"
        fi
#
        if [ "$FS" = "$FS_FSTAB" ]; then
            PR_FSTAB="Yes"
        else
            PR_FSTAB="No"
        fi
#
        # Ater comparing finish, save the result and clean up
        printf "%-30s%-40s%-15s%-15s%-s\n" $NAME $FS $PR_MOUNT $PR_FSTAB >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        done
#
        rm FS_ITEMS
#
        if [ $? -eq 0 ]
        then
            echo "   Task 4: Copied mounting information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt"
        else
            echo "   Task 4: Failed to copy mounting information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo
    fi
#
    # 5. Proxy/Internet: Check internet access
    echo "---------- Curl internet without proxy ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
#
    # Command to check internet connection without proxy
    command -v curl >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "      'curl' command does not exist in this OS version, trying wget..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo "      'curl' command does not exist in this OS version, trying wget"
#
        sudo wget --spider -O -  https://www.google.com >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt 2>&1
        if [ $? -eq 0 ]
        then
            echo "   Task 5: Checked internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
            echo "   Task 5: Failed to check internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
#
        echo 
        echo "---------- Curl internet with proxy ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo
#
        # Command to check internet connection with proxy
        sudo https_proxy=zscaler.proxy.lvmh:9480 wget https://www.google.com  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt 2>&1
        if [ $? -eq 0 ]
        then
            echo "   Task 5: Checked internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
            echo "   Task 5: Failed to check internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo
#
    else
        sudo curl --noproxy '*' https://www.google.com -I >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
#
        if [ $? -eq 0 ]
        then
            echo "   Task 5: Checked internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
            echo "   Task 5: Failed to check internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
#
        echo 
        echo "---------- Curl internet with proxy ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo
#
        # Command to check internet connection with proxy
        sudo curl --proxy zscaler.proxy.lvmh:9480  https://www.google.com -I >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 5: Checked internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
            echo "   Task 5: Failed to check internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo
    fi
#
    # 6. Port status: Show TCP/UDP listening port
    echo "---------- Port status list ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
    # Command to check listening port
    command -v netstat >> /dev/null
    if [ ! $? -eq 0 ] 
    then
        echo "  'netstat' command does not exist in this OS version, trying another command..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt 
        echo "  'netstat' command does not exist in this OS version, trying another command..."
        sudo lsof -i -P -n | egrep 'LISTEN|COMMAND' >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        if [ $? -eq 0 ]    
        then
            echo "   Task 6: Copied listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        else
            echo "   Task 6: Failed to copy listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        echo
    else
        sudo netstat -tulpn | egrep 'Proto|LISTEN' >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        echo
        if [ $? -eq 0 ]    
        then
            echo "   Task 6: Copied listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        else
            echo "   Task 6: Failed to copy listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        echo
    fi
    #7. TCP/IP config: ifconfig > "ipconfig-"$tstamp".txt" route > "route-"$tstamp".txt"
    echo "---------- IP information ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    echo
    # Command to check IP information
    command -v ifconfig >> /dev/null
    if [ ! $? -eq 0 ] 
    then
        echo "  'ifconfig' command does not exist in this OS version, trying another command..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        echo "  'ifconfig' command does not exist in this OS version, trying another command..." 
        sudo ip a >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        if [ $? -eq 0 ] 
        then
            echo "   Task 7: Copied IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        else
            echo "   Task 7: Failed to copy IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    else
        sudo ifconfig >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        if [ $? -eq 0 ] 
        then
            echo "   Task 7: Copied IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        else
            echo "   Task 7: Failed to copy IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    fi
    echo "---------- Routing information ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
    # Command to check routing information
    command -v route >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'route' command does not exist in this OS version, trying another command..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo
        echo "  'route' command does not exist in this OS version, trying another command..."
        sudo ip route >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 7: Copied routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        else
            echo "   Task 7: Failed to copy routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo
    else
        sudo route -n >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 7: Copied routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        else
            echo "   Task 7: Failed to copy routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo
    fi
    # 8. Disable personal firewall
    echo "---------- IPtables status ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
    # Command to check iptable information
    command -v iptables >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'iptables' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
        echo "  'iptables' command does not exist in this OS version"
    else
        sudo iptables -L >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 8: Copied iptables information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt"
        else
            echo "   Task 8: Failed to copy iptables information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
        echo
    fi
    #9. Show DNS resolver
    echo "---------- DNS status ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
    # Command to check DNS resolver
    if [ ! -f /etc/resolv.conf ]; then
        echo "  File /etc/resolv.conf does not exist" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
        echo
        echo "  File /etc/resolv.conf does not exist"
    else
        sudo cat /etc/resolv.conf >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 9: Copied DNS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt"
        else
            echo "   Task 9: Failed to copy DNS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
        echo
    fi    
    #10. Show running process  
    echo "---------- Running processes ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
    # Command to check processes information
    command -v ps >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'ps' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
        echo "  'ps' command does not exist in this OS version"
    else
        ps auxr >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 10: Copied running processes to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt"
        else
            echo "   Task 10: Failed to copy running processes to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
        echo
    fi
    #11. Show environment variables
    echo "---------- Environment variables ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
    # Command to check environment variables information
    command -v printenv >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'printenv' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
        echo "  'printenv' command does not exist in this OS version"
    else
        printenv >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 11: Copied environment variables to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt"
        else
            echo "   Task 11: Failed to copy environment variables to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
        echo
    fi
# Else if the flag is after
elif [ "$STAGE" == "after" ]
then
    # Create the folder for the stage (before/after)
    if [ ! -d ./"$hn"-"$STAGE"-"$tstamp" ] 
    then
        mkdir ./"$hn"-"$STAGE"-"$tstamp"
        chown -R $USER ./"$hn"-"$STAGE"-"$tstamp"
    fi
    # 1. OS services: Collect service status
    echo "Checking the machine after migrating..."
    echo "---------- OS information ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
    # Command to check OS information
    command -v hostnamectl >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'hostnamectl' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo "  'hostnamectl' command does not exist in this OS version"
    else
        sudo hostnamectl >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 1: Copied OS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        else
            echo "   Task 1: Failed to copy OS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo "---------- Service status ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
    fi
    # Command to check system services
    command -v systemctl >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'systemctl' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo "  'systemctl' command does not exist in this OS version"
    else
        sudo systemctl  --type=service --state=running >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 1: Copied Service status to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        else
            echo "   Task 1: Failed to copy Service status to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt"
        fi
        #Check if all running services are enabled
        sudo systemctl  list-unit-files --state=enabled --type=service |egrep -v 'UNIT' |awk '{print $1}' > ENSRV
#
        sudo systemctl  --type=service --state=running |egrep -v 'UNIT|LOAD|ACTIVE|SUB|To' |awk '{print $1}' > RUNSRV
#
        #sudo diff -w ENSRV RUNSRV >> CMP
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo " ---------- Services that is running and enabled ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        grep -f RUNSRV ENSRV -x  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        grep -f RUNSRV ENSRV -x  >> TMP
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
#
        echo "---------- Services that is running without being enabled ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        grep -f TMP RUNSRV -xv >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        sed -i '$ d' ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
#
        rm -rf ENSRV 
        rm -rf RUNSRV
        rm -rf TMP
#
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-os-"$tstamp".txt
        echo
    fi
#
#
    #2. CPU/RAM/Disk
#
    echo "---------- CPU usage ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt 
    command -v lscpu >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'lscpu' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
        echo "  'lscpu' command does not exist in this OS version"
    else
        # Command to check CPU usage
        sudo lscpu >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
#
        if [ $? -eq 0 ]
        then
            echo "   Task 2: Copied CPU information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt"
        else
            echo "   Task 2: Failed to copy CPU information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-cpu-"$tstamp".txt
    fi
#
    #
    echo "---------- RAM usage ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
    # Command to check RAM usage
    command -v free >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'free' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
        echo "  'free' command does not exist in this OS version"
    else
        sudo free --mega -ht >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
#
        if [ $? -eq 0 ]; then
        echo "   Task 2: Copied memory information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt"
        else
        echo "   Task 2: Failed to copy memory information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ram-"$tstamp".txt  
    fi    
#
    echo "---------- Disks usage ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
    # Commands to check Disks usage
    command -v fdisk >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'fdisks' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo "  'disks' command does not exist in this OS version"
    else
        sudo fdisk -l | grep '^Disk /dev/' >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
    fi
#
#
    command -v lsblk >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'lsblk' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo "  'lsblk' command does not exist in this OS version"
    else
        sudo lsblk /dev/sda >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        if [ $? -eq 0 ]; then
        echo "   Task 2: Copied disk information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt"
        else
        echo "   Task 2: Failed to copy disk information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt"
        fi
        echo  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        sudo lsblk /dev/sdb >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        sudo lsblk /dev/sdc >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
#
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-disks-"$tstamp".txt
        echo
    fi
#
#
    #3. Copy /etc/hosts > hosts-"$tstamp".txt
    echo "---------- OS Host ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
    # Command to check hosts
    if [ ! -f /etc/hosts ]; then
        echo "  File /etc/hosts does not exist" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        echo
        echo "  File /etc/hosts does not exist"
#
    else
        sudo cat /etc/hosts >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 3: Copied file /etc/hosts to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt"
        else
            echo "   Task 3: Failed to copy file /etc/hosts to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-hosts-"$tstamp".txt
        echo
    fi
#
#
    #4. Mountpoint: Listing mountpoint & compare with fstab 
    echo "---------- Mountpoints ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
    # Command to check mount point
    command -v df >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'df' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo "  'df' command does not exist in this OS version"
    else
        sudo df -PTh >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
#
        echo "" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo "---------- Compare with fstab ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo "" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
#
        # ====== Start comparing mountpoint vs fstab
        NAME=$(uname -n)
        sudo df -hPT |egrep -v 'Filesystem|tmpfs|devtmpfs' |awk '{print $7}' > FS_ITEMS
#
        sudo cat /etc/fstab |egrep -v 'tmpfs' |awk '$1 !~/#|^$/ {print $2}' >> FS_ITEMS
#
        printf "%-30s%-40s%-15s%-15s%-s\n" HOSTNAME FILESYSTEM MOUNTED ETC_FSTAB >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        printf "%-30s%-40s%-15s%-15s%-s\n" -------- ---------- ------- --------- >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
#       
        for FS in $(cat FS_ITEMS |sort |uniq)
        do
#       
        FS_DF=$(sudo df -hPT |grep -v Filesystem |awk '{print $7}' |grep -E "(^|\s)${FS}($|\s)")
        FS_FSTAB=$(sudo cat /etc/fstab |egrep -v 'tmpfs' | awk '$1 !~/#|^$|swap/ {print $2}' |grep -E "(^|\s)${FS}($|\s)")
#       
        if [ "$FS" = "$FS_DF" ]; then
            PR_MOUNT="Yes"
        else
            PR_MOUNT="No"
        fi
#       
        if [ "$FS" = "$FS_FSTAB" ]; then
            PR_FSTAB="Yes"
        else
            PR_FSTAB="No"
        fi
#       
        # Ater comparing finish, save the result and clean up
        printf "%-30s%-40s%-15s%-15s%-s\n" $NAME $FS $PR_MOUNT $PR_FSTAB >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        done
#       
        rm FS_ITEMS
#
#      
        if [ $? -eq 0 ]; then
        echo "   Task 4: Copied mounting information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt"
        else
        echo "   Task 4: Failed to copy mounting information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-mount-"$tstamp".txt
        echo
    fi
#
#
    # 5. Proxy/Internet: Check internet access
#   
    echo "---------- Curl internet without proxy ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
#
    # Command to check internet connection without proxy
    command -v curl >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "      'curl' command does not exist in this OS version, trying wget..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo "      'curl' command does not exist in this OS version, trying wget"
#
        sudo wget --spider -O -  https://www.google.com >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt 2>&1
        if [ $? -eq 0 ]
        then
            echo "   Task 5: Checked internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
            echo "   Task 5: Failed to check internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
#
        echo 
        echo "---------- Curl internet with proxy ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo
#
        # Command to check internet connection with proxy
        sudo https_proxy=zscaler.proxy.lvmh:9480 wget https://www.google.com  >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt 2>&1
        if [ $? -eq 0 ]
        then
            echo "   Task 5: Checked internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
            echo "   Task 5: Failed to check internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo
        # sudo rm -rf index.html 
        # sudo rm -rf index.html.*
#
    else
        sudo curl --noproxy '*' https://www.google.com -I >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
#
        echo
        if [ $? -eq 0 ]; then
        echo "   Task 5: Checked internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
        echo "   Task 5: Failed to check internet access without proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
#
        echo 
        echo "---------- Curl internet with proxy ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
#
        # Command to check internet connection with proxy
        sudo curl --proxy zscaler.proxy.lvmh:9480  https://www.google.com -I >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
#
        if [ $? -eq 0 ]; then
            echo "   Task 5: Checked internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        else
            echo "   Task 5: Failed to check internet access with proxy (./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt)"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-checkNet-"$tstamp".txt
        echo
    fi
#
#
    # 6. Port status: Show TCP/UDP listening port
    echo "---------- Port status list ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
    # Command to check listening port
    command -v netstat >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'netstat' command does not exist in this OS version, trying another command..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt 
        echo "  'netstat' command does not exist in this OS version, trying another command..."
#
        sudo lsof -i -P -n | egrep 'LISTEN|COMMAND' >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
#      
        if [ $? -eq 0 ]    
        then
            echo "   Task 6: Copied listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        else
            echo "   Task 6: Failed to copy listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        echo
#
    else
        sudo netstat -tulpn | egrep 'Proto|LISTEN' >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
#
        echo
        if [ $? -eq 0 ]; then
        echo "   Task 6: Copied listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        else
        echo "   Task 6: Failed to copy listening port to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ports-"$tstamp".txt
        echo
    fi
#
#
    #7. TCP/IP config: ifconfig > "ipconfig-"$tstamp".txt" route > "route-"$tstamp".txt"
    echo "---------- IP information ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    # Command to check IP information
    command -v ifconfig >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'ifconfig' command does not exist in this OS version, trying another command..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
#
        echo "  'ifconfig' command does not exist in this OS version, trying another command..." 
#
        sudo ip a >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        if [ $? -eq 0 ] 
        then
            echo "   Task 7: Copied IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        else
            echo "   Task 7: Failed to copy IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    else
        sudo ifconfig >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        if [ $? -eq 0 ]; then
        echo "   Task 7: Copied IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        else
        echo "   Task 7: Failed to copy IP information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-ipconfig-"$tstamp".txt
    fi    
#
    echo "---------- Routing information ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
    # Command to check routing information
    command -v route >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'route' command does not exist in this OS version, trying another command..." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo
        echo "  'route' command does not exist in this OS version, trying another command..."
#      
        sudo ip route >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        if [ $? -eq 0 ]
        then
            echo "   Task 7: Copied routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        else
            echo "   Task 7: Failed to copy routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo
#
    else
        sudo route -n >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        if [ $? -eq 0 ]; then
        echo "   Task 7: Copied routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        else
        echo "   Task 7: Failed to copy routing information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-route-"$tstamp".txt
        echo
    fi
#
#
    # 8. Disable personal firewall
    echo "---------- IPtables status ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
    # Command to check iptable information
    command -v iptables >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'iptables' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
        echo "  'iptables' command does not exist in this OS version"
    else
        sudo iptables -L >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
#     
        if [ $? -eq 0 ]; then
        echo "   Task 8: Copied iptables information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt"
        else
        echo "   Task 8: Failed to copy iptables information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-iptables-"$tstamp".txt
        echo
    fi
#
#
    # 9. Show DNS resolve
    echo "---------- DNS status ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
    # Command to check DNS resolver
    if [ ! -f /etc/resolv.conf ]; then
        echo "  File /etc/resolv.conf does not exist" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
        echo
        echo "  File /etc/resolv.conf does not exist"
    else
        sudo cat /etc/resolv.conf >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
#     
        if [ $? -eq 0 ]
        then
            echo "   Task 9: Copied DNS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt"
        else
            echo "   Task 9: Failed to copy DNS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-dns-"$tstamp".txt
        echo
    fi 
#
#
    #10. Show running process  
    echo "---------- Running processes ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
    # Command to check processes information
    command -v ps >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'ps' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
        echo "  'ps' command does not exist in this OS version"
    else
        ps auxr >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
 #       
        if [ $? -eq 0 ]; then
        echo "   Task 10: Copied DNS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt"
        else
        echo "   Task 10: Failed to copy DNS information to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-procs-"$tstamp".txt
        echo
    fi
#
#
    #11. Show environment variables
    echo "---------- Environment variables ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
    echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
    # Command to check environment variables information
    command -v printenv >> /dev/null
    if [ ! $? -eq 0 ]
    then
        echo "  'printenv' command does not exist in this OS version" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
        echo "  'printenv' command does not exist in this OS version"
    else
        printenv >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
 #       
        if [ $? -eq 0 ]; then
        echo "   Task 11: Copied environment variables to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt"
        else
        echo "   Task 11: Failed to copy environment variables to ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt"
        fi
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
        #echo "---------- Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-env-"$tstamp".txt
        echo
    fi
#
#
# If the flag is compare
elif [ "$STAGE" == "compare" ]
then
    # Check if "./before" and "./after" folders exist
    countDir=0
    arr=("$PWD/"$hn"-before-"$tstamp"" "$PWD/"$hn"-after-"$tstamp"" )
    for d in "${arr[@]}"; do
        if [ -d "$d" ]; then
            let countDir++
        fi
    done
#
    # If "./before" and "./after" do exist
    if [ $countDir == 2 ]; then
        echo "2 directory before/ and after exist!!! Comparing...."
#
        # Create compare directory for storing comparing result file
        if [ ! -d ./"$hn"-"$STAGE"-"$tstamp" ] 
        then
            mkdir ./"$hn"-"$STAGE"-"$tstamp"
            chown -R $USER ./"$hn"-"$STAGE"-"$tstamp"
        fi
#
        # ============= COMPARE EACH FILE IN THE TWO FOLDERS =============
        for FILE in "$hn"-before-"$tstamp"/*; do 
            #echo $FILE
#
            # Calculate time stamp length
            tslength=${#tstamp}
#
            # Calculate hostname length
            hnlength=${#hn}
#
            FILE2="$hn"-after-"$tstamp"/${FILE:$hnlength+$tslength+9}
            #echo ===$FILE2
#
            if [ ! -f $FILE2 ]; then
                echo " ##### $FILE2 does not exist! #####" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
                echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
                echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
            else
                echo " ##### Compare result: File ${FILE:$hnlength+$tslength+9} #####" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
                echo " ##### '<' = before and '>' = after #####" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
                #echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
#
                # Command to compare 2 files and ignore blank spaces
                sudo diff -w $FILE $FILE2 >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
                if [ $? -eq 0 ]; then
                    #echo "File $FILE and $FILE2 are identical."
                    echo " => 2 files are identical." >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt  
                fi
                echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
                echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
            fi
#
        done
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
        echo "---------- Comparing Date: $now ----------" >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
        echo >> ./"$hn"-"$STAGE"-"$tstamp"/"$hn"-res-"$tstamp".txt
#
        echo "Compare finished......."
#
    # If one of or both of them not exist    
    else
        echo 
        echo "Cannot compare 2 directory!!! Missing required directory(ies) (before/after)"
        echo
    fi
#
#
 else
    echo
    echo "Error!!! No flag detected"
    echo
fi
