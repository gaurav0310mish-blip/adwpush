SET echo on
SET timing on

CREATE TABLE IF NOT EXISTS CICD_PIPELINE_TEST AS
SELECT systimestamp AS executed_at FROM dual;

SELECT COUNT(*) FROM CICD_PIPELINE_TEST;


SET SERVEROUTPUT ON;
DECLARE
    v_clean_name   VARCHAR2(200);
    v_raw_folder   VARCHAR2(500);
    v_sql          VARCHAR2(4000);

    CURSOR c1 IS
        SELECT DISTINCT
            /* clean folder name (remove .junk suffix) */
            REGEXP_REPLACE(REGEXP_SUBSTR(object_name, '^[^/]+'), '\..*', '') AS clean_name,
            /* raw folder (actual S3 folder) */
            REGEXP_SUBSTR(object_name, '^[^/]+') AS raw_folder
        FROM DBMS_CLOUD.LIST_OBJECTS(
               credential_name => 'AWS_S3_CRED',
               location_uri    => 'https://s3.ap-south-1.amazonaws.com/snowflakes-iceberg-bucket/'
             )
        WHERE LOWER(object_name) LIKE '%.parquet';

BEGIN
    FOR r IN c1 LOOP

        v_clean_name := UPPER(r.clean_name) || '_EXT';
        v_raw_folder := r.raw_folder;

        v_sql := 'BEGIN
    DBMS_CLOUD.CREATE_EXTERNAL_TABLE(
        table_name      => ''' || v_clean_name || ''',
        credential_name => ''AWS_S3_CRED'',
        file_uri_list   => ''https://s3.ap-south-1.amazonaws.com/snowflakes-iceberg-bucket/' || v_raw_folder || '/*.parquet'',
        format          => ''{"type":"parquet"}''
    );
END;';

        DBMS_OUTPUT.PUT_LINE('Creating Table: ' || v_clean_name);
        DBMS_OUTPUT.PUT_LINE(v_sql);

        --  EXECUTE the CREATE TABLE dynamically
        EXECUTE IMMEDIATE v_sql;

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('ALL EXTERNAL TABLES CREATED SUCCESSFULLY');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
END;
/


EXIT;
