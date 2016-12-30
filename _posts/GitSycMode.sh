#!/bin/sh

SRCDATAPATH=./
echo SRCDATAPATH=$SRCDATAPATH
git config http.postBuffer 52428800000
git remote
echo "pull remote to loacal"
git pull

cd $SRCDATAPATH/

#git diff
GITLog=""
echo "Please Input GITLog:"
#read GITLog
if [ "$GITLog" = "" ]; then
  echo "Input GITLog is NULL"
  GITLog="chanage source code"
fi
echo "$GITLog"
git commit -am "$GITLog"
echo "push loacal to remote "
git push origin master






