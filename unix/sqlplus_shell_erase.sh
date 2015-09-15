#!/usr/bin/ksh
HERE1=/tmp/HERE1$$
HERE2=/tmp/HERE2$$
trap 'rm -f $HERE1 ;  rm -f $HERE2 ; exit' INT TERM
echo $ORACLE_CUST_USER/$ORACLE_CUST_PASSWORD $*  > $HERE1
cat > $HERE2
#
# Script to intercept calls to "sqlplus" and execute them in a "here" document
# ensuring that the oracle "login" and "password" are not viewable from the UNIX "ps"
# command
#
real_sqlplus=/u01/home/dba/oracle/product/7.3.4/bin/sqlplus
cat $HERE2 >> $HERE1
$real_sqlplus <  $HERE1
rm -f $HERE1
rm -f $HERE2
trap INT TERM