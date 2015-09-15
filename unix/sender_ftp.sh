sender(){
FILE=$1
DIR=$2
SRCDIR=$(echo $FILE | awk -F\/ '{  for (cnt=1;cnt<NF;cnt++)
                                        {
                                                printf("%s\/",$(cnt))
                                        }
                                        printf("\n")
                                        }')
cd $SRCDIR
file=$(echo $FILE | awk -F\/ '{ print $NF }')
HOST="10.16.7.4"
USERNAME="osecheck"
PASSWORD="osecheck"
export USERNAME PASSWORD DIR FILE
ftp -ni $HOST <<! 2> /dev/null
user "$USERNAME" "$PASSWORD"
cd Am
cd $DIR
del $file
put $file
bye
!
##
# Verify transfer
##
VERIFY=$(ftp -ni $HOST <<! | grep $file | wc -l
user "$USERNAME" "$PASSWORD"
cd Am
cd $DIR
dir $file
bye
!)
 
if [ $VERIFY -eq 1 ]
then
        echo "\nFILE: "$FILE" Has been transferred to OSE-HEALTHCHECK\\AM\\$DIR\n"
else
        echo "\nFILE: "$FILE" Failed to transfer\n"
fi
}
 
test_login(){
CHECK=$(sqlplus $ORACLE_CUST_USER/$ORACLE_CUST_PASSWORD@CR3PRA1 <<! | grep "ORACLE not available" | wc -l
exit
!
)
}