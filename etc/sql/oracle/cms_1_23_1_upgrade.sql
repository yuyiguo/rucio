-- Running upgrade a118956323f8 -> a193a275255c
  
ALTER TABLE "CMS_RUCIO_INT".messages ADD services VARCHAR2(2048 CHAR)

/

ALTER TABLE "CMS_RUCIO_INT".messages_history ADD services VARCHAR2(2048 CHAR)

/

UPDATE "CMS_RUCIO_INT".alembic_version SET version_num='a193a275255c' WHERE "CMS_RUCIO_INT".alembic_version.version_num = 'a118956323f8'

/

-- Running upgrade a193a275255c -> c0937668555f

CREATE TABLE rse_qos_map (
    rse_id RAW(16),
    qos_policy VARCHAR2(64 CHAR),
    created_at DATE,
    updated_at DATE
)

/

ALTER TABLE rse_qos_map ADD CONSTRAINT "RSE_QOS_MAP_PK" PRIMARY KEY (rse_id, qos_policy)

/

ALTER TABLE rse_qos_map ADD CONSTRAINT "RSE_QOS_MAP_CREATED_NN" CHECK (created_at is not null)

/

ALTER TABLE rse_qos_map ADD CONSTRAINT "RSE_QOS_MAP_UPDATED_NN" CHECK (updated_at is not null)

/

ALTER TABLE rse_qos_map ADD CONSTRAINT "RSE_QOS_MAP_RSE_ID_FK" FOREIGN KEY(rse_id) REFERENCES rses (id)

/

UPDATE "CMS_RUCIO_INT".alembic_version SET version_num='c0937668555f' WHERE "CMS_RUCIO_INT".alembic_version.version_num = 'a193a275255c'

/
-- Running upgrade c0937668555f -> 50280c53117c

ALTER TABLE "CMS_RUCIO_INT".rses ADD qos_class VARCHAR2(64 CHAR)

/

UPDATE "CMS_RUCIO_INT".alembic_version SET version_num='50280c53117c' WHERE "CMS_RUCIO_INT".alembic_version.version_num = 'c0937668555f'

/

