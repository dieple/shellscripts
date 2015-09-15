#!/bin/bash


###
#
# To run only tests on the Angular stack:
#
###

PROG="`basename $0`"
LUCAS_HOME="/apps/alps/lucasware"
UNIT_TEST="FALSE"
E2E="FALSE"
SITE_DOC="FALSE"
CLASS_NAME=""


usage()
{
	echo ""
	echo "Usage: $PROG [options]"
	echo ""
	echo "[-c single test with class name] ----> mvn clean cobertura:cobertura -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f lucas-services/pom.xml -Dtest=ClassNameToTest"
	echo ""
	echo "[-e E2E test] ----> cd $LUCAS_HOME/lucas-amd; mvn clean install -Palltests -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk" 
	echo ""
	echo "[-u unit test ] ----> cd $LUCAS_HOME/lucas-amd; mvn clean test"
	echo ""
	echo "[-s Site Doc Generation] ----> cd $LUCAS_HOME; mvn clean site:site -Palltests -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk  -f lucas-services/pom.xml"
	echo ""
}


#
# Main program
#

while getopts "c:eus?" 2> /dev/null ARG
do
	case $ARG in

		c)	CLASS_NAME="$OPTARG";;

		e)	E2E="TRUE";;

		u)	UNIT_TEST="TRUE";;

		s)	SITE_DOC="TRUE";;

		?)	usage
			exit 1;;
	esac	
done

if [ ! -z "$CLASS_NAME" ]
then
	#
	# To run a single test, issue the command below:
	# For example:
	# mvn clean cobertura:cobertura -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f lucas-services/pom.xml -Dtest=LocationServiceFunctionalTests
	#
	cd $LUCAS_HOME
	mvn clean cobertura:cobertura -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f lucas-services/pom.xml -Dtest=$CLASS_NAME
	exit 0
fi

if [ "$E2E" = "TRUE" ]
then
	#
	# Unit tests + e2e tests
	#
	cd $LUCAS_HOME/lucas-amd
	mvn clean install -Palltests -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk 
	exit 0
fi

if [ "$UNIT_TEST" = "TRUE" ]
then
	#
	# Only unit tests:
	#
	cd $LUCAS_HOME/lucas-amd
	mvn clean test
	exit 0
fi

if [ "$SITE_DOC" = "TRUE" ]
then
	#
	# Generating Site Documentation
	# Site Documentation includes static analysis reports, test coverage reports and javadocs amongst others: 
	#
	# Access $LUCAS_HOME/lucas-services/target/site/index.html to view the reports 
	#
	cd $LUCAS_HOME
	mvn clean site:site -Palltests -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk  -f lucas-services/pom.xml
	exit 0
fi


###
# End
###
