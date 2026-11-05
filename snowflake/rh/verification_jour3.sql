-- =====================================================================
-- verification_jour3.sql — contrôles sans valeur personnelle
-- Exécuter après une exécution réussie du graphe. Ce fichier ne modifie rien.
-- Reporter les résultats réels dans docs/JOUR_3_EXECUTION.md et REGISTRE.md.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- V31 — Volumes attendus avec le jeu fourni après purge :
-- 354 / 25 951 / 25 933 / 3 / 354 / 914.
SELECT
  (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS raw_drivers,
  (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS raw_shifts,
  (SELECT COUNT(*) FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS) AS staging_shifts,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DEPOT) AS dim_depot,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER) AS dim_driver,
  (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY) AS mart_driver_monthly;

-- V32 — R1 : plus aucun chauffeur arrivé à échéance depuis plus de 5 ans.
SELECT COUNT(*) AS chauffeurs_hors_conservation
FROM NYC_TAXI.RAW.DRIVERS
WHERE end_date < DATEADD(year, -5, CURRENT_DATE());

-- V33 — R2 : quatre tables personnelles avec RETENTION_TIME = 1.
SELECT table_schema, table_name, retention_time
FROM NYC_TAXI.INFORMATION_SCHEMA.TABLES
WHERE (table_schema = 'RAW' AND table_name IN ('DRIVERS', 'DRIVER_SHIFTS'))
   OR (table_schema = 'MARTS' AND table_name IN ('DIM_DRIVER', 'MART_DRIVER_MONTHLY'))
ORDER BY table_schema, table_name;

-- V34 — R3 : aucun fichier.
LIST @NYC_TAXI.RAW.RH_STAGE;

-- V35 — Dernière mesure : huit lignes au même instant.
SELECT regle, mesure_le, nb_anomalies, seuil, statut
FROM NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
QUALIFY DENSE_RANK() OVER (ORDER BY mesure_le DESC) = 1
ORDER BY regle;

-- V36 — Les trois tâches exécutées, sans futures lignes SCHEDULED.
SELECT name, state, error_message, scheduled_time, completed_time
FROM TABLE(NYC_TAXI.INFORMATION_SCHEMA.TASK_HISTORY(
  SCHEDULED_TIME_RANGE_START => DATEADD(hour, -24, CURRENT_TIMESTAMP()),
  SCHEDULED_TIME_RANGE_END => CURRENT_TIMESTAMP(),
  RESULT_LIMIT => 100))
WHERE name IN ('T_PURGE', 'T_QUALITE', 'T_TABLES')
  AND query_id IS NOT NULL
ORDER BY scheduled_time DESC, name;

-- V37 — Preuve effective après INSERT OVERWRITE, sans afficher de valeur RH.
-- POLICY_REFERENCES dépend des privilèges de visibilité sur les politiques ;
-- ce test métier prouve directement que le masquage reste appliqué.
USE ROLE ANALYSTE;
SELECT
  COUNT(*) AS lignes_visibles,
  COUNT_IF(driver_id = '*****') AS driver_id_masque,
  COUNT_IF(first_name = '*****') AS prenoms_masques,
  COUNT_IF(last_name = '*****') AS noms_masques,
  COUNT_IF(email = '*****') AS emails_masques,
  COUNT_IF(phone = '*****') AS telephones_masques,
  COUNT_IF(phone IS NULL) AS telephones_nuls,
  COUNT_IF(tlc_license_number = '*****') AS licences_masquees,
  COUNT_IF(MONTH(birth_date) = 1 AND DAY(birth_date) = 1)
    AS naissances_limitees_annee
FROM NYC_TAXI.MARTS.DIM_DRIVER;

USE ROLE TRANSFORMER;

-- V38 — Zéro description manquante sur les tables complètes.
SELECT table_name, COUNT_IF(comment IS NULL OR TRIM(comment) = '') AS descriptions_manquantes
FROM NYC_TAXI.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'MARTS' AND table_name IN ('DIM_DEPOT', 'DIM_DRIVER')
GROUP BY table_name
ORDER BY table_name;

-- V39 — Catalogue : 4 + 12 + 8 = 24 colonnes.
SELECT table_name, COUNT(*) AS nb_colonnes
FROM NYC_TAXI.GOUVERNANCE.V_CATALOGUE
GROUP BY table_name
ORDER BY table_name;

-- Arrêt final obligatoire pour ne pas consommer de crédits chaque jour :
-- ALTER TASK NYC_TAXI.MARTS.T_PURGE SUSPEND;
