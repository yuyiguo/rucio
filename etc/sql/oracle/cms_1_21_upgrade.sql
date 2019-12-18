
---------- Beginning of the CMS upgrade



-- Running upgrade 2cbee484dcf9 -> 53b479c3cb0f

ALTER TABLE did_meta ADD created_at DATE;
ALTER TABLE did_meta ADD updated_at DATE;
UPDATE alembic_version SET version_num='53b479c3cb0f' WHERE alembic_version.version_num = '2cbee484dcf9';

-- Running upgrade 53b479c3cb0f -> 9a1b149a2044

ALTER TABLE identities DROP CONSTRAINT "IDENTITIES_TYPE_CHK";
ALTER TABLE identities ADD CONSTRAINT "IDENTITIES_TYPE_CHK" CHECK (identity_type in ('X509', 'GSS', 'USERPASS', 'SSH', 'SAML'));
ALTER TABLE account_map DROP CONSTRAINT "ACCOUNT_MAP_ID_TYPE_CHK";
ALTER TABLE account_map ADD CONSTRAINT "ACCOUNT_MAP_ID_TYPE_CHK" CHECK (identity_type in ('X509', 'GSS', 'USERPASS', 'SSH', 'SAML'));
UPDATE alembic_version SET version_num='9a1b149a2044' WHERE alembic_version.version_num = '53b479c3cb0f';

-- Running upgrade 9a1b149a2044 -> bc68e9946deb

ALTER TABLE requests ADD staging_started_at DATE;
ALTER TABLE requests ADD staging_finished_at DATE;
ALTER TABLE requests_history ADD staging_started_at DATE;
ALTER TABLE requests_history ADD staging_finished_at DATE;
UPDATE alembic_version SET version_num='bc68e9946deb' WHERE alembic_version.version_num = '9a1b149a2044';

-- Running upgrade bc68e9946deb -> 2b69addda658

ALTER TABLE rse_protocols ADD third_party_copy_write INTEGER;
ALTER TABLE rse_protocols ADD third_party_copy_read INTEGER;
UPDATE alembic_version SET version_num='2b69addda658' WHERE alembic_version.version_num = 'bc68e9946deb';

-- Running upgrade 2b69addda658 -> a74275a1ad30

CREATE TABLE account_glob_limits (
    rse_expression VARCHAR2(3000 CHAR), 
    bytes NUMBER(19), 
    account VARCHAR2(25 CHAR), 
    created_at DATE, 
    updated_at DATE
);

ALTER TABLE account_glob_limits ADD CONSTRAINT "ACCOUNT_GLOB_LIMITS_PK" PRIMARY KEY (account, rse_expression);
ALTER TABLE account_glob_limits ADD CONSTRAINT "ACCOUNT_GLOB_LIMITS_CREATED_NN" CHECK (created_at is not null);
ALTER TABLE account_glob_limits ADD CONSTRAINT "ACCOUNT_GLOB_LIMITS_UPDATED_NN" CHECK (updated_at is not null);
ALTER TABLE account_glob_limits ADD CONSTRAINT "ACCOUNT_GLOBAL_LIMITS_ACC_FK" FOREIGN KEY(account) REFERENCES accounts (account);
UPDATE alembic_version SET version_num='a74275a1ad30' WHERE alembic_version.version_num = '2b69addda658';

-- Running upgrade a74275a1ad30 -> 7541902bf173

CREATE TABLE dids_followed (
    scope VARCHAR2(25 CHAR), 
    name VARCHAR2(255 CHAR), 
    account VARCHAR2(25 CHAR), 
    did_type VARCHAR(1 CHAR), 
    updated_at DATE, 
    created_at DATE, 
    CONSTRAINT "DIDS_FOLLOWED_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z'))
);

ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_PK" PRIMARY KEY (scope, name, account);
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_SCOPE_NN" CHECK (scope is not null);
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_NAME_NN" CHECK (name is not null);
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_ACCOUNT_NN" CHECK (account is not null);
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_DID_TYPE_NN" CHECK (did_type is not null);
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_CREATED_NN" CHECK (created_at is not null);
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_UPDATED_NN" CHECK (updated_at is not null);
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_ACCOUNT_FK" FOREIGN KEY(account) REFERENCES accounts (account);

-- Problems here with lock. Increased timeout to 60 seconds:
alter session set ddl_lock_timeout = 60;
ALTER TABLE dids_followed ADD CONSTRAINT "DIDS_FOLLOWED_SCOPE_NAME_FK" FOREIGN KEY(scope, name) REFERENCES dids (scope, name);

CREATE TABLE dids_followed_events (
    scope VARCHAR2(25 CHAR), 
    name VARCHAR2(255 CHAR), 
    account VARCHAR2(25 CHAR), 
    did_type VARCHAR(1 CHAR), 
    event_type VARCHAR2(1024 CHAR), 
    payload CLOB, 
    updated_at DATE, 
    created_at DATE, 
    CONSTRAINT "DIDS_FOLLOWED_EVENTS_TYPE_CHK" CHECK (did_type IN ('A', 'C', 'D', 'F', 'Y', 'X', 'Z'))
);

ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_PK" PRIMARY KEY (scope, name, account);
ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_SCOPE_NN" CHECK (scope is not null);
ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_NAME_NN" CHECK (name is not null);
ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_ACC_NN" CHECK (account is not null);
ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_TYPE_NN" CHECK (did_type is not null);
ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_CRE_NN" CHECK (created_at is not null);
ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_UPD_NN" CHECK (updated_at is not null);
ALTER TABLE dids_followed_events ADD CONSTRAINT "DIDS_FOLLOWED_EVENTS_ACC_FK" FOREIGN KEY(account) REFERENCES accounts (account);
CREATE INDEX "DIDS_FOLLOWED_EVENTS_ACC_IDX" ON dids_followed_events (account);
UPDATE alembic_version SET version_num='7541902bf173' WHERE alembic_version.version_num = 'a74275a1ad30';

-- Running upgrade 7541902bf173 -> 810a41685bc1

ALTER TABLE rse_transfer_limits ADD deadline NUMBER(19);
ALTER TABLE rse_transfer_limits ADD strategy VARCHAR2(25 CHAR);
ALTER TABLE rse_transfer_limits ADD direction VARCHAR2(25 CHAR);
UPDATE alembic_version SET version_num='810a41685bc1' WHERE alembic_version.version_num = '7541902bf173';

