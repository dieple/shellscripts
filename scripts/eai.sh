#!/bin/bash


###
#
# Script to build the ALPS code base...
#
###

PROG="`basename $0`"

# up the heap for E2E test run to succeed
export MAVEN_OPTS=-XX:MaxPermSize=256m
ENC_PASSWD="LUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk"
DB_USER="lucas"
DB_PASSWD="password"
#LOG_FILE=/tmp/"$PROG""_$$.log"
LOG_FILE=/tmp/"$PROG.log"

INITIAL="FALSE"
SKIP_TEST="FALSE"
RUN_NO_DB="FALSE"
BUILD_UNIT="FALSE"
RUN_WITH_LIQUIBASE="FALSE"
FLUSH_DB="FALSE"
DEBUG_MODE="FALSE"
RUN_MVN="mvn clean install"
RUN_ALL_STEPS="FALSE"
RUN_AMD_ONLY="FALSE"


usage()
{
	echo ""
	echo "Usage: $PROG [options]"
	echo ""
	echo "[-a run all steps] "
	echo ""
	echo "[-b build with unit test] ----> mvn clean install -D$ENC_PASSWD -f lucas-parent/pom.xml -Pall"
	echo ""
	echo "[-f flush DB] (optional to be used together with -r option)"
	echo ""
	echo "[-i initial build] ----> mvn clean install -f lucas-parent/pom.xml"
	echo ""
	echo "[-m run AMD only----> mvn clean install -D$ENC_PASSWD -Palltests"
	echo ""
	echo "[-n run unit, functional tests (no liquibase)] ----> mvn clean install -D$ENC_PASSWD -f lucas-parent/pom.xml -Pall,alltests"
	echo ""
	echo "[-l all with liquibase, functional tests (with liquibase)] ----> mvn clean install -D$ENC_PASSWD -f lucas-parent/pom.xml -Pall,alltests -Dskip.liquibase=false -Dliquibase.password=password"
	echo ""
	echo "[-s skip test] ----> mvn clean install -DskipTests=true -f lucas-parent/pom.xml -Pall"
	echo ""
	echo "[-x Verbose debug mode]"
	echo ""
}

flush_db()
{

	# drop and recreate as user lucas already has priviledges
	mysql --user=$DB_USER --password=$DB_PASSWD << EOF  2>/dev/null
	drop database lobdb;
	create database lobdb;
EOF
}

check_build_error()
{
	grep "BUILD FAILURE" $LOG_FILE >/dev/null 2>&1

	if [ $? = 0 ]
	then
		# there are errors - tell user where to find the log file...
		echo ""
		echo "###################################################"
		echo "Error: See logfile $LOG_FILE for more details"
		echo "###################################################"
		echo ""
		exit 0
	fi

	if [ "$RUN_ALL_STEPS" = "FALSE" ]
	then
		# exit after each step
		exit 0
	fi
}

run_initial()
{
	#
	# Building the code base - This step will be required to be 
	# carried out ONE time per developer instance. It creates a 
	# parent project that is used by all other projects. Once carried out, 
	# builds should be carried out from lucas-parent directory as 
	# outlined from step 2 below. Once the corporate repository is 
	# in place, this step will not be necessary.
	cd $EAI_HOME
	$RUN_MVN -f lucas-parent/pom.xml >> $LOG_FILE 2>&1
	check_build_error
}

run_skip_test()
{
	#
	# This will build the app in the corresponding target directories
	#
	cd $EAI_HOME
	$RUN_MVN -DskipTests=true -f lucas-parent/pom.xml -Pall >> $LOG_FILE 2>&1
	check_build_error
}

run_build_unit()
{
	#
	# To build the code with unit tests, you must specify the 
	# encryption key as below:
	#
	cd $EAI_HOME
	$RUN_MVN -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f lucas-parent/pom.xml -Pall  >> $LOG_FILE 2>&1
	check_build_error
}

run_no_db()
{
	#
	# To run all unit and functional tests with no liquibase:
	#
	stop_tomcat
	cd $EAI_HOME
	$RUN_MVN -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f lucas-parent/pom.xml -Pall,alltests >> $LOG_FILE 2>&1
	check_build_error
}

run_with_liquibase()
{
	#
	# first check whether the user want to flush the DB first for liquibase successful run
	#
	if [ "$FLUSH_DB" = "TRUE" ]
	then
		flush_db
	fi

	#
	# To run all unit tests and functional tests AND run liquibase scripts, issue:
	#
	stop_tomcat
	cd $EAI_HOME
	$RUN_MVN -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f lucas-parent/pom.xml -Pall,loc,alltests -Dskip.liquibase=false -Dliquibase.password=password  >> $LOG_FILE 2>&1
	check_build_error
}



###
# Main program
###

while getopts "abfilmnsx?" 2> /dev/null ARG
do
	case $ARG in

		a)	RUN_ALL_STEPS="TRUE";;

		b)	BUILD_UNIT="TRUE";;

		f)	FLUSH_DB="TRUE";;

		i)	INITIAL="TRUE";;

		l)	RUN_WITH_LIQUIBASE="TRUE";;

		m)	RUN_AMD_ONLY="TRUE";;

		n)	RUN_NO_DB="TRUE";;

		s)	SKIP_TEST="TRUE";;

		x)	DEBUG_MODE="TRUE";;

		?)	usage
			exit 1;;
	esac	
done

if [ -f $LOG_FILE ]
then
	#echo "Removing previous log..."
	rm $LOG_FILE
fi

if [ "$DEBUG_MODE" = "TRUE" ]
then
	RUN_MVN="mvn -X clean install"
fi

if [ "$RUN_AMD_ONLY" = "TRUE" ]
then
	$HOME/bin/setup_common_services
	cd $EAI_HOME/lucas-amd

	$RUN_MVN -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -Palltests >> $LOG_FILE 2>&1
	check_build_error
	exit 0;
fi

if [ "$RUN_ALL_STEPS" = "TRUE" ]
then
	run_initial
	run_skip_test
	run_build_unit
	#run_no_db
	run_with_liquibase
	check_build_error
	exit 0;
fi

if [ "$INITIAL" = "TRUE" ]
then
	run_initial
fi

if [ "$SKIP_TEST" = "TRUE" ]
then
	run_skip_test
fi

if [ "$BUILD_UNIT=" = "TRUE" ]
then
	run_build_unit
fi

if [ "$RUN_NO_DB" = "TRUE" ]
then
	run_no_db
fi

if [ "$RUN_WITH_LIQUIBASE" = "TRUE" ]
then
	run_with_liquibase
fi


###
# End
###
