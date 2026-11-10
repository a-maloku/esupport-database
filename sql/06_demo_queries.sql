-- =============================================================================
-- eSupport System - 06_demo_queries.sql
-- Example queries and procedure calls that show the system working.
-- =============================================================================
SET SERVEROUTPUT ON

-- Online check: only the open tickets
SELECT t.ticket_id,
       k.emri || ' ' || k.mbiemri AS klienti,
       p.emertimi                 AS pika_sherbimi,
       t.pershkrimi,
       t.data_hapjes
  FROM ES_TICKET t
  JOIN ES_KLIENT        k ON t.klient_id = k.klient_id
  JOIN ES_PIKA_SHERBIMI p ON t.pika_id   = p.pika_id
 WHERE t.status = 'OPEN';

EXEC ES_KONTROLLO_TICKET_OPEN(1);

-- Services offered at each service point
SELECT p.emertimi AS pika_sherbimi,
       s.emertimi AS sherbimi,
       s.cmimi
  FROM ES_PIKA_SHERBIM ps
  JOIN ES_PIKA_SHERBIMI p ON ps.pika_id    = p.pika_id
  JOIN ES_SHERBIM       s ON ps.sherbim_id = s.sherbim_id
 ORDER BY p.emertimi;

-- Device types and brands
SELECT l.emertimi AS lloj_pajisje,
       m.emertimi AS marka
  FROM ES_LLOJ_PAJISJE l
  JOIN ES_MARKA m ON l.lloj_id = m.lloj_id
 ORDER BY l.emertimi;

-- Users with their role and service point
SELECT u.emri,
       u.mbiemri,
       r.emertimi  AS roli,
       ps.emertimi AS pika_sherbimi
  FROM ES_PERDORUES u
  JOIN ES_ROL r ON u.rol_id = r.rol_id
  LEFT JOIN ES_PIKA_SHERBIMI ps ON u.pika_id = ps.pika_id;

-- Tickets for devices under warranty / out of warranty
SELECT t.ticket_id, k.emri || ' ' || k.mbiemri AS klienti, t.pershkrimi, t.status, p.ne_garanci
  FROM ES_TICKET t
  JOIN ES_KLIENT  k ON t.klient_id  = k.klient_id
  JOIN ES_PAJISJE p ON t.pajisje_id = p.pajisje_id
 ORDER BY p.ne_garanci DESC, t.ticket_id;

-- Knowledge base search
EXEC ES_KERKO_DOKUMENTIM('laptop');

-- Error handling: invoicing a device under warranty is refused (ORA-20004)
BEGIN
    ES_KRIJO_FATURE(3, 100);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Pritur: ' || SQLERRM);
END;
/

-- Reports
SELECT * FROM VW_TOTAL_FATURIME;
SELECT * FROM VW_FATURA_STATUS;
SELECT * FROM VW_FATURA_MUAJ;
SELECT * FROM VW_TICKET_STATUS;
SELECT * FROM VW_TICKET_PIKE;
SELECT * FROM VW_KLIENT_SHPENZIME;
SELECT * FROM VW_PAJISJE_GARANCI;
SELECT * FROM ES_RAPORT_FATURIM;

-- Tracking history of ticket 1
SELECT g.gjurmim_id,
       g.ticket_id,
       u1.emri || ' ' || u1.mbiemri AS nga_perdoruesi,
       u2.emri || ' ' || u2.mbiemri AS te_perdoruesi,
       g.data_delegimit,
       g.shenime
  FROM ES_TICKET_GJURMIM g
  JOIN ES_PERDORUES u1 ON g.nga_perdorues = u1.perdorues_id
  JOIN ES_PERDORUES u2 ON g.te_perdorues  = u2.perdorues_id
 WHERE g.ticket_id = 1
 ORDER BY g.data_delegimit;

-- Delays and priorities
SELECT * FROM ES_V_RAPORT_GJURMIM_VONESA ORDER BY ticket_id;

SELECT *
  FROM ES_V_RAPORT_PRIORITETE
 ORDER BY CASE prioritet WHEN 'LARTE' THEN 1 WHEN 'MESATARE' THEN 2 WHEN 'ULET' THEN 3 END;

-- Alert employees about late tickets (ticket 1 is late in the sample data)
EXEC ES_ALERT_VONESA;
