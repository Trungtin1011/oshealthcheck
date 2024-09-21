# oshealthcheck
Linux script checking system information

## Author: Tin Trung Ngo
## 


The 'osCheck.sh' script is written with the aim to check some system information of Linux servers (Application Consistency
)
1. The script will check the system and then generate the files to save these infomation. It's tasks include:
    - Check OS/services -> os
    - Check CPU/RAM/DISK -> cpu/ram/disks
    - Check file /etc/hosts -> hosts
    - Check mountpoint -> mount
    - Check internet connection with/without proxy -> checkNet
    - Check ports status -> ports
    - Check IP configuration -> ipconfig
    - Check iptables -> iptables
    - Check DNS resolver -> dns
    - Check running processes -> procs
    - Check environment variables -> env

2. To run the script, you need to be the superuser (root), then type: './osCheck.sh -s <options>' the options are:
    - sudo ./osCheck.sh -s before -> check and save system information before migration
    - sudo ./osCheck.sh -s after -> check and save system information after migration
    - sudo ./osCheck.sh -s compare -> compare system information before >< after migration



