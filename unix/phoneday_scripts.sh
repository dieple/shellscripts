"phoneday2" 1365 lines, 51375 characters 
#!/bin/ksh
#set -x
########################################################################
#
# UNIX SCRIPT SHELL
#
# IDENTIFICATION
#
# SYSTEMS: Customer/1 (UK) & ePPS
#
# PROGRAM NAME : phoneday2
#
# SHELL TYPE : Korn Shell
#
# DESCRIPTION :
#
# PURPOSE :
# This script will allow flexible reporting and fixing of phone numbers
# in accordance with OFTEL's PhoneDay 2 requirements. The usual sequence
# of events would be to issue the line command (phoneday2) followed by
# -s for the first run, -e for the next and then -u for the last.
# phoneday2 -s is not expected to be run twice in succession without an
# intervening phoneday2 -u run.
#
#
# CONCEPTS :
# 1)  This script includes embedded scripts for SQL, PL/SQL and awk.
#     They are extracted using the ConstructScript function, writing them
#     to a temporary file for subsequent processing by SQL*Plus or awk.
#
# 2)  This script has one logging function, LogMessage, which will write
#     lines to the log as the job progresses.
#
# USAGE:
#     phoneday2 [-s] [-e] [-u] [nnnn] [on|before|after] [dd/mm/yyyy]
#
# PROGRAMMER : Grahame Taylor
#
# REVISION TRAIL:
# Date          Programmer       STIR Number/Desc.
#
#
# PROCEDURES:
#   The following procedures have been defined and used within this script:
#
# Initialise()
# LogMessage()
# Finalise()
# ErrorMessage()
# CreateFile()
# Usage()
# GetArgs()
# ConstructScript()
# ConstructPartScript()
# ConstructAwkScript()
# GetPartitions()
# ConstructScanScript()
# ConstructReportScript()
# ConstructUpdateScript()
# ConstructRevertScript()
#
########################################################################
 
#=======================================================================
# Declare variables
#=======================================================================
Initialise(){
  ERR_NUM=0
  COMMIT_BLOCK=100000
  SCAN=FALSE
  REPORT=FALSE
  UPDATE=FALSE
  REVERT=FALSE
  EFF_DATE=""
  DETAILS=ALL
  OPERATOR=""
  OPERATOR_TEXT="on"
  FILEBASE=`mktemp`
  LOGFILE=$BATCHFILE_PATH/$THIS.`date +"%Y_%m_%d"`
  ERR_DETAIL_FILE=$HOME/${THIS}_`date +"%Y%m%d%H%M%S"`.err
  ERR_SUMMRY_FILE=$HOME/${THIS}_`date +"%Y%m%d%H%M%S"`.sum
  CONTROL_FILE=$HOME/$THIS.tabs
  if [[ -z ${ORACLE_ARC_USER:-"" }     ||
        -z ${ORACLE_ARC_PASSWORD:-"" } ||
        -z ${ORACLE_ARC_SERVER:-"" } ]] then
     ErrorMessage "One of the ORACLE environment variables is not set"
  fi
  case $ORACLE_ARC_SERVER in
    CR3PRB1)
        DEFAULT_SERVER=CR3PRA1
        ;;
    CR3VLB1)
        DEFAULT_SERVER=CR3VLA1
        ;;
    *)
        DEFAULT_SERVER=$ORACLE_ARC_SERVER
  esac
  if [[ ! -r $CONTROL_FILE ]] then
     ErrorMessage "The control file, $CONTROL_FILE, is not readable"
  fi
}
 

#=======================================================================
# Issue message to the log
# $1 - Message to log
#=======================================================================
LogMessage(){
  echo `date +"%d/%m/%Y %r "`"$THIS: $1" >> $LOGFILE
  echo "" >> $LOGFILE
}
 

#=======================================================================
# Clearup for the end of the run
# Remove temporary files only if all is well
#=======================================================================
Finalise(){
  LogMessage "Closing down..."
  if [[ $ERR_NUM -eq 0 ]] then
     LogMessage "$THIS completed successfully"
     LogMessage "Clearing up temporary files"
     rm -f $FILEBASE.* > /dev/null 2> /dev/null
     echo " $THIS completed successfully at "`date +"%d/%m/%Y %r"`
  else
     LogMessage "$THIS closing with return code: $ERR_NUM"
     LogMessage "Program terminated abnormally"
     LogMessage "Examine $FILEBASE.* files for details"
     echo " Error code $ERR_NUM"
     echo " "
     echo " $THIS aborted at "`date +"%d/%m/%Y %r"`
  fi
  LogMessage "Finish"
  echo " "
  exit $ERR_NUM
}
 
#=======================================================================
# Terminate run with message to log
# $1 - Message to log
# $2 - Error number
# $3 - Origin of error (e.g. PL/SQL, AWK etc.)
#=======================================================================
ErrorMessage(){
  if [[ $# -lt 2 ]] then
     ERR_NUM=1
  else
     ERR_NUM=$2
  fi
 
  if [[ -n $3 ]] then
     SOURCE=$3
  else
     SOURCE=$THIS
  fi
 
  if [[ $ERR_NUM -ne 0 ]] then
     LogMessage "*** FATAL ERROR $ERR_NUM ***"
  fi
  LogMessage "$1"
  echo " \"$1\" \n ...RETURNED BY $SOURCE"
  Finalise
}
 

#=======================================================================
# Create a file and assign it to a script variable
# $1 - name of the variable
# $2 - name of the file
#=======================================================================
CreateFile(){
  if [[ -a $2 ]] then
     ErrorMessage "The temp file for $1, $2, already exists"
  fi
  touch $2 > /dev/null 2> /dev/null
  if [[ $? -ne 0 ]] then
     ErrorMessage "Could not create file $2"
  fi
  export $1=$2
}
 

#========================================================================
# Display help information
#========================================================================
Usage(){
  echo " "
  echo " "
  echo "Usage: $THIS [-s] [-e] [nnnn] [-u] [when] [dd/mm/yyyy]"
  echo " "
  echo "         -s .... scan for errors and changes"
  echo "         -e .... produce error report from a previous scan"
  echo "       nnnn .... restrict error report to nnnn records (default is ALL)"
  echo "         -u .... perform updates from a previous scan"
  echo "       when .... on, before or after (default is on)"
  echo " dd/mm/yyyy .... report errors (-e) or update (-u) for"
  echo "                  -s runs performed on, before or after (when)"
  echo "                  this date. (default is today)"
  echo " "
  echo " "
}
 

#========================================================================
# Pull in arguments and assign to variables
#========================================================================
GetArgs(){
  while [ $# -gt 0 ]
  do
    case $1 in
      -s)
           SCAN=TRUE
           shift ;;
      -e)
           REPORT=TRUE
           shift ;;
      -u)
           UPDATE=TRUE
           shift ;;
 
      on|before|after)
           if [[ $OPERATOR != "" ]] then
              Usage
              ErrorMessage "Two 'when' arguments have been passed"
           else
              OPERATOR_TEXT=$1
              case $1 in
 
                on)     OPERATOR="=" ;;
                before) OPERATOR="<" ;;
                after)  OPERATOR=">" ;;
              esac
           fi
           shift ;;
 
      [0-3][0-9]/[0-1][0-9]/200[0-3])
           EFF_DATE=$1
           shift ;;
 
      [1-9]|[1-9][0-9]|[1-9][0-9][0-9]|[1-9][0-9][0-9][0-9])
           DETAILS=$1
           shift ;;
 
      REVERT)
           REVERT=TRUE
           shift ;;
 
      -h)
           Usage
           Finalise ;;
 
      *)
           Usage
           ErrorMessage "Bad parameter passed ($1)"
    esac
  done
 
#-----------------------------------------------------------------------
# If a number has been provided, assume that a report is required
#-----------------------------------------------------------------------
  if [[ $DETAILS != "ALL" ]] then
     REPORT=TRUE
  fi
 
#---------------------------------------------------------------------
# Check consistency of arguments
#---------------------------------------------------------------------
  if [[ $OPERATOR = "" ]] then
     OPERATOR="="
  else
     if [[ $REPORT = "FALSE"
     &&    $UPDATE = "FALSE"
     &&    $REVERT = "FALSE" ]] then
        Usage
        ErrorMessage "You can't specify 'when' without options -e or -u"
     fi
  fi
 
#---------------------------------------------------------------------
# Check date
#---------------------------------------------------------------------
  TODAY=`date +"%Y%m%d"`
  if [[ $EFF_DATE = "" ]] then
     if [[ $OPERATOR_TEXT = "after" ]] then
        EFF_DATE="01/01/2000"
     else
        EFF_DATE=`date +"%d/%m/%Y"`
     fi
  else
     if [[ $REPORT = "FALSE"
     &&    $UPDATE = "FALSE"
     &&    $REVERT = "FALSE" ]] then
        Usage
        ErrorMessage "You can't specify a date without options -e or -u"
     fi
  fi
  EFF_YYYY=`echo $EFF_DATE |  cut -d/ -f3`
  EFF_m=`echo $EFF_DATE | cut -d/ -f2`
  EFF_d=`echo $EFF_DATE | cut -d/ -f1`
  R_EFF_DATE=`echo $EFF_YYYY$EFF_m$EFF_d`
  if [[ $R_EFF_DATE > $TODAY ||
        $EFF_d      > 31     ||
        $EFF_m      > 12     ||
        $EFF_d      < 01     ||
        $EFF_m      < 01       ]] then
     Usage
     ErrorMessage "There is something wrong with the date"
  fi
  if [[ $EFF_d > 28 ]] then
     if [[ $EFF_m = 02 ]] then
        ErrorMessage "February has only 28 days"
     else
        if [[ $EFF_d = 31
        &&   ( $EFF_m = 04 ||
               $EFF_m = 06 ||
               $EFF_m = 09 ||
               $EFF_m = 11 )  ]] then
           Error Message "Too many days for the given month"
        fi
     fi
  fi
  TODAY=`date +"%d/%m/%Y"`
 
#-----------------------------------------------------------------------
# Confirm details with operator
#-----------------------------------------------------------------------
  echo " "
  echo " "
  echo "The options you have requested are..."
  echo "================================================================"
  if [[ $SCAN = "TRUE" ]] then
     echo "Scan required"
  fi
  if [[ $REPORT = "TRUE" ]] then
     echo "Report required from scan(s) done" $OPERATOR_TEXT $EFF_DATE
     echo "...."$DETAILS "records required"
  fi
  if [[ $UPDATE = "TRUE" ]] then
     echo "Apply update from scan(s) done" $OPERATOR_TEXT $EFF_DATE
  fi
  if [[ $REVERT = "TRUE" ]] then
     echo "REVERT to original phone numbers updated" $OPERATOR_TEXT $EFF_DATE
  fi
 
  echo "The tables involved will be..."
  cat $CONTROL_FILE | \
  while read record
  do
      TABLE_NAME=`echo $record | cut -d: -f1`
      if [[ $TABLE_NAME != "#" ]] then
         echo $TABLE_NAME
      fi
  done
 
  echo "================================================================"
  echo "Do you wish to proceed? enter YES for yes:"
  read ans
  if [[ $ans != "YES" ]] then
     echo "Ok, no go"
     Usage
     Finalise
  else
     echo "All temporary files will be saved as $FILEBASE.*"
  fi
}
 

#=======================================================================
# Search for lines from this file which begin with a given string. Put
# these lines (without the search string) into a given file
# $1 - string to search for
# $2 - file into which to put the script
#=======================================================================
ConstructScript(){
  LogMessage "Constructing embedded file $1"
  grep '#'$1 $THIS | cut -c `expr ${#1} + 3`- > $2
  CMD_ERR=$?
  if [[ $CMD_ERR -ne 0 ]] then
     ErrorMessage "Error constructing script file $1"
  fi
}
 

#=======================================================================
# This determines the list of partitions. It is prefixed with DATA to
# ensure that the awk script picks up only partitions. The output from
# this goes into PART_SCRIPT
#=======================================================================
ConstructPartScript(){
  ConstructScript SQL1 $PART_SCRIPT
#SQL1 whenever sqlerror exit sql.sqlcode
#SQL1 set heading off
#SQL1 set pages 0
#SQL1 set lines 300
#SQL1 select distinct 'DATA', database
#SQL1 from t_partitions
#SQL1 where tablename='&1'
#SQL1 /
#SQL1 exit sql.sqlcode
}
 

#=======================================================================
# This outputs the rows in PHONEDAY2_BACKUP that have not resulted in an
# update. It can be used for both update and reversion
# &1 = $NOT        = = (update) or <> (reversion)
# &2 =               ENTRY_DATE (update) or UPDATED_DATE (reversion)
# &3 = $OPERATOR   = <, = or >
# &4 = $EFF_DATE   = date entered with command
# &5 = $PARTITION  = database
# &6 = $TABLE_NAME = table name
#=======================================================================
ConstructCheckScript(){
  ConstructScript PSQ0 $PLSQL_FILE
#PSQ0 whenever sqlerror exit sql.sqlcode
#PSQ0 set verify off
#PSQ0 set feedback off
#PSQ0 set serveroutput on size 1000000
#PSQ0 declare
#PSQ0   cursor c_phoneday2_backup is
#PSQ0     select TABLE_NAME,
#PSQ0            PK_1, PK_2,
#PSQ0            OLD_STD_CODE, OLD_PHN_NO,
#PSQ0            NEW_STD_CODE, NEW_PHN_NO,
#PSQ0            UPDATED_DATE
#PSQ0     from   PHONEDAY2_BACKUP
#PSQ0     where  TABLE_NAME = '&6'
#PSQ0       and  nvl(to_char(UPDATED_DATE),'null') &1 'null'
#PSQ0       and  trunc(&2) &3 to_date('&4','DD/MM/YYYY');
#PSQ0   v_col_head    varchar2(78);
#PSQ0   v_col_undl    varchar2(78);
#PSQ0   v_det_rec     varchar2(78);
#PSQ0   v_full_number varchar2(38);
#PSQ0 begin
#PSQ0   dbms_output.put_line('Omitted Cases on partition &5...');
#PSQ0   v_col_head:=rpad('Table',10);
#PSQ0   v_col_head:=v_col_head||rpad('Primary Key 1',28);
#PSQ0   v_col_head:=v_col_head||rpad('Primary Key 2',15);
#PSQ0   v_col_head:=v_col_head||'Unmatching Phone Number';
#PSQ0   v_col_undl:=rpad('-----',10);
#PSQ0   v_col_undl:=v_col_undl||rpad('-------------',28);
#PSQ0   v_col_undl:=v_col_undl||rpad('-------------',15);
#PSQ0   v_col_undl:=v_col_undl||'-----------------------';
#PSQ0   dbms_output.put_line(v_col_head);
#PSQ0   dbms_output.put_line(v_col_undl);
#PSQ0   for c in c_phoneday2_backup loop
#PSQ0       v_det_rec:=rpad(c.TABLE_NAME,10);
#PSQ0       v_det_rec:=v_det_rec||rpad(c.PK_1,28);
#PSQ0       v_det_rec:=v_det_rec||rpad(nvl(c.PK_2,'null'),15);
#PSQ0       if c.UPDATED_DATE is null then
#PSQ0          v_full_number:=nvl(c.OLD_STD_CODE,' ')||nvl(c.OLD_PHN_NO,' ');
#PSQ0       else
#PSQ0          v_full_number:=nvl(c.NEW_STD_CODE,' ')||nvl(c.NEW_PHN_NO,' ');
#PSQ0       end if;
#PSQ0       v_det_rec:=v_det_rec||ltrim(rtrim(v_full_number));
#PSQ0       dbms_output.put_line(v_det_rec);
#PSQ0       if c_phoneday2_backup%ROWCOUNT = 100 then
#PSQ0          dbms_output.put_line('Only the first 100 will be listed');
#PSQ0          exit;
#PSQ0       end if;
#PSQ0   end loop;
#PSQ0 end;
#PSQ0 /
#PSQ0 exit sql.sqlcode
}
 

#========================================================================
# This will route out the second field (database) from any record with
# DATA as the first field. The output from this goes into AWK_FILE
#========================================================================
ConstructAwkScript(){
  ConstructScript AWK1 $AWK_FILE
#AWK1 BEGIN {
#AWK1   Found=0
#AWK1 }
#AWK1 $1 == "DATA" {
#AWK1    print $2
#AWK1    Found=1
#AWK1 }
#AWK1
#AWK1 END {
#AWK1     if (Found==0)
#AWK1     {
#AWK1        print "No databases returned"
#AWK1        exit 1
#AWK1     }
#AWK1 }
}
 

#=======================================================================
# Create a list of partitions for a given table
# $TABLE_NAME is passed into the PLSQL file and referenced as &1
#=======================================================================
GetPartitions(){
  LogMessage "Finding partitions of $TABLE_NAME"
 
  sqlplus -s $ORACLE_ARC_USER/$ORACLE_ARC_PASSWORD@$ORACLE_ARC_SERVER @$PART_SCRIPT $TABLE_NAME > $TEMP_FILE
  SQL_ERR=$?
  if [[ $SQL_ERR -ne 0 ]] then
     ErrorMessage "SQL error has occurred" $SQL_ERR sqlplus
  else
 
     LogMessage "Partitions found for $TABLE_NAME"
  fi
 
  LogMessage "Creating partition file"
 
  awk -f $AWK_FILE $TEMP_FILE > $PART_FILE
  AWK_ERR=$?
  if [[ $AWK_ERR -ne 0 ]] then
     if [[ $TABLE_NAME = "CU40TB03" ]] then
        echo $ORACLE_ARC_SERVER > $PART_FILE
     else
        echo $DEFAULT_SERVER    > $PART_FILE
     fi
  else
     LogMessage "Partition file created for table $TABLE_NAME"
  fi
}
 
#========================================================================
# This is the PL/SQL which will go through a given table on a given
# partition in order to retrieve, validate and identify required changes
# to the phone numbers held in the given columns
# &1 = $TABLE_NAME   = name of the table
# &2 = $PK1          = name of first primary key
# &3 = $PK2          = name of second primary key (or null if only one)
# &4 = $PK3          = name of third primary key (or null if less than 3)
# &5 = $STD          = name of STD column (or null if all in one field)
# &6 = $LOCAL        = name of local number column
# &7 = $PARTITION    = name of partition that the table is on
# &8 = $COMMIT_BLOCK = number of rows retrieved before commit
#========================================================================
ConstructScanScript(){
  ConstructScript PSQ1 $PLSQL_FILE
  LogMessage "Constructing scan script"
 
#PSQ1 whenever sqlerror exit sql.sqlcode
#PSQ1 set verify off
#PSQ1 set feedback off
#PSQ1 set serveroutput on size 1000000
#PSQ1 declare
#PSQ1   v_pk1       PHONEDAY2_BACKUP.PK_1%TYPE;
#PSQ1   v_pk2       PHONEDAY2_BACKUP.PK_2%TYPE;
#PSQ1   v_pk3       PHONEDAY2_BACKUP.PK_3%TYPE;
#PSQ1   v_std       PHONEDAY2_BACKUP.OLD_STD_CODE%TYPE;
#PSQ1   v_local     PHONEDAY2_BACKUP.OLD_PHN_NO%TYPE;
#PSQ1   v_new_std   PHONEDAY2_BACKUP.NEW_STD_CODE%TYPE;
#PSQ1   v_new_local PHONEDAY2_BACKUP.NEW_PHN_NO%TYPE;
#PSQ1   cursor c_phone_list is
#PSQ1     select &2, &3, &4, &5, &6
#PSQ1     from   &1;
#PSQ1   x_too_short       exception;
#PSQ1   x_too_long        exception;
#PSQ1   x_spurious        exception;
#PSQ1   x_no_leading_zero exception;
#PSQ1   v_combined    varchar2(25);
#PSQ1   v_spurious    varchar2(25);
#PSQ1   v_nondigit    varchar2(25);
#PSQ1   v_stripped    varchar2(25);
#PSQ1   v_1st_digit   char(1);
#PSQ1   v_2nd_digit   char(1);
#PSQ1   v_length      number(2);
#PSQ1   v_left_num    varchar2(7);
#PSQ1   v_right_num   varchar2(7);
#PSQ1   v_mask        varchar2(11);
#PSQ1   v_new_mask    varchar2(11);
#PSQ1   v_new_left    varchar2(7);
#PSQ1   v_new_stripped char(11);
#PSQ1   v_null_count     number(8) := 0;
#PSQ1   v_change_count   number(8) := 0;
#PSQ1   v_nochange_count number(8) := 0;
#PSQ1   v_error1_count   number(8) := 0;
#PSQ1   v_error2_count   number(8) := 0;
#PSQ1   v_error3_count   number(8) := 0;
#PSQ1   v_error4_count   number(8) := 0;
#PSQ1   v_total_count    number(8) := 0;
#PSQ1   b_match_found    boolean;
#PSQ1   i number(1);
#PSQ1 begin
#PSQ1   open c_phone_list;
#PSQ1   fetch c_phone_list
#PSQ1   into  v_pk1, v_pk2, v_pk3, v_std, v_local;
#PSQ1   while c_phone_list%FOUND
#PSQ1   loop
#PSQ1       begin
#PSQ1         v_total_count := v_total_count + 1;
#PSQ1         v_combined := v_std||v_local;
#COMM
#COMM         ----------------------------------------------------------
#COMM         Check for spurious characters
#COMM         ----------------------------------------------------------
#PSQ1         v_spurious := translate(v_combined,'#0123456789()- ','#');
#PSQ1         if v_spurious is not null then
#PSQ1            raise x_spurious;
#PSQ1         end if;
#COMM
#COMM         ----------------------------------------------------------
#COMM         Remove non-digits and check for leading zero
#COMM         ----------------------------------------------------------
#PSQ1         v_nondigit  := translate(v_combined,' 0123456789',' ');
#PSQ1         v_stripped  := translate(v_combined,'0'||v_nondigit,'0');
#PSQ1         v_1st_digit := substr(v_stripped,1,1);
#PSQ1         if v_1st_digit <> '0' then
#PSQ1            raise x_no_leading_zero;
#PSQ1         end if;
#COMM
#COMM         ----------------------------------------------------------
#COMM         Check for length
#COMM         ----------------------------------------------------------
#PSQ1         v_length := length(v_stripped);
#PSQ1         if v_length < 10 then
#PSQ1            raise x_too_short;
#PSQ1         elsif v_length > 11 then
#PSQ1            raise x_too_long;
#PSQ1         end if;
#COMM
#COMM         ----------------------------------------------------------
#COMM         Search for a conversion
#COMM         ----------------------------------------------------------
#PSQ1         if v_length <> 0 then
#PSQ1            i := 4;
#PSQ1            b_match_found := FALSE;
#PSQ1            while i <= 7
#PSQ1            loop
#PSQ1              v_left_num  := substr(v_stripped,1,v_length - i);
#PSQ1              v_right_num := substr(v_stripped,v_length - i + 1);
#PSQ1              v_mask      := rpad(v_left_num,v_length,'X');
#PSQ1              begin
#PSQ1                select NEW_FORMAT
#PSQ1                into   v_new_mask
#PSQ1                from   PHONEDAY2_CONVERSION
#PSQ1                where  OLD_FORMAT=rpad(v_mask,11);
#PSQ1                if SQL%FOUND then
#PSQ1                   i := 7;
#PSQ1                   b_match_found := TRUE;
#PSQ1                   v_new_left     := rtrim(v_new_mask,'X');
#PSQ1                   v_new_stripped := v_new_left||v_right_num;
#PSQ1                   v_2nd_digit    := substr(v_new_stripped,2,1);
#PSQ1                   if    v_2nd_digit = '2' then
#PSQ1                      v_new_std   := substr(v_new_stripped,1,3);
#PSQ1                      v_new_local := substr(v_new_stripped,4);
#PSQ1                   elsif v_2nd_digit = '7' then
#PSQ1                      v_new_std   := substr(v_new_stripped,1,5);
#PSQ1                      v_new_local := substr(v_new_stripped,6);
#PSQ1                   else
#PSQ1                      v_new_std   := substr(v_new_stripped,1,4);
#PSQ1                      v_new_local := substr(v_new_stripped,5);
#PSQ1                   end if;
#PSQ1                   if v_std is null then
#PSQ1                      v_new_local := rtrim(v_new_std)||' '||v_new_local;
#PSQ1                      v_new_std   := null;
#PSQ1                   end if;
#PSQ1                   insert into PHONEDAY2_BACKUP
#PSQ1                          (ENTRY_DATE, TABLE_NAME, PK_1, PK_2, PK_3,
#PSQ1                           OLD_STD_CODE, OLD_PHN_NO,
#PSQ1                           NEW_STD_CODE, NEW_PHN_NO,
#PSQ1                           UPDATED_DATE, DATABASE)
#PSQ1                   values (sysdate, '&1', v_pk1, v_pk2, v_pk3,
#PSQ1                           v_std, v_local,
#PSQ1                           v_new_std, v_new_local,
#PSQ1                           null,'&7');
#PSQ1                   v_change_count := v_change_count + 1;
#PSQ1                end if;
#PSQ1              exception
#PSQ1                when no_data_found then null;
#PSQ1              end;
#PSQ1              i := i + 1;
#PSQ1            end loop;
#PSQ1            if not b_match_found then
#PSQ1               v_nochange_count := v_nochange_count + 1;
#PSQ1            end if;
#PSQ1         else
#PSQ1            v_null_count := v_null_count + 1;
#PSQ1         end if;
#COMM
#COMM
#PSQ1       exception
#PSQ1         when x_too_short then
#PSQ1           v_error1_count := v_error1_count + 1;
#PSQ1           insert into PHONEDAY2_ERRORS
#PSQ1                  (ENTRY_DATE, TABLE_NAME, PK_1, PK_2, PK_3,
#PSQ1                   STD_CODE, PHN_NO, ERROR_CODE, PRINTED_DATE,
#PSQ1                   DATABASE)
#PSQ1           values (sysdate,'&1',v_pk1,v_pk2,v_pk3,
#PSQ1                   v_std,v_local,'1',null,
#PSQ1                   '&7');
#PSQ1         when x_too_long then
#PSQ1           v_error2_count := v_error2_count + 1;
#PSQ1           insert into PHONEDAY2_ERRORS
#PSQ1                  (ENTRY_DATE, TABLE_NAME, PK_1, PK_2, PK_3,
#PSQ1                   STD_CODE, PHN_NO, ERROR_CODE, PRINTED_DATE,
#PSQ1                   DATABASE)
#PSQ1           values (sysdate,'&1',v_pk1,v_pk2,v_pk3,
#PSQ1                   v_std,v_local,'2',null,
#PSQ1                   '&7');
#PSQ1         when x_spurious then
#PSQ1           v_error4_count := v_error4_count + 1;
#PSQ1           insert into PHONEDAY2_ERRORS
#PSQ1                  (ENTRY_DATE, TABLE_NAME, PK_1, PK_2, PK_3,
#PSQ1                   STD_CODE, PHN_NO, ERROR_CODE, PRINTED_DATE,
#PSQ1                   DATABASE)
#PSQ1           values (sysdate,'&1',v_pk1,v_pk2,v_pk3,
#PSQ1                   v_std,v_local,'4',null,
#PSQ1                   '&7');
#PSQ1         when x_no_leading_zero then
#PSQ1           v_error3_count := v_error3_count + 1;
#PSQ1           insert into PHONEDAY2_ERRORS
#PSQ1                  (ENTRY_DATE, TABLE_NAME, PK_1, PK_2, PK_3,
#PSQ1                   STD_CODE, PHN_NO, ERROR_CODE, PRINTED_DATE,
#PSQ1                   DATABASE)
#PSQ1           values (sysdate,'&1',v_pk1,v_pk2,v_pk3,
#PSQ1                   v_std,v_local,'3',null,
#PSQ1                   '&7');
#PSQ1       end;
#PSQ1       begin
#PSQ1         fetch c_phone_list
#PSQ1         into  v_pk1, v_pk2, v_pk3, v_std, v_local;
#PSQ1         if mod(c_phone_list%ROWCOUNT,&8) = 0 then
#PSQ1            commit;
#PSQ1            dbms_output.put_line(sysdate||' Committed after reading '||c_phone_list%ROWCOUNT||' rows');
#PSQ1         end if;
#PSQ1       end;
#PSQ1   end loop;
#PSQ1   close c_phone_list;
#PSQ1   dbms_output.put_line('Summary of Counts for table &1 on partition &7');
#PSQ1   dbms_output.put_line('==============================================');
#PSQ1   dbms_output.put_line('Date of scan: '||sysdate||chr(10));
#PSQ1   dbms_output.put_line('Numbers not for conversion :'||v_nochange_count);
#PSQ1   dbms_output.put_line('Null entries               :'||v_null_count);
#PSQ1   dbms_output.put_line('Numbers for conversion     :'||v_change_count);
#PSQ1   dbms_output.put_line('Numbers less than 10 digits:'||v_error1_count);
#PSQ1   dbms_output.put_line('Numbers more than 11 digits:'||v_error2_count);
#PSQ1   dbms_output.put_line('Numbers not starting zero  :'||v_error3_count);
#PSQ1   dbms_output.put_line('Numbers with invalid chars :'||v_error4_count);
#PSQ1   dbms_output.put_line('TOTAL                       '||v_total_count);
#PSQ1   dbms_output.put_line(chr(10));
#PSQ1 exception
#PSQ1   when others then
#PSQ1     dbms_output.put_line('Error '||to_char(sqlcode)||':'||sqlerrm);
#PSQ1     dbms_output.put_line(v_pk1||':'||v_std||':'||v_local);
#PSQ1 end;
#PSQ1 /
#PSQ1 exit sql.sqlcode
}
 

#========================================================================
# This is the PL/SQL which will go through the PHONEDAY2_ERRORS table in
# order to create a detailed error report
# &1 = $TABLE_NAME = name of the table
# &2 = $PKPOS      = which of the three primary keys is to be reported
# &3 = $PDESC      = 1st part of description of primary key
# &4 = $PDESC      = 2nd part of description of primary key
# &5 = $DETLINES   = number of lines of detail required
# &6 = &OPERATOR   = <, = or > (for selecting a date range)
# &7 = &EFF_DATE   = a date entered at the command (or defaulted)
#========================================================================
ConstructReportScript(){
  ConstructScript PSQ2 $PLSQL_FILE
  LogMessage "Constructing error script"
 
#PSQ2 whenever sqlerror exit sql.sqlcode
#PSQ2 set verify off
#PSQ2 set feedback off
#PSQ2 set serveroutput on size 1000000
#PSQ2 declare
#PSQ2   cursor c_phoneday2_errors is
#PSQ2     select &2, STD_CODE, PHN_NO, ERROR_CODE
#PSQ2     from   PHONEDAY2_ERRORS
#PSQ2     where  TABLE_NAME = '&1'
#PSQ2       and  trunc(ENTRY_DATE) &6 to_date('&7','DD/MM/YYYY')
#PSQ2       and  PRINTED_DATE is null
#PSQ2       and  ROWNUM <= &5
#PSQ2     for update;
#PSQ2   v_col_head varchar2(78);
#PSQ2   v_col_undl varchar2(78);
#PSQ2   v_det_rec  varchar2(78);
#PSQ2   v_error    varchar2(78);
#PSQ2   v_comment ALL_TAB_COMMENTS.COMMENTS%TYPE;
#PSQ2 begin
#COMM   ----------------------------------------------------------------
#COMM   Get the description of the table
#COMM   ----------------------------------------------------------------
#COMM   begin
#COMM     select COMMENTS
#COMM     into   v_comment
#COMM     from   ALL_TAB_COMMENTS
#COMM     where  TABLE_NAME='&1';
#COMM   exception
#COMM     when no_data_found then
#COMM       v_comment:='ePPS Table';
#COMM   end;
#COMM   ----------------------------------------------------------------
#COMM   Produce the table header with column headings
#COMM   ----------------------------------------------------------------
#PSQ2   v_col_head:=rpad('&3 &4',15);
#PSQ2   v_col_head:=v_col_head||rpad('STD Code',10);
#PSQ2   v_col_head:=v_col_head||rpad('Local Number',17);
#PSQ2   v_col_head:=v_col_head||'Error';
#PSQ2   v_col_undl:=rpad('-------------',15);
#PSQ2   v_col_undl:=v_col_undl||rpad('--------',10);
#PSQ2   v_col_undl:=v_col_undl||rpad('--------------',17);
#PSQ2   v_col_undl:=v_col_undl||'-----';
#COMM   dbms_output.put_line('Table : &1 ('||ltrim(rtrim(v_comment))||')');
#PSQ2   dbms_output.put_line('Table : &1 ');
#PSQ2   dbms_output.put_line(v_col_head);
#PSQ2   dbms_output.put_line(v_col_undl);
#COMM   ----------------------------------------------------------------
#COMM   For each qualifying row, format and output details
#COMM   ----------------------------------------------------------------
#PSQ2   for c in c_phoneday2_errors loop
#PSQ2       v_det_rec := rpad(c.&2,15);
#PSQ2       v_det_rec := v_det_rec||rpad(nvl(c.STD_CODE,' '),10);
#PSQ2       v_det_rec := v_det_rec||rpad(nvl(c.PHN_NO,' '),17);
#COMM
#PSQ2       if    c.ERROR_CODE = '1' then
#PSQ2          v_error := 'Too short';
#PSQ2       elsif c.ERROR_CODE = '2' then
#PSQ2          v_error := 'Too long';
#PSQ2       elsif c.ERROR_CODE = '3' then
#PSQ2          v_error := 'No leading zero';
#PSQ2       elsif c.ERROR_CODE = '4' then
#PSQ2          v_error := 'Invalid character';
#PSQ2       else
#PSQ2          v_error := 'Unknown';
#PSQ2       end if;
#COMM
#PSQ2       dbms_output.put_line(v_det_rec||v_error);
#PSQ2       update phoneday2_errors
#PSQ2       set PRINTED_DATE = sysdate
#PSQ2       where current of c_phoneday2_errors;
#PSQ2   end loop;
#PSQ2   dbms_output.put_line(chr(10));
#PSQ2 exception
#PSQ2   when others then
#PSQ2     dbms_output.put_line('Error '||to_char(sqlcode)||':'||sqlerrm);
#PSQ2     dbms_output.put_line(v_det_rec||v_error);
#PSQ2 end;
#PSQ2 /
#PSQ2 exit sql.sqlcode
}
 

#========================================================================
# This is the PL/SQL which will go through the PHONEDAY2_BACKUP table in
# order to update the main database
# &1  = $TABLE_NAME   = name of the table
# &2  = $PK1          = name of first primary key
# &3  = $PK2          = name of second primary key (or null if only one)
 

#========================================================================
# This is the PL/SQL which will go through the PHONEDAY2_BACKUP table in
# order to update the main database
# &1  = $TABLE_NAME   = name of the table
# &2  = $PK1          = name of first primary key
# &3  = $PK2          = name of second primary key (or null if only one)
# &4  = $PK3          = name of third primary key (or null if less than 3)
# &5  = $STD          = name of STD column (or null if all in one field)
# &6  = $LOCAL        = name of local number column
# &7  = $OPERATOR     = <, = or > (for selecting a date range)
# &8  = $EFF_DATE     = a date entered at the command (or defaulted)
# &9  = $PARTITION    = name of the database
# &10 = $COMMIT_BLOCK = number of rows updated before commit
#========================================================================
ConstructUpdateScript(){
  ConstructScript PSQ3 $PLSQL_FILE
  LogMessage "Constructing update script"
 
#PSQ3 whenever sqlerror exit sql.sqlcode
#PSQ3 set verify off
#PSQ3 set feedback off
#PSQ3 set serveroutput on size 1000000
#PSQ3 declare
#PSQ3   cursor c_phoneday2_backup is
#PSQ3     select PK_1, PK_2, PK_3,
#PSQ3            OLD_STD_CODE, OLD_PHN_NO,
#PSQ3            NEW_STD_CODE, NEW_PHN_NO
#PSQ3       from PHONEDAY2_BACKUP
#PSQ3     where  TABLE_NAME = '&1'
#PSQ3       and  DATABASE   = '&9'
#PSQ3       and  trunc(ENTRY_DATE) &7 to_date('&8','DD/MM/YYYY')
#PSQ3       and  UPDATED_DATE is null
#PSQ3     for update;
#PSQ3   v_pk varchar2(100);
#PSQ3   v_no varchar2(30);
#PSQ3   v_updated_count number(8):=0;
#PSQ3   v_found_count   number(8):=0;
#PSQ3 begin
#PSQ3   for c in c_phoneday2_backup loop
#PSQ3       begin
#PSQ3         v_found_count := v_found_count + 1;
#COMM         ----------------------------------------------------------
#COMM         The nth primary key stored in PHONEDAY2_BACKUP will be null
#COMM         only if there isn't one. Similarly for the STD.
#COMM         ----------------------------------------------------------
#PSQ3         if    c.PK_3 is not null then
#PSQ3            if c.NEW_STD_CODE is not null then
#PSQ3               update &1
#PSQ3                  set &5 = c.NEW_STD_CODE,
#PSQ3                      &6 = c.NEW_PHN_NO
#PSQ3                where &2 = c.PK_1
#PSQ3                  and &3 = c.PK_2
#PSQ3                  and &4 = c.PK_3
#PSQ3                  and &5 = c.OLD_STD_CODE
#PSQ3                  and &6 = rpad(c.OLD_PHN_NO,length(&6));
#PSQ3            else
#PSQ3               update &1
#PSQ3                  set &6 = c.NEW_PHN_NO
#PSQ3                where &2 = c.PK_1
#PSQ3                  and &3 = c.PK_2
#PSQ3                  and &4 = c.PK_3
#PSQ3                  and &6 = rpad(c.OLD_PHN_NO,length(&6));
#PSQ3            end if;
#PSQ3         elsif c.PK_2 is not null then
#PSQ3            if c.NEW_STD_CODE is not null then
#PSQ3               update &1
#PSQ3                  set &5 = c.NEW_STD_CODE,
#PSQ3                      &6 = c.NEW_PHN_NO
#PSQ3                where &2 = c.PK_1
#PSQ3                  and &3 = c.PK_2
#PSQ3                  and &5 = c.OLD_STD_CODE
#PSQ3                  and &6 = rpad(c.OLD_PHN_NO,length(&6));
#PSQ3            else
#PSQ3               update &1
#PSQ3                  set &6 = c.NEW_PHN_NO
#PSQ3                where &2 = c.PK_1
#PSQ3                  and &3 = c.PK_2
#PSQ3                  and &6 = rpad(c.OLD_PHN_NO,length(&6));
#PSQ3            end if;
#PSQ3         else
#PSQ3            if c.NEW_STD_CODE is not null then
#PSQ3               update &1
#PSQ3                  set &5 = c.NEW_STD_CODE,
#PSQ3                      &6 = c.NEW_PHN_NO
#PSQ3                where &2 = c.PK_1
#PSQ3                  and &5 = c.OLD_STD_CODE
#PSQ3                  and &6 = rpad(c.OLD_PHN_NO,length(&6));
#PSQ3            else
#PSQ3               update &1
#PSQ3                  set &6 = c.NEW_PHN_NO
#PSQ3                where &2 = c.PK_1
#PSQ3                  and &6 = rpad(c.OLD_PHN_NO,length(&6));
#PSQ3            end if;
#PSQ3         end if;
#PSQ3         if SQL%FOUND then
#PSQ3            update PHONEDAY2_BACKUP
#PSQ3               set UPDATED_DATE = sysdate
#PSQ3             where current of c_phoneday2_backup;
#PSQ3            v_updated_count := v_updated_count + 1;
#PSQ3            if mod(v_updated_count,&10) = 0 then
#PSQ3               dbms_output.put_line(v_updated_count||' updates performed');
#PSQ3            end if;
#PSQ3         end if;
#PSQ3       exception
#PSQ3         when no_data_found then
#PSQ3           v_pk := '&1:'||c.PK_1||':'||c.PK_2||':'||c.PK_3;
#PSQ3           v_no := c.OLD_STD_CODE||' '||c.OLD_PHN_NO;
#PSQ3           dbms_output.put_line('Non-match. '||v_pk||'   '||v_no);
#PSQ3       end;
#PSQ3   end loop;
#PSQ3   dbms_output.put_line(to_char(v_found_count)||' cases found, '||to_char(v_updated_count)||' updated, '||to_char(v_found_count
 - v_updated_count)||' remain');
#PSQ3 exception
#PSQ3   when others then
#PSQ3     dbms_output.put_line('Error '||to_char(sqlcode)||':'||sqlerrm);
#PSQ3 end;
#PSQ3 /
#PSQ3 exit sql.sqlcode
}
 

#========================================================================
# This is the PL/SQL which will go through the PHONEDAY2_BACKUP table in
# order to revert the main database back to a given point
# &1  = $TABLE_NAME   = name of the table
# &2  = $PK1          = name of first primary key
# &3  = $PK2          = name of second primary key (or null if only one)
# &4  = $PK3          = name of third primary key (or null if less than 3)
# &5  = $STD          = name of STD column (or null if all in one field)
# &6  = $LOCAL        = name of local number column
# &7  = $OPERATOR     = <, = or > (for selecting a date range)
# &8  = $EFF_DATE     = a date entered at the command (or defaulted)
# &9  = $PARTITION    = name of the database
# &10 = $COMMIT_BLOCK = number of rows reverted before commit
#========================================================================
ConstructRevertScript(){
  ConstructScript PSQ4 $PLSQL_FILE
  LogMessage "Constructing reversion script"
 
#PSQ4 whenever sqlerror exit sql.sqlcode
#PSQ4 set verify off
#PSQ4 set feedback off
#PSQ4 set serveroutput on size 1000000
#PSQ4 declare
#PSQ4   cursor c_phoneday2_backup is
#PSQ4     select PK_1, PK_2, PK_3,
#PSQ4            OLD_STD_CODE, OLD_PHN_NO,
#PSQ4            NEW_STD_CODE, NEW_PHN_NO
#PSQ4       from PHONEDAY2_BACKUP
#PSQ4     where  TABLE_NAME = '&1'
#PSQ4       and  DATABASE   = '&9'
#PSQ4       and  trunc(UPDATED_DATE) &7 to_date('&8','DD/MM/YYYY')
#PSQ4     for update;
#PSQ4   v_pk varchar2(100);
#PSQ4   v_no varchar2(30);
#PSQ4   v_updated_count number(8):=0;
#PSQ4   v_found_count   number(8):=0;
#PSQ4 begin
#PSQ4   for c in c_phoneday2_backup loop
#PSQ4       begin
#PSQ4         v_found_count := v_found_count + 1;
#PSQ4         if    c.PK_3 is not null then
#PSQ4            if c.OLD_STD_CODE is not null then
#PSQ4               update &1
#PSQ4                  set &5 = c.OLD_STD_CODE,
#PSQ4                      &6 = c.OLD_PHN_NO
#PSQ4                where &2 = c.PK_1
#PSQ4                  and &3 = c.PK_2
#PSQ4                  and &4 = c.PK_3
#PSQ4                  and &5 = c.NEW_STD_CODE
#PSQ4                  and &6 = rpad(c.NEW_PHN_NO, length(&6));
#PSQ4            else
#PSQ4               update &1
#PSQ4                  set &6 = c.OLD_PHN_NO
#PSQ4                where &2 = c.PK_1
#PSQ4                  and &3 = c.PK_2
#PSQ4                  and &4 = c.PK_3
#PSQ4                  and &6 = rpad(c.NEW_PHN_NO, length(&6));
#PSQ4            end if;
#PSQ4         elsif c.PK_2 is not null then
#PSQ4            if c.OLD_STD_CODE is not null then
#PSQ4               update &1
#PSQ4                  set &5 = c.OLD_STD_CODE,
#PSQ4                      &6 = c.OLD_PHN_NO
#PSQ4                where &2 = c.PK_1
#PSQ4                  and &3 = c.PK_2
#PSQ4                  and &5 = c.NEW_STD_CODE
#PSQ4                  and &6 = rpad(c.NEW_PHN_NO, length(&6));
#PSQ4            else
#PSQ4               update &1
#PSQ4                  set &6 = c.OLD_PHN_NO
#PSQ4                where &2 = c.PK_1
#PSQ4                  and &3 = c.PK_2
#PSQ4                  and &6 = rpad(c.NEW_PHN_NO, length(&6));
#PSQ4            end if;
#PSQ4         else
#PSQ4            if c.OLD_STD_CODE is not null then
#PSQ4               update &1
#PSQ4                  set &5 = c.OLD_STD_CODE,
#PSQ4                      &6 = c.OLD_PHN_NO
#PSQ4                where &2 = c.PK_1
#PSQ4                  and &5 = c.NEW_STD_CODE
#PSQ4                  and &6 = rpad(c.NEW_PHN_NO,length(&6));
#PSQ4            else
#PSQ4               update &1
#PSQ4                  set &6 = c.OLD_PHN_NO
#PSQ4                where &2 = c.PK_1
#PSQ4                  and &6 = rpad(c.NEW_PHN_NO,length(&6));
#PSQ4            end if;
#PSQ4         end if;
#PSQ4         if SQL%FOUND then
#PSQ4            update PHONEDAY2_BACKUP
#PSQ4               set UPDATED_DATE = null
#PSQ4             where current of c_phoneday2_backup;
#PSQ4            v_updated_count := v_updated_count + 1;
#PSQ4            if mod(v_updated_count,&10) = 0 then
#PSQ4               dbms_output.put_line(v_updated_count||' reverts performed');
#PSQ4            end if;
#PSQ4         end if;
#PSQ4       exception
#PSQ4         when no_data_found then
#PSQ4           v_pk := '&1:'||c.PK_1||':'||c.PK_2||':'||c.PK_3;
#PSQ4           v_no := c.NEW_STD_CODE||' '||c.NEW_PHN_NO;
#PSQ4           dbms_output.put_line('Non-match. '||v_pk||'   '||v_no);
#PSQ4       end;
#PSQ4   end loop;
#PSQ4   dbms_output.put_line(to_char(v_found_count)||' cases found, '||to_char(v_updated_count)||' reverted, '||to_char(v_found_coun
t - v_updated_count)||' remain');
#PSQ4 exception
#PSQ4   when others then
#PSQ4     dbms_output.put_line('Error '||to_char(sqlcode)||':'||sqlerrm);
#PSQ4 end;
#PSQ4 /
#PSQ4 exit sql.sqlcode
}
 
#========================================================================
#                         Processing Starts Here
#========================================================================
 
#------------------------------------------------------------------------
# Startup - Get arguments, set up variables and files
#------------------------------------------------------------------------
STOPFILE=stopped_because
THIS=`basename $0`
 
Initialise
trap "echo 0  exit                 > $STOPFILE; exit" 0
trap "echo 1  hangup               > $STOPFILE; exit" 1
trap "echo 2  interrupt            > $STOPFILE; exit" 2
trap "echo 3  quit                 > $STOPFILE; exit" 3
trap "echo 4  illegal instruction  > $STOPFILE; exit" 4
trap "echo 5  trace                > $STOPFILE; exit" 5
trap "echo 6  IOT instruction      > $STOPFILE; exit" 6
trap "echo 7  EMT instruction      > $STOPFILE; exit" 7
trap "echo 8  Floating Point Xn    > $STOPFILE; exit" 8
trap "echo 9  kill                 > $STOPFILE; exit" 9
trap "echo 10 bus error            > $STOPFILE; exit" 10
trap "echo 11 signal 11            > $STOPFILE; exit" 11
trap "echo 12 bad argument         > $STOPFILE; exit" 12
trap "echo 13 write to open pipe   > $STOPFILE; exit" 13
trap "echo 14 alarm timeout        > $STOPFILE; exit" 14
trap "echo 15 software termination > $STOPFILE; exit" 15
 
LogMessage "Beginning $THIS"
if [[ $# -eq 0 ]] then
   Usage
   exit
else
   GetArgs $*
fi
CreateFile PLSQL_FILE $FILEBASE'.sql'
CreateFile AWK_FILE   $FILEBASE'.awk'
CreateFile PART_FILE  $FILEBASE'.prt'
CreateFile TEMP_FILE  $FILEBASE'.tmp'
CreateFile PART_SCRIPT $FILEBASE'.scr'
ConstructPartScript
ConstructAwkScript
 
#-----------------------------------------------------------------------
#                            SCAN
#-----------------------------------------------------------------------
if [[ $SCAN = "TRUE" ]] then
   ConstructScanScript
   LogMessage "Beginning scan"
   cat $CONTROL_FILE | \
   while read record
   do
#      ---------------------------------------------------------
#      Get the table name and column names from the control file
#      ---------------------------------------------------------
       TABLE_NAME=`echo $record | cut -d: -f1`
       if [[ $TABLE_NAME != "#" ]] then
          PK1=`echo $record | cut -d: -f2`
          PK2=`echo $record | cut -d: -f3`
          PK3=`echo $record | cut -d: -f4`
          STD=`echo $record | cut -d: -f5`
          LOCAL=`echo $record | cut -d: -f6`
          GetPartitions
 
#         -----------------------------------------------------------------
#         Go through each of the partitions for this table to scan
#         -----------------------------------------------------------------
          for PARTITION in `cat $PART_FILE`
          do
              echo "Scanning table $TABLE_NAME in partition $PARTITION"
              LogMessage "Scanning table $TABLE_NAME in partition $PARTITION"
              sqlplus -s $ORACLE_ARC_USER/$ORACLE_ARC_PASSWORD@$PARTITION @$PLSQL_FILE $TABLE_NAME $PK1 $PK2 $PK3 $STD $LOCAL $PARTI
TION $COMMIT_BLOCK | tee -a $ERR_SUMMRY_FILE 2>> $LOGFILE
              SQL_ERR=$?
              if [[ $SQL_ERR -ne 0 ]] then
                 ErrorMessage "PL/SQL error has occurred" $SQL_ERR plsql
              fi
          done
       fi
   done
   LogMessage "Scan ended"
fi
 
#------------------------------------------------------------------------
#                       ERROR REPORT
#------------------------------------------------------------------------
if [[ $REPORT = "TRUE" ]] then
   ConstructReportScript
   LogMessage "Beginning error report"
   echo "Detailed PhoneDay 2 Error Report       $TODAY"     >  $ERR_DETAIL_FILE
   echo "=================================================" >> $ERR_DETAIL_FILE
   echo "This is for errors found $OPERATOR_TEXT $EFF_DATE" >> $ERR_DETAIL_FILE
   echo " " >> $ERR_DETAIL_FILE
   echo " " >> $ERR_DETAIL_FILE
   TABLE_COUNT=0
   cat $CONTROL_FILE | \
   while read record
   do
#      ---------------------------------------------------------
#      Get the table name and Primary Key position & description
#      ---------------------------------------------------------
       TABLE_NAME=`echo $record | cut -d: -f1`
       if [[ $TABLE_NAME != "#" ]] then
          PKDESC=`echo $record | cut -d: -f7`
          PKPOS=`echo $PKDESC | cut -d"(" -f2`
          PKDESC=`echo $PKDESC | cut -d"(" -f1`
 
#         ---------------------------------------------------------
#         Which of the primary keys will be reported on?
#         ---------------------------------------------------------
          if [[ $PKPOS = "2)" ]] then
             PKPOS="PK_2"
          else
             if [[ $PKPOS = "3)" ]] then
                PKPOS="PK_3"
             else
                PKPOS="PK_1"
             fi
          fi
          GetPartitions
          for PARTITION in `cat $PART_FILE`
          do
 
#           ---------------------------------------------------------
#           How many detail lines have we produced? (DONELINES)
#           Pass the remaining number (DETLINES) required to PLSQL
#           ---------------------------------------------------------
            DONELINES=`wc -l < $ERR_DETAIL_FILE`
            DONELINES=`expr $DONELINES - $TABLE_COUNT \* 5 - 5`
            if [[ $DETAILS = "ALL" ]] then
               DETLINES=99999999
            else
               DETLINES=`expr $DETAILS - $DONELINES`
            fi
 
#           ---------------------------------------------------------
#           Produce the error details for this table
#           ---------------------------------------------------------
            if [[ $DETLINES -gt 0 ]] then
               echo "Reporting table $TABLE_NAME in partition $PARTITION"
               LogMessage "Reporting table $TABLE_NAME in $PARTITION"
 
               sqlplus -s $ORACLE_ARC_USER/$ORACLE_ARC_PASSWORD@$PARTITION @$PLSQL_FILE $TABLE_NAME $PKPOS $PKDESC $DETLINES $OPERAT
OR $EFF_DATE >> $ERR_DETAIL_FILE 2>> $LOGFILE
 
               SQL_ERR=$?
               if [[ $SQL_ERR -ne 0 ]] then
                  ErrorMessage "PL/SQL error has occurred" $SQL_ERR plsql
               fi
               TABLE_COUNT=`expr $TABLE_COUNT + 1`
            fi
          done
       fi
   done
   LogMessage "Error report ended"
fi
 
#------------------------------------------------------------------------
#                                   UPDATE
#------------------------------------------------------------------------
if [[ $UPDATE = "TRUE" ]] then
   ConstructUpdateScript
   LogMessage "Beginning update to database"
   cat $CONTROL_FILE | \
   while read record
   do
#      -----------------------------------------------------------------
#      Get the table name and column names from the control file
#      -----------------------------------------------------------------
       TABLE_NAME=`echo $record | cut -d: -f1`
       if [[ $TABLE_NAME != "#" ]] then
          PK1=`echo $record | cut -d: -f2`
          PK2=`echo $record | cut -d: -f3`
          PK3=`echo $record | cut -d: -f4`
          STD=`echo $record | cut -d: -f5`
          LOCAL=`echo $record | cut -d: -f6`
 
#         -----------------------------------------------------------------
#         Can't pass null as an STD because the PL/SQL wouldn't compile,
#         so pass it something that will compile but won't be used
#         -----------------------------------------------------------------
          if [[ $STD = "null" ]] then
             STD=$PK1
          fi
          GetPartitions
 
#         -----------------------------------------------------------------
#         Go through each of the partitions for this table to update
#         -----------------------------------------------------------------
          for PARTITION in `cat $PART_FILE`
          do
              echo "Updating table $TABLE_NAME in partition $PARTITION"
              LogMessage "Updating table $TABLE_NAME in partition $PARTITION"
              sqlplus -s $ORACLE_ARC_USER/$ORACLE_ARC_PASSWORD@$PARTITION @$PLSQL_FILE $TABLE_NAME $PK1 $PK2 $PK3 $STD $LOCAL $OPERA
TOR $EFF_DATE $PARTITION $COMMIT_BLOCK | tee -a $LOGFILE 2>> $LOGFILE
              SQL_ERR=$?
              if [[ $SQL_ERR -ne 0 ]] then
                 ErrorMessage "PL/SQL error has occurred" $SQL_ERR plsql
              fi
          done
       fi
   done
   LogMessage "Update ended"
#  -----------------------------------------------------------------
#   Check that that are no updates that were omitted
#  -----------------------------------------------------------------
   LogMessage "Checking results"
   echo "Checking results"
   ConstructCheckScript
   NOT="="
   cat $CONTROL_FILE | \
   while read record
   do
       TABLE_NAME=`echo $record | cut -d: -f1`
       if [[ $TABLE_NAME != "#" ]] then
          GetPartitions
          for PARTITION in `cat $PART_FILE`
          do
              echo "Checking table $TABLE_NAME in partition $PARTITION"
              LogMessage "Checking table $TABLE_NAME in partition $PARTITION"
              sqlplus -s $ORACLE_ARC_USER/$ORACLE_ARC_PASSWORD@$PARTITION @$PLSQL_FILE $NOT ENTRY_DATE $OPERATOR $EFF_DATE $PARTITIO
N $TABLE_NAME | tee -a $LOGFILE 2>> $LOGFILE
              SQL_ERR=$?
              if [[ $SQL_ERR -ne 0 ]] then
                 ErrorMessage "PL/SQL error has occurred" $SQL_ERR plsql
              fi
          done
       fi
   done
fi
 

#------------------------------------------------------------------------
#                                   REVERT
#------------------------------------------------------------------------
if [[ $REVERT = "TRUE" ]] then
   ConstructRevertScript
   LogMessage "Beginning reversion of database"
   cat $CONTROL_FILE | \
   while read record
   do
       TABLE_NAME=`echo $record | cut -d: -f1`
       if [[ $TABLE_NAME != "#" ]] then
          PK1=`echo $record | cut -d: -f2`
          PK2=`echo $record | cut -d: -f3`
          PK3=`echo $record | cut -d: -f4`
          STD=`echo $record | cut -d: -f5`
          LOCAL=`echo $record | cut -d: -f6`
          if [[ $STD = "null" ]] then
             STD=$PK1
          fi
          GetPartitions
          for PARTITION in `cat $PART_FILE`
          do
              echo "Reverting table $TABLE_NAME in partition $PARTITION"
              LogMessage "Reverting table $TABLE_NAME in partition $PARTITION"
              sqlplus -s $ORACLE_ARC_USER/$ORACLE_ARC_PASSWORD@$PARTITION @$PLSQL_FILE $TABLE_NAME $PK1 $PK2 $PK3 $STD $LOCAL $OPERA
TOR $EFF_DATE $PARTITION $COMMIT_BLOCK | tee -a $LOGFILE 2>> $LOGFILE
              SQL_ERR=$?
              if [[ $SQL_ERR -ne 0 ]] then
                 ErrorMessage "PL/SQL error has occurred" $SQL_ERR plsql
              fi
          done
       fi
   done
   LogMessage "Reversion ended"
   LogMessage "Checking results"
   echo "Checking results"
   ConstructCheckScript
   NOT="<>"
   cat $CONTROL_FILE | \
   while read record
   do
       TABLE_NAME=`echo $record | cut -d: -f1`
       if [[ $TABLE_NAME != "#" ]] then
          GetPartitions
          for PARTITION in `cat $PART_FILE`
          do
              echo "Checking table $TABLE_NAME in partition $PARTITION"
              LogMessage "Checking table $TABLE_NAME in partition $PARTITION"
              sqlplus -s $ORACLE_ARC_USER/$ORACLE_ARC_PASSWORD@$PARTITION @$PLSQL_FILE $NOT UPDATED_DATE $OPERATOR $EFF_DATE $PARTIT
ION $TABLE_NAME | tee -a $LOGFILE 2>> $LOGFILE
              SQL_ERR=$?
              if [[ $SQL_ERR -ne 0 ]] then
                 ErrorMessage "PL/SQL error has occurred" $SQL_ERR plsql
              fi
          done
       fi
   done
fi
Finalise

