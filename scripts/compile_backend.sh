#!/bin/bash

cd $LUCAS_HOME
mvn clean install -DskipTests=true -f lucas-parent/pom.xml -Pall

