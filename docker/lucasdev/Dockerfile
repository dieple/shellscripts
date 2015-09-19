# My ubuntu devops development docker container

# DOCKER-VERSION 0.0.1
FROM      ubuntu:14.04

MAINTAINER Diep Le <dieple1@gmail.com>

# make sure the package repository is up to date
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get -y update

# install python-software-properties (so you can do add-apt-repository)
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties software-properties-common  && apt-get clean

# install SSH server so we can connect multiple times to the container
RUN apt-get -y install openssh-server && mkdir /var/run/sshd  && apt-get clean

# install oracle java from PPA
RUN add-apt-repository ppa:webupd8team/java -y
RUN apt-get update
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get -y install oracle-java8-installer && apt-get clean

# Set oracle java as the default java
RUN update-java-alternatives -s java-8-oracle
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.bashrc

# install utilities
RUN apt-get -y install vim git sudo zip bzip2 fontconfig curl byobu htop man wget  && apt-get clean

# install awscli
RUN apt-get install -yq --no-install-recommends awscli groff-base && apt-get clean

# install python
#RUN apt-get install -y python python-dev python-pip python-virtualenv

# install maven
RUN apt-get -y install maven  && apt-get clean

# install node.js
RUN curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
RUN apt-get install -y nodejs  && apt-get clean

# install yeoman & Jhipster
RUN npm install -g yo bower grunt-cli generator-jhipster@2.20.0

# configure the "devops" and "root" users
RUN echo 'root:devops' |chpasswd
RUN groupadd devops && useradd devops -s /bin/bash -m -g devops -G devops && adduser devops sudo
RUN echo 'devops:devops' |chpasswd

# install the sample app to download all Maven dependencies
RUN cd /home/devops && \
    wget https://github.com/jhipster/jhipster-sample-app/archive/v2.20.0.zip && \
    unzip v2.20.0.zip && \
    rm v2.20.0.zip
RUN cd /home/devops/jhipster-sample-app-2.20.0 && npm install
RUN cd /home && chown -R devops:devops /home/devops
RUN cd /home/devops/jhipster-sample-app-2.20.0 && sudo -u devops mvn dependency:go-offline

# expose the working directory, the Tomcat port, the BrowserSync ports, the SSHD port, and run SSHD
VOLUME ["/apps/sandboxes"]
EXPOSE 8080 3000 3001 22
CMD    /usr/sbin/sshd -D

