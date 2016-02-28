#!/usr/bin/ksh
 
BASEDIR=$HOME/bin/output/jackie
#IN=$BASEDIR/test_file
IN=$BASEDIR/pes_pmt_src_2000-08-22.txt
OUT=$BASEDIR/dual_payments_output.csv
 
cnt=0
LASTKEY=""
LASTSUP=""
LASTLINE=""
 
cat $IN | while read LINE
do
        KEY=$(echo $LINE | awk -F, '{ print $1 }')
        SUP=$(echo $LINE | awk -F, '{ print $2 }')
        if [ x"$LASTKEY" = x"$KEY" ]
       t hen
                if [ x"$LASTSUP" != x"$SUP" ]
                then
                        echo $LASTLINE
                        echo $LINE
                fi
        fi
        LASTSUP=$SUP
        LASTKEY=$KEY
        LASTLINE=$LINE
done | sed -e 's/-/,/g' | sed -e 's/@/ /g' > $OUT
 
#
# test file
#
 
#1012368804993-2200242291,RPA@Remittance@Processing
#1012368804993-2200421103,Eastern
#1012368804993-2200421103,Eastern
#1012368804993-2200421103,Eastern
#1012368804993-2200421103,Eastern
#1012368804993-2200421103,Eastern
#1012367813695-2001630719,Eastern
#1012367703751-1801606129,Eastern
#1012367703751-1801606129,Eastern
#1012367703751-1801606129,Eastern
#1012367683973-4200509104,Eastern
#1012367683973-4200509104,Eastern
#1012367683973-4200509104,Eastern
#1012367683973-4200509104,Eastern
#1012367683973-4200509104,Eastern
#1012367683973-4200509104,Eastern
#1012367683973-4200509104,Midland@HO@Coll@Acc@(HOCA)
 
#
#o utput
#
 
#1012367683973,4200509104,Eastern
#1012367683973,4200509104,Midland HO Coll Acc (HOCA)
 

