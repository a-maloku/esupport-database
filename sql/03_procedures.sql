-- =============================================================================
-- eSupport System - 03_procedures.sql
-- Stored procedures (PL/SQL). Run with SET SERVEROUTPUT ON to see messages.
-- =============================================================================

-- Online check: is a given ticket still open?
CREATE OR REPLACE PROCEDURE ES_KONTROLLO_TICKET_OPEN (
    p_ticket_id IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ES_TICKET
     WHERE ticket_id = p_ticket_id
       AND status = 'OPEN';

    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ticket është OPEN');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Ticket nuk është OPEN ose nuk ekziston');
    END IF;
END;
/

-- Opens a ticket at the front desk for a device UNDER warranty.
CREATE OR REPLACE PROCEDURE ES_HAP_TICKET_GARANCI (
    p_klient_id  NUMBER,
    p_pajisje_id NUMBER,
    p_pika_id    NUMBER,
    p_sportel_id NUMBER,
    p_pershkrimi VARCHAR2
) AS
    v_garanci CHAR(1);
BEGIN
    SELECT ne_garanci
      INTO v_garanci
      FROM ES_PAJISJE
     WHERE pajisje_id = p_pajisje_id;

    IF v_garanci = 'Y' THEN
        INSERT INTO ES_TICKET
            (ticket_id, klient_id, pika_id, pershkrimi, status, data_hapjes, pajisje_id, sportel_id)
        VALUES
            (ES_TICKET_SEQ.NEXTVAL, p_klient_id, p_pika_id, p_pershkrimi, 'OPEN', SYSDATE,
             p_pajisje_id, p_sportel_id);
        DBMS_OUTPUT.PUT_LINE('Ticket u hap (ne garanci).');
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Pajisja nuk eshte ne garanci');
    END IF;
END;
/

-- Opens a ticket at the front desk for a device OUT of warranty.
CREATE OR REPLACE PROCEDURE ES_HAP_TICKET_JASHTE_GARANCIE (
    p_klient_id  NUMBER,
    p_pajisje_id NUMBER,
    p_pika_id    NUMBER,
    p_sportel_id NUMBER,
    p_pershkrimi VARCHAR2
) AS
    v_garanci CHAR(1);
BEGIN
    SELECT ne_garanci
      INTO v_garanci
      FROM ES_PAJISJE
     WHERE pajisje_id = p_pajisje_id;

    IF v_garanci = 'N' THEN
        INSERT INTO ES_TICKET
            (ticket_id, klient_id, pika_id, pershkrimi, status, data_hapjes, pajisje_id, sportel_id)
        VALUES
            (ES_TICKET_SEQ.NEXTVAL, p_klient_id, p_pika_id, p_pershkrimi, 'OPEN', SYSDATE,
             p_pajisje_id, p_sportel_id);
        DBMS_OUTPUT.PUT_LINE('Ticket u hap (jashte garancie).');
    ELSE
        RAISE_APPLICATION_ERROR(-20002, 'Pajisja eshte ende ne garanci');
    END IF;
END;
/

-- Creates an invoice for a ticket. Devices under warranty are not invoiced.
CREATE OR REPLACE PROCEDURE ES_KRIJO_FATURE (
    p_ticket_id NUMBER,
    p_shuma     NUMBER
) AS
    v_garanci CHAR(1);
BEGIN
    SELECT p.ne_garanci
      INTO v_garanci
      FROM ES_TICKET t
      JOIN ES_PAJISJE p ON p.pajisje_id = t.pajisje_id
     WHERE t.ticket_id = p_ticket_id;

    IF v_garanci = 'N' THEN
        INSERT INTO ES_FATURE (fature_id, ticket_id, shuma)
        VALUES (ES_FATURE_SEQ.NEXTVAL, p_ticket_id, p_shuma);
        DBMS_OUTPUT.PUT_LINE('Fatura u krijua me sukses.');
    ELSE
        RAISE_APPLICATION_ERROR(-20004, 'Nuk krijohet fature per pajisje ne garanci');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Ticket nuk ekziston ose nuk ka pajisje');
END;
/

-- Performs the service and closes the ticket with today's date.
CREATE OR REPLACE PROCEDURE ES_KRYEJ_SHERBIM (
    p_ticket_id NUMBER
) AS
    v_pajisje NUMBER;
BEGIN
    SELECT pajisje_id
      INTO v_pajisje
      FROM ES_TICKET
     WHERE ticket_id = p_ticket_id;

    IF v_pajisje IS NULL THEN
        RAISE_APPLICATION_ERROR(-20011, 'Ticket pa pajisje');
    END IF;

    UPDATE ES_TICKET
       SET status = 'CLOSED',
           data_mbylljes = SYSDATE
     WHERE ticket_id = p_ticket_id;

    DBMS_OUTPUT.PUT_LINE('Sherbimi u krye dhe ticket u mbyll.');
END;
/

-- Searches the knowledge base for similar problems by keyword.
CREATE OR REPLACE PROCEDURE ES_KERKO_DOKUMENTIM (
    p_fjale_kyce VARCHAR2
) AS
BEGIN
    FOR r IN (
        SELECT d.pershkrim_problem, d.zgjidhje
          FROM ES_DOKUMENTIM d
         WHERE LOWER(d.pershkrim_problem) LIKE '%' || LOWER(p_fjale_kyce) || '%'
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Problem: '  || r.pershkrim_problem);
        DBMS_OUTPUT.PUT_LINE('Zgjidhje: ' || r.zgjidhje);
        DBMS_OUTPUT.PUT_LINE('----------------------');
    END LOOP;
END;
/

-- ---------------------------------------------------------------------------
-- Advanced requirements
-- ---------------------------------------------------------------------------

-- Hands a ticket over from one employee to another and logs it.
CREATE OR REPLACE PROCEDURE ES_DELEGO_TICKET (
    p_ticket_id NUMBER,
    p_nga_user  NUMBER,
    p_te_user   NUMBER,
    p_shenime   VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM ES_TICKET
     WHERE ticket_id = p_ticket_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20100, 'Ticket nuk ekziston');
    END IF;

    INSERT INTO ES_TICKET_GJURMIM
        (gjurmim_id, ticket_id, nga_perdorues, te_perdorues, data_delegimit, shenime)
    VALUES
        (ES_TICKET_GJURMIM_SEQ.NEXTVAL, p_ticket_id, p_nga_user, p_te_user, SYSDATE, p_shenime);

    DBMS_OUTPUT.PUT_LINE('Ticket u delegua me sukses.');
END;
/

-- Sets the response deadline (SLA): 3 days after the ticket was opened.
CREATE OR REPLACE PROCEDURE ES_CAKTO_SLA (
    p_ticket_id NUMBER
) AS
BEGIN
    UPDATE ES_TICKET
       SET afat_pergjigje = data_hapjes + 3
     WHERE ticket_id = p_ticket_id;

    DBMS_OUTPUT.PUT_LINE('Afati i përgjigjes u caktua.');
END;
/

-- Alerts the responsible employee for every ticket past its deadline.
CREATE OR REPLACE PROCEDURE ES_ALERT_VONESA AS
BEGIN
    FOR r IN (
        SELECT t.ticket_id, t.afat_pergjigje, g.te_perdorues
          FROM ES_TICKET t
          JOIN ES_TICKET_GJURMIM g ON t.ticket_id = g.ticket_id
         WHERE t.data_pergjigje IS NULL
           AND SYSDATE > t.afat_pergjigje
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            'ALERT: Ticket ID ' || r.ticket_id ||
            ' eshte ne vonese! Punonjesi pergjegjes ID = ' || r.te_perdorues
        );
    END LOOP;
END;
/
