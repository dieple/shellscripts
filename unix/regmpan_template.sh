"reg_mpan_template.sh" 48 lines, 791 characters 
#!/bin/ksh
 
BASEDIR=$HOME/bin
OUT=$BASEDIR
 
split -190 in_mpanaa tmp1
 
##########################
# Generate SQL Statement
##########################
for file in $(ls tmp1*)
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
        sqlplus -s $USERNAME/$PASSWD@CR3PRA1 <<! | tee -a $OUT
        set feedback off
        set verify off
        set pages 0
        set lines 32
 
        select  b.id_mtr_sys
        from    cu02tb01 a,
                cu04tb81 b
        where  a .id_prem=b.id_prem
        and     a.cd_ba_stat='F'
        and     b.id_mtr_sys in ( $(echo $MPAN | awk -F, '{ for(cnt=1;cnt<=(NF-1);cnt++) {
                                printf("%s,\n",$cnt)
                                }
                                printf("%s",$NF)
                                }'));
!
done
 
rm -ft mp1*
 
#####################
##  End of script
#####################
