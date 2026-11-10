-- =============================================================================
-- eSupport System - 02_triggers.sql
-- =============================================================================

-- Gives a new client an ID from the sequence when none is provided.
CREATE OR REPLACE TRIGGER trg_es_klient_pk
BEFORE INSERT ON ES_KLIENT
FOR EACH ROW
BEGIN
    IF :NEW.klient_id IS NULL THEN
        :NEW.klient_id := ES_KLIENT_SEQ.NEXTVAL;
    END IF;
END;
/

-- Records the hand-over date automatically for every new tracking row.
CREATE OR REPLACE TRIGGER trg_gjurmim_ticket
BEFORE INSERT ON ES_TICKET_GJURMIM
FOR EACH ROW
BEGIN
    :NEW.data_delegimit := SYSDATE;
END;
/
