-- =====================================================================
-- taches_rh.sql — graphe quotidien T_PURGE -> T_QUALITE -> T_TABLES
-- Exécuter EN ENTIER avec TRANSFORMER. Rejouable : la racine est suspendue
-- avant toute modification. Les tâches restent suspendues après création.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- Snowflake exige une racine suspendue avant de modifier un graphe existant.
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_PURGE SUSPEND;
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_QUALITE SUSPEND;
ALTER TASK IF EXISTS NYC_TAXI.MARTS.T_TABLES SUSPEND;

-- 1. Purger chaque jour à 07:00, heure de Paris.
-- Les copies MARTS sont aussi nettoyées avant la qualité : si T_QUALITE bloque,
-- aucune donnée arrivée à échéance ne subsiste en attendant le prochain run.
CREATE OR ALTER TASK NYC_TAXI.MARTS.T_PURGE
  WAREHOUSE = NYC_TAXI_WH
  SCHEDULE = 'USING CRON 0 7 * * * Europe/Paris'
  AUTOCOMMIT = TRUE
  COMMENT = 'R1 : purge quotidienne des chauffeurs terminés depuis plus de cinq ans et de toutes leurs copies'
AS
EXECUTE IMMEDIATE $$
BEGIN
  BEGIN TRANSACTION;

  DELETE FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY m
  WHERE m.driver_id IN (
    SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date < DATEADD(year, -5, CURRENT_DATE())
  );

  DELETE FROM NYC_TAXI.MARTS.DIM_DRIVER m
  WHERE m.driver_id IN (
    SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date < DATEADD(year, -5, CURRENT_DATE())
  );

  DELETE FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
  WHERE s.driver_id IN (
    SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date < DATEADD(year, -5, CURRENT_DATE())
  );

  DELETE FROM NYC_TAXI.RAW.DRIVERS
  WHERE end_date < DATEADD(year, -5, CURRENT_DATE());

  COMMIT;
  RETURN 'Purge terminée';
END;
$$;

-- 2. Mesurer les huit règles sur RAW et ajouter huit lignes d'historique.
-- Seul service_rattache est bloquant, et seulement si nb_anomalies > 50.
CREATE OR ALTER TASK NYC_TAXI.MARTS.T_QUALITE
  WAREHOUSE = NYC_TAXI_WH
  AUTOCOMMIT = TRUE
  COMMENT = 'Mesure les huit règles contractuelles ; service_rattache au-dessus de 50 bloque le graphe'
  AFTER NYC_TAXI.MARTS.T_PURGE
AS
EXECUTE IMMEDIATE $$
DECLARE
  mesure_le       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()::TIMESTAMP_NTZ;
  nb_service      NUMBER DEFAULT 0;
  service_bloque  EXCEPTION (-20001, 'service_rattache dépasse le seuil bloquant de 50');
BEGIN
  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT 'licence_unique', :mesure_le,
         COUNT(*) - COUNT(DISTINCT tlc_license_number), 0,
         IFF(COUNT(*) - COUNT(DISTINCT tlc_license_number) > 0, 'ALERTE', 'OK')
  FROM NYC_TAXI.RAW.DRIVERS;

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  WITH mesure AS (
    SELECT
      COUNT_IF(end_date IS NULL AND (phone IS NULL OR TRIM(phone) = '')) AS anomalies,
      COUNT_IF(end_date IS NULL) * 0.05 AS seuil
    FROM NYC_TAXI.RAW.DRIVERS
  )
  SELECT 'telephone_renseigne', :mesure_le, anomalies, seuil,
         IFF(anomalies > seuil, 'ALERTE', 'OK')
  FROM mesure;

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT 'email_valide', :mesure_le,
         COUNT_IF(email IS NULL OR NOT CONTAINS(email, '@')), 0,
         IFF(COUNT_IF(email IS NULL OR NOT CONTAINS(email, '@')) > 0, 'ALERTE', 'OK')
  FROM NYC_TAXI.RAW.DRIVERS;

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT 'dates_coherentes', :mesure_le,
         COUNT_IF(hire_date > CURRENT_DATE()
                  OR (end_date IS NOT NULL AND end_date < hire_date)), 0,
         IFF(COUNT_IF(hire_date > CURRENT_DATE()
                      OR (end_date IS NOT NULL AND end_date < hire_date)) > 0,
             'ALERTE', 'OK')
  FROM NYC_TAXI.RAW.DRIVERS;

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  WITH mesure AS (
    SELECT
      (SELECT COUNT_IF(depot NOT IN ('Bronx', 'Brooklyn', 'Queens') OR depot IS NULL)
       FROM NYC_TAXI.RAW.DRIVERS)
      +
      (SELECT COUNT_IF(depot NOT IN ('Bronx', 'Brooklyn', 'Queens') OR depot IS NULL)
       FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS anomalies
  )
  SELECT 'depot_connu', :mesure_le, anomalies, 0,
         IFF(anomalies > 0, 'ALERTE', 'OK')
  FROM mesure;

  SELECT COUNT(*) INTO :nb_service
  FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
  WHERE NOT EXISTS (
    SELECT 1 FROM NYC_TAXI.RAW.DRIVERS d WHERE d.driver_id = s.driver_id
  );

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT 'service_rattache', :mesure_le, :nb_service, 50,
         IFF(:nb_service > 50, 'ALERTE', 'OK');

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT 'service_unique', :mesure_le,
         COUNT(*) - COUNT(DISTINCT shift_id), 0,
         IFF(COUNT(*) - COUNT(DISTINCT shift_id) > 0, 'ALERTE', 'OK')
  FROM NYC_TAXI.RAW.DRIVER_SHIFTS;

  INSERT INTO NYC_TAXI.GOUVERNANCE.QUALITE_RESULTATS
    (regle, mesure_le, nb_anomalies, seuil, statut)
  SELECT 'duree_plausible', :mesure_le,
         COUNT_IF(hours_worked > 16), 0,
         IFF(COUNT_IF(hours_worked > 16) > 0, 'ALERTE', 'OK')
  FROM NYC_TAXI.RAW.DRIVER_SHIFTS;

  IF (nb_service > 50) THEN
    RAISE service_bloque;
  END IF;

  RETURN 'Qualité enregistrée : seuil bloquant respecté';
END;
$$;

-- 3. Reconstruire sans remplacer les tables : tags, commentaires et politiques
-- restent attachés. Cette tâche ne démarre que si T_QUALITE a réussi.
CREATE OR ALTER TASK NYC_TAXI.MARTS.T_TABLES
  WAREHOUSE = NYC_TAXI_WH
  AUTOCOMMIT = TRUE
  COMMENT = 'Reconstruit les trois MARTS avec INSERT OVERWRITE après qualité réussie'
  AFTER NYC_TAXI.MARTS.T_QUALITE
AS
EXECUTE IMMEDIATE $$
BEGIN
  INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DEPOT
    (depot, quartier, ouvert_en, nb_places)
  VALUES
    ('Bronx',    'Hunts Point',      2009, 140),
    ('Brooklyn', 'East New York',    2011, 120),
    ('Queens',   'Long Island City', 2008, 180);

  INSERT OVERWRITE INTO NYC_TAXI.MARTS.DIM_DRIVER
  SELECT
    driver_id, first_name, last_name, email, phone, birth_date,
    tlc_license_number, depot, hire_date, end_date,
    end_date IS NULL AS is_active,
    ROUND(DATEDIFF(day, hire_date, COALESCE(end_date, CURRENT_DATE())) / 365.25, 1)
      AS tenure_years
  FROM NYC_TAXI.STAGING.STG_RH__DRIVERS;

  INSERT OVERWRITE INTO NYC_TAXI.MARTS.MART_DRIVER_MONTHLY
  SELECT
    DATE_TRUNC('month', s.shift_date)::date AS activity_month,
    s.driver_id,
    d.first_name || ' ' || d.last_name AS driver_name,
    s.depot,
    COUNT(*) AS nb_shifts,
    ROUND(SUM(s.hours_worked), 1) AS hours_worked,
    SUM(s.trips_count) AS trips_count,
    ROUND(SUM(s.revenue_usd), 2) AS revenue_usd
  FROM NYC_TAXI.STAGING.STG_RH__DRIVER_SHIFTS s
  LEFT JOIN NYC_TAXI.MARTS.DIM_DRIVER d ON d.driver_id = s.driver_id
  GROUP BY 1, 2, 3, 4;

  RETURN 'MARTS reconstruits sans perte des protections';
END;
$$;

-- Ne pas activer automatiquement : la checklist du jour 3 fait lancer et
-- observer le graphe, puis suspendre la racine pour éviter des crédits inutiles.
SHOW TASKS IN SCHEMA NYC_TAXI.MARTS;
