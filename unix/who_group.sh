#
#whogroup
#
group=$1
gid=$(grep "^$group:" /etc/group | awk -F: '{ print $3 }')
for user in $(grep $gid /etc/passwd | awk -F: '{ print $1"-"$4 }')
do
        name=$(echo $user | awk -F\- '{ print $1 }')
        gcheck=$(echo $user | awk -F\- '{ print $2 }')
        if [ $gcheck = $gid ]
        then
                echo $name
                tput smso
                who | grep $name
                tput rmso
        fi
done
 
===
#
# "sql" [Read only] 14 lines, 401 characters 
#
echo "set heading off " > QUERY.sql
echo "spool MPANS" >> QUERY.sql
for mpan in $(cat MPANLIST)
do
        echo $mpan
cat <<!>> QUERY.sql
        select c.id_mtr_sys, b.dt_ba_opn, a.nm_cust, a.ad_hse_name, a.ad_hse_num, a.ad_str_name, a.ad_vill, a.ad_town
        from cu01tb01 a, cu02tb01 b, cu16tb02 c
        where a.id_prem = c.id_prem and
        a.id_ba = b.id_ba and
        c.id_mtr_sys = '$mpan';
!
done
echo "spool off" >> QUERY.sql
 
===
#
# "p" [Read only] 27 lines, 478 characters 
#
exec 3< 10DIGITS.txt
LOOP=0
while [ $LOOP -eq 0 ]
exec 3< 10DIGITS.txt
LOOP=0
while [ $LOOP -eq 0 ]
do
        read line <&3
        if [ x"$line" != "x" ]
        then
                field1=$(echo $line | awk '{ print $1 }')
                field2=$(echo $line | awk '{ print $2 }')
                pad=$(echo $field2 | awk  '{ print length($1) }')
                pad=$(expr 10 - $pad)
                if [ $pad -ne 0 ]
                then
                        cnt=0
                        PADDER=""
                        while [ $cnt -lt $pad ]
                        do
                                cnt=$(expr $cnt + 1)
                                PADDER=$PADDER"0"
                        done
                        field2=$PADDER$field2
                fi
                echo $field1","$field2
        else
                LOOP=1
        fi
done
 
====
#
# fixit
#
cd $HOME/logging
FILE=$(ls -ltr | grep CUBAS310 | grep msg | tail -1 | awk '{ print $NF }')
MSID=$(tail -5 $FILE | grep MSID | awk '{ print $NF }')
echo $MSID
cat <<!
select * from cu16tb09 where id_mtr_sys = $MSID;
!
sqlplus cusonline/H0n01u1u@CR3PRA1 <<!
set heading off
select * from cu16tb09 where id_mtr_sys = $MSID;
!
echo "Confirm Delete ? Y/N \c"
read ans
if [ "$ans" = "Y" ] || [ "$ans" = "y" ]
then
set heading off
sqlplus cusonline/H0n01u1u@CR3PRA1 <<!
delete from cu16tb09 where id_mtr_sys = $MSID;
commit;
!
else
        echo "Commit aborted at user request!"
fi
 
===


