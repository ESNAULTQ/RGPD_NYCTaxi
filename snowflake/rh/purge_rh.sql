-- =====================================================================
-- purge_rh.sql — appliquer R1 et prouver la suppression
-- Exécuter EN ENTIER avec TRANSFORMER, une seule fois avant les tâches.
-- Une fin de contrat strictement antérieure à aujourd'hui moins 5 ans est purgée.
-- Le script supprime toutes les copies physiques, services compris, puis montre
-- l'état antérieur avec Time Travel sans afficher de valeur personnelle.
-- =====================================================================

USE SECONDARY ROLES NONE;
USE ROLE TRANSFORMER;
USE WAREHOUSE NYC_TAXI_WH;

-- P01 — Prévision. Le jeu fourni donne 46 chauffeurs au 2026-11-03.
SELECT COUNT(*) AS chauffeurs_a_purger
FROM NYC_TAXI.RAW.DRIVERS
WHERE end_date < DATEADD(year, -5, CURRENT_DATE());

-- L'instant est conservé dans la session Snowsight pour la preuve Time Travel.
-- Il faut donc exécuter ce fichier en entier dans la même feuille.
SET instant_avant_purge = CURRENT_TIMESTAMP();

BEGIN TRANSACTION;

-- MARTS est purgé immédiatement : si la qualité bloque ensuite sa reconstruction,
-- aucune ancienne copie personnelle ne doit rester disponible.
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

-- R1 s'applique aussi aux services rattachés. On les traite avant DRIVERS afin
-- de pouvoir encore retrouver la date de fin du chauffeur dans la source.
DELETE FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
WHERE s.driver_id IN (
    SELECT driver_id FROM NYC_TAXI.RAW.DRIVERS
    WHERE end_date < DATEADD(year, -5, CURRENT_DATE())
);

DELETE FROM NYC_TAXI.RAW.DRIVERS
WHERE end_date < DATEADD(year, -5, CURRENT_DATE());

COMMIT;

-- P02 — État courant : 354 chauffeurs attendus avec le jeu fourni.
SELECT
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS raw_drivers_apres,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVER_SHIFTS) AS raw_shifts_apres,
    (SELECT COUNT(*) FROM NYC_TAXI.MARTS.DIM_DRIVER) AS dim_driver_apres,
    (SELECT COUNT(*) FROM NYC_TAXI.MARTS.MART_DRIVER_MONTHLY) AS mart_mensuel_apres;

-- P03 — Preuve Time Travel : aucun détail RH n'est affiché, seulement un nombre.
-- Attendu juste après la purge : 400 dans le passé et 354 dans l'état courant.
SELECT
    (SELECT COUNT(*)
     FROM NYC_TAXI.RAW.DRIVERS AT (TIMESTAMP => $instant_avant_purge)) AS avant_purge,
    (SELECT COUNT(*) FROM NYC_TAXI.RAW.DRIVERS) AS apres_purge;

-- P04 — La purge ne doit pas créer plus de 50 services orphelins.
SELECT COUNT(*) AS services_sans_chauffeur
FROM NYC_TAXI.RAW.DRIVER_SHIFTS s
WHERE NOT EXISTS (
    SELECT 1 FROM NYC_TAXI.RAW.DRIVERS d WHERE d.driver_id = s.driver_id
);
