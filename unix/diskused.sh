"DISKUSE" 21 lines, 433 characters 
cat <<!
Blocks     Bytes                MBytes     Directory
 
!
for dir in $(ls -al | grep "^d" | awk '{ if(NR>2) print $NF }')
do
        INFO=$(du -s $dir 2> /dev/null)
        BLOCKS=$(echo $INFO | awk '{ print $1 }')
        DIR=$(echo $INFO | awk '{ print $2 }')
BYTES=$(bc <<!
$BLOCKS * 512
!
)
MBYTES=$(bc <<!
scale=2
$BYTES / (1024* 1024)
!
)
 
echo $BLOCKS"   "$BYTES"        "$MBYTES"       "$DIR | awk '{ printf("%-10s %-20s %-10s %s\n",$1,$2,$3,$4) }'
done
 
Blocks     Bytes               MBytes     Directory
 
0              0                        0                 .elm
104        53248                .05                LOGIN
0              0                        0                 Mail
504392     258248704      246.28         PATCH_BACKUP
574056     293916672      280.30         PATCH_UNLOAD
1064       544768               .51             SKIP_SCRIPTS
165120     84541440        80.62          workarea

