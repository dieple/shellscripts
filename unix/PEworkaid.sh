"PEWorkAid.scr" 373 lines, 12483 characters 
#!/usr/bin/ksh
#########################################################################
##                                                                      #
##  This script extracts open PE WFMs that are holding up bills,        #
##  for accounts that are not pre payment.  The results are place       #
##  in csv format ready for download to a spreadsheet.                  #
##                                                                      #
#########################################################################
 

THIS=`basename $0`
SCRIPT=$0
TODAY=$(date "+%C%y-%m-%d")
DATE=$(date "+%Y%m%d")
BASEDIR=$HOME/bin
OUTDIR=$BASEDIR/output
TEMPDIR=$BASEDIR/temp
 
BLINK=$(tput blink)
RESET=$(tput reset)
 
DBNAME=$USERNAME
DBPASS=$PASSWD
 

NEXTBILL=30
 
## Define temporary files
 
T10=$TEMPDIR/PE.tmp10
T11=$TEMPDIR/PE.tmp11
T12=$TEMPDIR/PE.tmp12
T13=$TEMPDIR/PE.tmp13
T14=$TEMPDIR/PE.tmp14
T15=$TEMPDIR/PE.tmp15
T16=$TEMPDIR/PE.tmp16
T17=$TEMPDIR/PE.tmp17
T18=$TEMPDIR/PE.tmp18
T19=$TEMPDIR/PE.tmp19
T20=$TEMPDIR/PE.tmp20
T21=$TEMPDIR/PE.tmp21
T22=$TEMPDIR/PE.tmp22
T23=$TEMPDIR/PE.tmp23
T24=$TEMPDIR/PE.tmp24
 
T2=$TEMPDIR/PE.tmp2
T3=$TEMPDIR/PE.tmp3
T4=$TEMPDIR/PE.tmp4
T5=$TEMPDIR/PE.tmp5
T6=$TEMPDIR/PE.tmp6
T7=$TEMPDIR/PE.tmp7
T8=$TEMPDIR/PE.tmp8
 
R1=$OUTDIR/PE_workAid_"$TODAY".doc
SQL_FILE1=$TEMPDIR/PEWorkAid.sql
SQL_FILE2=$TEMPDIR/PECodes.sql
 
###################
## FUNCTIONS     ##
###################
 
GenerateSQL()
{
        grep '#'$1 $SCRIPT | cut -c `expr ${#1} + 3`- > $2
}
 
#################
# Generate SQL  #
#################
 
GenerateSQL SQL1 $SQL_FILE1
GenerateSQL SQL2 $SQL_FILE2
 
#SQL1 whenever sqlerror exit sql.sqlcode
#SQL1 set feedback off
#SQL1 set verify off
#SQL1 set lines 132
#SQL1 set pages 0
#SQL1 select
#SQL1 -- Sort Key ( 1- 8) made up of
#SQL1 -- WFM less than 45 days old?  Yes = 0 No = 4
#SQL1         ( decode(sign(t o_date(to_char(sysdate-45,'YYYY-MM-DD" 00.00.00"'))
#SQL1         - to_date(substr(a.time_stamp,1,10)||' 00.00.00')),-1,0,1) * 4 ) +
#SQL1 -- Pay plan?  Yes = 2 No = 0
#SQL1         ( decode(b.cd_acct_pmt_mthd,'NO',0,1) * 2 ) +
#SQL1 -- Had a bill yet?  Yes = 1 No = 0
#SQL1        d ecode(nvl(e.ts_bill,'Donkey'),'Donkey',0,1)  + 1         || ','  ||
#SQL1 -- Data for list
#SQL1         a.time_stamp                                              || ','  ||
#SQL1        to_char(b.id_ba,'FM0000000009')                            || ' P' ||
#SQL1 -- Reason Code
#SQL1         to_char(
#SQL1         (ltrim(rtrim(substr(dump(g.tx_wfm_dtl,10,2,1),16,3))) * 256 ) +
#SQL1         ltrim(rtrim(substr(dump(g.tx_wfm_dtl,10,3,1),16,3))),'FM99999')
#SQL1 from    cu40tb03 a,
#SQL1         cu02tb01 b,
#SQL1         cu02tb02 e,
#SQL1         cu20tb14 f,
#SQL1         cu40tb04 g
#SQL1 -- select streaming ranges --
#SQL1 where   a.id_ba             >= '&&1'
#SQL1 and     a.id_ba             <= '&&2'
#SQL1 -- select open PE WFMs --
#SQL1 and     a.id_wfm_wrk_typ    = 'PE'
#SQL1 and     a.stat_cd           =' O'
#SQL1 -- join to the account row and remove pre payments --
#SQL1a nd     b.id_ba             =  a.id_ba
#SQL1 and     a.cd_acct_mgr not in( '02','08','14')
#SQL1 --and     b.cd_acct_pmt_mthd& lt;> 'AM'
#SQL1 -- remove inactive and void accounts
#SQL1 and     b.cd_ba_stat       in ('P','A','T')
#SQL1 -- select items on valid bill cycles
#SQL1 and     b.id_bill_cy        > 1
#SQL1 -- join to activity schedule for next bill cycle --
#SQL1 and     f.id_bill_cy        = b.id_bill_cy
#SQL1 and     f.dt_nxt_cy_bill    =
#SQL1      (  select min(g.dt_nxt_cy_bill)
#SQL1         from   cu20tb14 g
#SQL1         where  g.id_bill_cy = f.id_bill_cy
#SQL1         and    g.dt_nxt_sch_rdg > sysdate )
#SQL1 -- if there is a bill then it is latest bill for that account
#SQL1 and     e.id_ba(+)          = b.id_ba
#SQL1 and  (  e.ts_bill is null
#SQL1      or e.ts_bill =
#SQL1      (  select max(f.ts_bill)
#SQL1         from   cu02tb02  f
#SQL1         where  f.id_ba = e.id_ba ) )
#SQL1 -- join to all wfm detail rows for this wfm
#SQL1a nd     g.time_stamp     = a.time_stamp
#SQL1 and     g.id_ba          = a.id_ba
#SQL1 and     g.id_wfm_wrk_typ = a.id_wfm_wrk_typ
#SQL1a nd     g.id_wfm_wrk_typ = 'PE'
#SQL1 and     g.seq_num        = 2
#SQL1 -- The WFM was raised in a bill window
#SQL1 and exists
#SQL1      (  select null
#SQL1         from   cu20tb14 c
#SQL1         where  c.dt_mrdg_gener  <= substr(a.time_stamp,1,10)||' 00.00.00'
#SQL1         and    c.dt_nxt_cy_bill >= substr(a.time_stamp,1,10)||'0 0.00.00'
#SQL1         and    c.id_bill_cy      = b.id_bill_cy  )
#SQL1 -- There has not been a bill since the WFM was raised
#SQL1 and not exists
#SQL1      (  select null
#SQL1         from   cu02tb02 d
#SQL1         where  d.id_ba   = a.id_ba
#SQL1         and    d.ts_bill > a.time_stamp  )
#SQL1 -- The next bill is more than a parameter no.of days in the future
#SQL1 and     f.dt_nxt_sch_rdg > sysdate + '&&3'
#SQL1 /
#SQL1 exit SQL.SQLCODE
 
#SQL2 whenever sqlerror exit sql.sqlcode
#SQL2 set linesize 132
#SQL2 set pagesize5 0000
#SQL2 set feedback off
#SQL2 set heading off
#SQL2
#SQL2s elect  'P'||
#SQL2        t o_char(
#SQL2   (ltrim(rtrim(substr(dump(b.tx_wfm_dtl,10,2,1),16,3))) * 256 ) +
#SQL2         ltrim(rtrim(substr(dump(b.tx_wfm_dtl,10,3,1),16,3))),'FM99999') || '!' ||
#SQL2         rtrim(substr(b.tx_wfm_dtl,15,100))
#SQL2 from     cu40tb04 b
#SQL2 where    b.id_wfm_wrk_typ = 'PE'
#SQL2 and      b.seq_num = 2
#SQL2 group by 'P'||
#SQL2    to_char(
#SQL2    (ltrim(rtrim(substr(dump(b.tx_wfm_dtl,10,2,1),16,3))) * 256 ) +
#SQL2    ltrim(rtrim(substr(dump(b.tx_wfm_dtl,10,3,1),16,3))),'FM99999') || '!' ||
#SQL2    rtrim(substr(b.tx_wfm_dtl,15,100))
#SQL2 order by 1
#SQL2 /
#SQL2 exit SQL.SQLCODE
 
print "\n$THIS started at "`date +"%Y-%m-%d %r"`
print "Extracting data,$BLINK Please wait ... $RESET \n"
 
## Run the extract sql on both boxes directing the result to files
 
sqlplus -s $DBNAME/$DBPASS@cr3pra1 @$SQL_FILE1           1  499999999 $NEXTBILL > $T10 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1@ $SQL_FILE1   500000000  999999999 $NEXTBILL > $T11 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1 @$SQL_FILE1  1000000000 1499999999 $NEXTBILL > $T12 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1@ $SQL_FILE1  1500000000 1999999999 $NEXTBILL > $T13 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1 @$SQL_FILE1  2000000000 2499999999 $NEXTBILL > $T14 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1 @$SQL_FILE1  2500000000 2999999999 $NEXTBILL > $T15 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1@ $SQL_FILE1  3000000000 3499999999 $NEXTBILL > $T16 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1 @$SQL_FILE1  3500000000 3999999999 $NEXTBILL > $T17 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1 @$SQL_FILE1  4000000000 4499999999 $NEXTBILL > $T18 &
sqlplus -s $DBNAME/$DBPASS@cr3pra1@ $SQL_FILE1  4500000000 5000000509 $NEXTBILL > $T19 &
sqlplus -s $DBNAME/$DBPASS@cr3prb1 @$SQL_FILE1  5000000510 5999999999 $NEXTBILL > $T20  &
sqlplus -s $DBNAME/$DBPASS@cr3prb1 @$SQL_FILE1  6000000000 6999999999 $NEXTBILL > $T21  &
sqlplus -s $DBNAME/$DBPASS@cr3prb1 @$SQL_FILE1  7000000000 7999999999 $NEXTBILL > $T22  &
sqlplus -s $DBNAME/$DBPASS@cr3prb1 @$SQL_FILE1  8000000000 8999999999 $NEXTBILL > $T23  &
sqlplus -s $DBNAME/$DBPASS@cr3prb1 @$SQL_FILE1  9000000000 9999999999 $NEXTBILL > $T24  &
sqlplus -s $DBNAME/$DBPASS@cr3prb1 @$SQL_FILE2 | sed -e 's/ /@/g' -e 's/!/ /g'   > $T6  &
wait
 
## A little post processing of the results
 
print "Formatting of the decodes list"
cat $T6 | sed -e 's/P63417/P2119/g' -e 's/P63418/P2118/g' -e 's/P63428/P2108/g' | grep "P" > $T7
 
awk ' BEGIN { NEWPAGE = "Y" }
       { CODE = $1
         DECODE = $2
         if ( LINECOUNT == 66 )
           { NEWPAGE = "Y" }
         if ( NEWPAGE == "Y" )
           { print "" 
            print "Pre Bill Error WFM Work Organiser: DeCodes"
            print "------------------------------------------"
            print " "
            print " Code  Decode "
            print "------ ----------------------------------------------------------------------------------------------------"
            LINECOUNT = 6
            NEWPAGE = "N" }
        print CODE "  " DECODE
       } ' $T7 | sed -e 's/@/ /g' > $R1
 
print "Joining the output of the streams and grouping reasons for each WFM"
cat $T10 $T11 $T12 $T13 $T14 $T15 $T16 $T17 $T18 $T19 $T20 $T21 $T22 $T23 $T24 | sort -k1| \
    sed -e 's/P63417/P2119/g' -e 's/P63418/P2118/g' -e' s/P63428/P2108/g' | grep ',' > $T3
 
awk ' BEGIN { OLDKEY = "ZZZZ" }
      { KEY        = $1
        PEREASON   =$ 2
        if ( KEY  != OLDKEY) 
        {  if ( OLDKEY != "ZZZZ" )
           { p rint   LINEOUT  }
           OLDKEY  = KEY
           LINEOUT = KEY " " PEREASON
        }
        else
        {  LINEOUT = LINEOUT "," PEREASON }
     }
     END { print LINEOUT } ' $T3 | sed -e 's/,/ /1' -e 's/,/ /1' | sort -k 1,1 -k 4,4  > $T4
 
 
 
print "Grouping by priority and reason combination to give a summary file"
 
awk ' BEGIN { COUNT  = 1
              OLDKEY = "ZZZZ" }
     {  PRIORITY = $1
        REASONS  = $4
        ID_BA    = $3
        TS       = $2
        KEY      = PRIORITY " " REASONS
        if ( OLDKEY != KEY) 
        {  if ( OLDKEY != "ZZZZ" )
           {   print COUNT " " OLDKEY  }
           COUNT =1 
           OLDKEY = KEY
           OLDREASONS = REASONS
           OLDPRIORITY = PRIORITY
           }
        else
        {   COUNT = COUNT + 1 }
     }
     END { print COUNT " " OLDKEY } ' $T4 > $T5
 
 
 
print "Formating the summary by priority"
 
awk ' BEGIN { START = "Y"
         NEWPAGE = "Y"
         TOTALCOUNT = 0 }
       { COUNT    = $1
         PRIORITY = $2
         KEY      = PRIORITY
         if ( START == "Y" )
           { START = "N"
             OLDKEY = KEY }
         if ( NEWPAGE == "Y" )
            { LINECOUNT = 9
              print "^L"
              print " "
              print "Pre Bill Error WFM Work Organiser: Summary by Priority"
              print "------------------------------------------------------"
              print " "
              NEWPAGE = "N" }
         if ( KEY != OLDKEY )
             { printf ( " Priority %8s   %8d\n", OLDKEY , PRIORITYCOUNT )
             print " "
             OLDKEY = KEY
             PRIORITYCOUNT = 0 }
        T OTALCOUNT = TOTALCOUNT + COUNT
         PRIORITYCOUNT =P RIORITYCOUNT + COUNT }
      END { printf ( "P riority %8s   %8d\n", OLDKEY , PRIORITYCOUNT )
            print " "
            print " All Selected PE WFMSs: " TOTALCOUNT } ' $T5 >> $R1
 
print "Formating summary by priority and reason"
 
awk ' BEGIN { START = "Y"
      LINECOUNT = 1
      NEWPAGE = "Y"
      PRIORITYCOUNT = 0 }
      { COUNT    = $1
        PRIORITY = $2
        REASONS  = $3
        if ( START == "Y" )
          { OLDKEY = PRIORITY
            START  = "N" }
        KEY      = PRIORITY
        if ( OLDKEY != KEY) 
          { NEWPAGE =" Y"
            print " "
            print " Total for Priority " OLDKEY ": " PRIORITYCOUNT
            PRIORITYCOUNT = 0
            OLDKEY = KEY }
        if ( LINECOUNT == 66 )
           { NEWPAGE = "Y" }
        if ( NEWPAGE == "Y") 
           { LINECOUNT = 9
             print "^L"
             print " "
             print "Pre Bill Error WFM Work Organiser: Summary by Priority and Reason"
             print "-----------------------------------------------------------------"
             print " "
             print "Priority of these WFMs: " PRIORITY
             print " "
             print "WFM Count  Reasons"
             print "---------- ---------------------------------------------------------------------------------"
             NEWPAGE = "N" }
       printf ("%8d   %-80s\n",  COUNT,  REASONS)
      PRIORITYCOUNT = PRIORITYCOUNT + COUNT
     L INECOUNT = LINECOUNT + 1 }
      END { } ' $T5 >> $R1
 
print "Formating the detail print"
 
awk ' BEGIN { OLDKEY = "ZZZZZ" }
      { PRIORITY = $1
        REASONS  = $4
        IDBA     = $3
        TS       = $2
        WFMDATE  = substr(TS,1,10)
        KEY = PRIORITY REASONS
        if ( OLDKEY != KEY) 
         {  OLDKEY = KEY
           N EWPAGE = "Y" }
        if (COUNT  == 66)
         {  NEWPAGE = "Y" }
        if (NEWPAGE == "Y")
         {  COUNT =1 1
            print "^L"
            print " "
            print "Pre Bill Error WFM Work Organiser: Detail"
            print "-----------------------------------------"
            print " "
            print "Priority of these WFMs: " PRIORITY
            print " "
            print "Reasons for these WFMs: " REASONS
            print " "
            print "  Account     WFM Date"
           p rint "----------   ----------"
            NEWPAGE = "N" }
         printf ( "%10s   %10s\n", IDBA, WFMDATE )
         COUNT = COUNT + 1} 
      END { } ' $T4 >> $R1
 
#tidy up
# Temporarily commented out to allow diagnostic of rollback segment errors
#rm -f $T2 $T3 $T4 $T5 $T6 $T7
#rm -f $T8 $T10 $T11 $T12 $T13 $T14 $T15 $T16 $T17 $T18
 
print" \n\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a\a$THIS has finished successfully at "`date +"%Y-%m-%d %r"`
 
###################
## End of script
###################
