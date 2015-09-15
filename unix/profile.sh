#!/usr/bin/ksh

###############
# User .profile file (Don't mess with it! - order by Dragon Lee)
#############

stty kill "^U" intr "^C" eof "^D"
#stty erase 

# Oracle

export ORACLE_SID=IA_PROD
export DB_LOGIN=ia_load/ia_load


# Set up the search paths:

export COBDIR=/opt/thirdpp/cobol 

PATH=/usr/bin:/usr/ucb:/opt/bin:/opt/thirdpp/oracle/u01/product/8.1.6/bin:/usr/sbin:/usr/ccs/bin:/usr/share/lib:/opt/thirdpp/SUNWspro/bin:/opt/mki/local/bin:/opt/mki/utils/bin:/opt/mki/bin:/opt/thirdpp/syncsort/bin:.
export PATH=$PATH:/opt/apps/ia/prod/bin:/opt/thirdpp/cobol/coblib/:${COBDIR}/bin/:${COBDIR}:/usr/lib

LD_LIBRARY_PATH=/opt/mki/utils/lib:/usr/ccs/lib:/opt/thirdpp/SUNWspro/lib:/usr/ucblib/:/opt/thirdpp/syncsort/lib:$COBDIR:${ORACLE_HOME}/lib/:/usr/lib/:/opt/thirdpp/cobol/coblib/:

export LD_LIBRARY_PATH


# Set up the shell environment:
	set -u
	trap "echo 'logout'" 0

# Set up the shell variables:
	EDITOR=vi
	export EDITOR
	export TERM=vt100
	umask 022

PS4='$0 line $LINENO: '
export PS4
alias trace="set -o xtrace"
alias notrace="set +o xtrace"

MAIL=/usr/mail/${LOGNAME:?}

export PS1="$LOGNAME@"`hostname`:'${PWD##*/}'" $ "


#
# Set up aliases
#

alias mv='mv -i'
alias l='ls -ltr'
alias p='ps -ef | grep '
alias rm='rm -i '
alias lt="ls -alFtr"
alias cc="/opt/thirdpp/SUNWspro/bin/cc"
alias lint='/opt/thirdpp/SUNWspro/bin/lint'
alias sccs='sccs -d /opt/apps/ia/prod'

export LPDEST=arn02p04    # Sets the printer default
