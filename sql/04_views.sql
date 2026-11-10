-- =============================================================================
-- eSupport System - 04_views.sql
-- Statistical and tracking reports.
-- =============================================================================

-- Total amount invoiced
CREATE OR REPLACE VIEW VW_TOTAL_FATURIME AS
SELECT SUM(shuma) AS total_faturime
  FROM ES_FATURE;

-- Invoices grouped by payment status
CREATE OR REPLACE VIEW VW_FATURA_STATUS AS
SELECT status_pagesa,
       COUNT(*)   AS nr_faturash,
       SUM(shuma) AS total_shuma
  FROM ES_FATURE
 GROUP BY status_pagesa;

-- Invoices per month
CREATE OR REPLACE VIEW VW_FATURA_MUAJ AS
SELECT TO_CHAR(data_fatures, 'YYYY-MM') AS muaji,
       COUNT(*)   AS nr_faturash,
       SUM(shuma) AS total_mujor
  FROM ES_FATURE
 GROUP BY TO_CHAR(data_fatures, 'YYYY-MM');

-- Tickets per status
CREATE OR REPLACE VIEW VW_TICKET_STATUS AS
SELECT status,
       COUNT(*) AS nr_ticket
  FROM ES_TICKET
 GROUP BY status;

-- Tickets per service point
CREATE OR REPLACE VIEW VW_TICKET_PIKE AS
SELECT p.emertimi        AS pika_sherbimi,
       COUNT(t.ticket_id) AS nr_ticket
  FROM ES_TICKET t
  JOIN ES_PIKA_SHERBIMI p ON t.pika_id = p.pika_id
 GROUP BY p.emertimi;

-- Total spending per client
CREATE OR REPLACE VIEW VW_KLIENT_SHPENZIME AS
SELECT k.emri || ' ' || k.mbiemri AS klienti,
       SUM(f.shuma)               AS total_shpenzime
  FROM ES_FATURE f
  JOIN ES_TICKET t ON f.ticket_id = t.ticket_id
  JOIN ES_KLIENT k ON t.klient_id = k.klient_id
 GROUP BY k.emri, k.mbiemri;

-- Devices in / out of warranty
CREATE OR REPLACE VIEW VW_PAJISJE_GARANCI AS
SELECT ne_garanci,
       COUNT(*) AS nr_pajisjesh
  FROM ES_PAJISJE
 GROUP BY ne_garanci;

-- Full invoice report with client and service point
CREATE OR REPLACE VIEW ES_RAPORT_FATURIM AS
SELECT f.fature_id,
       f.data_fatures,
       f.shuma,
       f.status_pagesa,
       k.emri || ' ' || k.mbiemri AS klienti,
       p.emertimi                 AS pika_sherbimi
  FROM ES_FATURE f
  JOIN ES_TICKET        t ON f.ticket_id = t.ticket_id
  JOIN ES_KLIENT        k ON t.klient_id = k.klient_id
  JOIN ES_PIKA_SHERBIMI p ON t.pika_id   = p.pika_id;

-- Ticket tracking with delays (status and number of days late)
CREATE OR REPLACE VIEW ES_V_RAPORT_GJURMIM_VONESA AS
SELECT t.ticket_id,
       t.data_hapjes,
       t.afat_pergjigje,
       t.data_pergjigje,
       g.nga_perdorues,
       g.te_perdorues,
       g.data_delegimit,
       CASE
           WHEN t.data_pergjigje IS NULL AND SYSDATE > t.afat_pergjigje THEN 'VONESE'
           WHEN t.data_pergjigje > t.afat_pergjigje                    THEN 'VONESE'
           ELSE 'NE AFAT'
       END AS status_vonese,
       CASE
           WHEN t.data_pergjigje IS NOT NULL
               THEN GREATEST(TRUNC(t.data_pergjigje - t.afat_pergjigje), 0)
           WHEN SYSDATE > t.afat_pergjigje
               THEN TRUNC(SYSDATE - t.afat_pergjigje)
           ELSE 0
       END AS dite_vonese
  FROM ES_TICKET t
  LEFT JOIN ES_TICKET_GJURMIM g ON t.ticket_id = g.ticket_id;

-- Tickets by priority, with on-time / late status
CREATE OR REPLACE VIEW ES_V_RAPORT_PRIORITETE AS
SELECT t.ticket_id,
       t.prioritet,
       t.status,
       t.data_hapjes,
       t.afat_pergjigje,
       CASE
           WHEN t.data_pergjigje IS NULL AND SYSDATE > t.afat_pergjigje THEN 'VONESE'
           WHEN t.data_pergjigje > t.afat_pergjigje                    THEN 'VONESE'
           ELSE 'NE AFAT'
       END AS status_vonese
  FROM ES_TICKET t;
