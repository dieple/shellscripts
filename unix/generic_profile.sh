".profile" 255 lines, 5212 characters 
trap 'print "Escape or CTL-C not permitted whilst logging in."; exit' INT TERM
 
# @(#) $Revision: 72.2 $
 
# Default user .profile file (/usr/bin/sh initialization).
 
# Set up the terminal:
        if [ "$TERM" = "" ]
        then
                review ` tset -s -Q -m ':?hp' `
        else
                review ` tset -s -Q `
        fi
        stty erase "^H" kill "^U" intr "^C" eof "^D"
        stty hupcl ixon ixoff
        tabs
 
# Set up the search paths:
        PATH=$PATH:.
 
# Set up the shell environment:
        set -u
        trap "echo 'logout'" 0
 
# Set up the shell variables:
        EDITOR=vi
        export EDITOR
 
        export TERM=vt100
        export MLC=/home/dieple/bin/menus/
        umask 066
 
PS4='$0 line $LINENO: '
export PS4
alias trace="set -o xtrace"
alias notrace="set +o xtrace"
 
# @(#) $Revision: 72.2 $
 
# Default user .profile file (/usr/bin/sh initialization).
 
# Set up the terminal:
        if [ "$TERM" = "" ]
        then
                review ` tset -s -Q -m ':?hp' `
        else
                review ` tset -s -Q `
        fi
        stty erase "^H" kill "^U" intr "^C" eof "^D"
        stty hupcl ixon ixoff
        tabs
 
        export TERM=vt100
 
        PS4='$0 line $LINENO: '
        export PS4
 
# Set up the shell environment:
        set -u
        trap "echo 'logout'" 0
 
# Set up the shell variables:
        EDITOR=vi
        export EDITOR
 
# Oracle
        export ORACLE_HOME=/u01/home/dba/oracle/product/7.3.4
        export ULOGDIR=$HOME/logging
 
# Additions to path
        export PATH=/home/tx92b01/bin:$PATH:$ORACLE_HOME/bin
 

# @(#) $Revision: 72.2 $
 
# Default user .profile file (/usr/bin/sh initialization).
 
# Set up the terminal:
        if [ "$TERM" = "" ]
        then
                review ` tset -s -Q -m ':?hp' `
        else
                review ` tset -s -Q `
        fi
        stty erase "^H" kill "^U" intr "^C" eof "^D"
        stty hupcl ixon ixoff
        tabs
 
        export TERM=vt100
 
        PS4='$0 line $LINENO: '
        export PS4
 
# Set up the shell environment:
        set -u
        trap "echo 'logout'" 0
 
# Set up the shell variables:
        EDITOR=vi
        export EDITOR
 
# Oracle
        export ORACLE_HOME=/u01/home/dba/oracle/product/7.3.4
        export ULOGDIR=$HOME/logging
 
# Additions to path
        export PATH=$PATH:$ORACLE_HOME/bin:$HOME/bin
 
get_pass(){
CHKLOOP=0
while [ $CHKLOOP -eq 0 ]
do
tput clear
cat <<!
####################################################################################
 
                            ##  ORACLE LOG ON  ##
 
In order to set up aliases for sqla & sqlb please enter your oracle login details:
 
!
echo "Login (or press Enter to accept default of \"$LOGNAME\") :\c"
stty -echo
read ORACLE_CUST_USER
stty echo
echo
if [ x"$ORACLE_CUST_USER" = "xCUSONLINE" ]
then
        echo "CUSONLINE Not permitted. Please enter YOUR OWN account details."
        sleep 3
else
        CHKLOOP=1
fi
done
if [ x"$ORACLE_CUST_USER" = "x" ]
then
        ORACLE_CUST_USER=$LOGNAME
fi
if [ x"$ORACLE_CUST_USER" = "xUNIX" ] || [ x"$ORACLE_CUST_USER" = "xunix" ]
then
        echo "$(tput blink) Warning .... Your ORACLE environment has not been set up $(tput rmso)"
        #
        # If a ".ownprofile" exists then execute it
        #
 
        if [ -s $HOME/.ownprofile ]
        then
                . $HOME/.ownprofile
        fi
        #
        # Print MOTD file (If it exists)
        #
        group=$(id | awk '{ print $2 }' | sed s/")"/" "/g | sed s/"("/" "/g | awk '{ print $2 }')
        if [ -s /home/tx92b01/LOGIN/motd/$group ]
        then
                cat /home/tx92b01/LOGIN/motd/$group
        fi
        #
        # Reset Traps
        #
        trap INT TERM
        /usr/bin/ksh
        exit
fi
echo "Password: \c"
stty -echo
read ORACLE_CUST_PASSWORD
stty echo
echo
}
 
test_login(){
CHECK=$(sqlplus $ORACLE_CUST_USER/$ORACLE_CUST_PASSWORD@CR3PRA1 <<! | grep "ORACLE not available" | wc -l
exit
!
)
}
 
validate_oracle(){
CHECKLOGIN=1
while [ $CHECKLOGIN -eq 1 ]
do
        get_pass
        test_login
        CHECKLOGIN=$CHECK
        if [ $CHECKLOGIN -eq 1 ]
        then
                echo "\nInvalid Oracle Account / Password Combination .."
                echo "\n======= Press Enter to Continue ======= \c"
                read CONT
        fi
done
 
echo "Your Oracle login has been validated. Use sqla for CR3PRA1 and sqlb for CR3PRB1.\n"
}
stty erase ^H
ORACLE_CUST_USER=""
ORACLE_CUST_PASSWORD=""
 
validate_oracle
 
#
# Set up aliases
#
 
export ORACLE_CUST_USER ORACLE_CUST_PASSWORD
#export PS1=`hostname`:$LOGNAME:'$PWD'" >"
export PS1="DRAGON:"'$PWD> '
export ORACLE_HOME=/u01/home/dba/oracle/product/7.3.4
export ULOGDIR=$HOME/logging
export EPPS_ID=epps_read
export EPPS_PASS=eppsread
export ESRSNAME=led
export ESRSPASS=temp75
export USERNAME=$ORACLE_CUST_USER
export PASSWD=$ORACLE_CUST_PASSWORD
export CAPPS_ID=$ORACLE_CUST_USER
export CAPPS_PASS=$ORACLE_CUST_PASSWORD
 

alias rm='rm -i'
alias mv='mv -i'
alias lt="ls -ltr"
alias wa='cd /home/dieple/workarea'
alias bn='cd /home/dieple/bin'
alias op='cd /home/dieple/bin/output'
alias tp='cd /home/dieple/bin/temp'
alias sq='cd /home/dieple/bin/sql_scripts'
alias ad='cd /home/dieple/bin/adhocs'
alias to='cd /home/tx92b01/OSE_SCRIPTS/output'
alias pl='cd /home/dieple/workarea/plsql'
alias mp='cd /home/dieple/bin/adhocs/input_mpans'
alias ca='cd /capps/workarea/diep'
 
alias sqla='print " LOGGED IN TO <CR3PRA1> "; sqlplus $USERNAME/$PASSWD@CR3PRA1'
alias sqlb='print " LOGGED IN TO <CR3PRB1> "; sqlplus $USERNAME/$PASSWD@CR3PRB1'
alias sqlc='print " LOGGED IN TO <EPPS> "; sqlplus $EPPS_ID/$EPPS_PASS@EPPP'
alias sqld='print " LOGGED IN TO <ESRS> "; sqlplus $ESRSNAME/$ESRSPASS@carep1'
 
.my_motd
print "\n\n"
banner DRAGON LEE
print "\n\n"
#
# If a ".ownprofile" exists then execute it
#
 
if [ -s $HOME/.ownprofile ]
then
        . $HOME/.ownprofile
fi
#
# Reset Traps
#
trap INT TERM

