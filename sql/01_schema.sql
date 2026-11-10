-- =============================================================================
-- eSupport System - 01_schema.sql
-- Tables and sequences, in the order they depend on each other.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Service points, services and the service points <-> services link
-- ---------------------------------------------------------------------------
CREATE TABLE ES_PIKA_SHERBIMI (
    pika_id    NUMBER        PRIMARY KEY,
    emertimi   VARCHAR2(100) NOT NULL,
    adresa     VARCHAR2(200) NOT NULL,
    email      VARCHAR2(100)
);

CREATE TABLE ES_SHERBIM (
    sherbim_id NUMBER        PRIMARY KEY,
    emertimi   VARCHAR2(100) NOT NULL,
    pershkrimi VARCHAR2(300),
    cmimi      NUMBER(8,2)
);

-- Which services each service point offers (many-to-many)
CREATE TABLE ES_PIKA_SHERBIM (
    pika_id    NUMBER NOT NULL,
    sherbim_id NUMBER NOT NULL,
    CONSTRAINT pk_pika_sherbim PRIMARY KEY (pika_id, sherbim_id),
    CONSTRAINT fk_ps_pika    FOREIGN KEY (pika_id)    REFERENCES ES_PIKA_SHERBIMI(pika_id),
    CONSTRAINT fk_ps_sherbim FOREIGN KEY (sherbim_id) REFERENCES ES_SHERBIM(sherbim_id)
);

-- ---------------------------------------------------------------------------
-- Clients
-- ---------------------------------------------------------------------------
CREATE TABLE ES_KLIENT (
    klient_id        NUMBER        PRIMARY KEY,
    emri             VARCHAR2(50)  NOT NULL,
    mbiemri          VARCHAR2(50)  NOT NULL,
    nr_kontakti      VARCHAR2(20),
    email            VARCHAR2(100),
    adresa           VARCHAR2(200),
    karte_anetaresie VARCHAR2(30)
);

-- ---------------------------------------------------------------------------
-- Device types, brands and devices
-- ---------------------------------------------------------------------------
CREATE TABLE ES_LLOJ_PAJISJE (
    lloj_id  NUMBER        PRIMARY KEY,
    emertimi VARCHAR2(100) NOT NULL
);

CREATE TABLE ES_MARKA (
    marka_id NUMBER        PRIMARY KEY,
    emertimi VARCHAR2(100) NOT NULL,
    lloj_id  NUMBER        NOT NULL,
    CONSTRAINT fk_marka_lloj FOREIGN KEY (lloj_id) REFERENCES ES_LLOJ_PAJISJE(lloj_id)
);

CREATE TABLE ES_PAJISJE (
    pajisje_id NUMBER       PRIMARY KEY,
    klient_id  NUMBER       NOT NULL,
    marka_id   NUMBER       NOT NULL,
    nr_serie   VARCHAR2(50),
    ne_garanci CHAR(1)      CHECK (ne_garanci IN ('Y', 'N')),
    CONSTRAINT fk_pajisje_klient FOREIGN KEY (klient_id) REFERENCES ES_KLIENT(klient_id),
    CONSTRAINT fk_pajisje_marka  FOREIGN KEY (marka_id)  REFERENCES ES_MARKA(marka_id)
);

-- ---------------------------------------------------------------------------
-- Users and roles (front desk, service point manager, system admin)
-- ---------------------------------------------------------------------------
CREATE TABLE ES_ROL (
    rol_id   NUMBER       PRIMARY KEY,
    emertimi VARCHAR2(50) NOT NULL
);

CREATE TABLE ES_PERDORUES (
    perdorues_id NUMBER        PRIMARY KEY,
    emri         VARCHAR2(50)  NOT NULL,
    mbiemri      VARCHAR2(50)  NOT NULL,
    email        VARCHAR2(100) UNIQUE,
    username     VARCHAR2(50)  UNIQUE,
    fjalekalim   VARCHAR2(100),
    rol_id       NUMBER        NOT NULL,
    pika_id      NUMBER,
    CONSTRAINT fk_user_rol  FOREIGN KEY (rol_id)  REFERENCES ES_ROL(rol_id),
    CONSTRAINT fk_user_pika FOREIGN KEY (pika_id) REFERENCES ES_PIKA_SHERBIMI(pika_id)
);

-- ---------------------------------------------------------------------------
-- Tickets (support cases)
-- ---------------------------------------------------------------------------
CREATE TABLE ES_TICKET (
    ticket_id      NUMBER        PRIMARY KEY,
    klient_id      NUMBER        NOT NULL,
    pika_id        NUMBER        NOT NULL,
    pershkrimi     VARCHAR2(300),
    status         VARCHAR2(20),
    data_hapjes    DATE          DEFAULT SYSDATE,
    pajisje_id     NUMBER,
    sportel_id     NUMBER,
    data_mbylljes  DATE,
    afat_pergjigje DATE,
    data_pergjigje DATE,
    prioritet      VARCHAR2(10)  CHECK (prioritet IN ('LARTE', 'MESATARE', 'ULET')),
    CONSTRAINT fk_ticket_klient  FOREIGN KEY (klient_id)  REFERENCES ES_KLIENT(klient_id),
    CONSTRAINT fk_ticket_pika    FOREIGN KEY (pika_id)    REFERENCES ES_PIKA_SHERBIMI(pika_id),
    CONSTRAINT fk_ticket_pajisje FOREIGN KEY (pajisje_id) REFERENCES ES_PAJISJE(pajisje_id),
    CONSTRAINT fk_ticket_sportel FOREIGN KEY (sportel_id) REFERENCES ES_PERDORUES(perdorues_id)
);

-- Ticket hand-overs from one employee to another
CREATE TABLE ES_TICKET_GJURMIM (
    gjurmim_id     NUMBER        PRIMARY KEY,
    ticket_id      NUMBER        NOT NULL,
    nga_perdorues  NUMBER        NOT NULL,
    te_perdorues   NUMBER        NOT NULL,
    data_delegimit DATE          DEFAULT SYSDATE,
    shenime        VARCHAR2(300),
    CONSTRAINT fk_gj_ticket FOREIGN KEY (ticket_id)     REFERENCES ES_TICKET(ticket_id),
    CONSTRAINT fk_gj_nga    FOREIGN KEY (nga_perdorues) REFERENCES ES_PERDORUES(perdorues_id),
    CONSTRAINT fk_gj_te     FOREIGN KEY (te_perdorues)  REFERENCES ES_PERDORUES(perdorues_id)
);

-- ---------------------------------------------------------------------------
-- Invoices and knowledge base
-- ---------------------------------------------------------------------------
CREATE TABLE ES_FATURE (
    fature_id     NUMBER        PRIMARY KEY,
    ticket_id     NUMBER        NOT NULL,
    data_fatures  DATE          DEFAULT SYSDATE,
    shuma         NUMBER(10,2)  NOT NULL,
    status_pagesa VARCHAR2(20)  DEFAULT 'PA PAGUAR',
    CONSTRAINT fk_fature_ticket FOREIGN KEY (ticket_id) REFERENCES ES_TICKET(ticket_id)
);

-- Known problems and their solutions, to help with similar cases
CREATE TABLE ES_DOKUMENTIM (
    dokumentim_id     NUMBER        PRIMARY KEY,
    sherbim_id        NUMBER        NOT NULL,
    pershkrim_problem VARCHAR2(300) NOT NULL,
    zgjidhje          VARCHAR2(500) NOT NULL,
    data_krijimit     DATE          DEFAULT SYSDATE,
    krijuar_nga       NUMBER,
    CONSTRAINT fk_dok_sherbim FOREIGN KEY (sherbim_id)  REFERENCES ES_SHERBIM(sherbim_id),
    CONSTRAINT fk_dok_user    FOREIGN KEY (krijuar_nga) REFERENCES ES_PERDORUES(perdorues_id)
);

-- ---------------------------------------------------------------------------
-- Sequences (automatic primary keys)
-- ---------------------------------------------------------------------------
CREATE SEQUENCE ES_PIKA_SEQ           START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_SHERBIM_SEQ        START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_KLIENT_SEQ         START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_LLOJ_SEQ           START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_MARKA_SEQ          START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_PAJISJE_SEQ        START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_ROL_SEQ            START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_PERDORUES_SEQ      START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_TICKET_SEQ         START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_TICKET_GJURMIM_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_FATURE_SEQ         START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ES_DOKUMENTIM_SEQ     START WITH 1 INCREMENT BY 1;
