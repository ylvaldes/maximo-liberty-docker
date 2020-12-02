#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#copy skel files
if [ ! -f "/home/ctginst1/.bashrc" ]
then
    cp -r /etc/skel/. /home/ctginst1
fi

if [ -d "${DB2_PATH}" ]
then
    source ~/sqllib/db2profile
    db2start
    db2 update dbm config using SVCENAME ${MAXDB_SERVICE_PORT} DEFERRED
    db2stop
    db2set -null DB2COMM
    db2start
    db2 create db ${MAXDB} using codeset UTF-8 territory US pagesize 32 K
    db2 update db cfg for ${MAXDB} using SELF_TUNING_MEM ON
    db2 update db cfg for ${MAXDB} using APPGROUP_MEM_SZ 16384 DEFERRED
    db2 update db cfg for ${MAXDB} using APPLHEAPSZ 2048 AUTOMATIC DEFERRED
    db2 update db cfg for ${MAXDB} using AUTO_MAINT ON DEFERRED
    db2 update db cfg for ${MAXDB} using AUTO_TBL_MAINT ON DEFERRED
    db2 update db cfg for ${MAXDB} using AUTO_RUNSTATS ON DEFERRED
    db2 update db cfg for ${MAXDB} using AUTO_REORG ON DEFERRED
    db2 update db cfg for ${MAXDB} using AUTO_DB_BACKUP ON DEFERRED
    db2 update db cfg for ${MAXDB} using CATALOGCACHE_SZ 800 DEFERRED
    db2 update db cfg for ${MAXDB} using CHNGPGS_THRESH 40 DEFERRED
    db2 update db cfg for ${MAXDB} using DBHEAP AUTOMATIC
    db2 update db cfg for ${MAXDB} using LOCKLIST AUTOMATIC DEFERRED
    db2 update db cfg for ${MAXDB} using LOGBUFSZ 1024 DEFERRED
    db2 update db cfg for ${MAXDB} using LOCKTIMEOUT 300 DEFERRED
    db2 update db cfg for ${MAXDB} using LOGPRIMARY 20 DEFERRED
    db2 update db cfg for ${MAXDB} using LOGSECOND 100 DEFERRED
    db2 update db cfg for ${MAXDB} using LOGFILSIZ 8192 DEFERRED
    db2 update db cfg for ${MAXDB} using SOFTMAX 1000 DEFERRED
    db2 update db cfg for ${MAXDB} using MAXFILOP 61440 DEFERRED
    db2 update db cfg for ${MAXDB} using PCKCACHESZ AUTOMATIC DEFERRED
    db2 update db cfg for ${MAXDB} using STAT_HEAP_SZ AUTOMATIC DEFERRED
    db2 update db cfg for ${MAXDB} using STMTHEAP 20000 DEFERRED
    db2 update db cfg for ${MAXDB} using UTIL_HEAP_SZ 10000 DEFERRED
    db2 update db cfg for ${MAXDB} using DATABASE_MEMORY AUTOMATIC DEFERRED
    db2 update db cfg for ${MAXDB} using AUTO_STMT_STATS OFF DEFERRED
    db2 update db cfg for ${MAXDB} using STMT_CONC LITERALS DEFERRED
    db2 update db cfg for ${MAXDB} using DFT_QUERYOPT 5
    db2 update db cfg for ${MAXDB} using NUM_IOCLEANERS AUTOMATIC
    db2 update db cfg for ${MAXDB} using NUM_IOSERVERS AUTOMATIC
    db2 update db cfg for ${MAXDB} using CUR_COMMIT ON
    db2 update db cfg for ${MAXDB} using AUTO_REVAL DEFERRED
    db2 update db cfg for ${MAXDB} using DEC_TO_CHAR_FMT NEW
    db2 update db cfg for ${MAXDB} using REC_HIS_RETENTN 30

    db2 update alert cfg for database on ${MAXDB} using db.db_backup_req SET THRESHOLDSCHECKED YES
    db2 update alert cfg for database on ${MAXDB} using db.tb_reorg_req SET THRESHOLDSCHECKED YES
    db2 update alert cfg for database on ${MAXDB} using db.tb_runstats_req SET THRESHOLDSCHECKED YES

    db2 update dbm cfg using PRIV_MEM_THRESH 32767 DEFERRED
    db2 update dbm cfg using KEEPFENCED NO DEFERRED
    db2 update dbm cfg using NUMDB 2 DEFERRED
    db2 update dbm cfg using RQRIOBLK 65535 DEFERRED
    db2 update dbm cfg using HEALTH_MON OFF DEFERRED
    db2 update dbm cfg using AGENT_STACK_SZ 1024 DEFERRED
    db2 update dbm cfg using MON_HEAP_SZ AUTOMATIC DEFERRED
    db2 update dbm cfg using diagsize 512

    db2set DB2_SKIPINSERTED=ON
    db2set DB2_INLIST_TO_NLJN=YES
    db2set DB2_MINIMIZE_LISTPREFETCH=YES
    db2set DB2_EVALUNCOMMITTED=YES
    db2set DB2_FMP_COMM_HEAPSZ=65536
    db2set DB2_SKIPDELETED=ON
    db2set DB2_USE_ALTERNATE_PAGE_CLEANING=ON
    db2set DB2_WORKLOAD=MAXIMO
    db2stop force
    db2start

    db2 connect to ${MAXDB}
    db2 CREATE BUFFERPOOL MAXBUFPOOL IMMEDIATE SIZE 4096 AUTOMATIC PAGESIZE 32 K
    db2 CREATE REGULAR TABLESPACE MAXDATA PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE INITIALSIZE 5000 M BUFFERPOOL MAXBUFPOOL
    db2 CREATE TEMPORARY TABLESPACE MAXTEMP PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL MAXBUFPOOL
    db2 CREATE REGULAR TABLESPACE MAXINDEX PAGESIZE 32 K MANAGED BY AUTOMATIC STORAGE INITIALSIZE 5000 M BUFFERPOOL MAXBUFPOOL
    db2 GRANT USE OF TABLESPACE MAXDATA TO USER MAXIMO
    db2 CREATE SCHEMA maximo AUTHORIZATION maximo
    db2 GRANT DBADM,CREATETAB,BINDADD,CONNECT,CREATE_NOT_FENCED_ROUTINE,IMPLICIT_SCHEMA, LOAD,CREATE_EXTERNAL_ROUTINE,QUIESCE_CONNECT,SECADM ON DATABASE TO USER MAXIMO
    db2 GRANT CREATEIN,DROPIN,ALTERIN ON SCHEMA MAXIMO TO USER MAXIMO

    db2 connect reset
    db2stop force

    db2set -null DB2COMM
fi

if ls ${BACKUPDIR}/${MAXDB}.* > /dev/null 2>&1; then
  echo "Start initial database configurations."
  /bin/bash -c "db2set -null DB2COMM"
  db2start
  until db2gcf -s -t 1 >/dev/null 2>&1; do
    sleep 1
  done

  echo "Restore database ${MAXDB} from ${BACKUPDIR} ..."
  /bin/bash -c "db2 restore database ${MAXDB} from ${BACKUPDIR} without prompting && db2 rollforward database ${MAXDB} to end of logs and stop && db2 terminate"
  db2stop
  rm ${BACKUPDIR}/*
fi
