#!/usr/bin/ksh
# =====================================================================
#
# Script Name : taskreset -n -s
#
# Usage       : $0 -n -s
#    -n         TASKNAME - name of the task
#    -s         SOURCESYSTEM - name of the src system for the task
#
# Description : Resets a task in active/failed state ready for 
#               restarting.
#
# Called by   : Admin Tool /
#               or can be run stand alone - see Usage
#
# ---------------------------------------------------------------------
# Revision History
# Version    Date     Description
# ---------------------------------------------------------------------
# 1.0.0   24-09-1999  Created
# =====================================================================


# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# GLOBALS
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

SCRIPTCTL_HOME=/opt/apps/shellctl/


# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# USAGE
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

USAGE="
$0 - formatted list of scripts assoicated to a task
Version 1.0.0
Usage: $0 -n -s
\t -n        TASKNAME - name of the task 
\t -s        SOURCESYSTEM - name of the src system for the task
"

Usage ()
{
   if [[ -n $1 ]];
   then
      echo "$0: --illegal option -- $1"
      echo "${USAGE}" >&2
   else
      echo "Error: Insufficient arguments"
      echo "${USAGE}" >&2
   fi
   exit 1
}



# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# FUNCTIONS/PROCEDURES
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


function _au_task_status
{
    
   _PROGSTAT=`$SCRIPTCTL_HOME\db_task_info -n"$_TASKNAME" -s"$_SRCSYSTEM"`

   # check return code
   _RETURN=`echo $_PROGSTAT | cut -f1 -d~` 

   if [ "$_RETURN" = "0" ]
   then
      # derive current task status parameters

      _TASKID=`echo $_PROGSTAT | cut -f2 -d~`
      _CUR_SCRIPTID=`echo $_PROGSTAT | cut -f5 -d~`
      _CUR_SCRIPTSTATUS=`echo $_PROGSTAT | cut -f6 -d~`
      _END_SCRIPTID=`echo $_PROGSTAT | cut -f8 -d~`

   else
      _LBR_err
      echo "ERROR                : the Task ID and/or Source system "
      echo "                       specified is not valid/registered"
      echo "                       with scriptctl"
      _LBR_err
      exit 1
   fi

}


# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function _au_reset 
{
   #update the task log with script reset 
   $SCRIPTCTL_HOME\db_task_update -i$_TASKID -m0 -sR
   if (( $? ));
   then
      _LBR_err
      echo "ERROR                : Task failed to reset"
      _LBR_err
      exit 1
   else
      echo "Task reset and ready to restart" 
   fi

}


# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function _LBR {
   echo "-----------------------------------------------------------"
}

function _LBR_err {
   echo "*---------------------------------------------------------*"
}



# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# M A I N
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


while getopts "n:s:r:" option; 
do
   case "$option" in
   n) _TASKNAME="${OPTARG}";;
   s) _SRCSYSTEM="${OPTARG}";;
   *) Usage $option;;
   esac
done

if [[ -z "$_TASKNAME" ]] ||
   [[ -z "$_SRCSYSTEM" ]] 
then
   Usage;
fi


_LBR
echo "Resetting Task Name    : $_TASKNAME"
echo "          Source system: $_SRCSYSTEM"
_LBR

# get the tasks current status #
_au_task_status

# perform the rest #
_au_reset


