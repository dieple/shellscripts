#!/usr/bin/ksh
 
#
## Mpan format
#
 
BASEDIR=$HOME/bin/adhocs/input_mpans
IN_FILE=$BASEDIR/x
OUT=$BASEDIR/xx
 
for file in $(ls $IN_FILE)
do
        MPAN=""
        CNT=0
        for MPANS in $(cat $file)
        do
                if [ $CNT -eq 0 ]
                then
                        MPAN="'"$MPANS"'"
                else
                        MPAN=$MPAN",""'"$MPANS"'"
                fi
                CNT=$(expr $CNT + 1)
        done
        print $MPAN > $OUT
        print ")" >> $OUT
done
