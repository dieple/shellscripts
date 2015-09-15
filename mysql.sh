#!/bin/bash

PROG="`basename $0`"
#DB_ROOTUSER="root"
#DB_ROOTPASSWD="mysqlr00t"
DB_ROOTUSER="lucas"
DB_ROOTPASSWD="password"
DB_NAME="lucas"
DB_USER="password"
DB_PASSWD=""
FLUSH_DB="FALSE"


create_db()
{

	# drop and recreate as user lucas already has priviledges
	#mysql --user=$DB_ROOTUSER --password=$DB_ROOTPASSWD << EOF  2>/dev/null
	mysql --user=$DB_ROOTUSER --password=$DB_ROOTPASSWD << EOF
	create database $DB_NAME;
	#create user '$DB_USER'@'localhost' identified by '$DB_PASSWD';
	#create user '$DB_USER'@'localhost' identified by '$DB_PASSWD'; 
	#grant all privileges on *.* to '$DB_USER'@'localhost' with grant option;
EOF
}

drop_db()
{

	#mysql --user=$DB_ROOTUSER --password=$DB_ROOTPASSWD << EOF  2>/dev/null
	mysql --user=$DB_ROOTUSER --password=$DB_ROOTPASSWD << EOF
	drop database $DB_NAME;
EOF
}


usage()
{
	echo ""
	echo "Usage: $PROG [options]"
	echo ""
	echo "[-d DB name to create] "
	echo ""
	echo "[-f Drop DB first] "
	echo ""
	echo "[-p password]"
	echo ""
	echo "[-u User name]"
	echo ""
}

#
# Main program
#
while getopts "d:fp:u:?" 2> /dev/null ARG
do
	case $ARG in

		d)	DB_NAME=$OPTARG;;

		f)	FLUSH_DB="TRUE";;

		p)	DB_PASSWD=$OPTARG;;

		u)	DB_USER=$OPTARG;;

		?)	usage
			exit 1;;
	esac	
done

#if [ -z "$DB_USER" ] || [ -z "$DB_PASSWD" ] || [ -z "$DB_NAME" ]
if [ -z "$DB_NAME" ]
then
	echo "All three paramters are required"
	usage
	exit 1
else
	if [ "$FLUSH_DB" = "TRUE" ]
	then
		drop_db
	fi

	create_db
fi

