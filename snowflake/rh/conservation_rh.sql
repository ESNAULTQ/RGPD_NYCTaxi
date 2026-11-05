-- =====================================================================
-- conservation_rh.sql — appliquer R2 et revérifier R3
-- Exécuter avec TRANSFORMER, propriétaire des tables.
-- Les vues STAGING ne stockent aucune copie et n'ont pas de rétention propre.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

ALTER TABLE NYC_TAXI.RAW.DRIVERS
  SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.RAW.DRIVER_SHIFTS
  SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.DIM_DRIVER
  SET DATA_RETENTION_TIME_IN_DAYS = 1;
ALTER TABLE NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
  SET DATA_RETENTION_TIME_IN_DAYS = 1;

-- R2 : quatre lignes avec RETENTION_TIME = 1.
SELECT table_schema, table_name, retention_time
FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE (table_schema = 'RAW' AND table_name IN ('DRIVERS', 'DRIVER_SHIFTS'))
   OR (table_schema = 'MARTS' AND table_name IN ('DIM_DRIVER', 'MART_DRIVER_MONTHLY'))
ORDER BY table_schema, table_name;

-- R3 : aucun fichier ne doit rester sur le stage.
LIST @NYC_TAXI.RAW.RH_STAGE;

-- Limite à documenter : après 1 jour de Time Travel, les versions historiques
-- des tables permanentes passent 7 jours en Fail-safe. Ce délai n'est pas
-- paramétrable et seul Snowflake peut tenter une récupération exceptionnelle.
