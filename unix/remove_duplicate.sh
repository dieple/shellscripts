"remove_duplicate.sh" 70 lines, 1653 characters 
#!/usr/bin/ksh
 
BASEDIR=$HOME/bin/output/jackie
#IN1=$BASEDIR/orig_file_A.txt        # output will be print from this original file
#IN2=$BASEDIR/compare_file_b.txt     # duplicate will be remove
IN1=$BASEDIR/a
IN2=$BASEDIR/b
OUT=$BASEDIR/remove_dup_TEST.txt
T1=$BASEDIR/t1.tmp
T2=$BASEDIR/t2.tmp
T3=$BASEDIR/t3.tmp
 
PREV_MPAN=""
PREV_LINE=""
 
cat $IN1 | sed -e 's/^/A,/g'  | sort -u > $T1
cat $IN2 | sed -e 's/^/B,/g'  | sort -u > $T2
 
#  All 3 sort statements are working but field separator
#  must be blank not comma separated
#
 
#cat $T1 $T2 | sed -e 's/,/ /g' | sort +1n > $T3
#cat $T1 $T2 | sed -e 's/,/ /g' | sort -k2,2 -k1,1  > $T3
#cat $T1 $T2 | sed -e 's/,/ /g' | sort  -n -k2.1 -k2.13  > $T3
 
cat $T1 $T2 | sed -e 's/,/ /g' | sort +1n | while read LINE
do
        TAG=$(print $LINE  | awk -F" "  '{ print $1 }')
        MPAN=$(print $LINE | awk -F" "  '{ print $2 }')
 
        if [ x"$TAG"=x"A" ]
        then
                if [ x"$PREV_MPAN" != x"$MPAN" ]
                then
                        print $LINE
                fi
        fi
        PREV_MPAN=$MPAN
        PREV_LINE=$LINE
done > $T3
 
cat $T3 | sed -e 's/^A file://g' | sed -e 's/ /,/g' > $OUT
 
rm -f $T1 $T2 $T3
#
# End of script
#
 
# orig_A
 
#1012367683973,4200509104|Midland@HO@Coll@Acc@(HOCA)
#1012367703751,1801606129|Eastern
#1012367813695,2001630719|Eastern
#1012368804993,2200421103|Eastern
#2012367683973,4200509104|Midland@HO@Coll@Acc@(HOCA)
#2012367703751,1801606129|Eastern
#2012367813695,2001630719|Eastern
#2012368804993,2200421103|Eastern
#2012367683973,4200509104|Midland@HO@Coll@Acc@(HOCA)
#2012367703751,1801606129|Eastern
#2012367813695,2001630719|Eastern
#2012368804993,2200421103|Eastern
 
# compare_B
 
#1012367683973
#1012367703751
#1012367813695
#1012368804993
 

