-- =============================================================================
-- eSupport System - 00_drop_all.sql
-- Removes every eSupport object so the scripts can be run again from scratch.
-- Safe to run on an empty schema: missing objects are skipped.
-- =============================================================================
BEGIN
    FOR o IN (
        SELECT object_name, object_type
          FROM user_objects
         WHERE (object_name LIKE 'ES\_%' ESCAPE '\' OR object_name LIKE 'VW\_%' ESCAPE '\'
                OR object_name IN ('TRG_ES_KLIENT_PK', 'TRG_GJURMIM_TICKET'))
           AND object_type IN ('VIEW', 'PROCEDURE', 'TRIGGER', 'SEQUENCE', 'TABLE')
    ) LOOP
        BEGIN
            IF o.object_type = 'TABLE' THEN
                EXECUTE IMMEDIATE 'DROP TABLE "' || o.object_name || '" CASCADE CONSTRAINTS PURGE';
            ELSE
                EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' "' || o.object_name || '"';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN NULL;  -- already dropped together with its table
        END;
    END LOOP;
END;
/
