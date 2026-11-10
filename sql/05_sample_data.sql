-- =============================================================================
-- eSupport System - 05_sample_data.sql
-- Test data. Run on an empty schema, right after 01-04.
-- =============================================================================
SET SERVEROUTPUT ON

-- Roles
INSERT INTO ES_ROL (rol_id, emertimi) VALUES (ES_ROL_SEQ.NEXTVAL, 'SPORTEL');
INSERT INTO ES_ROL (rol_id, emertimi) VALUES (ES_ROL_SEQ.NEXTVAL, 'MENAXHER');
INSERT INTO ES_ROL (rol_id, emertimi) VALUES (ES_ROL_SEQ.NEXTVAL, 'ADMIN');

-- Service points
INSERT INTO ES_PIKA_SHERBIMI (pika_id, emertimi, adresa, email)
VALUES (ES_PIKA_SEQ.NEXTVAL, 'Pika Tirane Qender', 'Rruga e Durresit, Tirane', 'tirane@esupport.com');
INSERT INTO ES_PIKA_SHERBIMI (pika_id, emertimi, adresa, email)
VALUES (ES_PIKA_SEQ.NEXTVAL, 'Pika Durres', 'Lagja 1, Durres', 'durres@esupport.com');

-- Services and which service point offers them
INSERT INTO ES_SHERBIM (sherbim_id, emertimi, pershkrimi, cmimi)
VALUES (ES_SHERBIM_SEQ.NEXTVAL, 'Riparim Laptop', 'Diagnostikim dhe riparim laptopi', 30);
INSERT INTO ES_SHERBIM (sherbim_id, emertimi, pershkrimi, cmimi)
VALUES (ES_SHERBIM_SEQ.NEXTVAL, 'Nderrim Ekrani', 'Nderrim ekrani telefoni', 50);

INSERT INTO ES_PIKA_SHERBIM (pika_id, sherbim_id) VALUES (1, 1);
INSERT INTO ES_PIKA_SHERBIM (pika_id, sherbim_id) VALUES (1, 2);
INSERT INTO ES_PIKA_SHERBIM (pika_id, sherbim_id) VALUES (2, 2);

-- Device types and brands
INSERT INTO ES_LLOJ_PAJISJE (lloj_id, emertimi) VALUES (ES_LLOJ_SEQ.NEXTVAL, 'Laptop');
INSERT INTO ES_LLOJ_PAJISJE (lloj_id, emertimi) VALUES (ES_LLOJ_SEQ.NEXTVAL, 'Telefon');

INSERT INTO ES_MARKA (marka_id, emertimi, lloj_id) VALUES (ES_MARKA_SEQ.NEXTVAL, 'Dell', 1);
INSERT INTO ES_MARKA (marka_id, emertimi, lloj_id) VALUES (ES_MARKA_SEQ.NEXTVAL, 'HP', 1);
INSERT INTO ES_MARKA (marka_id, emertimi, lloj_id) VALUES (ES_MARKA_SEQ.NEXTVAL, 'Samsung', 2);
INSERT INTO ES_MARKA (marka_id, emertimi, lloj_id) VALUES (ES_MARKA_SEQ.NEXTVAL, 'Apple', 2);

-- Clients (klient_id is filled in by the trigger trg_es_klient_pk)
INSERT INTO ES_KLIENT (emri, mbiemri, nr_kontakti, email, adresa, karte_anetaresie)
VALUES ('Elira', 'Shehu', '0691234567', 'elira@email.com', 'Tirane', 'PO');
INSERT INTO ES_KLIENT (emri, mbiemri, nr_kontakti, email, adresa, karte_anetaresie)
VALUES ('Ardit', 'Hoxha', '0689876543', 'ardit@email.com', 'Durres', 'JO');

-- Users: front desk, manager, admin
-- (passwords are plain text for demo purposes only; a real system would store hashes)
INSERT INTO ES_PERDORUES (perdorues_id, emri, mbiemri, email, username, fjalekalim, rol_id, pika_id)
VALUES (ES_PERDORUES_SEQ.NEXTVAL, 'Erion', 'Kola', 'erion@esupport.com', 'ekola', 'demo', 1, 1);
INSERT INTO ES_PERDORUES (perdorues_id, emri, mbiemri, email, username, fjalekalim, rol_id, pika_id)
VALUES (ES_PERDORUES_SEQ.NEXTVAL, 'Ana', 'Meta', 'ana@esupport.com', 'ameta', 'demo', 2, 1);
INSERT INTO ES_PERDORUES (perdorues_id, emri, mbiemri, email, username, fjalekalim, rol_id, pika_id)
VALUES (ES_PERDORUES_SEQ.NEXTVAL, 'Admin', 'System', 'admin@esupport.com', 'admin', 'demo', 3, NULL);

-- Devices: one under warranty (Dell laptop), one out of warranty (HP laptop)
INSERT INTO ES_PAJISJE (pajisje_id, klient_id, marka_id, nr_serie, ne_garanci)
VALUES (ES_PAJISJE_SEQ.NEXTVAL, 1, 1, 'SN12345', 'Y');
INSERT INTO ES_PAJISJE (pajisje_id, klient_id, marka_id, nr_serie, ne_garanci)
VALUES (ES_PAJISJE_SEQ.NEXTVAL, 2, 2, 'SN99999', 'N');

-- Two older tickets, entered directly
INSERT INTO ES_TICKET (ticket_id, klient_id, pika_id, pershkrimi, status, data_hapjes, pajisje_id, sportel_id)
VALUES (ES_TICKET_SEQ.NEXTVAL, 1, 1, 'Laptop nuk ndizet', 'OPEN', SYSDATE - 5, 1, 1);
INSERT INTO ES_TICKET (ticket_id, klient_id, pika_id, pershkrimi, status, data_hapjes, pajisje_id, sportel_id, data_mbylljes)
VALUES (ES_TICKET_SEQ.NEXTVAL, 2, 2, 'Ekrani i thyer', 'CLOSED', SYSDATE - 5, 2, 1, SYSDATE - 2);

-- Knowledge base
INSERT INTO ES_DOKUMENTIM (dokumentim_id, sherbim_id, pershkrim_problem, zgjidhje, krijuar_nga)
VALUES (ES_DOKUMENTIM_SEQ.NEXTVAL, 1, 'Laptop nuk ndizet',
        'Kontrollo karikuesin, baterinë dhe motherboard', 1);
INSERT INTO ES_DOKUMENTIM (dokumentim_id, sherbim_id, pershkrim_problem, zgjidhje, krijuar_nga)
VALUES (ES_DOKUMENTIM_SEQ.NEXTVAL, 2, 'Ekrani i telefonit i thyer',
        'Zëvendësim i ekranit me pjesë origjinale', 1);

COMMIT;

-- New tickets opened through the procedures
BEGIN
    ES_HAP_TICKET_GARANCI(1, 1, 1, 1, 'Laptop nxehet shume');                -- ticket 3
    ES_HAP_TICKET_JASHTE_GARANCIE(2, 2, 1, 1, 'Laptop nuk karikohet');      -- ticket 4
END;
/

-- Response deadlines (opening date + 3 days) for every ticket
BEGIN
    FOR t IN (SELECT ticket_id FROM ES_TICKET) LOOP
        ES_CAKTO_SLA(t.ticket_id);
    END LOOP;
END;
/

-- Ticket 2 was answered on time; ticket 1 was never answered and is now late
UPDATE ES_TICKET SET data_pergjigje = SYSDATE - 4 WHERE ticket_id = 2;

-- Priorities
UPDATE ES_TICKET SET prioritet = 'LARTE'    WHERE ticket_id IN (1, 4);
UPDATE ES_TICKET SET prioritet = 'MESATARE' WHERE ticket_id = 2;
UPDATE ES_TICKET SET prioritet = 'ULET'     WHERE ticket_id = 3;

-- Ticket 1 handed from the front desk to the manager
BEGIN
    ES_DELEGO_TICKET(1, 1, 2, 'Deleguar te menaxheri per verifikim');
END;
/

-- Ticket 4 (out of warranty): invoice it, then perform the service and close it
BEGIN
    ES_KRIJO_FATURE(4, 150);
    ES_KRYEJ_SHERBIM(4);
END;
/

COMMIT;
