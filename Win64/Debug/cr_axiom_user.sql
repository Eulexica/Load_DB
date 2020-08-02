create role axiom_update_role;
DROP USER axiom CASCADE;
CREATE USER axiom
IDENTIFIED BY axiom
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
PROFILE DEFAULT
ACCOUNT UNLOCK;
GRANT axiom_UPDATE_ROLE TO axiom WITH ADMIN OPTION;
GRANT DBA TO axiom;
GRANT CTXAPP TO AXIOM;
ALTER USER AXIOM DEFAULT ROLE ALL;
GRANT RESOURCE TO axiom;
GRANT CONNECT TO axiom;
ALTER USER axiom DEFAULT ROLE DBA, RESOURCE, axiom_UPDATE_ROLE;
GRANT DROP USER TO axiom;
GRANT CREATE SYNONYM TO axiom;
GRANT ALTER USER TO axiom;
GRANT CREATE DATABASE LINK TO axiom;
GRANT CREATE SEQUENCE TO axiom;
GRANT CREATE PUBLIC SYNONYM TO axiom;
GRANT CREATE TRIGGER TO axiom;
GRANT CREATE PROCEDURE TO axiom;
GRANT CREATE ROLE TO axiom;
GRANT ANALYZE ANY TO axiom;
GRANT UNLIMITED TABLESPACE TO axiom;
GRANT CREATE TABLE TO axiom WITH ADMIN OPTION;
GRANT CREATE TYPE TO axiom;
GRANT CREATE USER TO axiom;
GRANT CREATE MATERIALIZED VIEW TO axiom WITH ADMIN OPTION;
GRANT CREATE VIEW TO axiom WITH ADMIN OPTION;
GRANT DROP ANY MATERIALIZED VIEW TO AXIOM WITH ADMIN OPTION;
GRANT DROP ANY VIEW TO AXIOM WITH ADMIN OPTION;
GRANT CREATE OPERATOR TO axiom;
GRANT CREATE JOB TO axiom;
GRANT CREATE ANY CONTEXT TO axiom;
GRANT CREATE INDEXTYPE TO axiom;
GRANT BECOME USER TO axiom;
GRANT SELECT ON SYS.V_$SESSION TO axiom;
GRANT SELECT ON SYS.v_$INSTANCE TO axiom;
GRANT EXECUTE ON SYS.DBMS_ALERT TO axiom_update_role;
GRANT EXECUTE ON SYS.DBMS_RLS TO axiom;
GRANT EXECUTE ON CTSSYS.CTX_DDL TO axiom;
GRANT EXECUTE ON CTXSYS.CTX_DOC TO axiom;
GRANT CREATE SESSION TO AXIOM WITH ADMIN OPTION;
GRANT SELECT ON SYS.V_$lock TO AXIOM_update_role;
GRANT SELECT ON SYS.V_$SESSION TO AXIOM_update_role;
GRANT SELECT ON SYS.V_$process TO AXIOM_update_role;
GRANT SELECT ON SYS.V_$rollname TO AXIOM_update_role;
GRANT SELECT ON SYS.dba_objects TO AXIOM_update_role;
grant execute on UTL_SMTP to axiom;
EXIT;