# build parent
cd $LUCAS_HOME/lucas-parent
mvn clean install -f lucas-parent/pom.xml

# run tests and build projects
cd $LUCAS_HOME/lucas-parent
mvn clean install -DLUCAS_ENCRYPTION_PASSWORD=Hn4UKcorcdoQIFyby1BAs7ZQVmBm+NRk -Pall,dev,alltests -Dskip.liquibase=true -Dliquibase.password=l00casd3vdbus3r -Dlucas.mq.host=54.87.153.50

# deploy lucas-amd to beanstalk
cd $LUCAS_HOME/lucas-amd
mvn package beanstalk:upload-source-bundle beanstalk:create-application-version beanstalk:update-environment -Pbeanstalk,dev -DskipTests=true
# clean old lucas-amd versions from beanstalk
cd $LUCAS_HOME/lucas-amd
mvn package beanstalk:upload-source-bundle beanstalk:create-application-version beanstalk:update-environment -Pbeanstalk,dev -DskipTests=true
# deploy lucas-api to beanstalk
cd $LUCAS_HOME/lucas-rest-api
mvn package beanstalk:upload-source-bundle beanstalk:create-application-version beanstalk:update-environment -Pbeanstalk,dev -DskipTests=true
# cleanup old lucas-api versions from beanstalk
cd $LUCAS_HOME/lucas-rest-api
mvn br.com.ingenieux:beanstalk-maven-plugin:clean-previous-versions -Dbeanstalk.versionsToKeep=3 -Dbeanstalk.dryRun=false
