#! /bin/bash

ts="$(date +'%Y%m%d')"
hn=$HOSTNAME

rm -rf ./"$hn"-before-"$ts"/*.txt
rm -rf ./"$hn"-before-"$ts"
rm -rf ./"$hn"-after-"$ts"/*.txt
rm -rf ./"$hn"-after-"$ts"
rm -rf ./"$hn"-compare-"$ts"/*.txt
rm -rf ./"$hn"-compare-"$ts"
if [ $? -eq 0 ]; then
   echo "Successfully clean all the related file(s) and folder(s)"
else
   echo FAIL
fi
