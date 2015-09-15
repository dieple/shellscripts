for pid in $(ps -fu  dieple | grep sqlplus | grep -v grep | awk '{ print $2 }')
do
	kill -9 $pid
done
