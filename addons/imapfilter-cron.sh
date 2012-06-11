#!/bin/bash
LCK=/tmp/.imapfilter.lck
LOG=/var/log/imapfilter.log

[ -f "$LCK" ] && exit
touch $LCK

lm=5
nl=$(cat $LOG 2>/dev/null | wc -l)
if [ "$nl" -gt 50000 ]; then
   [ -f ${LOG}.${lm}.gz ] && rm ${LOG}.5.gz
   for x in $(seq $((${lm} - 1)) -1 1)
   do
      if [ -f ${LOG}.${x}.gz ]; then
         mv ${LOG}.${x}.gz ${LOG}.$((${x} + 1)).gz
      fi
   done
   mv $LOG ${LOG}.1
   gzip ${LOG}.1
   touch $LOG
fi

/usr/bin/imapfilter

rm -f $LCK
