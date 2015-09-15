###-----------------------------------------------------------------------------
# Set the environment variable ORACLE_HOME and ORACLE_SID 
# so that you can log onto the appropriate database
# Usage :    . setup_oraenv <ORACLE_SID>
# 
###-----------------------------------------------------------------------------

#
# Set minimum environment variables
#

ORACLE_HOME="/opt/thirdpp/oracle/u01/product/8.0.4"
ORACLE_SID=$1
export ORACLE_SID ORACLE_HOME
export PATH=$PATH:$ORACLE_HOME/bin
