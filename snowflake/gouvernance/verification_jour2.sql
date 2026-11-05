-- =====================================================================
-- verification_jour2.sql — exécuter UN BLOC À LA FOIS
-- Copier les résultats dans docs/ACCES.md. Ne pas publier les valeurs RH.
-- =====================================================================

-- ---------------------------------------------------------------------
-- V00 — Inventaire des contrôles
USE SECONDARY ROLES NONE;
USE ROLE GOUVERNANCE;
USE WAREHOUSE NYC_TAXI_WH;
SHOW MASKING POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
SHOW ROW ACCESS POLICIES IN SCHEMA NYC_TAXI.GOUVERNANCE;
SELECT * FROM NYC_TAXI.GOUVERNANCE.ACCES_DEPOT ORDER BY role_name, depot;

-- ---------------------------------------------------------------------
-- A01 — RH_PAIE : 400 chauffeurs, valeurs réelles
USE SECONDARY ROLES NONE;
USE ROLE RH_PAIE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT depot, COUNT(*) AS nb
FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot ORDER BY depot;
SELECT driver_id, first_name, last_name, email, phone, birth_date, tlc_license_number
FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
SELECT COUNT(*) AS nb_depots FROM NYC_TAXI.MARTS.DIM_DEPOT;

-- ---------------------------------------------------------------------
-- A02/A04 — Queens : 161 chauffeurs, 365 lignes mensuelles, D0003 visible
USE SECONDARY ROLES NONE;
USE ROLE RESP_DEPOT_QUEENS;
USE WAREHOUSE NYC_TAXI_WH;
SELECT depot, COUNT(*) AS nb
FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot ORDER BY depot;
SELECT depot, COUNT(*) AS nb
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY GROUP BY depot ORDER BY depot;
SELECT driver_id, first_name, last_name, email, phone, birth_date, tlc_license_number
FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
SELECT driver_id, driver_name, activity_month
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
WHERE driver_id = 'D0003' ORDER BY activity_month;
SELECT COUNT(*) AS nb_depots FROM NYC_TAXI.MARTS.DIM_DEPOT;

-- ---------------------------------------------------------------------
-- A03/A05 — Bronx : 122 chauffeurs, 290 lignes mensuelles, D0003 invisible
USE SECONDARY ROLES NONE;
USE ROLE RESP_DEPOT_BRONX;
USE WAREHOUSE NYC_TAXI_WH;
SELECT depot, COUNT(*) AS nb
FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot ORDER BY depot;
SELECT depot, COUNT(*) AS nb
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY GROUP BY depot ORDER BY depot;
SELECT COUNT(*) AS d0003_visible
FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
SELECT COUNT(*) AS nb_depots FROM NYC_TAXI.MARTS.DIM_DEPOT;

-- ---------------------------------------------------------------------
-- A06 — ANALYSTE : tous les dépôts, identifiants directs masqués
USE SECONDARY ROLES NONE;
USE ROLE ANALYSTE;
USE WAREHOUSE NYC_TAXI_WH;
SELECT depot, COUNT(*) AS nb
FROM NYC_TAXI.MARTS.DIM_DRIVER GROUP BY depot ORDER BY depot;
SELECT COUNT(*) AS nb_mensuel FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY;
SELECT driver_id, first_name, last_name, email, phone, birth_date, tlc_license_number
FROM NYC_TAXI.MARTS.DIM_DRIVER WHERE driver_id = 'D0003';
SELECT driver_id, driver_name, activity_month
FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
WHERE driver_id = 'D0003' ORDER BY activity_month;
SELECT COUNT(*) AS nb_depots FROM NYC_TAXI.MARTS.DIM_DEPOT;

-- ---------------------------------------------------------------------
-- A07 — GOUVERNANCE : refus déjà observé et consigné.
-- Le test volontairement en erreur est isolé dans verification_jour2_refus.sql
-- afin que ce fichier puisse être rejoué en entier sans s'arrêter.

-- ---------------------------------------------------------------------
-- A08 — ACCOUNTADMIN : 0 ligne sur les quatre tables RH
USE SECONDARY ROLES NONE;
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
SELECT
  (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS raw_drivers,
  (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS raw_shifts,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER) AS dim_driver,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY) AS mart_monthly;

-- ---------------------------------------------------------------------
-- A09 — PUBLIC : test volontairement en erreur isolé dans
-- verification_jour2_refus.sql. Ne pas accorder USAGE/SELECT pour le faire passer.

-- ---------------------------------------------------------------------
-- P03 — Références de politiques après reconstruction.
-- TRANSFORMER est propriétaire de la table : INFORMATION_SCHEMA peut donc
-- exposer ses références. GOUVERNANCE n'a volontairement aucun privilège TABLE.
USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;
SELECT policy_name, policy_kind, ref_entity_name, ref_column_name,
       tag_name, policy_status
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.POLICY_REFERENCES(
  REF_ENTITY_NAME => 'NYC_TAXI.MARTS.DIM_DRIVER',
  REF_ENTITY_DOMAIN => 'TABLE'))
ORDER BY policy_kind, ref_column_name, policy_name;


