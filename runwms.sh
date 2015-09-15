#!/bin/bash

# build
cd $LUCAS_HOME
mvn clean install -f wms-parent/pom.xml
mvn clean install -DskipTests=true -f wms-parent/pom.xml -Pall

# run test
#To build the code with unit tests, you must specify the encryption key as below:
mvn clean install -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f wms-parent/pom.xml -Pall


# To run unit tests and functional tests, issue:
 mvn clean install -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f wms-parent/pom.xml -Pall,alltests

# To run unit tests and functional tests AND run liquibase scripts, issue:
mvn clean install -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f wms-parent/pom.xml -Pall,alltests -Dskip.liquibase=false -Dliquibase.password=password

# To run unit tests and functional tests AND run liquibase scripts, issue: (Running locally against remote api server)
mvn clean install -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -f wms-parent/pom.xml -Pall,loc,alltests -Dskip.liquibase=false -Dliquibase.password=password
