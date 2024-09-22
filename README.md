# oshealthcheck
Linux script checking system information

## Author: Tin Trung Ngo


## Before you begin

This script is usually used in scenarios where there are some important changes in the system (replatform, rehost, ...) and we want to make sure that after the change, everything remains the same as before the change.

You need to be the **super user** or in **sudo group** before running the script

> This script has been tested and works well on Debian 11, CentOS 7, Ubuntu 20.04, Red Hat 8.2

The script supports 3 healthcheck modes: Before - After - Compare.

The script is written with the aim to check some system information of Linux servers (for Application Consistency). It will check the system and then generate the files to save those infomation. It's tasks include:
1. OS services: Collect service status: run before shutdown/after start VM           
2. CPU/RAM/Disk: CPU + RAM in total, Disk in detail                                  
3. DNS: Copy & save file /etc/hosts to compare                                       
4. Mountpoint: Listing mountpoint & compare with fstab                              
5. Proxy/Internet: Check internet access                                             
6. Port status: Show TCP/UDP listening port                                          
7. TCP/IP config: Save IPconfig to "ipconfig.txt", save route print to "route.txt"   
8. Disable personal firewall: Check iptable status                                   
9. Show DNS resolve                                                                  
10. Show running processes                                                           
11. Show environment variables

## Usage

Run in sequence these commands:
1. `./healthcheck.sh -s before`: Check the system information before any changes.
2. `./healthcheck.sh -s after`: Check the system information again after the changes.
3. `./healthcheck.sh -s compare`: Compare the system information before and after the changes.

The `-s` flag will indicate the stage we want to run.

Output will be a folder named: `hostname-stage-date` (ex: ubuntu-before-20230102)


                                                                                     


