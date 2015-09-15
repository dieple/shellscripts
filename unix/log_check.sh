#!/usr/bin/ksh
PASSWORDS=/etc/passwd
cat <<!
Login                Real Name                              Shell
!
for user in $(cat $PASSWORDS | awk -F: '{ print $1 }')
do
	USER=$(echo $user | awk '{ printf("%-12s\n",$0)}')
	NAME=$(grep "^$user:" $PASSWORDS | awk -F: '{ print $5 }' | awk '{ printf("%-25s\n",$0)}')
	SHELL=$(grep "^$user:" $PASSWORDS | awk -F: '{ print $NF }')
	echo "$USER$NAME                "$SHELL
done

