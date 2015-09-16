#!/bin/bash

###
# Makes a non git directory to a new private bitbucket repository with all files added to initial commit
# Usage = enter your bitbucket username and password in the script
###

PROG="`basename $0`"
GIT_USER=""
GIT_PASSWD=""
GIT_REPO_NAME=""
RUN="FALSE"

usage()
{
	echo ""
	echo "Usage: $PROG [options]"
	echo ""
	echo "[-n repo name]  Repository name to create"
	echo ""
	echo "[-p password]   Password"
	echo ""
	echo "[-u username]   Username"
	echo ""
}

confirm_current_location()
{
	DIR=`pwd`
	echo "Current directory is:"
	echo "$DIR"
	ls -al
	echo ""
	
	echo "Are you sure you want to create Git repository $GIT_REPO_NAME [Y/N]?"
	read ANS

	if [ "$ANS" = "Y" ] || [ "$ANS" = "y" ]
	then
		RUN="TRUE"
	fi
	
}

#
# Main program
#

while getopts "n:p:u:?" 2> /dev/null ARG
do
	case $ARG in

		n)	GIT_REPO_NAME=$OPTARG;;

		p)	GIT_PASSWD=$OPTARG;;

		u)	GIT_USER=$OPTARG;;

		?)	usage
			exit 1;;
	esac	
done

if [ "$GIT_REPO_NAME" = "" ]
then
        echo ""
        echo "$PROG: Repository name is required !"
        echo ""
	usage
        exit 1
fi

if [ "$GIT_PASSWD" = "" ]
then
        echo ""
        echo "$PROG: Password is required !"
        echo ""
	usage
        exit 1
fi

if [ "$GIT_USER" = "" ]
then
        echo ""
        echo "$PROG: User is required !"
        echo ""
	usage
        exit 1
fi

confirm_current_location

if [ "$RUN" = "TRUE" ]
then
	git init
	git add -A .
	git commit -m "Initial commit"
	echo "Creating new remote repo on bitbucket"
	curl --user $GIT_USER:$GIT_PASSWD https://api.bitbucket.org/1.0/repositories/ --data name=$GIT_REPO_NAME --data is_private='true'
	git remote add origin git@bitbucket.org:$GIT_USER/$GIT_REPO_NAME.git
	git push -u origin --all
	git push -u origin --tags
fi

###
# END
###

mkdir /path/to/your/project
cd /path/to/your/project
git init
git remote add origin git@bitbucket.org:dieple/wms.git

Create your first file, commit, and push

echo "Diep Le" >> contributors.txt
git add contributors.txt
git commit -m 'Initial commit with contributors'
git push -u origin master
