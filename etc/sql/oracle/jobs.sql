-- Definitions of Rucio database scheduler jobs
-- Authors: Rucio team and Gancho Dimitrov 


/*
 select  OWNER, JOB_NAME from all_scheduler_jobs where OWNER='CMS_RUCIO_DEV_ADMIN';

OWNER			       JOB_NAME
------------------------------ ------------------------------
CMS_RUCIO_DEV_ADMIN	       COLLECTION_REPLICAS_UPDATES_JB

*/


/*
Note: 
the Rucio jobs have to run on the Rucio services defined on the DB cluster (in order to take advantage of the already cached data/index blocks on the relevant DB nodes). RUCIO_JOB_CLASS and RUCIO_JOB_CLASS_2 have to be predefined on the database and execute privilege has to be granted to the DB user before creating the Rucio DB scheduler jobs.  
*/


--- 1 -------------------------------------------------------------------------------------------------------------------------------------------------


--- 2 -------------------------------------------------------------------------------------------------------------------------------------------------



--- 3 -------------------------------------------------------------------------------------------------------------------------------------------------

exec dbms_scheduler.drop_job('UPDATE_RSE_USAGE_HISTORY');

BEGIN
dbms_scheduler.create_job('UPDATE_RSE_USAGE_HISTORY',
job_type=>'STORED_PROCEDURE',
job_action=> 'ADD_RSE_USAGE',
number_of_arguments=>0,
start_date=>TO_TIMESTAMP_TZ('06-APR-2016 11.00.00 EUROPE/ZURICH','DD-MON-YYYY HH24:MI:SS TZR'),
repeat_interval=> 'FREQ=Minutely; INTERVAL=30',
job_class=> 'RUCIO_JOB_CLASS',
enabled=>TRUE,
auto_drop=>FALSE
);
END;
/


--- 4 -------------------------------------------------------------------------------------------------------------------------------------------------

exec dbms_scheduler.drop_job('RUCIO_DATA_SLIDING_WINDOWS');

BEGIN 
dbms_scheduler.create_job(
'RUCIO_DATA_SLIDING_WINDOWS',
job_type=>'PLSQL_BLOCK', 
job_action=> 'BEGIN RUCIO_DATA_SLIDING_WINDOW(''REQUESTS_HISTORY'', 180); RUCIO_TABLE_SL_WINDOW(''MESSAGES_HISTORY'',''CREATED_AT'', 30, 1); END;', 
start_date=>TO_TIMESTAMP_TZ('03-NOV-2014 09.00.00 EUROPE/ZURICH','DD-MON-YYYY HH24:MI:SS TZR'), 
repeat_interval=> 'FREQ=WEEKLY; BYDAY=MON; BYHOUR=10; BYMINUTE=0; BYSECOND=0;', 
job_class=>'RUCIO_JOB_CLASS', 
enabled=>TRUE, 
auto_drop=>FALSE,
comments=>'Every Monday remove partitions that are older than the number of most recent partitions given as argument to the PLSQL procedure'
);
END; 
/


--- 5 -------------------------------------------------------------------------------------------------------------------------------------------------

exec dbms_scheduler.drop_job('RULES_HIST_SL_WINDOW');

  
BEGIN 
dbms_scheduler.create_job(
'RULES_HIST_SL_WINDOW',
job_type=>'PLSQL_BLOCK',
job_action=> 'BEGIN RUCIO_TABLE_SL_WINDOW(''RULES_HIST_RECENT'',''UPDATED_AT'',5,7); END;',
start_date=>TO_TIMESTAMP_TZ('09-MAR-2015 07.00.00 EUROPE/ZURICH','DD-MON-YYYY HH24:MI:SS TZR'),
repeat_interval=> 'FREQ=WEEKLY; BYDAY=MON; BYHOUR=07; BYMINUTE=0; BYSECOND=0;', 
job_class=>'RUCIO_JOB_CLASS', 
enabled=>TRUE, 
auto_drop=> FALSE,
comments=> 'Every Monday delete partitions that are oleder than last 5 weeks'
);
END; 
/



--- 6 -------------------------------------------------------------------------------------------------------------------------------------------------





---- 7 ------------------------------------------------------------------------------------------------------------------------------------------------



---- 8 ------------------------------------------------------------------------------------------------------------------------------------------------


--- 9 -------------------------------------------------------------------------------------------------------------------------------------------------



--- 10 -------------------------------------------------------------------------------------------------------------------------------------------------


--- 11 -------------------------------------------------------------------------------------------------------------------------------------------------



--- 12 -------------------------------------------------------------------------------------------------------------------------------------------------



--- 13 -------------------------------------------------------------------------------------------------------------------------------------------------




--- 14 -------------------------------------------------------------------------------------------------------------------------------------------------



--- 15 -------------------------------------------------------------------------------------------------------------------------------------------------



--- 16 -------------------------------------------------------------------------------------------------------------------------------------------------


--- 17 -------------------------------------------------------------------------------------------------------------------------------------------------

exec dbms_scheduler.drop_job('RUCIO_ACCOUNT_USAGE_HIST_JOB');


BEGIN 

dbms_scheduler.create_job
(
'RUCIO_ACCOUNT_USAGE_HIST_JOB',
job_type=>'PLSQL_BLOCK', 
job_action=> 'BEGIN ADD_ACCOUNT_USAGE_HISTORY;  END; ',
number_of_arguments=> 0,
start_date=>TO_TIMESTAMP_TZ('10-JAN-2019 08.00.00 EUROPE/ZURICH','DD-MON-YYYY HH24:MI:SS TZR'), 
repeat_interval=> 'FREQ=DAILY; BYHOUR=08; BYMINUTE=0; BYSECOND=0;', 
job_class=>'RUCIO_JOB_CLASS', 
enabled=> TRUE, 
auto_drop=> FALSE,
comments=> 'Job for regular insertion of the changed (since the previous execution rows) from the ACCOUNT_USAGE into the ACCOUNT_USAGE_HISTORY table.'
);

END; 
/






