
CREATE TABLE quarantined_replicas_history (
        rse_id RAW(16) NOT NULL,
        path VARCHAR2(1024 CHAR) NOT NULL,
        bytes NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "QRD_REPLICAS_HISTORY_PK" PRIMARY KEY (rse_id, path, updated_at)
) PCTFREE 0;


CREATE TABLE requests_history (
        id RAW(16) NOT NULL,
        request_type VARCHAR(1 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        did_type VARCHAR(1 CHAR),
        dest_rse_id RAW(16),
        source_rse_id RAW(16),
        attributes VARCHAR2(4000 CHAR),
        state VARCHAR(1 CHAR),
        external_id VARCHAR2(64 CHAR),
        external_host VARCHAR2(256 CHAR),
        retry_count INTEGER DEFAULT '0',
        err_msg VARCHAR2(4000 CHAR),
        previous_attempt_id RAW(16),
        rule_id RAW(16),
        activity VARCHAR2(50 CHAR),
        bytes NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        dest_url VARCHAR2(2048 CHAR),
        submitted_at DATE,
        started_at DATE,
        transferred_at DATE,
        estimated_at DATE,
        submitter_id INTEGER,
        estimated_started_at DATE,
        estimated_transferred_at DATE,
        staging_started_at DATE,
        staging_finished_at DATE,
        account VARCHAR2(25 CHAR),
        requested_at DATE,
        priority INTEGER,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "REQUESTS_HISTORY_PK" PRIMARY KEY (id, updated_at),
        CONSTRAINT "RUCIO_ENUM_647d06" CHECK (request_type IN ('I', 'U', 'T', 'O', 'D')),
        CONSTRAINT "RUCIO_ENUM_6e77b6" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "RUCIO_ENUM_f6c539" CHECK (state IN ('A', 'D', 'G', 'F', 'M', 'L', 'O', 'N', 'Q', 'S', 'U', 'W'))
) PCTFREE 0;


CREATE TABLE accounts (
        account VARCHAR2(25 CHAR) NOT NULL,
        account_type VARCHAR(7 CHAR),
        status VARCHAR(9 CHAR),
        email VARCHAR2(255 CHAR),
        suspended_at DATE,
        deleted_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ACCOUNTS_PK" PRIMARY KEY (account),
        CONSTRAINT "ACCOUNTS_TYPE_NN" CHECK (ACCOUNT_TYPE IS NOT NULL),
        CONSTRAINT "ACCOUNTS_STATUS_NN" CHECK (STATUS IS NOT NULL),
        CONSTRAINT "ACCOUNTS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNTS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNTS_TYPE_CHK" CHECK (account_type IN ('GROUP', 'USER', 'SERVICE')),
        CONSTRAINT "ACCOUNTS_STATUS_CHK" CHECK (status IN ('ACTIVE', 'DELETED', 'SUSPENDED'))
) PCTFREE 0;


CREATE TABLE vos (
        vo VARCHAR2(3 CHAR) NOT NULL,
        description VARCHAR2(255 CHAR),
        email VARCHAR2(255 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "VOS_PK" PRIMARY KEY (vo),
        CONSTRAINT "VOS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "VOS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE tmp_dids (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        rse_id RAW(16),
        path VARCHAR2(1024 CHAR),
        bytes NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        expired_at DATE,
        guid RAW(16),
        events NUMBER(19),
        task_id INTEGER,
        panda_id INTEGER,
        parent_scope VARCHAR2(25 CHAR),
        parent_name VARCHAR2(500 CHAR),
        offset NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "TMP_DIDS_PK" PRIMARY KEY (scope, name),
        CONSTRAINT "TMP_DIDS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "TMP_DIDS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "TMP_DIDS_EXPIRED_AT_IDX" ON tmp_dids (expired_at);


CREATE TABLE alembic_version (
        version_num VARCHAR2(32 CHAR) NOT NULL,
        CONSTRAINT "ALEMBIC_VERSION_PK" PRIMARY KEY (version_num)
) PCTFREE 0;


CREATE TABLE identities (
        identity VARCHAR2(2048 CHAR) NOT NULL,
        identity_type VARCHAR(8 CHAR) NOT NULL,
        username VARCHAR2(255 CHAR),
        password VARCHAR2(255 CHAR),
        salt BLOB,
        email VARCHAR2(255 CHAR),
        updated_at DATE,
        created_at DATE,
        deleted NUMBER(1),
        deleted_at DATE,
        CONSTRAINT "IDENTITIES_PK" PRIMARY KEY (identity, identity_type),
        CONSTRAINT "IDENTITIES_TYPE_NN" CHECK (IDENTITY_TYPE IS NOT NULL),
        CONSTRAINT "IDENTITIES_EMAIL_NN" CHECK (EMAIL IS NOT NULL),
        CONSTRAINT "IDENTITIES_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "IDENTITIES_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "IDENTITIES_DELETED_NN" CHECK (DELETED IS NOT NULL),
        CONSTRAINT "IDENTITIES_TYPE_CHK" CHECK (identity_type IN ('GSS', 'SAML', 'X509', 'SSH', 'USERPASS', 'OIDC')),
        CHECK (deleted IN (0, 1))
) PCTFREE 0;


CREATE TABLE oauth_requests (
        account VARCHAR2(25 CHAR),
        state VARCHAR2(50 CHAR) NOT NULL,
        nonce VARCHAR2(50 CHAR),
        access_msg VARCHAR2(2048 CHAR),
        redirect_msg VARCHAR2(2048 CHAR),
        refresh_lifetime INTEGER,
        ip VARCHAR2(39 CHAR),
        expired_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "OAUTH_REQUESTS_PK" PRIMARY KEY (state),
        CONSTRAINT "OAUTH_REQUESTS_EXPIRED_AT_NN" CHECK (EXPIRED_AT IS NOT NULL),
        CONSTRAINT "OAUTH_REQUESTS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "OAUTH_REQUESTS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "OAUTH_REQUESTS_ACC_EXP_AT_IDX" ON oauth_requests (account, expired_at);

CREATE INDEX "OAUTH_REQUESTS_ACCESS_MSG_IDX" ON oauth_requests (access_msg);


CREATE TABLE rules_history (
        id RAW(16),
        subscription_id RAW(16),
        account VARCHAR2(25 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        did_type VARCHAR(1 CHAR),
        state VARCHAR(1 CHAR),
        error VARCHAR2(255 CHAR),
        rse_expression VARCHAR2(3000 CHAR),
        copies SMALLINT,
        expires_at DATE,
        weight VARCHAR2(255 CHAR),
        locked NUMBER(1),
        locks_ok_cnt NUMBER(19),
        locks_replicating_cnt NUMBER(19),
        locks_stuck_cnt NUMBER(19),
        source_replica_expression VARCHAR2(255 CHAR),
        activity VARCHAR2(50 CHAR),
        grouping VARCHAR(1 CHAR),
        notification VARCHAR(1 CHAR),
        stuck_at DATE,
        priority INTEGER,
        purge_replicas NUMBER(1),
        ignore_availability NUMBER(1),
        ignore_account_limit NUMBER(1),
        comments VARCHAR2(255 CHAR),
        child_rule_id RAW(16),
        eol_at DATE,
        split_container NUMBER(1),
        meta VARCHAR2(4000 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "RULES_HISTORY_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "RULES_HISTORY_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "RULES_HISTORY_DIDTYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "RULES_HISTORY_STATE_CHK" CHECK (state IN ('I', 'O', 'S', 'R', 'U', 'W')),
        CHECK (locked IN (0, 1)),
        CONSTRAINT "RULES_HISTORY_GROUPING_CHK" CHECK (grouping IN ('A', 'D', 'N')),
        CONSTRAINT "RULES_HISTORY_NOTIFY_CHK" CHECK (notification IN ('Y', 'P', 'C', 'N')),
        CHECK (purge_replicas IN (0, 1)),
        CHECK (ignore_availability IN (0, 1)),
        CHECK (ignore_account_limit IN (0, 1)),
        CHECK (split_container IN (0, 1))
) PCTFREE 0;

CREATE INDEX "RULES_HISTORY_SCOPENAME_IDX" ON rules_history (scope, name);


CREATE TABLE updated_dids (
        id RAW(16) NOT NULL,
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        rule_evaluation_action VARCHAR(1 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "UPDATED_DIDS_PK" PRIMARY KEY (id),
        CONSTRAINT "UPDATED_DIDS_SCOPE_NN" CHECK (SCOPE IS NOT NULL),
        CONSTRAINT "UPDATED_DIDS_NAME_NN" CHECK (NAME IS NOT NULL),
        CONSTRAINT "UPDATED_DIDS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "UPDATED_DIDS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "UPDATED_DIDS_RULE_EVAL_ACT_CHK" CHECK (rule_evaluation_action IN ('A', 'D'))
) PCTFREE 0;

CREATE INDEX "UPDATED_DIDS_SCOPERULENAME_IDX" ON updated_dids (scope, rule_evaluation_action, name);


CREATE TABLE deleted_dids (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR),
        did_type VARCHAR(1 CHAR),
        is_open NUMBER(1),
        monotonic NUMBER(1) DEFAULT '0',
        hidden NUMBER(1) DEFAULT '0',
        obsolete NUMBER(1) DEFAULT '0',
        complete NUMBER(1),
        is_new NUMBER(1) DEFAULT '1',
        availability VARCHAR(1 CHAR),
        suppressed NUMBER(1) DEFAULT '0',
        bytes NUMBER(19),
        length NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        expired_at DATE,
        deleted_at DATE,
        events NUMBER(19),
        guid RAW(16),
        project VARCHAR2(50 CHAR),
        datatype VARCHAR2(50 CHAR),
        run_number INTEGER,
        stream_name VARCHAR2(70 CHAR),
        prod_step VARCHAR2(50 CHAR),
        version VARCHAR2(50 CHAR),
        campaign VARCHAR2(50 CHAR),
        task_id INTEGER,
        panda_id INTEGER,
        lumiblocknr INTEGER,
        provenance VARCHAR2(2 CHAR),
        phys_group VARCHAR2(25 CHAR),
        transient NUMBER(1) DEFAULT '0',
        purge_replicas NUMBER(1),
        accessed_at DATE,
        closed_at DATE,
        eol_at DATE,
        is_archive NUMBER(1),
        constituent NUMBER(1),
        access_cnt INTEGER,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DELETED_DIDS_PK" PRIMARY KEY (scope, name),
        CONSTRAINT "DELETED_DIDS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DELETED_DIDS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "DEL_DIDS_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "DEL_DIDS_IS_OPEN_CHK" CHECK (is_open IN (0, 1)),
        CONSTRAINT "DEL_DIDS_MONO_CHK" CHECK (monotonic IN (0, 1)),
        CONSTRAINT "DEL_DIDS_HIDDEN_CHK" CHECK (hidden IN (0, 1)),
        CONSTRAINT "DEL_DIDS_OBSOLETE_CHK" CHECK (obsolete IN (0, 1)),
        CONSTRAINT "DEL_DIDS_COMPLETE_CHK" CHECK (complete IN (0, 1)),
        CONSTRAINT "DEL_DIDS_IS_NEW_CHK" CHECK (is_new IN (0, 1)),
        CONSTRAINT "DEL_DIDS_AVAIL_CHK" CHECK (availability IN ('A', 'D', 'L')),
        CONSTRAINT "DEL_FILES_SUPP_CHK" CHECK (suppressed IN (0, 1)),
        CONSTRAINT "DEL_DID_TRANSIENT_CHK" CHECK (transient IN (0, 1)),
        CONSTRAINT "DELETED_DIDS_PURGE_RPLCS_CHK" CHECK (purge_replicas IN (0, 1)),
        CONSTRAINT "DEL_DIDS_ARCH_CHK" CHECK (is_archive IN (0, 1)),
        CONSTRAINT "DEL_DIDS_CONST_CHK" CHECK (constituent IN (0, 1))
) PCTFREE 0;


CREATE TABLE account_usage_history (
        account VARCHAR2(25 CHAR) NOT NULL,
        rse_id RAW(16) NOT NULL,
        files NUMBER(19),
        bytes NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ACCOUNT_USAGE_HISTORY_PK" PRIMARY KEY (account, rse_id, updated_at)
) PCTFREE 0;


CREATE TABLE configs_history (
        section VARCHAR2(128 CHAR) NOT NULL,
        opt VARCHAR2(128 CHAR) NOT NULL,
        value VARCHAR2(4000 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "CONFIGS_HISTORY_PK" PRIMARY KEY (section, opt, updated_at)
) PCTFREE 0;


CREATE TABLE messages (
        id RAW(16) NOT NULL,
        event_type VARCHAR2(1024 CHAR),
        payload VARCHAR2(4000 CHAR),
        payload_nolimit CLOB,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "MESSAGES_PK" PRIMARY KEY (id),
        CONSTRAINT "MESSAGES_EVENT_TYPE_NN" CHECK (EVENT_TYPE IS NOT NULL),
        CONSTRAINT "MESSAGES_PAYLOAD_NN" CHECK (PAYLOAD IS NOT NULL),
        CONSTRAINT "MESSAGES_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "MESSAGES_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE messages_history (
        id RAW(16),
        event_type VARCHAR2(1024 CHAR),
        payload VARCHAR2(4000 CHAR),
        payload_nolimit CLOB,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "MESSAGES_HISTORY_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "MESSAGES_HISTORY_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE updated_col_rep (
        id RAW(16) NOT NULL,
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        did_type VARCHAR(1 CHAR),
        rse_id RAW(16),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "UPDATED_COL_REP_PK" PRIMARY KEY (id),
        CONSTRAINT "UPDATED_COL_REP_SCOPE_NN" CHECK (SCOPE IS NOT NULL),
        CONSTRAINT "UPDATED_COL_REP_NAME_NN" CHECK (NAME IS NOT NULL),
        CONSTRAINT "UPDATED_COL_REP_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "UPDATED_COL_REP_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "UPDATED_COL_REP_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z'))
) PCTFREE 0;

CREATE INDEX "UPDATED_COL_REP_SNR_IDX" ON updated_col_rep (scope, name, rse_id);


CREATE TABLE subscriptions_history (
        id RAW(16) NOT NULL,
        name VARCHAR2(64 CHAR),
        filter VARCHAR2(2048 CHAR),
        replication_rules VARCHAR2(1024 CHAR),
        policyid SMALLINT DEFAULT '0',
        state VARCHAR(1 CHAR),
        last_processed DATE,
        account VARCHAR2(25 CHAR),
        lifetime DATE,
        comments VARCHAR2(4000 CHAR),
        retroactive NUMBER(1),
        expired_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "SUBSCRIPTIONS_HISTORY_PK" PRIMARY KEY (id, updated_at),
        CONSTRAINT "RUCIO_ENUM_2cb259" CHECK (state IN ('I', 'A', 'B', 'U', 'N')),
        CONSTRAINT "SUBS_HISTORY_RETROACTIVE_CHK" CHECK (retroactive IN (0, 1))
) PCTFREE 0;


CREATE TABLE configs (
        section VARCHAR2(128 CHAR) NOT NULL,
        opt VARCHAR2(128 CHAR) NOT NULL,
        value VARCHAR2(4000 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "CONFIGS_PK" PRIMARY KEY (section, opt),
        CONSTRAINT "CONFIGS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "CONFIGS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE rules_hist_recent (
        id RAW(16),
        subscription_id RAW(16),
        account VARCHAR2(25 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        did_type VARCHAR(1 CHAR),
        state VARCHAR(1 CHAR),
        error VARCHAR2(255 CHAR),
        rse_expression VARCHAR2(3000 CHAR),
        copies SMALLINT,
        expires_at DATE,
        weight VARCHAR2(255 CHAR),
        locked NUMBER(1),
        locks_ok_cnt NUMBER(19),
        locks_replicating_cnt NUMBER(19),
        locks_stuck_cnt NUMBER(19),
        source_replica_expression VARCHAR2(255 CHAR),
        activity VARCHAR2(50 CHAR),
        grouping VARCHAR(1 CHAR),
        notification VARCHAR(1 CHAR),
        stuck_at DATE,
        purge_replicas NUMBER(1),
        ignore_availability NUMBER(1),
        ignore_account_limit NUMBER(1),
        priority INTEGER,
        comments VARCHAR2(255 CHAR),
        child_rule_id RAW(16),
        eol_at DATE,
        split_container NUMBER(1),
        meta VARCHAR2(4000 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "RULES_HIST_RECENT_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "RULES_HIST_RECENT_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "RULES_HIST_RECENT_DIDTYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "RULES_HIST_RECENT_STATE_CHK" CHECK (state IN ('I', 'O', 'S', 'R', 'U', 'W')),
        CHECK (locked IN (0, 1)),
        CONSTRAINT "RULES_HIST_RECENT_GROUPING_CHK" CHECK (grouping IN ('A', 'D', 'N')),
        CONSTRAINT "RULES_HIST_RECENT_NOTIFY_CHK" CHECK (notification IN ('Y', 'P', 'C', 'N')),
        CHECK (purge_replicas IN (0, 1)),
        CHECK (ignore_availability IN (0, 1)),
        CHECK (ignore_account_limit IN (0, 1)),
        CHECK (split_container IN (0, 1))
) PCTFREE 0;

CREATE INDEX "RULES_HIST_RECENT_ID_IDX" ON rules_hist_recent (id);

CREATE INDEX "RULES_HIST_RECENT_SC_NA_IDX" ON rules_hist_recent (scope, name);


CREATE TABLE did_keys (
        key VARCHAR2(255 CHAR) NOT NULL,
        is_enum NUMBER(1) DEFAULT '0',
        key_type VARCHAR(10 CHAR),
        value_type VARCHAR2(255 CHAR),
        value_regexp VARCHAR2(255 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DID_KEYS_PK" PRIMARY KEY (key),
        CONSTRAINT "DID_KEYS_TYPE_NN" CHECK (key_type IS NOT NULL),
        CONSTRAINT "DID_KEYS_IS_ENUM_NN" CHECK (is_enum IS NOT NULL),
        CONSTRAINT "DID_KEYS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DID_KEYS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "DID_KEYS_IS_ENUM_CHK" CHECK (is_enum IN (0, 1)),
        CONSTRAINT "DID_KEYS_TYPE_CHK" CHECK (key_type IN ('ALL', 'CONTAINER', 'DERIVED', 'COLLECTION', 'DATASET', 'FILE'))
) PCTFREE 0;


CREATE TABLE sources_history (
        request_id RAW(16) NOT NULL,
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        rse_id RAW(16) NOT NULL,
        dest_rse_id RAW(16),
        url VARCHAR2(2048 CHAR),
        bytes NUMBER(19),
        ranking INTEGER,
        is_using NUMBER(1),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "SOURCES_HISTORY_PK" PRIMARY KEY (request_id, scope, name, rse_id, updated_at),
        CHECK (is_using IN (0, 1))
) PCTFREE 0;


CREATE TABLE rse_usage_history (
        rse_id RAW(16) NOT NULL,
        source VARCHAR2(255 CHAR) NOT NULL,
        used NUMBER(19),
        free NUMBER(19),
        files NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "RSE_USAGE_HISTORY_PK" PRIMARY KEY (rse_id, source, updated_at)
) PCTFREE 0;


CREATE TABLE contents_history (
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        child_scope VARCHAR2(25 CHAR),
        child_name VARCHAR2(500 CHAR),
        did_type VARCHAR(1 CHAR),
        child_type VARCHAR(1 CHAR),
        bytes NUMBER(19),
        adler32 VARCHAR2(8 CHAR),
        md5 VARCHAR2(32 CHAR),
        guid RAW(16),
        events NUMBER(19),
        rule_evaluation NUMBER(1),
        did_created_at DATE,
        deleted_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "CONTENTS_HIST_DID_TYPE_NN" CHECK (DID_TYPE IS NOT NULL),
        CONSTRAINT "CONTENTS_HIST_CHILD_TYPE_NN" CHECK (CHILD_TYPE IS NOT NULL),
        CONSTRAINT "CONTENTS_HISTORY_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "CONTENTS_HISTORY_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "CONTENTS_HIST_DID_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "CONTENTS_HIST_CHILD_TYPE_CHK" CHECK (child_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "CONTENTS_HIST_RULE_EVAL_CHK" CHECK (rule_evaluation IN (0, 1))
) PCTFREE 0;

CREATE INDEX "CONTENTS_HISTORY_IDX" ON contents_history (scope, name);


CREATE TABLE heartbeats (
        executable VARCHAR2(64 CHAR) NOT NULL,
        readable VARCHAR2(4000 CHAR),
        hostname VARCHAR2(128 CHAR) NOT NULL,
        pid INTEGER NOT NULL,
        thread_id NUMBER(19) NOT NULL,
        thread_name VARCHAR2(64 CHAR),
        payload VARCHAR2(3000 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "HEARTBEATS_PK" PRIMARY KEY (executable, hostname, pid, thread_id),
        CONSTRAINT "HEARTBEATS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "HEARTBEATS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE archive_contents_history (
        child_scope VARCHAR2(25 CHAR),
        child_name VARCHAR2(500 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        bytes NUMBER(19),
        adler32 VARCHAR2(8 CHAR),
        md5 VARCHAR2(32 CHAR),
        guid RAW(16),
        length NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ARCH_CNTS_HIST_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ARCH_CNTS_HIST_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "ARCH_CONT_HIST_IDX" ON archive_contents_history (scope, name);


CREATE TABLE lifetime_except (
        id RAW(16) NOT NULL,
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        did_type VARCHAR(1 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR) NOT NULL,
        pattern VARCHAR2(255 CHAR),
        comments VARCHAR2(4000 CHAR),
        state VARCHAR(1 CHAR),
        expires_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "LIFETIME_EXCEPT_PK" PRIMARY KEY (id, scope, name, did_type, account),
        CONSTRAINT "LIFETIME_EXCEPT_SCOPE_NN" CHECK (SCOPE IS NOT NULL),
        CONSTRAINT "LIFETIME_EXCEPT_NAME_NN" CHECK (NAME IS NOT NULL),
        CONSTRAINT "LIFETIME_EXCEPT_DID_TYPE_NN" CHECK (DID_TYPE IS NOT NULL),
        CONSTRAINT "LIFETIME_EXCEPT_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "LIFETIME_EXCEPT_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "LIFETIME_EXCEPT_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "LIFETIME_EXCEPT_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "LIFETIME_EXCEPT_STATE_CHK" CHECK (state IN ('A', 'R', 'W'))
) PCTFREE 0;


CREATE TABLE account_attr_map (
        account VARCHAR2(25 CHAR) NOT NULL,
        key VARCHAR2(255 CHAR) NOT NULL,
        value VARCHAR2(255 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ACCOUNT_ATTR_MAP_PK" PRIMARY KEY (account, key),
        CONSTRAINT "ACCOUNT_ATTR_MAP_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "ACCOUNT_ATTR_MAP_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNT_ATTR_MAP_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "ACCOUNT_ATTR_MAP_KEY_VALUE_IDX" ON account_attr_map (key, value);


CREATE TABLE rses (
        id RAW(16) NOT NULL,
        rse VARCHAR2(255 CHAR),
        vo VARCHAR2(3 CHAR) DEFAULT 'def' NOT NULL,
        rse_type VARCHAR(4 CHAR),
        deterministic NUMBER(1),
        volatile NUMBER(1),
        staging_area NUMBER(1),
        city VARCHAR2(255 CHAR),
        region_code VARCHAR2(2 CHAR),
        country_name VARCHAR2(255 CHAR),
        continent VARCHAR2(2 CHAR),
        time_zone VARCHAR2(255 CHAR),
        "ISP" VARCHAR2(255 CHAR),
        "ASN" VARCHAR2(255 CHAR),
        longitude FLOAT,
        latitude FLOAT,
        availability INTEGER DEFAULT '7',
        updated_at DATE,
        created_at DATE,
        deleted NUMBER(1),
        deleted_at DATE,
        CONSTRAINT "RSES_PK" PRIMARY KEY (id),
        CONSTRAINT "RSES_RSE_UQ" UNIQUE (rse, vo),
        CONSTRAINT "RSES_RSE__NN" CHECK (RSE IS NOT NULL),
        CONSTRAINT "RSES_TYPE_NN" CHECK (RSE_TYPE IS NOT NULL),
        CONSTRAINT "RSES_VOS_FK" FOREIGN KEY(vo) REFERENCES vos (vo),
        CONSTRAINT "RSES_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "RSES_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "RSES_DELETED_NN" CHECK (DELETED IS NOT NULL),
        CONSTRAINT "RSES_TYPE_CHK" CHECK (rse_type IN ('DISK', 'TAPE')),
        CONSTRAINT "RSE_DETERMINISTIC_CHK" CHECK (deterministic IN (0, 1)),
        CONSTRAINT "RSE_VOLATILE_CHK" CHECK (volatile IN (0, 1)),
        CONSTRAINT "RSE_STAGING_AREA_CHK" CHECK (staging_area IN (0, 1)),
        CHECK (deleted IN (0, 1))
) PCTFREE 0;


CREATE TABLE subscriptions (
        id RAW(16) NOT NULL,
        name VARCHAR2(64 CHAR),
        filter VARCHAR2(2048 CHAR),
        replication_rules VARCHAR2(1024 CHAR),
        policyid SMALLINT DEFAULT '0',
        state VARCHAR(1 CHAR),
        last_processed DATE,
        account VARCHAR2(25 CHAR),
        lifetime DATE,
        comments VARCHAR2(4000 CHAR),
        retroactive NUMBER(1),
        expired_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "SUBSCRIPTIONS_PK" PRIMARY KEY (id),
        CONSTRAINT "SUBSCRIPTIONS_NAME_ACCOUNT_UQ" UNIQUE (name, account),
        CONSTRAINT "SUBSCRIPTIONS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "SUBSCRIPTIONS_RETROACTIVE_NN" CHECK (RETROACTIVE IS NOT NULL),
        CONSTRAINT "SUBSCRIPTIONS_ACCOUNT_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "SUBSCRIPTIONS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "SUBSCRIPTIONS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "SUBSCRIPTIONS_STATE_CHK" CHECK (state IN ('I', 'A', 'B', 'U', 'N')),
        CONSTRAINT "SUBSCRIPTIONS_RETROACTIVE_CHK" CHECK (retroactive IN (0, 1))
) PCTFREE 0;


CREATE TABLE dids_followed_events (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR) NOT NULL,
        did_type VARCHAR(1 CHAR),
        event_type VARCHAR2(1024 CHAR),
        payload CLOB,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_PK" PRIMARY KEY (scope, name, account),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_SCOPE_NN" CHECK (SCOPE IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_NAME_NN" CHECK (NAME IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_ACC_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_TYPE_NN" CHECK (DID_TYPE IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_ACC_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_CRE_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_UPD_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_EVENTS_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z'))
) PCTFREE 0;

CREATE INDEX "DIDS_FOLLOWED_EVENTS_ACC_IDX" ON dids_followed_events (account);


CREATE TABLE scopes (
        scope VARCHAR2(25 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR),
        is_default NUMBER(1),
        status VARCHAR(1 CHAR),
        closed_at DATE,
        deleted_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "SCOPES_PK" PRIMARY KEY (scope),
        CONSTRAINT "SCOPES_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "SCOPES_IS_DEFAULT_NN" CHECK (is_default IS NOT NULL),
        CONSTRAINT "SCOPES_STATUS_NN" CHECK (STATUS IS NOT NULL),
        CONSTRAINT "SCOPES_ACCOUNT_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "SCOPES_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "SCOPES_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "SCOPES_DEFAULT_CHK" CHECK (is_default IN (0, 1)),
        CONSTRAINT "SCOPE_STATUS_CHK" CHECK (status IN ('C', 'D', 'O'))
) PCTFREE 0;


CREATE TABLE tokens (
        token VARCHAR2(3072 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR),
        refresh_token VARCHAR2(315 CHAR),
        refresh NUMBER(1),
        refresh_start DATE,
        refresh_expired_at DATE,
        refresh_lifetime INTEGER,
        oidc_scope VARCHAR2(2048 CHAR),
        identity VARCHAR2(2048 CHAR),
        audience VARCHAR2(315 CHAR),
        expired_at DATE,
        ip VARCHAR2(39 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "TOKENS_PK" PRIMARY KEY (token),
        CONSTRAINT "TOKENS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "TOKENS_EXPIRED_AT_NN" CHECK (EXPIRED_AT IS NOT NULL),
        CONSTRAINT "TOKENS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "TOKENS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "TOKENS_REFRESH_CHK" CHECK (refresh IN (0, 1))
) PCTFREE 0;

CREATE INDEX "TOKENS_ACCOUNT_EXPIRED_AT_IDX" ON tokens (account, expired_at);


CREATE TABLE bad_pfns (
        path VARCHAR2(2048 CHAR) NOT NULL,
        state VARCHAR(1 CHAR) NOT NULL,
        reason VARCHAR2(255 CHAR),
        account VARCHAR2(25 CHAR),
        expires_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "BAD_PFNS_PK" PRIMARY KEY (path, state),
        CONSTRAINT "BAD_PFNS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "BAD_PFNS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "BAD_PFNS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "BAD_PFNS_STATE_CHK" CHECK (state IN ('A', 'S', 'B', 'T'))
) PCTFREE 0;


CREATE TABLE bad_replicas (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        rse_id RAW(16) NOT NULL,
        reason VARCHAR2(255 CHAR),
        state VARCHAR(1 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR),
        bytes NUMBER(19),
        expires_at DATE,
        updated_at DATE,
        created_at DATE NOT NULL,
        CONSTRAINT "BAD_REPLICAS_PK" PRIMARY KEY (scope, name, rse_id, state, created_at),
        CONSTRAINT "BAD_REPLICAS_SCOPE_NN" CHECK (SCOPE IS NOT NULL),
        CONSTRAINT "BAD_REPLICAS_NAME_NN" CHECK (NAME IS NOT NULL),
        CONSTRAINT "BAD_REPLICAS_RSE_ID_NN" CHECK (RSE_ID IS NOT NULL),
        CONSTRAINT "BAD_REPLICAS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "BAD_REPLICAS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "BAD_REPLICAS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "BAD_REPLICAS_STATE_CHK" CHECK (state IN ('B', 'D', 'L', 'S', 'R', 'T'))
) PCTFREE 0;

CREATE INDEX "BAD_REPLICAS_STATE_IDX" ON bad_replicas (rse_id, state);

CREATE INDEX "BAD_REPLICAS_EXPIRES_AT_IDX" ON bad_replicas (expires_at);


CREATE TABLE did_key_map (
        key VARCHAR2(255 CHAR) NOT NULL,
        value VARCHAR2(255 CHAR) NOT NULL,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DID_KEY_MAP_PK" PRIMARY KEY (key, value),
        CONSTRAINT "DID_MAP_KEYS_FK" FOREIGN KEY(key) REFERENCES did_keys (key),
        CONSTRAINT "DID_KEY_MAP_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DID_KEY_MAP_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE account_map (
        identity VARCHAR2(2048 CHAR) NOT NULL,
        identity_type VARCHAR(8 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR) NOT NULL,
        is_default NUMBER(1),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ACCOUNT_MAP_PK" PRIMARY KEY (identity, identity_type, account),
        CONSTRAINT "ACCOUNT_MAP_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "ACCOUNT_MAP_ID_TYPE_FK" FOREIGN KEY(identity, identity_type) REFERENCES identities (identity, identity_type),
        CONSTRAINT "ACCOUNT_MAP_IS_DEFAULT_NN" CHECK (is_default IS NOT NULL),
        CONSTRAINT "ACCOUNT_MAP_ID_TYPE_NN" CHECK (IDENTITY_TYPE IS NOT NULL),
        CONSTRAINT "ACCOUNT_MAP_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNT_MAP_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNT_MAP_ID_TYPE_CHK" CHECK (identity_type IN ('GSS', 'SAML', 'X509', 'SSH', 'USERPASS', 'OIDC')),
        CONSTRAINT "ACCOUNT_MAP_DEFAULT_CHK" CHECK (is_default IN (0, 1))
) PCTFREE 0;


CREATE TABLE account_glob_limits (
        account VARCHAR2(25 CHAR) NOT NULL,
        rse_expression VARCHAR2(3000 CHAR) NOT NULL,
        bytes NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ACCOUNT_GLOB_LIMITS_PK" PRIMARY KEY (account, rse_expression),
        CONSTRAINT "ACCOUNT_GLOBAL_LIMITS_ACC_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "ACCOUNT_GLOB_LIMITS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNT_GLOB_LIMITS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE distances (
        src_rse_id RAW(16) NOT NULL,
        dest_rse_id RAW(16) NOT NULL,
        ranking INTEGER,
        agis_distance INTEGER,
        geoip_distance INTEGER,
        active INTEGER,
        submitted INTEGER,
        finished INTEGER,
        failed INTEGER,
        transfer_speed INTEGER,
        packet_loss INTEGER,
        latency INTEGER,
        mbps_file INTEGER,
        mbps_link INTEGER,
        queued_total INTEGER,
        done_1h INTEGER,
        done_6h INTEGER,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DISTANCES_PK" PRIMARY KEY (src_rse_id, dest_rse_id),
        CONSTRAINT "DISTANCES_SRC_RSES_FK" FOREIGN KEY(src_rse_id) REFERENCES rses (id),
        CONSTRAINT "DISTANCES_DEST_RSES_FK" FOREIGN KEY(dest_rse_id) REFERENCES rses (id),
        CONSTRAINT "DISTANCES_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DISTANCES_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "DISTANCES_DEST_RSEID_IDX" ON distances (dest_rse_id);


CREATE TABLE updated_account_counters (
        id RAW(16) NOT NULL,
        account VARCHAR2(25 CHAR),
        rse_id RAW(16),
        files NUMBER(19),
        bytes NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "UPDATED_ACCOUNT_COUNTERS_PK" PRIMARY KEY (id),
        CONSTRAINT "UPDATED_ACCNT_CNTRS_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "UPDATED_ACCNT_CNTRS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "UPDATED_ACCNT_CNTRS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "UPDATED_ACCNT_CNTRS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "UPDATED_ACCNT_CNTRS_RSE_ID_IDX" ON updated_account_counters (account, rse_id);


CREATE TABLE rse_usage (
	rse_id RAW(16) NOT NULL, 
	source VARCHAR2(255 CHAR) NOT NULL, 
	used NUMBER(19), 
	free NUMBER(19), 
	files NUMBER(19), 
	updated_at DATE, 
	created_at DATE, 
	CONSTRAINT "RSE_USAGE_PK" PRIMARY KEY (rse_id, source), 
	CONSTRAINT "RSE_USAGE_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id), 
	CONSTRAINT "RSE_USAGE_CREATED_NN" CHECK (CREATED_AT IS NOT NULL), 
	CONSTRAINT "RSE_USAGE_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE rse_attr_map (
	rse_id RAW(16) NOT NULL, 
	key VARCHAR2(255 CHAR) NOT NULL, 
	value VARCHAR2(255 CHAR), 
	updated_at DATE, 
	created_at DATE, 
	CONSTRAINT "RSE_ATTR_MAP_PK" PRIMARY KEY (rse_id, key), 
	CONSTRAINT "RSE_ATTR_MAP_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id), 
	CONSTRAINT "RSE_ATTR_MAP_CREATED_NN" CHECK (CREATED_AT IS NOT NULL), 
	CONSTRAINT "RSE_ATTR_MAP_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "RSE_ATTR_MAP_KEY_VALUE_IDX" ON rse_attr_map (key, value);


CREATE TABLE replicas_history (
        rse_id RAW(16) NOT NULL,
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        bytes NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "REPLICAS_HISTORY_PK" PRIMARY KEY (rse_id, scope, name),
        CONSTRAINT "REPLICAS_HIST_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "REPLICAS_HIST_SIZE_NN" CHECK (bytes IS NOT NULL),
        CONSTRAINT "REPLICAS_HISTORY_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "REPLICAS_HISTORY_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE naming_conventions (
        scope VARCHAR2(25 CHAR) NOT NULL,
        regexp VARCHAR2(255 CHAR),
        convention_type VARCHAR(10 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "NAMING_CONVENTIONS_PK" PRIMARY KEY (scope),
        CONSTRAINT "NAMING_CONVENTIONS_SCOPE_FK" FOREIGN KEY(scope) REFERENCES scopes (scope),
        CONSTRAINT "NAMING_CONVENTIONS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "NAMING_CONVENTIONS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "CVT_TYPE_CHK" CHECK (convention_type IN ('ALL', 'CONTAINER', 'DERIVED', 'COLLECTION', 'DATASET', 'FILE'))
) PCTFREE 0;


CREATE TABLE updated_rse_counters (
        id RAW(16) NOT NULL,
        rse_id RAW(16),
        files NUMBER(19),
        bytes NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "UPDATED_RSE_COUNTERS_PK" PRIMARY KEY (id),
        CONSTRAINT "UPDATED_RSE_CNTRS_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "UPDATED_RSE_CNTRS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "UPDATED_RSE_CNTRS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "UPDATED_RSE_CNTRS_RSE_ID_IDX" ON updated_rse_counters (rse_id);


CREATE TABLE rse_transfer_limits (
        rse_id RAW(16) NOT NULL,
        activity VARCHAR2(50 CHAR) NOT NULL,
        rse_expression VARCHAR2(3000 CHAR),
        max_transfers NUMBER(19),
        volume NUMBER(19),
        deadline NUMBER(19),
        strategy VARCHAR2(25 CHAR),
        direction VARCHAR2(25 CHAR),
        transfers NUMBER(19),
        waitings NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "RSE_TRANSFER_LIMITS_PK" PRIMARY KEY (rse_id, activity),
        CONSTRAINT "RSE_TRANSFER_LIMITS_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "RSE_TRANSFER_LIMITS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "RSE_TRANSFER_LIMITS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE account_usage (
        account VARCHAR2(25 CHAR) NOT NULL,
        rse_id RAW(16) NOT NULL,
        files NUMBER(19),
        bytes NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ACCOUNT_USAGE_PK" PRIMARY KEY (account, rse_id),
        CONSTRAINT "ACCOUNT_USAGE_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "ACCOUNT_USAGE_RSES_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "ACCOUNT_USAGE_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNT_USAGE_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE quarantined_replicas (
        rse_id RAW(16) NOT NULL,
        path VARCHAR2(1024 CHAR) NOT NULL,
        bytes NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "QUARANTINED_REPLICAS_PK" PRIMARY KEY (rse_id, path),
        CONSTRAINT "QURD_REPLICAS_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "QURD_REPLICAS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "QURD_REPLICAS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE UNIQUE INDEX "QUARANTINED_REPLICAS_PATH_IDX" ON quarantined_replicas (path, rse_id);


CREATE TABLE account_limits (
        account VARCHAR2(25 CHAR) NOT NULL,
        rse_id RAW(16) NOT NULL,
        bytes NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ACCOUNT_LIMITS_PK" PRIMARY KEY (account, rse_id),
        CONSTRAINT "ACCOUNT_LIMITS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "ACCOUNT_LIMITS_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "ACCOUNT_LIMITS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ACCOUNT_LIMITS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE TABLE rse_protocols (
        rse_id RAW(16) NOT NULL,
        scheme VARCHAR2(255 CHAR) NOT NULL,
        hostname VARCHAR2(255 CHAR) DEFAULT '' NOT NULL,
        port INTEGER DEFAULT '0' NOT NULL,
        prefix VARCHAR2(1024 CHAR),
        impl VARCHAR2(255 CHAR) NOT NULL,
        read_lan INTEGER DEFAULT '0',
        write_lan INTEGER DEFAULT '0',
        delete_lan INTEGER DEFAULT '0',
        read_wan INTEGER DEFAULT '0',
        write_wan INTEGER DEFAULT '0',
        delete_wan INTEGER DEFAULT '0',
        third_party_copy INTEGER DEFAULT '0',
        third_party_copy_read INTEGER DEFAULT '0',
        third_party_copy_write INTEGER DEFAULT '0',
        extended_attributes VARCHAR2(4000 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "RSE_PROTOCOLS_PK" PRIMARY KEY (rse_id, scheme, hostname, port),
        CONSTRAINT "RSE_PROTOCOL_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "RSE_PROTOCOLS_IMPL_NN" CHECK (IMPL IS NOT NULL),
        CONSTRAINT "RSE_PROTOCOLS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "RSE_PROTOCOLS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE rse_limits (
        rse_id RAW(16) NOT NULL,
        name VARCHAR2(255 CHAR) NOT NULL,
        value NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "RSE_LIMITS_PK" PRIMARY KEY (rse_id, name),
        CONSTRAINT "RSE_LIMIT_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "RSE_LIMITS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "RSE_LIMITS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE dids (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR),
        did_type VARCHAR(1 CHAR),
        is_open NUMBER(1),
        monotonic NUMBER(1) DEFAULT '0',
        hidden NUMBER(1) DEFAULT '0',
        obsolete NUMBER(1) DEFAULT '0',
        complete NUMBER(1),
        is_new NUMBER(1) DEFAULT '1',
        availability VARCHAR(1 CHAR),
        suppressed NUMBER(1) DEFAULT '0',
        bytes NUMBER(19),
        length NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        expired_at DATE,
        purge_replicas NUMBER(1) DEFAULT '1',
        deleted_at DATE,
        events NUMBER(19),
        guid RAW(16),
        project VARCHAR2(50 CHAR),
        datatype VARCHAR2(50 CHAR),
        run_number INTEGER,
        stream_name VARCHAR2(70 CHAR),
        prod_step VARCHAR2(50 CHAR),
        version VARCHAR2(50 CHAR),
        campaign VARCHAR2(50 CHAR),
        task_id INTEGER,
        panda_id INTEGER,
        lumiblocknr INTEGER,
        provenance VARCHAR2(2 CHAR),
        phys_group VARCHAR2(25 CHAR),
        transient NUMBER(1) DEFAULT '0',
        accessed_at DATE,
        closed_at DATE,
        eol_at DATE,
        is_archive NUMBER(1),
        constituent NUMBER(1),
        access_cnt INTEGER,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DIDS_PK" PRIMARY KEY (scope, name),
        CONSTRAINT "DIDS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account) ON DELETE CASCADE,
        CONSTRAINT "DIDS_SCOPE_FK" FOREIGN KEY(scope) REFERENCES scopes (scope),
        CONSTRAINT "DIDS_MONOTONIC_NN" CHECK (MONOTONIC IS NOT NULL),
        CONSTRAINT "DIDS_OBSOLETE_NN" CHECK (OBSOLETE IS NOT NULL),
        CONSTRAINT "DIDS_SUPP_NN" CHECK (SUPPRESSED IS NOT NULL),
        CONSTRAINT "DIDS_ACCOUNT_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "DIDS_PURGE_REPLICAS_NN" CHECK (PURGE_REPLICAS IS NOT NULL),
        CONSTRAINT "DIDS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DIDS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "DIDS_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "DIDS_IS_OPEN_CHK" CHECK (is_open IN (0, 1)),
        CONSTRAINT "DIDS_MONOTONIC_CHK" CHECK (monotonic IN (0, 1)),
        CONSTRAINT "DIDS_HIDDEN_CHK" CHECK (hidden IN (0, 1)),
        CONSTRAINT "DIDS_OBSOLETE_CHK" CHECK (obsolete IN (0, 1)),
        CONSTRAINT "DIDS_COMPLETE_CHK" CHECK (complete IN (0, 1)),
        CONSTRAINT "DIDS_IS_NEW_CHK" CHECK (is_new IN (0, 1)),
        CONSTRAINT "DIDS_AVAILABILITY_CHK" CHECK (availability IN ('A', 'D', 'L')),
        CONSTRAINT "FILES_SUPP_CHK" CHECK (suppressed IN (0, 1)),
        CONSTRAINT "DIDS_PURGE_RPLCS_CHK" CHECK (purge_replicas IN (0, 1)),
        CONSTRAINT "DID_TRANSIENT_CHK" CHECK (transient IN (0, 1)),
        CONSTRAINT "DIDS_ARCHIVE_CHK" CHECK (is_archive IN (0, 1)),
        CONSTRAINT "DIDS_CONSTITUENT_CHK" CHECK (constituent IN (0, 1))
) PCTFREE 0;

CREATE INDEX "DIDS_EXPIRED_AT_IDX" ON dids (expired_at);

CREATE INDEX "DIDS_IS_NEW_IDX" ON dids (is_new);



CREATE TABLE contents (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        child_scope VARCHAR2(25 CHAR) NOT NULL,
        child_name VARCHAR2(500 CHAR) NOT NULL,
        did_type VARCHAR(1 CHAR),
        child_type VARCHAR(1 CHAR),
        bytes NUMBER(19),
        adler32 VARCHAR2(8 CHAR),
        md5 VARCHAR2(32 CHAR),
        guid RAW(16),
        events NUMBER(19),
        rule_evaluation NUMBER(1),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "CONTENTS_PK" PRIMARY KEY (scope, name, child_scope, child_name),
        CONSTRAINT "CONTENTS_ID_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "CONTENTS_CHILD_ID_FK" FOREIGN KEY(child_scope, child_name) REFERENCES dids (scope, name) ON DELETE CASCADE,
        CONSTRAINT "CONTENTS_DID_TYPE_NN" CHECK (DID_TYPE IS NOT NULL),
        CONSTRAINT "CONTENTS_CHILD_TYPE_NN" CHECK (CHILD_TYPE IS NOT NULL),
        CONSTRAINT "CONTENTS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "CONTENTS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "CONTENTS_DID_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "CONTENTS_CHILD_TYPE_CHK" CHECK (child_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "CONTENTS_RULE_EVALUATION_CHK" CHECK (rule_evaluation IN (0, 1))
) PCTFREE 0;

CREATE INDEX "CONTENTS_CHILD_SCOPE_NAME_IDX" ON contents (child_scope, child_name, scope, name);


CREATE TABLE archive_contents (
        child_scope VARCHAR2(25 CHAR) NOT NULL,
        child_name VARCHAR2(500 CHAR) NOT NULL,
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        bytes NUMBER(19),
        adler32 VARCHAR2(8 CHAR),
        md5 VARCHAR2(32 CHAR),
        guid RAW(16),
        length NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "ARCHIVE_CONTENTS_PK" PRIMARY KEY (child_scope, child_name, scope, name),
        CONSTRAINT "ARCH_CONTENTS_PARENT_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "ARCH_CONTENTS_CHILD_FK" FOREIGN KEY(child_scope, child_name) REFERENCES dids (scope, name) ON DELETE CASCADE,
        CONSTRAINT "ARCHIVE_CONTENTS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "ARCHIVE_CONTENTS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;

CREATE INDEX "ARCH_CONTENTS_CHILD_IDX" ON archive_contents (scope, name, child_scope, child_name);



CREATE TABLE dids_followed (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        account VARCHAR2(25 CHAR) NOT NULL,
        did_type VARCHAR(1 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DIDS_FOLLOWED_PK" PRIMARY KEY (scope, name, account),
        CONSTRAINT "DIDS_FOLLOWED_SCOPE_NN" CHECK (SCOPE IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_NAME_NN" CHECK (NAME IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_ACCOUNT_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_DID_TYPE_NN" CHECK (DID_TYPE IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "DIDS_FOLLOWED_SCOPE_NAME_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "DIDS_FOLLOWED_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "DIDS_FOLLOWED_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z'))
) PCTFREE 0;


CREATE TABLE collection_replicas (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        did_type VARCHAR(1 CHAR),
        rse_id RAW(16) NOT NULL,
        bytes NUMBER(19),
        length NUMBER(19),
        available_bytes NUMBER(19),
        available_replicas_cnt NUMBER(19),
        state VARCHAR(1 CHAR),
        accessed_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "COLLECTION_REPLICAS_PK" PRIMARY KEY (scope, name, rse_id),
        CONSTRAINT "COLLECTION_REPLICAS_LFN_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "COLLECTION_REPLICAS_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "COLLECTION_REPLICAS_STATE_NN" CHECK (STATE IS NOT NULL),
        CONSTRAINT "COLLECTION_REPLICAS_SIZE_NN" CHECK (bytes IS NOT NULL),
        CONSTRAINT "COLLECTION_REPLICAS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "COLLECTION_REPLICAS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "COLLECTION_REPLICAS_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "COLLECTION_REPLICAS_STATE_CHK" CHECK (state IN ('A', 'C', 'B', 'D', 'U', 'T'))
) PCTFREE 0;

CREATE INDEX "COLLECTION_REPLICAS_RSE_ID_IDX" ON collection_replicas (rse_id);


CREATE TABLE replicas (
        rse_id RAW(16) NOT NULL,
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        bytes NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        path VARCHAR2(1024 CHAR),
        state VARCHAR(1 CHAR),
        lock_cnt INTEGER DEFAULT '0',
        accessed_at DATE,
        tombstone DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "REPLICAS_PK" PRIMARY KEY (scope, name, rse_id),
        CONSTRAINT "REPLICAS_LFN_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "REPLICAS_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "REPLICAS_STATE_NN" CHECK (STATE IS NOT NULL),
        CONSTRAINT "REPLICAS_SIZE_NN" CHECK (bytes IS NOT NULL),
        CONSTRAINT "REPLICAS_LOCK_CNT_NN" CHECK (lock_cnt IS NOT NULL),
        CONSTRAINT "REPLICAS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "REPLICAS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "REPLICAS_STATE_CHK" CHECK (state IN ('A', 'C', 'B', 'D', 'U', 'T'))
) PCTFREE 0;

CREATE INDEX "REPLICAS_TOMBSTONE_IDX" ON replicas (tombstone);

CREATE INDEX "REPLICAS_PATH_IDX" ON replicas (path);


CREATE TABLE rules (
        id RAW(16) NOT NULL,
        subscription_id RAW(16),
        account VARCHAR2(25 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        did_type VARCHAR(1 CHAR),
        state VARCHAR(1 CHAR),
        error VARCHAR2(255 CHAR),
        rse_expression VARCHAR2(3000 CHAR),
        copies SMALLINT DEFAULT '1',
        expires_at DATE,
        weight VARCHAR2(255 CHAR),
        locked NUMBER(1),
        locks_ok_cnt NUMBER(19) DEFAULT '0',
        locks_replicating_cnt NUMBER(19) DEFAULT '0',
        locks_stuck_cnt NUMBER(19) DEFAULT '0',
        source_replica_expression VARCHAR2(255 CHAR),
        activity VARCHAR2(50 CHAR),
        grouping VARCHAR(1 CHAR),
        notification VARCHAR(1 CHAR),
        stuck_at DATE,
        purge_replicas NUMBER(1),
        ignore_availability NUMBER(1),
        ignore_account_limit NUMBER(1),
        priority INTEGER,
        comments VARCHAR2(255 CHAR),
        child_rule_id RAW(16),
        eol_at DATE,
        split_container NUMBER(1),
        meta VARCHAR2(4000 CHAR),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "RULES_PK" PRIMARY KEY (id),
        CONSTRAINT "RULES_SCOPE_NAME_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "RULES_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "RULES_SUBS_ID_FK" FOREIGN KEY(subscription_id) REFERENCES subscriptions (id),
        CONSTRAINT "RULES_CHILD_RULE_ID_FK" FOREIGN KEY(child_rule_id) REFERENCES rules (id),
        CONSTRAINT "RULES_STATE_NN" CHECK (STATE IS NOT NULL),
        CONSTRAINT "RULES_SCOPE_NN" CHECK (SCOPE IS NOT NULL),
        CONSTRAINT "RULES_NAME_NN" CHECK (NAME IS NOT NULL),
        CONSTRAINT "RULES_GROUPING_NN" CHECK (grouping IS NOT NULL),
        CONSTRAINT "RULES_COPIES_NN" CHECK (COPIES IS NOT NULL),
        CONSTRAINT "RULES_LOCKED_NN" CHECK (LOCKED IS NOT NULL),
        CONSTRAINT "RULES_ACCOUNT_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "RULES_LOCKS_OK_CNT_NN" CHECK (LOCKS_OK_CNT IS NOT NULL),
        CONSTRAINT "RULES_LOCKS_REPLICATING_CNT_NN" CHECK (LOCKS_REPLICATING_CNT IS NOT NULL),
        CONSTRAINT "RULES_LOCKS_STUCK_CNT_NN" CHECK (LOCKS_STUCK_CNT IS NOT NULL),
        CONSTRAINT "RULES_PURGE_REPLICAS_NN" CHECK (PURGE_REPLICAS IS NOT NULL),
        CONSTRAINT "RULES_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "RULES_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "RULES_DID_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "RULES_STATE_CHK" CHECK (state IN ('I', 'O', 'S', 'R', 'U', 'W')),
        CONSTRAINT "RULES_LOCKED_CHK" CHECK (locked IN (0, 1)),
        CONSTRAINT "RULES_GROUPING_CHK" CHECK (grouping IN ('A', 'D', 'N')),
        CONSTRAINT "RULES_NOTIFICATION_CHK" CHECK (notification IN ('Y', 'P', 'C', 'N')),
        CONSTRAINT "RULES_PURGE_REPLICAS_CHK" CHECK (purge_replicas IN (0, 1)),
        CONSTRAINT "RULES_IGNORE_AVAILABILITY_CHK" CHECK (ignore_availability IN (0, 1)),
        CONSTRAINT "RULES_IGNORE_ACCOUNT_LIMIT_CHK" CHECK (ignore_account_limit IN (0, 1)),
        CONSTRAINT "RULES_SPLIT_CONTAINER_CHK" CHECK (split_container IN (0, 1))
) PCTFREE 0;
CREATE UNIQUE INDEX "RULES_SC_NA_AC_RS_CO_UQ_IDX" ON rules (scope, name, account, rse_expression, copies);

CREATE INDEX "RULES_CHILD_RULE_ID_IDX" ON rules (child_rule_id);

CREATE INDEX "RULES_SCOPE_NAME_IDX" ON rules (scope, name);

CREATE INDEX "RULES_STUCKSTATE_IDX" ON rules (state);

CREATE INDEX "RULES_EXPIRES_AT_IDX" ON rules (expires_at);

CREATE TABLE requests (
        id RAW(16) NOT NULL,
        request_type VARCHAR(1 CHAR),
        scope VARCHAR2(25 CHAR),
        name VARCHAR2(500 CHAR),
        did_type VARCHAR(1 CHAR),
        dest_rse_id RAW(16),
        source_rse_id RAW(16),
        attributes VARCHAR2(4000 CHAR),
        state VARCHAR(1 CHAR),
        external_id VARCHAR2(64 CHAR),
        external_host VARCHAR2(256 CHAR),
        retry_count INTEGER DEFAULT '0',
        err_msg VARCHAR2(4000 CHAR),
        previous_attempt_id RAW(16),
        rule_id RAW(16),
        activity VARCHAR2(50 CHAR),
        bytes NUMBER(19),
        md5 VARCHAR2(32 CHAR),
        adler32 VARCHAR2(8 CHAR),
        dest_url VARCHAR2(2048 CHAR),
        submitted_at DATE,
        started_at DATE,
        transferred_at DATE,
        estimated_at DATE,
        submitter_id INTEGER,
        estimated_started_at DATE,
        estimated_transferred_at DATE,
        staging_started_at DATE,
        staging_finished_at DATE,
        account VARCHAR2(25 CHAR),
        requested_at DATE,
        priority INTEGER,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "REQUESTS_PK" PRIMARY KEY (id),
        CONSTRAINT "REQUESTS_DID_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "REQUESTS_RSES_FK" FOREIGN KEY(dest_rse_id) REFERENCES rses (id),
        CONSTRAINT "REQUESTS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "REQUESTS_RSE_ID_NN" CHECK (dest_rse_id IS NOT NULL),
        CONSTRAINT "REQUESTS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "REQUESTS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "REQUESTS_TYPE_CHK" CHECK (request_type IN ('I', 'U', 'T', 'O', 'D')),
        CONSTRAINT "REQUESTS_DIDTYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z')),
        CONSTRAINT "REQUESTS_STATE_CHK" CHECK (state IN ('A', 'D', 'G', 'F', 'M', 'L', 'O', 'N', 'Q', 'S', 'U', 'W'))
) PCTFREE 0;

CREATE INDEX "REQUESTS_SCOPE_NAME_RSE_IDX" ON requests (scope, name, dest_rse_id, request_type);

CREATE INDEX "REQUESTS_RULEID_IDX" ON requests (rule_id);

CREATE INDEX "REQUESTS_EXTERNALID_UQ" ON requests (external_id);

CREATE INDEX "REQUESTS_TYP_STA_UPD_IDX" ON requests (request_type, state, activity);

CREATE INDEX "REQUESTS_TYP_STA_UPD_IDX_OLD" ON requests (request_type, state, updated_at);


CREATE TABLE did_meta (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        meta CLOB,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DID_META_PK" PRIMARY KEY (scope, name),
        CONSTRAINT "DID_META_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "DID_META_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DID_META_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL)
) PCTFREE 0;


CREATE TABLE dataset_locks (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        rule_id RAW(16) NOT NULL,
        rse_id RAW(16) NOT NULL,
        account VARCHAR2(25 CHAR),
        state VARCHAR(1 CHAR),
        length NUMBER(19),
        bytes NUMBER(19),
        accessed_at DATE,
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "DATASET_LOCKS_PK" PRIMARY KEY (scope, name, rule_id, rse_id),
        CONSTRAINT "DATASET_LOCKS_DID_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name),
        CONSTRAINT "DATASET_LOCKS_RULE_ID_FK" FOREIGN KEY(rule_id) REFERENCES rules (id),
        CONSTRAINT "DATASET_LOCKS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "DATASET_LOCKS_STATE_NN" CHECK (STATE IS NOT NULL),
        CONSTRAINT "DATASET_LOCKS_ACCOUNT_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "DATASET_LOCKS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "DATASET_LOCKS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "DATASET_LOCKS_STATE_CHK" CHECK (state IN ('S', 'R', 'O'))
) PCTFREE 0;

CREATE INDEX "DATASET_LOCKS_RULE_ID_IDX" ON dataset_locks (rule_id);

CREATE INDEX "DATASET_LOCKS_RSE_ID_IDX" ON dataset_locks (rse_id);


CREATE TABLE locks (
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        rule_id RAW(16) NOT NULL,
        rse_id RAW(16) NOT NULL,
        account VARCHAR2(25 CHAR),
        bytes NUMBER(19),
        state VARCHAR(1 CHAR),
        repair_cnt NUMBER(19),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "LOCKS_PK" PRIMARY KEY (scope, name, rule_id, rse_id),
        CONSTRAINT "LOCKS_RULE_ID_FK" FOREIGN KEY(rule_id) REFERENCES rules (id),
        CONSTRAINT "LOCKS_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account),
        CONSTRAINT "LOCKS_STATE_NN" CHECK (STATE IS NOT NULL),
        CONSTRAINT "LOCKS_ACCOUNT_NN" CHECK (ACCOUNT IS NOT NULL),
        CONSTRAINT "LOCKS_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "LOCKS_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CONSTRAINT "LOCKS_STATE_CHK" CHECK (state IN ('S', 'R', 'O'))
) PCTFREE 0;

CREATE INDEX "LOCKS_RULE_ID_IDX" ON locks (rule_id);


CREATE TABLE sources (
        request_id RAW(16) NOT NULL,
        scope VARCHAR2(25 CHAR) NOT NULL,
        name VARCHAR2(500 CHAR) NOT NULL,
        rse_id RAW(16) NOT NULL,
        dest_rse_id RAW(16),
        url VARCHAR2(2048 CHAR),
        bytes NUMBER(19),
        ranking INTEGER,
        is_using NUMBER(1),
        updated_at DATE,
        created_at DATE,
        CONSTRAINT "SOURCES_PK" PRIMARY KEY (request_id, rse_id, scope, name),
        CONSTRAINT "SOURCES_REQ_ID_FK" FOREIGN KEY(request_id) REFERENCES requests (id),
        CONSTRAINT "SOURCES_REPLICA_FK" FOREIGN KEY(scope, name, rse_id) REFERENCES replicas (scope, name, rse_id),
        CONSTRAINT "SOURCES_RSES_FK" FOREIGN KEY(rse_id) REFERENCES rses (id),
        CONSTRAINT "SOURCES_DEST_RSES_FK" FOREIGN KEY(dest_rse_id) REFERENCES rses (id),
        CONSTRAINT "SOURCES_CREATED_NN" CHECK (CREATED_AT IS NOT NULL),
        CONSTRAINT "SOURCES_UPDATED_NN" CHECK (UPDATED_AT IS NOT NULL),
        CHECK (is_using IN (0, 1))
) PCTFREE 0;

CREATE INDEX "SOURCES_DEST_RSEID_IDX" ON sources (dest_rse_id);

CREATE INDEX "SOURCES_SRC_DST_IDX" ON sources (rse_id, dest_rse_id);

CREATE INDEX "SOURCES_SC_NM_DST_IDX" ON sources (scope, rse_id, name);




