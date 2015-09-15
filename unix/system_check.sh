#"check" 43 lines, 1723 characters 
#!/bin/ksh
#############################
## script to monitor PUST92
#############################
 
BOLD=$(tput bold)
RESET=$(tput rmso)
BLINK=$(tput blink)
HOSTNAME=$(uname -n)
 
LOG=$HOME/bin/SQL_LOG
 
whilet rue
do
        clear
        print  "$BLINK$HOSTNAME System check... $RESET \n"
        AVAIL1=$(df -b /home | awk '{print $5}')
        AVAIL2=$(df -b /capps | awk '{print $5}')
        print "$BLINK DISK SPACE AVAILABLE = $AVAIL1 KBytes mounted at '/home partition'$RESET "
        print "$BLINK DISK SPACE AVAILABLE = $AVAIL2 KBytes mounted at '/capps partition'$RESET\n"
        if [[ $AVAIL1 -lt 100000 || $AVAIL2 -lt 100000 ]]               # If disk space is <100 MB left
        #if [[ $AVAIL1 -lt 30000 || $AVAIL2 -lt 30000 ]]                # If disk space is <30 MB left
        then                                                            # All hell break loose
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"
                print "\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a"      # that should wake you up!
                print "$BLINK Warning: diskspace is  CRITICALLY LOW $RESET"
                exit 1
        fi
        TODAY=$(date)
        print "$BLINK$TODAY$RESET\n"  | tee -a $LOG
        ps -eaf | grep sql | grep -v grep | sort | awk  -F\t '{print $1, $8, $9}' | tee -a $LOG
        sleep 10
        clear
        top -d 2
done
