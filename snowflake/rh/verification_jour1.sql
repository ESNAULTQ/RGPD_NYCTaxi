-- =====================================================================
-- verification_jour1.sql — observations à exécuter après le catalogue
-- Ce fichier ne modifie rien. Reporter les résultats dans JOUR_1_EXECUTION.md.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- À reporter dans VEILLE.md pour l'analyse de localisation et de transfert.
SELECT CURRENT_REGION() AS region_snowflake;

-- Volumes attendus avant purge : 400 / 25 951 / 25 933 / 3 / 400 / 914.
SELECT
  (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS raw_drivers,
  (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS raw_shifts,
  (SELECT COUNT(*) FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS) AS staging_shifts,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT) AS dim_depot,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER) AS dim_driver,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY) AS mart_driver_monthly;

-- Attendu : aucun fichier.
LIST @NYC_TAXI.RAW.RH_STAGE;

-- Attendu : zéro colonne sans description pour ces trois tables.
SELECT table_schema, table_name, COUNT_IF(comment IS NULL OR TRIM(comment) = '') AS descriptions_manquantes
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE (table_schema = 'RAW' AND table_name = 'DRIVERS')
   OR (table_schema = 'MARTS' AND table_name IN ('DIM_DRIVER', 'DIM_DEPOT'))
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name;

-- Commentaires de table attendus sur les cinq objets catalogués.
SELECT table_schema, table_name, comment
FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE (table_schema = 'RAW' AND table_name IN ('DRIVERS', 'DRIVER_SHIFTS'))
   OR (table_schema = 'MARTS' AND table_name IN ('DIM_DEPOT', 'DIM_DRIVER', 'MART_DRIVER_MONTHLY'))
ORDER BY table_schema, table_name;

-- Tags réellement attachés, table par table.
SELECT 'RAW.DRIVERS' AS objet, level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVERS', 'table'))
UNION ALL
SELECT 'RAW.DRIVER_SHIFTS', level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.RAW.DRIVER_SHIFTS', 'table'))
UNION ALL
SELECT 'MARTS.DIM_DEPOT', level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DEPOT', 'table'))
UNION ALL
SELECT 'MARTS.DIM_DRIVER', level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.DIM_DRIVER', 'table'))
UNION ALL
SELECT 'MARTS.MART_DRIVER_MONTHLY', level, column_name, tag_name, tag_value
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS('NYC_TAXI.MARTS.MART_DRIVER_MONTHLY', 'table'))
ORDER BY objet, level, column_name, tag_name;

