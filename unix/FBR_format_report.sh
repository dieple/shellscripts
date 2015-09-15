"FBR_format_report.scr" 25 lines, 676 characters 
echo '' >$ 3
echo '' > $3
i=1
j=1
sed -e 's/ /@/g' $1 >$1x
date | cut -c 1-10 | read rundate
while read LINE
do
    if [ "$i" -eq 1 ]
    then
       echo '^L' >> $3
       echo '                                       (' $j ')                                ' >> $3
       echo '          ' $2 ' ' $rundate& gt;> $3
       echo '   MSID       Account No.    SSD    Date of Next Bill  Date Bill Stop  Move OutP ending ' >> $3
       echo '   ----       -----------    ---    -----------------  --------------  ---------------- ' >> $3
    fi
 
    echo $LINE | sed -e 's/@/ /g' >> $3
    i=`expr $i + 1`
    if [ "$i" -ge 50 ]
    then
       i=1
       j=`expr $j + 1`
    fi
done < $1x
rm $1x

