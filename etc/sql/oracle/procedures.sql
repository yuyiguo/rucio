/*
Current procedures and triggers

SQL> select object_type, object_name from user_procedures;

OBJECT_TYPE	    OBJECT_NAME
------------------- --------------------------------------------------------------------------------------------------------------------------------
PROCEDURE	    COLLECTION_REPLICAS_UPDATES
TRIGGER 	    CHECK_DID_UNIQUENESS
TRIGGER 	    MIGRATE_DELETED_DID
TRIGGER 	    SCOPE_AVOID_UPDATE_DELETE
TRIGGER 	    ACCOUNT_AVOID_UPDATE_DELETE

*/





-- Rucio DB functions and procedure definitions for Oracle RDBMS
-- Authors: Rucio team and Gancho Dimitrov 



-- ==============================================================================
-- ==============================  Functions  ===================================
-- ==============================================================================

CREATE OR REPLACE FUNCTION RSE2ID(RSE_NAME IN VARCHAR2)
RETURN RAW
DETERMINISTIC
IS
    rse_id RAW(16);
BEGIN
    SELECT id
    INTO rse_id
    FROM rses
    WHERE rse = RSE_NAME;

    RETURN rse_id;
END;
/

--------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION ID2RSE(RSE_ID IN RAW)
RETURN VARCHAR2
DETERMINISTIC
IS
    rse_name VARCHAR2(256);
BEGIN
    SELECT rse
    INTO rse_name
    FROM rses
    WHERE id = RSE_ID;

    RETURN rse_name;
END;
/

--------------------------------------------------------------------------------------------------------------------------------
/*
GRANT EXECUTE on DBMS_CRYPTO to CMS_RUCIO_DEV_ADMIN; 


CREATE OR REPLACE FUNCTION LFN2PATH(scope varchar2, name varchar2) 
RETURN VARCHAR2 DETERMINISTIC IS
      md5  varchar2(1024) := lower(rawtohex(dbms_crypto.hash(to_clob(name), 2))) ;
      path varchar2(1024);
BEGIN

   IF scope like 'user.%' THEN
	path := 'user/' || regexp_substr(scope, '[^.]+', 1, 2) || '/' ;
   ELSIF scope like 'group.%' THEN
	path := 'group/' || regexp_substr(scope, '[^.]+', 1, 2) || '/' ;
   ELSE
	path := scope || '/';
   END IF;
   RETURN path || SUBSTR(md5, 1, 2) || '/' || SUBSTR(md5, 3, 2) || '/' || name;

END;
/

*/

-- =========================================================================================
-- ==============================  Procedures  =============================================
-- =========================================================================================


-- PLSQL procedure for adding new LIST partition to any relevant Rucio table (the LOGGING_TABPARTITIONS table must exist beforehand) 
-- Use of DBMS_ASSERT for validation of the input. Sanitise the input by replacing the dots and dashes into the SCOPE names by underscore for the partition names to be Oracle friendly.
/*
CREATE OR REPLACE PROCEDURE ADD_NEW_PARTITION( m_tabname VARCHAR2, m_partition_name VARCHAR2) 
AS
	-- PRAGMA AUTONOMOUS_TRANSACTION;
	-- define exception handling for the ORA-00054: resource busy and acquire with NOWAIT specified error
	resource_busy EXCEPTION;
	PRAGMA exception_init (resource_busy,-54);
	stmt VARCHAR2(1000);
	v_error_message VARCHAR2(1000);
BEGIN
	-- version 1.2 with the use of the DBMS_ASSERT package for validation of the input value
	-- the partition names are capitalised as by default
	-- dots and dashes are replaced into the SCOPE names by underscore for the partition names to be Oracle friendly
	-- Oracle has specific meaning/treatment for these symbols and INTERVAL stats gathering does not work
	LOOP
		   BEGIN

			-- the DBMS_ASSERT.SIMPLE_SQL_NAME is needed to verify that the input string is a simple SQL name.
			-- The name must begin with an alphabetic character. It may contain alphanumeric characters as well as the characters _, $, and # as of the second position

            stmt := 'ALTER TABLE '|| DBMS_ASSERT.QUALIFIED_SQL_NAME ( m_tabname ) ||' ADD PARTITION ' || DBMS_ASSERT.SIMPLE_SQL_NAME(REPLACE(REPLACE(UPPER(m_partition_name),'.', '_'), '-', '_' )) || ' VALUES  ('|| DBMS_ASSERT.ENQUOTE_LITERAL(m_partition_name) ||')';

            DBMS_UTILITY.exec_ddl_statement(stmt);

			-- a logging record
			INSERT INTO  LOGGING_TABPARTITIONS(table_name, partition_name, partition_value , action_type, action_date, executed_sql_stmt, message )
			VALUES (m_tabname, REPLACE(REPLACE(UPPER(m_partition_name),'.', '_'), '-', '_' ), m_partition_name ,'CREATE', systimestamp, stmt, 'success');
		     	EXIT;
		   EXCEPTION
    			WHEN resource_busy
				-- THEN DBMS_LOCK.sleep(1);
				THEN DBMS_SESSION.sleep(1); -- from 12c onwards 
				CONTINUE;
			WHEN OTHERS
				THEN v_error_message := SUBSTR(SQLERRM,1,1000);
				INSERT INTO  LOGGING_TABPARTITIONS(table_name, partition_name, partition_value, action_type, action_date, executed_sql_stmt, message )
				VALUES (m_tabname, REPLACE(REPLACE(UPPER(m_partition_name),'.', '_'), '-', '_' ), m_partition_name ,'CREATE', systimestamp, stmt, v_error_message );
				EXIT;
		   END;
	END LOOP;
COMMIT;
END;
/
*/



-------------------------------------------------------------------------------------------------------------------------------------------------

/*

CREATE OR REPLACE PROCEDURE ABACUS_ACCOUNT AS
   type array_raw is table of RAW(16) index by binary_integer;
   type array_number is table of NUMBER(19) index by binary_integer;
   type array_varchar2 is table of VARCHAR2(25 CHAR) index by binary_integer;

   r array_raw;
   f array_number;
   b array_number;
   a array_varchar2;
BEGIN
       DELETE FROM UPDATED_ACCOUNT_COUNTERS
       RETURNING rse_id, files, bytes, account BULK COLLECT INTO r,f,b,a;

       FORALL i in r.FIRST .. r.LAST
               MERGE INTO account_usage D
               USING (select r(i) as rse_id, a(i) as account from dual) T
               ON (D.rse_id = T.rse_id and D.account = T.account )
               WHEN MATCHED THEN UPDATE SET files = files + f(i), bytes = bytes + b(i), updated_at = CAST(SYS_EXTRACT_UTC(LOCALTIMESTAMP) AS DATE)
               WHEN NOT MATCHED THEN INSERT (rse_id, account, files, bytes, updated_at, created_at)
               VALUES (r(i), a(i), f(i), b(i), CAST(SYS_EXTRACT_UTC(LOCALTIMESTAMP) AS DATE), CAST(SYS_EXTRACT_UTC(LOCALTIMESTAMP) AS DATE) );

       COMMIT;
END;
/
*/
-------------------------------------------------------------------------------------------------------------------------------------------------
/*

CREATE OR REPLACE PROCEDURE ABACUS_RSE AS 
    type array_raw is table of RAW(16) index by binary_integer;
    type array_number is table of NUMBER(19) index by binary_integer;
    r array_raw;
    f array_number;
    b array_number;
BEGIN
        DELETE FROM UPDATED_RSE_COUNTERS
        RETURNING rse_id, files, bytes BULK COLLECT INTO r,f,b;

        FORALL i in r.FIRST .. r.LAST
                MERGE INTO RSE_usage D
                USING (select r(i) as rse_id, sys_extract_utc(systimestamp) as now from dual) T
                ON (D.rse_id = T.rse_id and D.source = 'rucio')
                WHEN MATCHED THEN UPDATE SET files = files + f(i), used = used + b(i), updated_at = T.now           
                WHEN NOT MATCHED THEN INSERT (rse_id, files, used, source, updated_at, created_at)
                VALUES (r(i), f(i), b(i), 'rucio', T.now, T.now);                                
        COMMIT;
END;
/

*/

-------------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE ADD_RSE_USAGE AS
BEGIN
      FOR i in (SELECT rse_usage.rse_id, 
                         rse_usage.used as bytes, 
                         rse_usage.free,                          
                         rse_usage.files, 
                         rse_usage.updated_at, 
                         rse_usage.source
                  FROM   rse_usage, rses
                  WHERE  rse_usage.rse_id = rses.id AND deleted = '0')
        LOOP
              MERGE INTO RSE_USAGE_HISTORY H
              USING (SELECT i.rse_id as rse_id, i.bytes as bytes, i.files as files, i.free as free, i.updated_at as updated_at, i.source as source from DUAL) U
              ON (h.rse_id = u.rse_id and h.source = U.source and h.updated_at = u.updated_at)
              WHEN NOT MATCHED THEN INSERT(rse_id, source, used, files, free, updated_at, created_at)
              VALUES (u.rse_id, U.source, u.bytes, u.files, u.free, u.updated_at, u.updated_at);
        END LOOP;
              
        MERGE INTO RSE_USAGE_HISTORY H
        USING (SELECT hextoraw('00000000000000000000000000000000') as rse_id, 'rucio', sum(used) as bytes, sum(files) as files, sys_extract_utc(systimestamp) as updated_at
             FROM   rse_usage c, rses r
             WHERE  c.rse_id = r.id AND c.source = 'rucio' AND r.deleted = '0') U
        ON (h.rse_id = u.rse_id and h.source = 'rucio' and h.UPDATED_AT = u.UPDATED_AT)
        WHEN NOT MATCHED THEN INSERT(rse_id, source, used, files, updated_at, created_at)
        VALUES (u.rse_id, 'rucio', u.bytes, u.files, u.updated_at, u.updated_at);

         FOR usage IN (SELECT /*+ INDEX(R REPLICAS_STATE_IDX ) */ rse_id, SUM(bytes) AS bytes , COUNT(*) AS files
                FROM replicas r WHERE (CASE WHEN state != 'A' THEN rse_id END) IS NOT NULL
                AND (state='U' or state='C') AND tombstone IS NULL GROUP BY rse_id)
         LOOP
              MERGE INTO rse_usage USING DUAL ON (RSE_USAGE.rse_id = usage.rse_id and source = 'unavailable')
              WHEN MATCHED THEN UPDATE SET used=usage.bytes, files=usage.files, updated_at=sysdate
              WHEN NOT MATCHED THEN INSERT (rse_id, source, used, files, updated_at, created_at) VALUES (usage.rse_id, 'unavailable', usage.bytes, usage.files, sysdate, sysdate);
         END LOOP;
                                
        COMMIT;
END;
/



-------------------------------------------------------------------------------------------------------------------------------------------------

-- PLSQL procedure for sustaining DAYS_OFFSET days sliding window on chosen table which has automatic INTERVAL partitioning NUMTODSINTERVAL(1,'DAY')


CREATE OR REPLACE PROCEDURE RUCIO_DATA_SLIDING_WINDOW (mytab_name VARCHAR2, DAYS_OFFSET NUMBER default 90) AUTHID DEFINER
AS
-- Procedure for sustaining DAYS_OFFSET days sliding window on chosen table which has automatic INTERVAL partitioning NUMTODSINTERVAL(1,'DAY')

-- Define exception handling for the ORA-00054: resource busy and acquire with NOWAIT specified error
resource_busy EXCEPTION;
PRAGMA exception_init (resource_busy,-54);

stmt VARCHAR2(4000);
TYPE part_names IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
coll_parts part_names;
messg VARCHAR2(10);
fullq_name VARCHAR2(100);

BEGIN

-- ver 1.2, last update 30th Oct 2014

-- Note: Oracle does NOT allow dropping of the last remaining non-interval partition (ORA-14758)! That is why is better to have INTERVAL = 'YES' condition in the WHERE clause
-- get the older than the last DAYS_OFFSET partitions (days)

-- the DBMS_ASSERT.SQL_OBJECT_NAME function checks that the input string represents an existing object
-- The ORA-44002: invalid object name exception is raised when the input string does not match an existing object name
SELECT DBMS_ASSERT.SQL_OBJECT_NAME( sys_context('USERENV', 'CURRENT_SCHEMA') || '.' || UPPER(mytab_name) ) into fullq_name FROM DUAL;


SELECT partition_name BULK COLLECT INTO coll_parts
FROM USER_TAB_PARTITIONS
WHERE table_name = UPPER(mytab_name)
AND INTERVAL = 'YES' AND partition_position <= (SELECT MAX(partition_position) - DAYS_OFFSET FROM USER_TAB_PARTITIONS
WHERE table_name = UPPER(mytab_name) );

-- do NOT drop partitions that are within DAYS_OFFSET from now. In that case exit the procedure
IF (coll_parts.COUNT <= 0) THEN
	stmt:= 'USER DEFINED INFO: There are NOT partitions with data older than ' || to_char(DAYS_OFFSET) || ' days for drop!';
	-- this RAISE call is commented out as the procedure will be called from within a scheduler job monthly and would be not good to be shown error on the shifters page
	-- RAISE_APPLICATION_ERROR(-20101, stmt );
	return;
END IF;

-- Verification and partition drop part --

FOR j IN 1 .. coll_parts.COUNT LOOP

	-- for each older than the last DAYS_OFFSET partitions check whether the MAX(modificationdate) is smaller than DAYS_OFFSET days
	stmt := 'SELECT (CASE WHEN MAX(created_at) < (SYSDATE - ' || DAYS_OFFSET || ') THEN ''OK'' ELSE ''NOT OK'' END ) FROM ' ||UPPER(mytab_name)||' PARTITION ( ' || coll_parts(j) || ')' ;
	-- DBMS_OUTPUT.put_line(stmt);

	EXECUTE IMMEDIATE stmt INTO messg;

	IF (messg = 'OK') THEN
		stmt := 'ALTER TABLE '|| UPPER(mytab_name)||' DROP PARTITION ' || coll_parts(j) ;

		-- loop until gets exclusive lock on the table
		LOOP
		   BEGIN
			EXECUTE IMMEDIATE stmt;
		     	EXIT;
		   EXCEPTION
    			WHEN resource_busy 
			 THEN DBMS_LOCK.sleep(1);
--			THEN DBMS_SESSION.sleep(1); -- from 12c onwards

		   END;
		END LOOP;
	END IF;

END LOOP;

END;
/



-------------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE RUCIO_TABLE_SL_WINDOW (mytab_name VARCHAR2, mytab_column VARCHAR2, part_offset NUMBER DEFAULT 3, part_range NUMBER DEFAULT 1) AUTHID DEFINER
AS
-- Procedure for sustaining partition offset sliding window on a given table which has automatic INTERVAL partitioning NUMTODSINTERVAL(part_range)
-- the DROP partition clause is with  UPDATE GLOBAL INDEXES option
-- mytab_name: name of the table on which will be enforced a sliding window policy
-- mytab_column: a DATE or a TIMESTAMP column on which is based the RANGE (+ interval) partitioning
-- part_offset: the number of most recent partitions which have to stay in the table
-- part_range: the period in days/months/years defined for a partition

-- define exception handling for the ORA-00054: resource busy and acquire with NOWAIT specified error
resource_busy EXCEPTION;
PRAGMA exception_init (resource_busy,-54);

stmt VARCHAR2(4000);
TYPE part_names IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER;
coll_parts part_names;
messg VARCHAR2(10);
fullq_name VARCHAR2(100);

BEGIN

-- ver 1.0, last update 16th January 2015

-- Note: Oracle does NOT allow dropping of the last remaining non-interval partition (ORA-14758)! That is why is better to have INTERVAL = 'YES' condition in the WHERE clause
-- get the older than the last DAYS_OFFSET partitions (days)

-- the DBMS_ASSERT.SQL_OBJECT_NAME function checks that the input string represents an existing object
-- The ORA-44002: invalid object name exception is raised when the input string does not match an existing object name
SELECT DBMS_ASSERT.SQL_OBJECT_NAME( sys_context('USERENV', 'CURRENT_SCHEMA') || '.' || UPPER(mytab_name) ) into fullq_name FROM DUAL;

SELECT partition_name BULK COLLECT INTO coll_parts
FROM USER_TAB_PARTITIONS
WHERE table_name = UPPER(mytab_name)
AND INTERVAL = 'YES' AND partition_position <= (SELECT MAX(partition_position) - part_offset FROM USER_TAB_PARTITIONS
WHERE table_name = UPPER(mytab_name) );

-- do NOT drop partitions that are within DAYS_OFFSET from now. In that case exit the procedure
IF (coll_parts.COUNT <= 0) THEN
	stmt:= 'USER DEFINED INFO: There are NOT partitions with data older than ' || to_char(part_offset*part_range) || ' days for drop!';
	-- this RAISE call is commented out as the procedure will be called from within a scheduler job monthly and would be not good to be shown error on the shifters page
	-- RAISE_APPLICATION_ERROR(-20101, stmt );
	return;
END IF;

-- Verification and partition drop part --
FOR j IN 1 .. coll_parts.COUNT LOOP

	-- for each older than the last DAYS_OFFSET partitions check whether the MAX(modificationdate) is smaller than DAYS_OFFSET days
	stmt := 'SELECT (CASE WHEN MAX('||mytab_column||') < (SYSDATE - ' || part_offset*part_range || ') THEN ''OK'' ELSE ''NOT OK'' END ) FROM ' ||UPPER(mytab_name)||' PARTITION ( ' || coll_parts(j) || ')' ;
	-- DBMS_OUTPUT.put_line(stmt);

	EXECUTE IMMEDIATE stmt INTO messg;

	IF (messg = 'OK') THEN
		stmt := 'ALTER TABLE '|| UPPER(mytab_name)||' DROP PARTITION ' || coll_parts(j) || ' UPDATE GLOBAL INDEXES';

		-- loop until gets exclusive lock on the table
		LOOP
		   BEGIN
			EXECUTE IMMEDIATE stmt;
		     	EXIT;
		   EXCEPTION
    			WHEN resource_busy 
			 THEN DBMS_LOCK.sleep(1);
--			THEN DBMS_SESSION.sleep(1); -- from Oracle 12c onwards
		   END;
		END LOOP;
	END IF;

END LOOP;

END;
/


-------------------------------------------------------------------------------------------------------------------------------------------------

/*
CREATE OR REPLACE PROCEDURE RUCIO_ACCOUNT_LOGICAL_BYTES 
*/


-------------------------------------------------------------------------------------------------------------------------------------------------


/*
CREATE OR REPLACE PROCEDURE ESTIMATE_TRANSFER_TIME 
*/

-------------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE "COLL_REPLICAS_UPDATE_ALL" AS
    type array_raw is table of RAW(16) index by binary_integer;
    type array_scope is table of VARCHAR2(30) index by binary_integer;
    type array_name  is table of VARCHAR2(255) index by binary_integer;

    ids     array_raw;
    rse_ids array_raw;
    scopes  array_scope;
    names   array_name;

    ds_length                 NUMBER(19);
    ds_bytes                  NUMBER(19);
    available_replicas        NUMBER(19);
    old_available_replicas    NUMBER(19);
    ds_available_bytes        NUMBER(19);
    ds_replica_state          VARCHAR2(1);
    row_exists                NUMBER;


      CURSOR get_upd_col_rep
      IS
      SELECT id, scope, name, rse_id
      FROM updated_col_rep;

BEGIN
    -- Delete duplicates
    DELETE FROM UPDATED_COL_REP A WHERE A.rowid > ANY (SELECT B.rowid FROM UPDATED_COL_REP B WHERE A.scope = B.scope AND A.name=B.name AND A.did_type=B.did_type AND (A.rse_id=B.rse_id OR (A.rse_id IS NULL and B.rse_id IS NULL)));
    -- Delete Update requests which do not have Collection_replicas
    DELETE FROM UPDATED_COL_REP A WHERE A.rse_id IS NOT NULL AND NOT EXISTS(SELECT * FROM COLLECTION_REPLICAS B WHERE B.scope = A.scope AND B.name = A.name  AND B.rse_id = A.rse_id);
    DELETE FROM UPDATED_COL_REP A WHERE A.rse_id IS NULL AND NOT EXISTS(SELECT * FROM COLLECTION_REPLICAS B WHERE B.scope = A.scope AND B.name = A.name);
    COMMIT;

    OPEN get_upd_col_rep;
    LOOP
        FETCH get_upd_col_rep BULK COLLECT INTO ids, scopes, names, rse_ids LIMIT 5000;
        FOR i IN 1 .. rse_ids.count
        LOOP
            DELETE FROM updated_col_rep WHERE id = ids(i);
            IF rse_ids(i) IS NOT NULL THEN
                -- Check one specific DATASET_REPLICA
                BEGIN
                    SELECT length, bytes, available_replicas_cnt INTO ds_length, ds_bytes, old_available_replicas FROM collection_replicas WHERE scope=scopes(i) and name=names(i) and rse_id=rse_ids(i);
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN CONTINUE;
                END;

                SELECT count(*), sum(r.bytes) INTO available_replicas, ds_available_bytes FROM replicas r, contents c WHERE r.scope = c.child_scope and r.name = c.child_name and c.scope = scopes(i) and c.name = names(i) and r.state='A' and r.rse_id=rse_ids(i);
                IF available_replicas >= ds_length THEN
                    ds_replica_state := 'A';
                ELSE
                    ds_replica_state := 'U';
                END IF;
                IF old_available_replicas > 0 AND available_replicas = 0 THEN
                    DELETE FROM COLLECTION_REPLICAS WHERE scope = scopes(i) and name = names(i) and rse_id = rse_ids(i);
                ELSE
                    UPDATE COLLECTION_REPLICAS
                    SET state=ds_replica_state, available_replicas_cnt=available_replicas, length=ds_length, bytes=ds_bytes, available_bytes=ds_available_bytes, updated_at=sys_extract_utc(systimestamp)
                    WHERE scope = scopes(i) and name = names(i) and rse_id = rse_ids(i);
                END IF;
            ELSE
                -- Check all DATASET_REPLICAS of this DS
                SELECT count(*), SUM(bytes) INTO ds_length, ds_bytes FROM contents WHERE scope=scopes(i) and name=names(i);
                UPDATE COLLECTION_REPLICAS SET length=nvl(ds_length,0), bytes=nvl(ds_bytes,0) WHERE scope = scopes(i) and name = names(i);
                FOR rse IN (SELECT rse_id, count(*) as available_replicas, sum(r.bytes) as ds_available_bytes FROM replicas r, contents c WHERE r.scope = c.child_scope and r.name = c.child_name and c.scope = scopes(i) and c.name = names(i) and r.state='A' GROUP BY rse_id)
                LOOP
                    IF rse.available_replicas >= ds_length THEN
                        ds_replica_state := 'A';
                    ELSE
                        ds_replica_state := 'U';
                    END IF;
                    UPDATE COLLECTION_REPLICAS
                    SET state=ds_replica_state, available_replicas_cnt=rse.available_replicas, available_bytes=rse.ds_available_bytes, updated_at=sys_extract_utc(systimestamp)
                    WHERE scope = scopes(i) and name = names(i) and rse_id = rse.rse_id;
                END LOOP;
            END IF;
            COMMIT;
        END LOOP;
        EXIT WHEN get_upd_col_rep%NOTFOUND;
    END LOOP;
    CLOSE get_upd_col_rep;
    COMMIT;
END;
/

--CREATE OR REPLACE PROCEDURE COLL_UPDATED_REPLICAS (virt_scope_gr VARCHAR2)
--AS
--    type array_raw is table of RAW(16) index by binary_integer;
--    type array_scope is table of VARCHAR2(30) index by binary_integer;
--    type array_name  is table of VARCHAR2(255) index by binary_integer;
--
--    ids     array_raw;
--    rse_ids array_raw;
--    scopes  array_scope;
--    names   array_name;
--
--    ds_length                 NUMBER(19);
--    ds_bytes                  NUMBER(19);
--    available_replicas        NUMBER(19);
--    old_available_replicas    NUMBER(19);
--    ds_available_bytes        NUMBER(19);
--    ds_replica_state          VARCHAR2(1);
--    row_exists                NUMBER;
--
--
--	CURSOR get_upd_col_rep
--	IS
--	SELECT id, scope, name, rse_id
--	FROM updated_col_rep
--	WHERE virt_scope_group = virt_scope_gr
--	ORDER BY scope, name;
--
--BEGIN
--
--	/* 22nd March 2018 , ver 1.0 */
--	-- Within the requested virt_scope_gr delete the unnecessary rows
--	-- Delete requests which do not have Collection_replicas
--	DELETE FROM UPDATED_COL_REP A
--	WHERE
--	virt_scope_group = virt_scope_gr
--	AND
--	(
--	A.rse_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM COLLECTION_REPLICAS B WHERE B.scope = A.scope AND B.name = A.name  AND B.rse_id = A.rse_id)
--	)
--	OR
--	(
--	A.rse_id IS NULL AND NOT EXISTS(SELECT 1 FROM COLLECTION_REPLICAS B WHERE B.scope = A.scope AND B.name = A.name)
--	);
--
--     -- Delete duplicates
--    DELETE FROM UPDATED_COL_REP A
--	WHERE
--	virt_scope_group = virt_scope_gr
--	AND
--	A.rowid > ANY (SELECT B.rowid FROM updated_col_rep B WHERE A.scope = B.scope AND A.name=B.name AND A.did_type=B.did_type AND (A.rse_id=B.rse_id OR (A.rse_id IS NULL and B.rse_id IS NULL)));
--
--	COMMIT;
--
--    -- Execute the query
--    OPEN get_upd_col_rep;
--    LOOP
--        FETCH get_upd_col_rep BULK COLLECT INTO ids, scopes, names, rse_ids LIMIT 50000;
--        FOR i IN 1 .. rse_ids.count
--        LOOP
--            DELETE FROM updated_col_rep WHERE id = ids(i);
--            IF rse_ids(i) IS NOT NULL THEN
--                -- Check one specific DATASET_REPLICA
--                BEGIN
--                    SELECT length, bytes, available_replicas_cnt INTO ds_length, ds_bytes, old_available_replicas FROM collection_replicas WHERE scope=scopes(i) and name=names(i) and rse_id=rse_ids(i);
--                EXCEPTION
--                    WHEN NO_DATA_FOUND THEN CONTINUE;
--                END;
--
--                SELECT count(*), sum(r.bytes) INTO available_replicas, ds_available_bytes FROM replicas r, contents c WHERE r.scope = c.child_scope and r.name = c.child_name and c.scope = scopes(i) and c.name = names(i) and r.state='A' and r.rse_id=rse_ids(i);
--                IF available_replicas >= ds_length THEN
--                    ds_replica_state := 'A';
--                ELSE
--                    ds_replica_state := 'U';
--                END IF;
--                IF old_available_replicas > 0 AND available_replicas = 0 THEN
--                    DELETE FROM COLLECTION_REPLICAS WHERE scope = scopes(i) and name = names(i) and rse_id = rse_ids(i);
--                ELSE
--                    UPDATE COLLECTION_REPLICAS
--                    SET state=ds_replica_state, available_replicas_cnt=available_replicas, length=ds_length, bytes=ds_bytes, available_bytes=ds_available_bytes, updated_at=sys_extract_utc(systimestamp)
--                    WHERE scope = scopes(i) and name = names(i) and rse_id = rse_ids(i);
--                END IF;
--            ELSE
--                -- Check all DATASET_REPLICAS of this DS
--                SELECT count(*), SUM(bytes) INTO ds_length, ds_bytes FROM contents WHERE scope=scopes(i) and name=names(i);
--                UPDATE COLLECTION_REPLICAS SET length=nvl(ds_length,0), bytes=nvl(ds_bytes,0) WHERE scope = scopes(i) and name = names(i);
--                FOR rse IN (SELECT rse_id, count(*) as available_replicas, sum(r.bytes) as ds_available_bytes FROM replicas r, contents c WHERE r.scope = c.child_scope and r.name = c.child_name and c.scope = scopes(i) and c.name = names(i) and r.state='A' GROUP BY rse_id)
--                LOOP
--                    IF rse.available_replicas >= ds_length THEN
--                        ds_replica_state := 'A';
--                    ELSE
--                        ds_replica_state := 'U';
--                    END IF;
--                    UPDATE COLLECTION_REPLICAS
--                    SET state=ds_replica_state, available_replicas_cnt=rse.available_replicas, available_bytes=rse.ds_available_bytes, updated_at=sys_extract_utc(systimestamp)
--                    WHERE scope = scopes(i) and name = names(i) and rse_id = rse.rse_id;
--                END LOOP;
--            END IF;
--            COMMIT;
--        END LOOP;
--        EXIT WHEN get_upd_col_rep%NOTFOUND;
--    END LOOP;
--    CLOSE get_upd_col_rep;
--    COMMIT;
--END;
--/
--


-------------------------------------------------------------------------------------------------------------------------------------------------

/*

CREATE OR REPLACE PROCEDURE COLL_UPDATED_REPLICAS_ORAHASH (virt_scope_gr VARCHAR2, num_splitters NUMBER DEFAULT 0, portion_id NUMBER DEFAULT 0)
AS
    type array_raw is table of RAW(16) index by binary_integer;
    type array_scope is table of VARCHAR2(30) index by binary_integer;
    type array_name  is table of VARCHAR2(255) index by binary_integer;

    ids     array_raw;
    rse_ids array_raw;
    scopes  array_scope;
    names   array_name;

    ds_length                 NUMBER(19);
    ds_bytes                  NUMBER(19);
    available_replicas        NUMBER(19);
    old_available_replicas    NUMBER(19);
    ds_available_bytes        NUMBER(19);
    ds_replica_state          VARCHAR2(1);
    row_exists                NUMBER;

	-- Get the rows of the asked virtual scope and data portion based to the num_splitters and the result from ORA_HASH(name, num_splitters ) = portion_id
	-- ORA_HASH computes a hash value for a given expression. It is useful for operations such as analyzing a subset of data and generating a random sample.
	CURSOR get_upd_col_rep
	IS
	SELECT id, scope, name, rse_id
	FROM updated_col_rep
	WHERE virt_scope_group = virt_scope_gr
	AND ORA_HASH(name, num_splitters ) = portion_id
	ORDER BY scope, name;

BEGIN

	--4nd April 2018, ver 1.0

	--Within the requested virt_scope_gr and data portion based to the num_splitters and the result from ORA_HASH(name, num_splitters ) = portion_id, delete the unnecessary rows
	-- Delete requests which do not have Collection_replicas
	DELETE FROM UPDATED_COL_REP A
	WHERE
	virt_scope_group = virt_scope_gr
	AND ORA_HASH(name, num_splitters) = portion_id
	AND
	(
	A.rse_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM COLLECTION_REPLICAS B WHERE B.scope = A.scope AND B.name = A.name  AND B.rse_id = A.rse_id)
	)
	OR
	(
	A.rse_id IS NULL AND NOT EXISTS(SELECT 1 FROM COLLECTION_REPLICAS B WHERE B.scope = A.scope AND B.name = A.name)
	);
	COMMIT;

     -- Delete duplicates
    DELETE FROM UPDATED_COL_REP A
	WHERE
	virt_scope_group = virt_scope_gr
	AND ORA_HASH(name, num_splitters) = portion_id
	AND
	A.rowid > ANY (SELECT B.rowid FROM updated_col_rep B WHERE A.scope = B.scope AND A.name=B.name AND A.did_type=B.did_type AND (A.rse_id=B.rse_id OR (A.rse_id IS NULL and B.rse_id IS NULL)));

	COMMIT;

    -- Execute the query
    OPEN get_upd_col_rep;
    LOOP
        FETCH get_upd_col_rep BULK COLLECT INTO ids, scopes, names, rse_ids LIMIT 70000;
        FOR i IN 1 .. rse_ids.count
        LOOP
            DELETE FROM updated_col_rep WHERE id = ids(i);
            IF rse_ids(i) IS NOT NULL THEN
                -- Check one specific DATASET_REPLICA
                BEGIN
                    SELECT length, bytes, available_replicas_cnt INTO ds_length, ds_bytes, old_available_replicas FROM collection_replicas WHERE scope=scopes(i) and name=names(i) and rse_id=rse_ids(i);
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN CONTINUE;
                END;

                SELECT count(*), sum(r.bytes) INTO available_replicas, ds_available_bytes FROM replicas r, contents c WHERE r.scope = c.child_scope and r.name = c.child_name and c.scope = scopes(i) and c.name = names(i) and r.state='A' and r.rse_id=rse_ids(i);
                IF available_replicas >= ds_length THEN
                    ds_replica_state := 'A';
                ELSE
                    ds_replica_state := 'U';
                END IF;
                IF old_available_replicas > 0 AND available_replicas = 0 THEN
                    DELETE FROM COLLECTION_REPLICAS WHERE scope = scopes(i) and name = names(i) and rse_id = rse_ids(i);
                ELSE
                    UPDATE COLLECTION_REPLICAS
                    SET state=ds_replica_state, available_replicas_cnt=available_replicas, length=ds_length, bytes=ds_bytes, available_bytes=ds_available_bytes, updated_at=sys_extract_utc(systimestamp)
                    WHERE scope = scopes(i) and name = names(i) and rse_id = rse_ids(i);
                END IF;
            ELSE
                -- Check all DATASET_REPLICAS of this DS
                SELECT count(*), SUM(bytes) INTO ds_length, ds_bytes FROM contents WHERE scope=scopes(i) and name=names(i);
                UPDATE COLLECTION_REPLICAS SET length=nvl(ds_length,0), bytes=nvl(ds_bytes,0) WHERE scope = scopes(i) and name = names(i);
                FOR rse IN (SELECT rse_id, count(*) as available_replicas, sum(r.bytes) as ds_available_bytes FROM replicas r, contents c WHERE r.scope = c.child_scope and r.name = c.child_name and c.scope = scopes(i) and c.name = names(i) and r.state='A' GROUP BY rse_id)
                LOOP
                    IF rse.available_replicas >= ds_length THEN
                        ds_replica_state := 'A';
                    ELSE
                        ds_replica_state := 'U';
                    END IF;
                    UPDATE COLLECTION_REPLICAS
                    SET state=ds_replica_state, available_replicas_cnt=rse.available_replicas, available_bytes=rse.ds_available_bytes, updated_at=sys_extract_utc(systimestamp)
                    WHERE scope = scopes(i) and name = names(i) and rse_id = rse.rse_id;
                END LOOP;
            END IF;
            COMMIT;
        END LOOP;
        EXIT WHEN get_upd_col_rep%NOTFOUND;
    END LOOP;
    CLOSE get_upd_col_rep;
    COMMIT;
END;
/

*/

-------------------------------------------------------------------------------------------------------------------------------------------------


CREATE OR REPLACE PROCEDURE ADD_ACCOUNT_USAGE_HISTORY 
AS
BEGIN

	/* 9th Jan 2019: A PLSQL procedure for insertion of the changed (since the previous execution) rows from the ACCOUNT_USAGE into the ACCOUNT_USAGE_HISTORY table */

	MERGE INTO ACCOUNT_USAGE_HISTORY h 
	USING 
	( SELECT   account_usage.account,
                         account_usage.rse_id, 
                         account_usage.bytes,                          
                         account_usage.files, 
                         account_usage.updated_at
                  FROM   account_usage, rses
                  WHERE  account_usage.rse_id = rses.id AND deleted = '0') u 
	ON (h.rse_id = u.rse_id and h.account = u.account and h.updated_at = u.updated_at)
	WHEN NOT MATCHED THEN INSERT(account, rse_id, bytes, files,  updated_at, created_at)
	VALUES (u.account, u.rse_id, u.bytes, u.files, u.updated_at, CAST(SYS_EXTRACT_UTC(LOCALTIMESTAMP) AS DATE) );
        
COMMIT;

END;
/


--/
