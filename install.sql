-- =============================================================================
-- eSupport System - install.sql
-- Builds the whole database in one go.
-- SQL Developer: open this file and press F5 (Run Script).
-- SQL*Plus / SQLcl: run  @install.sql  from this folder.
-- =============================================================================
SET SERVEROUTPUT ON

@@sql/00_drop_all.sql
@@sql/01_schema.sql
@@sql/02_triggers.sql
@@sql/03_procedures.sql
@@sql/04_views.sql
@@sql/05_sample_data.sql
